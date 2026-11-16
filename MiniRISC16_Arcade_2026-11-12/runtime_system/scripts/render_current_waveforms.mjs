import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const designRoot = path.resolve(scriptDir, '..');
const waveDir = path.join(designRoot, 'reports', 'waveforms', 'current_terminal');

function esc(value) {
  return String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

function parseVcd(filePath) {
  const lines = fs.readFileSync(filePath, 'utf8').split(/\r?\n/);
  const idInfo = new Map();
  const changes = new Map();
  let inData = false;
  let time = 0;

  for (const raw of lines) {
    const line = raw.trim();
    if (!inData) {
      const match = line.match(/^\$var\s+\S+\s+(\d+)\s+(\S+)\s+(\S+)/);
      if (match) {
        const [, width, id, name] = match;
        idInfo.set(id, { name, width: Number(width) });
        changes.set(name, []);
      }
      if (line.startsWith('$enddefinitions')) inData = true;
      continue;
    }
    if (!line || line.startsWith('$')) continue;
    if (line[0] === '#') {
      time = Number(line.slice(1));
      continue;
    }
    let id;
    let value;
    if ('01xz'.includes(line[0])) {
      value = line[0];
      id = line.slice(1).trim();
    } else if (line[0] === 'b') {
      const parts = line.slice(1).split(/\s+/);
      value = parts[0];
      id = parts[1];
    } else {
      continue;
    }
    const info = idInfo.get(id);
    if (!info) continue;
    const list = changes.get(info.name);
    if (!list.length || list.at(-1).value !== value) list.push({ time, value });
  }
  return { changes, info: new Map([...idInfo.values()].map(x => [x.name, x])) };
}

function valueAt(vcd, name, time) {
  const list = vcd.changes.get(name) || [];
  let value = 'x';
  for (const item of list) {
    if (item.time > time) break;
    value = item.value;
  }
  return value;
}

function formatValue(vcd, name, value) {
  if (/^[01]+$/.test(value)) {
    const width = vcd.info.get(name)?.width || value.length;
    const digits = Math.ceil(width / 4);
    return Number.parseInt(value, 2).toString(16).toUpperCase().padStart(digits, '0');
  }
  return value.toUpperCase();
}

function collectSegments(vcd, name, start, end) {
  const list = vcd.changes.get(name) || [];
  const points = [{ time: start, value: valueAt(vcd, name, start) }];
  for (const item of list) {
    if (item.time > start && item.time < end) points.push(item);
  }
  points.push({ time: end, value: valueAt(vcd, name, end) });
  return points;
}

function findQualifiedEvents(vcd, qualifier, expected, payload, acceptedValues) {
  const events = [];
  for (const item of vcd.changes.get(qualifier) || []) {
    if (item.value !== '1') continue;
    if (expected && formatValue(vcd, expected.name, valueAt(vcd, expected.name, item.time)) !== expected.value) continue;
    const payloadValue = formatValue(vcd, payload, valueAt(vcd, payload, item.time));
    if (!acceptedValues || acceptedValues.includes(payloadValue)) events.push({ time: item.time, value: payloadValue });
  }
  return events;
}

const palette = {
  page: '#F6F8FB',
  ink: '#172033',
  muted: '#60708A',
  plot: '#0B1220',
  plot2: '#111A2B',
  grid: '#2B3850',
  scalar: '#55E68B',
  bus: '#62C6FF',
  busText: '#D8F2FF',
  accent: '#FFB547',
  alert: '#FF6B6B',
  labelBg: '#FFFFFF',
  divider: '#D7DFEA'
};

function renderPanel(vcd, panel, x, y, width, rowHeight = 42) {
  const labelWidth = 185;
  const plotX = x + labelWidth;
  const plotW = width - labelWidth;
  const headerH = 42;
  const plotY = y + headerH;
  const plotH = panel.signals.length * rowHeight;
  const endY = plotY + plotH;
  const sx = t => plotX + ((t - panel.start) / (panel.end - panel.start)) * plotW;
  const out = [];

  out.push(`<rect x="${x}" y="${y}" width="${width}" height="${headerH + plotH}" rx="8" fill="${palette.labelBg}" stroke="${palette.divider}"/>`);
  out.push(`<rect x="${plotX}" y="${plotY}" width="${plotW}" height="${plotH}" fill="${palette.plot}"/>`);
  out.push(`<text x="${x + 14}" y="${y + 26}" class="panel-title">${esc(panel.title)}</text>`);
  out.push(`<text x="${plotX + plotW - 12}" y="${y + 26}" text-anchor="end" class="panel-range">${(panel.start / 1e6).toFixed(3)}–${(panel.end / 1e6).toFixed(3)} µs</text>`);

  for (let tick = 0; tick <= 5; tick++) {
    const tx = plotX + (plotW * tick) / 5;
    const tt = panel.start + ((panel.end - panel.start) * tick) / 5;
    out.push(`<line x1="${tx}" y1="${plotY}" x2="${tx}" y2="${endY}" stroke="${palette.grid}" stroke-width="1"/>`);
    out.push(`<text x="${tx}" y="${plotY - 8}" text-anchor="middle" class="axis">${(tt / 1000).toFixed(0)} ns</text>`);
  }

  panel.signals.forEach((signal, row) => {
    const cy = plotY + row * rowHeight + rowHeight / 2;
    const top = cy - 11;
    const bottom = cy + 11;
    out.push(`<line x1="${x}" y1="${plotY + row * rowHeight}" x2="${x + width}" y2="${plotY + row * rowHeight}" stroke="${row ? palette.divider : palette.grid}" stroke-opacity="${row ? 0.55 : 1}"/>`);
    out.push(`<text x="${plotX - 12}" y="${cy + 5}" text-anchor="end" class="signal">${esc(signal.label || signal.name)}</text>`);
    const segments = collectSegments(vcd, signal.name, panel.start, panel.end);
    const widthBits = vcd.info.get(signal.name)?.width || 1;
    if (widthBits === 1) {
      let d = '';
      for (let i = 0; i < segments.length - 1; i++) {
        const a = segments[i];
        const b = segments[i + 1];
        const xa = sx(a.time);
        const xb = sx(b.time);
        const ya = a.value === '1' ? top : a.value === '0' ? bottom : cy;
        if (!d) d = `M ${xa} ${ya}`;
        d += ` H ${xb}`;
        if (i + 1 < segments.length - 1) {
          const next = segments[i + 1].value;
          const yn = next === '1' ? top : next === '0' ? bottom : cy;
          d += ` V ${yn}`;
        }
      }
      out.push(`<path d="${d}" fill="none" stroke="${palette.scalar}" stroke-width="2"/>`);
    } else {
      for (let i = 0; i < segments.length - 1; i++) {
        const a = segments[i];
        const b = segments[i + 1];
        const xa = sx(a.time);
        const xb = sx(b.time);
        const value = formatValue(vcd, signal.name, a.value);
        out.push(`<line x1="${xa}" y1="${cy}" x2="${xb}" y2="${cy}" stroke="${palette.bus}" stroke-width="2"/>`);
        if (i > 0) {
          out.push(`<path d="M ${xa - 4} ${cy - 8} L ${xa + 4} ${cy + 8} M ${xa - 4} ${cy + 8} L ${xa + 4} ${cy - 8}" stroke="${palette.bus}" stroke-width="1.5"/>`);
        }
        if (xb - xa > 42) {
          out.push(`<text x="${(xa + xb) / 2}" y="${cy - 7}" text-anchor="middle" class="bus-value">${esc(value)}</text>`);
        }
      }
    }
  });

  for (const event of panel.events || []) {
    const ex = sx(event.time);
    out.push(`<line x1="${ex}" y1="${plotY}" x2="${ex}" y2="${endY}" stroke="${event.color || palette.accent}" stroke-width="2" stroke-dasharray="6 4"/>`);
    out.push(`<rect x="${Math.max(plotX + 4, Math.min(ex - 54, plotX + plotW - 112))}" y="${plotY + 6}" width="108" height="24" rx="12" fill="${event.color || palette.accent}"/>`);
    out.push(`<text x="${Math.max(plotX + 58, Math.min(ex, plotX + plotW - 58))}" y="${plotY + 23}" text-anchor="middle" class="event">${esc(event.label)}</text>`);
  }
  return { svg: out.join('\n'), height: headerH + plotH };
}

function documentSvg(width, height, title, subtitle, panels, footer) {
  const panelSvg = panels.map(p => p.svg).join('\n');
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
<style>
  text { font-family: "Segoe UI", "Microsoft YaHei", sans-serif; fill: ${palette.ink}; }
  .title { font-size: 30px; font-weight: 600; }
  .subtitle { font-size: 16px; fill: ${palette.muted}; }
  .panel-title { font-size: 16px; font-weight: 600; }
  .panel-range, .axis { font-size: 12px; fill: ${palette.muted}; }
  .signal { font-family: Consolas, monospace; font-size: 14px; font-weight: 600; }
  .bus-value { font-family: Consolas, monospace; font-size: 12px; fill: ${palette.busText}; }
  .event { font-size: 12px; font-weight: 600; fill: #111827; }
  .footer { font-size: 13px; fill: ${palette.muted}; }
</style>
<rect width="100%" height="100%" fill="${palette.page}"/>
<text x="48" y="52" class="title">${esc(title)}</text>
<text x="48" y="80" class="subtitle">${esc(subtitle)}</text>
${panelSvg}
<text x="48" y="${height - 24}" class="footer">${esc(footer)}</text>
</svg>`;
}

function writeRunningLight() {
  const file = path.join(waveDir, 'runtime_running_light_io.vcd');
  const vcd = parseVcd(file);
  const writes = findQualifiedEvents(vcd, 'io_we', { name: 'io_addr', value: '30' }, 'io_wdata', ['0001', '0002']);
  if (writes.length < 2) throw new Error('Expected LED writes 0x01 and 0x02 were not found in the VCD.');
  const signals = [
    { name: 'clk' }, { name: 'rst' }, { name: 'pc', label: 'PC[9:0]' },
    { name: 'instruction' }, { name: 'io_we' }, { name: 'io_addr' },
    { name: 'io_wdata' }, { name: 'led', label: 'board LED' }
  ];
  const panels = [];
  const specs = [
    { event: writes[0], title: '首次写 LED：初始化为 0x01', label: 'OUP LED = 01' },
    { event: writes[1], title: '下一步写 LED：右移到 0x02', label: 'OUP LED = 02' }
  ];
  let y = 116;
  for (const spec of specs) {
    const start = Math.max(0, spec.event.time - 70000);
    const end = spec.event.time + 70000;
    const panel = renderPanel(vcd, {
      title: spec.title, start, end, signals,
      events: [{ time: spec.event.time, label: spec.label }]
    }, 48, y, 1504, 40);
    panels.push(panel);
    y += panel.height + 42;
  }
  const height = y + 18;
  const svg = documentSvg(
    1600, height,
    '当前终端版 · Running Light I/O 波形',
    'runtime_board_top → runtime_soc → cpu_core → I/O decoder → led8；保留 10 月 17 日要求的 PC、instruction、io_we、io_addr、io_wdata、LED。',
    panels,
    '功能判定：tb_runtime_running_light_wave: TEST PASS · LED 0x01 → 0x02 · 100 MHz 行为仿真'
  );
  fs.writeFileSync(path.join(waveDir, 'runtime_running_light_io.svg'), svg);
}

function writeExtendedIsa() {
  const file = path.join(waveDir, 'runtime_extended_isa.vcd');
  const vcd = parseVcd(file);
  const dataWrites = findQualifiedEvents(vcd, 'data_we', null, 'data_wdata');
  const dataReads = findQualifiedEvents(vcd, 'data_re', null, 'data_rdata');
  const jumps = (vcd.changes.get('long_jump') || []).filter(x => x.value === '1');
  const ioWrites = findQualifiedEvents(vcd, 'io_we', { name: 'io_addr', value: '30' }, 'io_wdata');
  const signals = [
    { name: 'clk' }, { name: 'rst' }, { name: 'pc', label: 'PC[9:0]' },
    { name: 'pc_next' }, { name: 'instruction' }, { name: 'opcode' },
    { name: 'data_we' }, { name: 'data_re' }, { name: 'data_addr' },
    { name: 'data_wdata' }, { name: 'data_rdata' }, { name: 'long_jump' },
    { name: 'io_we' }, { name: 'io_addr' }, { name: 'io_wdata' },
    { name: 'z_flag' }, { name: 'r0' }, { name: 'r1' }, { name: 'r2' }, { name: 'r3' }
  ];
  const events = [];
  if (dataWrites[0]) events.push({ time: dataWrites[0].time, label: 'STR [22]=005A', color: palette.accent });
  if (dataReads[0]) events.push({ time: dataReads[0].time, label: 'LDR R2=005A', color: '#7DD3FC' });
  if (jumps[0]) events.push({ time: jumps[0].time, label: 'JMPA 200', color: '#C4B5FD' });
  if (ioWrites[0]) events.push({ time: ioWrites[0].time, label: 'OUP 30=A5', color: '#86EFAC' });
  const panel = renderPanel(vcd, {
    title: '扩展 ISA 连续执行：STR → LDR → CMP/JZ → JMPA → OUP',
    start: 20000, end: 125000, signals, events
  }, 48, 116, 1504, 42);
  const height = 116 + panel.height + 58;
  const svg = documentSvg(
    1600, height,
    '当前终端版 · 扩展 ISA 波形',
    '验证 256×16 数据 RAM、10 位 PC、页内 JZ 与跨页 JMPA；指令来自当前 runtime_system/core RTL。',
    [panel],
    '功能判定：tb_runtime_extended_isa_wave: TEST PASS · memory[0x22]=0x005A · R2=0x005A · PC=0x202 · OUP 0x30=0x00A5'
  );
  fs.writeFileSync(path.join(waveDir, 'runtime_extended_isa.svg'), svg);
}

fs.mkdirSync(waveDir, { recursive: true });
writeRunningLight();
writeExtendedIsa();
console.log('WAVEFORM_RENDER_PASS');

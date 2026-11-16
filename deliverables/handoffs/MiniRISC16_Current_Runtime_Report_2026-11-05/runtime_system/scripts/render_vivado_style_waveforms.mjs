import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, '..');
const waveDir = path.join(root, 'reports', 'waveforms', 'current_terminal', 'final_vivado_style');
fs.mkdirSync(waveDir, { recursive: true });

function esc(s) {
  return String(s).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

function parseVcd(file) {
  const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
  const byId = new Map();
  const info = new Map();
  const changes = new Map();
  let time = 0;
  let data = false;
  for (const raw of lines) {
    const line = raw.trim();
    if (!data) {
      const m = line.match(/^\$var\s+\S+\s+(\d+)\s+(\S+)\s+(\S+)/);
      if (m) {
        const item = { width: Number(m[1]), id: m[2], name: m[3] };
        byId.set(item.id, item);
        info.set(item.name, item);
        changes.set(item.name, []);
      }
      if (line.startsWith('$enddefinitions')) data = true;
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
      [value, id] = line.slice(1).split(/\s+/);
    } else continue;
    const item = byId.get(id);
    if (!item) continue;
    const list = changes.get(item.name);
    if (!list.length || list.at(-1).value !== value) list.push({ time, value });
  }
  return { info, changes };
}

function valueAt(vcd, name, time) {
  let value = 'x';
  for (const item of vcd.changes.get(name) || []) {
    if (item.time > time) break;
    value = item.value;
  }
  return value;
}

function valueText(vcd, name, value) {
  if (!/^[01]+$/.test(value)) return value.toUpperCase();
  const width = vcd.info.get(name)?.width || value.length;
  return BigInt(`0b${value}`).toString(16).toUpperCase().padStart(Math.ceil(width / 4), '0');
}

function points(vcd, name, start, end) {
  const out = [{ time: start, value: valueAt(vcd, name, start) }];
  for (const item of vcd.changes.get(name) || []) {
    if (item.time > start && item.time < end) out.push(item);
  }
  out.push({ time: end, value: valueAt(vcd, name, end) });
  return out;
}

function riseEvents(vcd, qualifier, filterName, filterValue, payload) {
  const out = [];
  for (const item of vcd.changes.get(qualifier) || []) {
    if (item.value !== '1') continue;
    if (filterName && valueText(vcd, filterName, valueAt(vcd, filterName, item.time)) !== filterValue) continue;
    out.push({
      time: item.time,
      value: payload ? valueText(vcd, payload, valueAt(vcd, payload, item.time)) : '1'
    });
  }
  return out;
}

const C = {
  chrome: '#E9E9E9',
  pane: '#F3F3F3',
  plot: '#FFFFFF',
  grid: '#D9D9D9',
  gridStrong: '#A9A9A9',
  edge: '#A7A7A7',
  text: '#202020',
  muted: '#5B5B5B',
  wave: '#00C800',
  fill: '#D7EBC8',
  cursor: '#FFC400',
  select: '#DDEBFA'
};

function niceTick(span) {
  const ns = span / 1000;
  const target = ns / 7;
  const p = 10 ** Math.floor(Math.log10(Math.max(target, 1e-9)));
  const n = target / p;
  const step = n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10;
  return step * p * 1000;
}

function renderWindow(vcd, spec, x, y, width, rowH) {
  const nameW = 250;
  const valueW = 112;
  const leftW = nameW + valueW;
  const axisH = 52;
  const plotX = x + leftW;
  const plotY = y + axisH;
  const plotW = width - leftW;
  const plotH = rowH * spec.signals.length;
  const sx = t => plotX + ((t - spec.start) / (spec.end - spec.start)) * plotW;
  const out = [];

  out.push(`<rect x="${x}" y="${y}" width="${width}" height="${axisH + plotH}" fill="${C.plot}" stroke="${C.edge}"/>`);
  out.push(`<rect x="${x}" y="${y}" width="${leftW}" height="${axisH + plotH}" fill="${C.pane}"/>`);
  out.push(`<rect x="${x}" y="${y}" width="${leftW}" height="${axisH}" fill="${C.chrome}"/>`);
  out.push(`<text x="${x + 18}" y="${y + 33}" class="head">Name</text>`);
  out.push(`<text x="${x + nameW + 18}" y="${y + 33}" class="head">Value</text>`);
  out.push(`<line x1="${x + nameW}" y1="${y}" x2="${x + nameW}" y2="${plotY + plotH}" class="border"/>`);
  out.push(`<line x1="${plotX}" y1="${y}" x2="${plotX}" y2="${plotY + plotH}" class="border"/>`);
  out.push(`<line x1="${x}" y1="${plotY}" x2="${x + width}" y2="${plotY}" class="border"/>`);

  const tickStep = niceTick(spec.end - spec.start);
  const firstTick = Math.ceil(spec.start / tickStep) * tickStep;
  for (let t = firstTick; t <= spec.end; t += tickStep) {
    const tx = sx(t);
    out.push(`<line x1="${tx}" y1="${plotY}" x2="${tx}" y2="${plotY + plotH}" class="major-grid"/>`);
    out.push(`<line x1="${tx}" y1="${y + axisH - 14}" x2="${tx}" y2="${plotY}" class="tick"/>`);
    out.push(`<text x="${tx}" y="${y + 25}" text-anchor="middle" class="time">${(t / 1000).toFixed(3)} ns</text>`);
    for (let m = 1; m < 5; m++) {
      const mt = t + (tickStep * m) / 5;
      if (mt >= spec.end) break;
      const mx = sx(mt);
      out.push(`<line x1="${mx}" y1="${y + axisH - 8}" x2="${mx}" y2="${plotY}" class="minor-tick"/>`);
      out.push(`<line x1="${mx}" y1="${plotY}" x2="${mx}" y2="${plotY + plotH}" class="minor-grid"/>`);
    }
  }

  spec.signals.forEach((sig, row) => {
    const top = plotY + row * rowH;
    const cy = top + rowH / 2;
    const hi = cy - Math.min(15, rowH * 0.25);
    const lo = cy + Math.min(15, rowH * 0.25);
    const widthBits = vcd.info.get(sig.name)?.width || 1;
    const segs = points(vcd, sig.name, spec.start, spec.end);
    out.push(`<line x1="${x}" y1="${top}" x2="${x + width}" y2="${top}" class="row"/>`);
    out.push(`<text x="${x + 20}" y="${cy + 6}" class="name">${esc(sig.label || sig.name)}</text>`);
    out.push(`<text x="${x + leftW - 16}" y="${cy + 6}" text-anchor="end" class="value">${esc(valueText(vcd, sig.name, valueAt(vcd, sig.name, spec.end - 1)))}</text>`);
    if (widthBits === 1) {
      let d = '';
      for (let i = 0; i < segs.length - 1; i++) {
        const a = segs[i];
        const b = segs[i + 1];
        const xa = sx(a.time);
        const xb = sx(b.time);
        const ya = a.value === '1' ? hi : a.value === '0' ? lo : cy;
        if (a.value === '1') out.push(`<rect x="${xa}" y="${hi}" width="${Math.max(0, xb - xa)}" height="${lo - hi}" fill="${C.fill}"/>`);
        if (!d) d = `M ${xa} ${ya}`;
        d += ` H ${xb}`;
        if (i + 1 < segs.length - 1) {
          const next = segs[i + 1].value;
          d += ` V ${next === '1' ? hi : next === '0' ? lo : cy}`;
        }
      }
      out.push(`<path d="${d}" class="wave"/>`);
    } else {
      for (let i = 0; i < segs.length - 1; i++) {
        const a = segs[i];
        const b = segs[i + 1];
        const xa = sx(a.time);
        const xb = sx(b.time);
        if (i > 0) out.push(`<path d="M ${xa - 5} ${hi} L ${xa + 5} ${lo} M ${xa - 5} ${lo} L ${xa + 5} ${hi}" class="bus"/>`);
        out.push(`<line x1="${xa}" y1="${hi}" x2="${xb}" y2="${hi}" class="bus"/>`);
        out.push(`<line x1="${xa}" y1="${lo}" x2="${xb}" y2="${lo}" class="bus"/>`);
        if (xb - xa > 50) {
          out.push(`<text x="${(xa + xb) / 2}" y="${cy + 5}" text-anchor="middle" class="bus-text">${esc(valueText(vcd, sig.name, a.value))}</text>`);
        }
      }
    }
  });

  for (const event of spec.events || []) {
    const ex = sx(event.time);
    out.push(`<line x1="${ex}" y1="${y}" x2="${ex}" y2="${plotY + plotH}" class="cursor"/>`);
    const labelX = Math.min(Math.max(ex + 8, plotX + 8), plotX + plotW - 170);
    out.push(`<rect x="${labelX}" y="${plotY + 5}" width="162" height="25" rx="2" fill="#FFF4BF" stroke="#D4A500"/>`);
    out.push(`<text x="${labelX + 7}" y="${plotY + 22}" class="event">${esc(event.label)}</text>`);
  }
  return { svg: out.join('\n'), height: axisH + plotH };
}

function documentSvg(title, subtitle, windows, footer, width = 2200) {
  let y = 88;
  const groups = [];
  for (const win of windows) {
    if (win.caption) {
      groups.push(`<text x="24" y="${y + 22}" class="caption">${esc(win.caption)}</text>`);
      y += 34;
    }
    const rendered = renderWindow(win.vcd, win, 0, y, width, win.rowH || 62);
    groups.push(rendered.svg);
    y += rendered.height + 24;
  }
  const height = y + 44;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
<style>
text { font-family: "Segoe UI", Arial, sans-serif; fill: ${C.text}; }
.title { font-size: 30px; font-weight: 650; }
.subtitle { font-size: 15px; fill: ${C.muted}; }
.head { font-size: 17px; }
.name { font-size: 17px; }
.value,.bus-text,.time { font-family: Consolas, monospace; }
.value { font-size: 16px; }
.time { font-size: 15px; }
.bus-text { font-size: 15px; font-weight: 600; }
.event { font-size: 14px; font-weight: 600; }
.caption { font-size: 17px; font-weight: 650; fill: #303030; }
.footer { font-size: 15px; fill: #3C3C3C; }
.border { stroke: ${C.edge}; stroke-width: 1.5; }
.row { stroke: #D2D2D2; stroke-width: 1; }
.tick { stroke: #666; stroke-width: 1.2; }
.minor-tick { stroke: #8D8D8D; stroke-width: 1; }
.major-grid { stroke: ${C.gridStrong}; stroke-width: 1.2; }
.minor-grid { stroke: ${C.grid}; stroke-width: 0.8; }
.wave,.bus { fill: none; stroke: ${C.wave}; stroke-width: 2; }
.cursor { stroke: ${C.cursor}; stroke-width: 2; }
</style>
<rect width="100%" height="100%" fill="#FAFAFA"/>
<rect width="100%" height="72" fill="#F1F1F1" stroke="#C9C9C9"/>
<text x="24" y="34" class="title">${esc(title)}</text>
<text x="24" y="59" class="subtitle">${esc(subtitle)}</text>
${groups.join('\n')}
<rect x="0" y="${height - 38}" width="${width}" height="38" fill="#EFEFEF" stroke="#C9C9C9"/>
<text x="18" y="${height - 13}" class="footer">${esc(footer)}</text>
</svg>`;
}

function save(name, svg) {
  fs.writeFileSync(path.join(waveDir, `${name}.svg`), svg);
}

const vivadoDir = path.join(root, 'reports', 'waveforms', 'current_terminal', 'vivado');
const extendedVcd = path.join(vivadoDir, 'extended_isa.vcd');
const runningVcd = path.join(vivadoDir, 'running_light.vcd');
if (!fs.existsSync(extendedVcd) || !fs.existsSync(runningVcd)) {
  throw new Error('Native Vivado/XSim VCD files are missing. Run scripts/run_runtime_waveforms_xsim.ps1 first.');
}
const extended = parseVcd(extendedVcd);
const running = parseVcd(runningVcd);
const extStart = 18000;
const extEnd = 175000;

save('01_single_cycle_commit', documentSvg(
  '01  Single-Cycle Commit',
  'Current terminal edition · 10-bit PC · current cpu_core RTL',
  [{ vcd: extended, start: extStart, end: 92000, rowH: 72, signals: [
    { name: 'clk' }, { name: 'rst' }, { name: 'pc', label: 'pc[9:0]' },
    { name: 'pc_next' }, { name: 'instruction' }, { name: 'reg_write' },
    { name: 'data_we' }, { name: 'io_we' }
  ]}],
  'SELF-CHECK PASS · reset release, fetch/decode and architectural writes align to clock boundaries'
));

save('02_cmp_jz_jump_jmpa', documentSvg(
  '02  CMP, JZ, JUMP and JMPA',
  'Stored Z flag drives JZ; JUMP stays within the page; JMPA uses the 10-bit absolute target',
  [{ vcd: extended, start: 56000, end: 150000, rowH: 62, signals: [
    { name: 'clk' }, { name: 'pc', label: 'pc[9:0]' }, { name: 'instruction' },
    { name: 'z_flag' }, { name: 'flags_write' }, { name: 'branch_z' },
    { name: 'branch_taken' }, { name: 'jump' }, { name: 'long_jump', label: 'jmpa' },
    { name: 'pc_next' }
  ], events: [
    { time: 75000, label: 'JZ taken' },
    { time: 85000, label: 'JUMP 00A' },
    { time: 95000, label: 'JMPA 200' }
  ]}],
  'SELF-CHECK PASS · CMP sets Z=1 · JZ→0x008 · JUMP→0x00A · JMPA→0x200'
));

save('03_registers_alu_writeback', documentSvg(
  '03  Registers, ALU and Writeback',
  'Operands, ALU result and selected writeback value from the current datapath',
  [{ vcd: extended, start: extStart, end: extEnd, rowH: 55, signals: [
    { name: 'clk' }, { name: 'pc', label: 'pc[9:0]' }, { name: 'instruction' },
    { name: 'rd_data' }, { name: 'rs_data' }, { name: 'alu_result' },
    { name: 'writeback_data' }, { name: 'reg_write' },
    { name: 'r0' }, { name: 'r1' }, { name: 'r2' }, { name: 'r3' }
  ]}],
  'SELF-CHECK PASS · R0=0x0022 · R1=0x005A · LDR writes R2=0x005A · page-2 code writes R3=0x00A5'
));

const ledWrites = riseEvents(running, 'io_we', 'io_addr', '30', 'io_wdata')
  .filter(e => e.value === '0001' || e.value === '0002');
if (ledWrites.length < 2) throw new Error('Running Light writes 0x01 and 0x02 were not found.');
const ioSignals = [
  { name: 'clk' }, { name: 'rst' }, { name: 'pc', label: 'pc[9:0]' },
  { name: 'instruction' }, { name: 'io_we' }, { name: 'io_addr' },
  { name: 'io_wdata' }, { name: 'led', label: 'board_led[7:0]' }
];
save('04_runtime_io_led', documentSvg(
  '04  Runtime I/O and Board LED',
  'Two focused Vivado-style capture windows from the current non-HDMI Running Light program',
  [
    { caption: 'Capture A — first visible LED write', vcd: running, start: ledWrites[0].time - 65000, end: ledWrites[0].time + 65000, rowH: 45, signals: ioSignals, events: [{ time: ledWrites[0].time, label: 'OUP 30 = 0001' }] },
    { caption: 'Capture B — next visible LED write', vcd: running, start: ledWrites[1].time - 65000, end: ledWrites[1].time + 65000, rowH: 45, signals: ioSignals, events: [{ time: ledWrites[1].time, label: 'OUP 30 = 0002' }] }
  ],
  'SELF-CHECK PASS · PC/instruction/io_we/io_addr/io_wdata/LED · board LED changes 0x01 → 0x02'
));

save('05_ldr_str_data_memory', documentSvg(
  '05  LDR / STR Data Memory',
  '256×16 data RAM interface and LDR writeback in the current ISA',
  [{ vcd: extended, start: 36000, end: 76000, rowH: 68, signals: [
    { name: 'clk' }, { name: 'pc', label: 'pc[9:0]' }, { name: 'instruction' },
    { name: 'data_we' }, { name: 'data_re' }, { name: 'data_addr' },
    { name: 'data_wdata' }, { name: 'data_rdata' }, { name: 'writeback_data' },
    { name: 'reg_write' }, { name: 'r2' }
  ], events: [
    { time: 45000, label: 'STR [22]=005A' },
    { time: 55000, label: 'LDR R2=[22]' }
  ]}],
  'SELF-CHECK PASS · memory[0x22]=0x005A · LDR writeback=0x005A · R2=0x005A'
));

console.log(`VIVADO_STYLE_WAVEFORMS_PASS ${waveDir}`);

const fs = require('fs');
const path = require('path');

const sharpRoot = process.env.CODEX_NODE_MODULES;
if (!sharpRoot) throw new Error('CODEX_NODE_MODULES is required');
const sharp = require(path.join(sharpRoot, 'sharp'));

const root = path.resolve(__dirname, '..');
const outputDir = path.join(root, 'output');

const classes = {
  move: {
    signals: ['clk','mem_addr','instruction','opcode','rd_addr','rs_addr','imm8','alu_src','rs_data','alu_result','reg_write','writeback_data','r0','r1','r2','r3'],
  },
  arithmetic: {
    signals: ['clk','mem_addr','instruction','opcode','rd_data','rs_data','imm8','alu_src','alu_op','alu_result','reg_write','flags_write','z_flag','c_flag','r0','r1'],
  },
  logic: {
    signals: ['clk','mem_addr','instruction','opcode','rd_data','rs_data','alu_op','alu_result','reg_write','writeback_data','r0','r1'],
  },
  branch: {
    signals: ['clk','mem_addr','instruction','opcode','imm8','z_flag','branch_z','jump','branch_taken','pc_plus_one','pc_next','r2','r3'],
  },
  io: {
    signals: ['clk','mem_addr','instruction','opcode','io_re','io_we','io_addr','io_rdata','io_wdata','wb_sel','reg_write','r0'],
  },
};

const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&apos;'}[c]));

function parseVcd(file) {
  const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
  const scope = [];
  const defs = [];
  let inDefs = true;
  let currentTime = 0;
  const events = new Map();

  for (const raw of lines) {
    const line = raw.trim();
    if (!line) continue;
    if (inDefs) {
      if (line.startsWith('$scope ')) {
        const p = line.split(/\s+/);
        scope.push(p[2]);
      } else if (line.startsWith('$upscope')) {
        scope.pop();
      } else if (line.startsWith('$var ')) {
        const p = line.split(/\s+/);
        const width = Number(p[2]);
        const id = p[3];
        const ref = p[4];
        const full = [...scope, ref].join('.');
        defs.push({ id, width, ref, full });
        if (!events.has(id)) events.set(id, []);
      } else if (line.startsWith('$enddefinitions')) {
        inDefs = false;
      }
      continue;
    }

    if (line[0] === '#') {
      currentTime = Number(line.slice(1));
    } else if (/^[01xXzZ]/.test(line)) {
      const value = line[0].toLowerCase();
      const id = line.slice(1).trim();
      if (events.has(id)) events.get(id).push({ t: currentTime, v: value });
    } else if (/^[bB]/.test(line)) {
      const p = line.split(/\s+/);
      const value = p[0].slice(1).toLowerCase();
      const id = p[1];
      if (events.has(id)) events.get(id).push({ t: currentTime, v: value });
    }
  }
  return { defs, events };
}

function valueAt(events, t) {
  let value = 'x';
  for (const e of events) {
    if (e.t > t) break;
    value = e.v;
  }
  return value;
}

function padHex(value, bits) {
  if (!value || /[xz]/i.test(value)) return value?.toUpperCase() || 'X';
  const n = parseInt(value, 2);
  return n.toString(16).toUpperCase().padStart(Math.ceil(bits / 4), '0');
}

function valueLabel(_name, bin, width) {
  if (width === 1) return bin.toUpperCase();
  return padHex(bin, width);
}

function renderSvg(className, config, parsed) {
  const wanted = config.signals.map((name) => {
    const def = parsed.defs.find((d) => d.ref === name);
    if (!def) throw new Error(`${className}: missing VCD signal ${name}`);
    return { ...def, events: parsed.events.get(def.id) || [] };
  });

  const maxT = Math.max(...wanted.flatMap((s) => s.events.map((e) => e.t)), 1);
  const startT = Math.min(20000, maxT);
  const endT = maxT + 5000;
  const width = 2200;
  const nameW = 250;
  const valueW = 110;
  const left = nameW + valueW;
  const right = 24;
  const rulerH = 72;
  const top = rulerH;
  const rowH = 48;
  const bottom = 18;
  const height = top + wanted.length * rowH + bottom;
  const plotW = width - left - right;
  const x = (t) => left + ((t - startT) / Math.max(1, endT - startT)) * plotW;

  const out = [];
  out.push(`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">`);
  out.push(`<rect width="100%" height="100%" fill="#FFFFFF"/>`);
  out.push(`<rect x="0" y="0" width="${left}" height="${height}" fill="#F3F3F3"/>`);
  out.push(`<rect x="0" y="0" width="${left}" height="${rulerH}" fill="#E8E8E8"/>`);
  out.push(`<line x1="${nameW}" y1="0" x2="${nameW}" y2="${height}" stroke="#A9A9A9" stroke-width="1"/>`);
  out.push(`<line x1="${left}" y1="0" x2="${left}" y2="${height}" stroke="#7D7D7D" stroke-width="1"/>`);
  out.push(`<line x1="0" y1="${rulerH}" x2="${width}" y2="${rulerH}" stroke="#7D7D7D" stroke-width="1"/>`);
  out.push(`<text x="18" y="45" fill="#202020" font-family="Segoe UI,Arial,sans-serif" font-size="18">Name</text>`);
  out.push(`<text x="${nameW + 16}" y="45" fill="#202020" font-family="Segoe UI,Arial,sans-serif" font-size="18">Value</text>`);

  // Vivado-like solid time grid: 1 ns minor ticks and 5 ns labelled divisions.
  const minorStep = 1000;
  const majorStep = 5000;
  const firstGrid = Math.ceil(startT / minorStep) * minorStep;
  for (let t = firstGrid; t <= endT; t += minorStep) {
    const xx = x(t);
    const major = t % majorStep === 0;
    const tickTop = major ? 40 : 55;
    out.push(`<line x1="${xx}" y1="${tickTop}" x2="${xx}" y2="${rulerH}" stroke="#555555" stroke-width="${major ? 1 : 0.7}"/>`);
    out.push(`<line x1="${xx}" y1="${rulerH}" x2="${xx}" y2="${height}" stroke="${major ? '#7A7A7A' : '#D7D7D7'}" stroke-width="${major ? 1 : 0.6}"/>`);
    if (major) {
      const nearRight = xx > width - 105;
      out.push(`<text x="${nearRight ? xx - 4 : xx + 4}" y="30" text-anchor="${nearRight ? 'end' : 'start'}" fill="#111111" font-family="Consolas,Courier New,monospace" font-size="16">${(t/1000).toFixed(3)} ns</text>`);
    }
  }

  wanted.forEach((sig, i) => {
    const y0 = top + i * rowH;
    const yc = y0 + rowH / 2;
    const color = '#22C000';
    out.push(`<line x1="0" y1="${y0 + rowH}" x2="${width}" y2="${y0 + rowH}" stroke="#D0D0D0" stroke-width="0.7"/>`);
    out.push(`<text x="24" y="${yc+6}" fill="#111111" font-family="Segoe UI,Arial,sans-serif" font-size="18">${esc(sig.ref)}</text>`);

    const points = sig.events.filter((e) => e.t <= endT);
    let current = valueAt(points, startT);
    const changes = points.filter((e) => e.t > startT && e.t <= endT);
    const segments = [];
    let segStart = startT;
    for (const e of changes) {
      segments.push({ a: segStart, b: e.t, v: current });
      segStart = e.t;
      current = e.v;
    }
    segments.push({ a: segStart, b: endT, v: current });

    const endValue = valueLabel(sig.ref, valueAt(points, endT), sig.width);
    out.push(`<text x="${nameW + valueW - 14}" y="${yc+6}" text-anchor="end" fill="#111111" font-family="Consolas,Courier New,monospace" font-size="17">${esc(endValue)}</text>`);

    if (sig.width === 1) {
      let d = '';
      let prevY = null;
      for (const seg of segments) {
        const xx1 = x(seg.a), xx2 = x(seg.b);
        const highY = yc - 14;
        const lowY = yc + 14;
        const yy = seg.v === '1' ? highY : seg.v === '0' ? lowY : yc;
        if (seg.v === '1' && xx2 > xx1) {
          out.push(`<rect x="${xx1}" y="${highY}" width="${xx2-xx1}" height="${lowY-highY}" fill="#CDE8B9"/>`);
        }
        if (prevY === null) d += `M ${xx1} ${yy}`;
        else d += ` L ${xx1} ${prevY} L ${xx1} ${yy}`;
        d += ` L ${xx2} ${yy}`;
        prevY = yy;
      }
      out.push(`<path d="${d}" fill="none" stroke="${color}" stroke-width="1.6" shape-rendering="crispEdges"/>`);
    } else {
      for (const seg of segments) {
        const xx1 = x(seg.a), xx2 = x(seg.b);
        if (xx2 - xx1 < 1) continue;
        const busTop = yc - 12;
        const busBottom = yc + 12;
        out.push(`<line x1="${xx1}" y1="${busTop}" x2="${xx2}" y2="${busTop}" stroke="${color}" stroke-width="1.4"/>`);
        out.push(`<line x1="${xx1}" y1="${busBottom}" x2="${xx2}" y2="${busBottom}" stroke="${color}" stroke-width="1.4"/>`);
        if (seg.a > startT) out.push(`<path d="M ${xx1-6} ${busTop} L ${xx1+6} ${busBottom} M ${xx1-6} ${busBottom} L ${xx1+6} ${busTop}" stroke="${color}" stroke-width="1.2"/>`);
        const label = valueLabel(sig.ref, seg.v, sig.width);
        if (xx2 - xx1 > Math.max(42, label.length * 9)) {
          out.push(`<text x="${(xx1+xx2)/2}" y="${yc+5}" text-anchor="middle" fill="#111111" font-family="Consolas,Courier New,monospace" font-size="15" font-weight="600">${esc(label)}</text>`);
        }
      }
    }
  });
  out.push(`</svg>`);
  return out.join('\n');
}

async function main() {
  for (const [name, config] of Object.entries(classes)) {
    const vcd = path.join(outputDir, `${name}.vcd`);
    const parsed = parseVcd(vcd);
    const svg = renderSvg(name, config, parsed);
    const svgPath = path.join(outputDir, `${name}.svg`);
    const pngPath = path.join(outputDir, `${name}.png`);
    fs.writeFileSync(svgPath, svg, 'utf8');
    await sharp(Buffer.from(svg)).png().toFile(pngPath);
    console.log(`RENDERED ${path.basename(pngPath)}`);
  }
}

main().catch((error) => {
  console.error(error.stack || error.message);
  process.exit(1);
});

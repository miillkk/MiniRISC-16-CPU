import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { FileBlob, Presentation, PresentationFile } from "@oai/artifact-tool";

const workspaceDir = "C:/Users/xieke/Desktop/CPU/MiniRISC-16-CPU-main";
const SKILL_DIR = "C:/Users/xieke/.codex/plugins/cache/openai-primary-runtime/presentations/26.909.12148/skills/presentations";
const TMP_DIR = "C:/Users/xieke/Desktop/CPU/MiniRISC-16-CPU-main/.codex-ppt-build";
const RUNTIME_PYTHON = "C:/Users/xieke/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe";
const RUNTIME_NODE_MODULES = "C:/Users/xieke/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules";
const RUNTIME_BIN_DIR = "C:/Users/xieke/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/override";

process.env.RUNTIME_NODE_MODULES = RUNTIME_NODE_MODULES;
process.env.RUNTIME_BIN_DIR = RUNTIME_BIN_DIR;

const {
  makeNativeBulletParagraphs,
  finalizePresentation,
} = await import(pathToFileURL(path.join(SKILL_DIR, "container_tools/artifact_tool_utils.mjs")).href);

const W = 1280;
const H = 720;
const expectedSlideSizeEmu = "12192000,6858000";
const font = "Microsoft YaHei";
const codeFont = "Consolas";
const bg = "#08111f";
const panel = "#101d32";
const panel2 = "#132943";
const accent = "#4cc9f0";
const accent2 = "#80ed99";
const accent3 = "#f6c85f";
const text = "#f7fbff";
const muted = "#b6c2d2";
const grid = "#2b3d55";

const outDir = path.join(workspaceDir, "reports", "presentation");
await fs.mkdir(outDir, { recursive: true });
await fs.mkdir(TMP_DIR, { recursive: true });

async function nextVersionedPath(baseName) {
  for (let i = 1; i < 100; i += 1) {
    const candidate = path.join(outDir, `${baseName}_v${i}.pptx`);
    try {
      await fs.access(candidate);
    } catch {
      return { finalPath: candidate, version: i };
    }
  }
  throw new Error("Too many presentation revisions");
}

const { finalPath: FINAL_PPTX, version } = await nextVersionedPath("MiniRISC16_CPU_中文答辩PPT");

const presentation = Presentation.create({
  slideSize: { width: W, height: H },
});

presentation.theme.colorScheme = {
  name: "MiniRISC Technical Dark",
  themeColors: {
    accent1: accent,
    accent2: accent2,
    accent3: accent3,
    accent4: "#ff6b6b",
    accent5: "#9b5de5",
    accent6: "#00f5d4",
    bg1: bg,
    bg2: panel,
    tx1: text,
    tx2: muted,
    dk1: "#020617",
    dk2: "#0f172a",
    lt1: "#ffffff",
    lt2: "#dbeafe",
    hlink: accent,
    folHlink: "#c084fc",
  },
};

function addSlide() {
  const slide = presentation.slides.add();
  slide.background.fill = bg;
  return slide;
}

function shape(slide, opts) {
  return slide.shapes.add({
    geometry: opts.geometry ?? "rect",
    name: opts.name,
    position: opts.position,
    fill: opts.fill ?? "none",
    line: opts.line ?? { fill: "none", width: 0 },
  });
}

function textBox(slide, opts) {
  const s = shape(slide, {
    geometry: "textbox",
    name: opts.name,
    position: opts.position,
    fill: "none",
    line: { fill: "none", width: 0 },
  });
  s.text = opts.text;
  s.text.style = {
    typeface: opts.typeface ?? font,
    fontSize: opts.fontSize ?? 24,
    bold: opts.bold ?? false,
    color: opts.color ?? text,
    autoFit: "shrinkText",
    ...(opts.align ? { alignment: opts.align } : {}),
  };
  return s;
}

function title(slide, textValue, page) {
  textBox(slide, {
    name: "slide_title",
    text: textValue,
    position: { left: 56, top: 38, width: 950, height: 54 },
    fontSize: 34,
    bold: true,
  });
  textBox(slide, {
    name: "page_number",
    text: String(page).padStart(2, "0"),
    position: { left: 1152, top: 42, width: 72, height: 32 },
    fontSize: 20,
    bold: true,
    color: accent,
    align: "right",
  });
  shape(slide, {
    name: "title_rule",
    geometry: "line",
    position: { left: 56, top: 103, width: 1168, height: 0 },
    line: { style: "solid", fill: grid, width: 1.2 },
  });
}

function footer(slide) {
  textBox(slide, {
    name: "footer",
    text: "MiniRISC-16 CPU，RTL 设计与 Vivado XSim 功能验证",
    position: { left: 56, top: 666, width: 740, height: 24 },
    fontSize: 12,
    color: "#7f8da3",
  });
}

function bullets(slide, items, left, top, width, height, opts = {}) {
  const s = textBox(slide, {
    name: opts.name,
    text: makeNativeBulletParagraphs(items, {
      marginLeftPoints: opts.marginLeftPoints ?? 18,
      hangingPoints: opts.hangingPoints ?? 8,
      spaceAfterPoints: opts.spaceAfterPoints ?? 8,
    }),
    position: { left, top, width, height },
    fontSize: opts.fontSize ?? 21,
    color: opts.color ?? text,
  });
  return s;
}

function label(slide, textValue, left, top, width, color = accent) {
  textBox(slide, {
    text: textValue,
    position: { left, top, width, height: 24 },
    fontSize: 15,
    bold: true,
    color,
  });
}

function card(slide, left, top, width, height, heading, body, color = accent) {
  shape(slide, {
    geometry: "roundRect",
    position: { left, top, width, height },
    fill: panel,
    line: { style: "solid", fill: "#25415f", width: 1 },
  });
  textBox(slide, {
    text: heading,
    position: { left: left + 22, top: top + 20, width: width - 44, height: 28 },
    fontSize: 20,
    bold: true,
    color,
  });
  textBox(slide, {
    text: body,
    position: { left: left + 22, top: top + 58, width: width - 44, height: height - 72 },
    fontSize: 17,
    color: muted,
  });
}

function setNotes(slide, notes) {
  slide.speakerNotes.textFrame.setText(notes);
  slide.speakerNotes.setVisible(true);
}

function styleTable(table, opts = {}) {
  table.borders.assign({ style: "solid", fill: "#2f4159", width: 0.8 });
  table.cells.block({ row: 0, column: 0, rowCount: 1, columnCount: opts.columns }).assign({
    fill: "#173557",
    textStyle: { typeface: font, fontSize: opts.headerSize ?? 14, bold: true, color: text },
    margins: { left: 5, right: 5, top: 3, bottom: 3 },
  });
  if (opts.rows > 1) {
    table.cells.block({ row: 1, column: 0, rowCount: opts.rows - 1, columnCount: opts.columns }).assign({
      fill: opts.bodyFill ?? "#0d1a2d",
      textStyle: { typeface: font, fontSize: opts.bodySize ?? 13, color: "#edf5ff" },
      margins: { left: 5, right: 5, top: 2, bottom: 2 },
      anchor: "middle",
    });
  }
}

function addConnector(slide, x1, y1, x2, y2, color = accent) {
  const left = Math.min(x1, x2);
  const top = Math.min(y1, y2);
  const width = Math.abs(x2 - x1);
  const height = Math.abs(y2 - y1);
  shape(slide, {
    geometry: "line",
    position: { left, top, width, height },
    line: { style: "solid", fill: color, width: 2, beginArrowType: "none", endArrowType: "triangle" },
  });
}

function addBox(slide, left, top, width, height, titleText, bodyText, fillColor = panel2) {
  shape(slide, {
    geometry: "roundRect",
    position: { left, top, width, height },
    fill: fillColor,
    line: { style: "solid", fill: "#35506e", width: 1.1 },
  });
  textBox(slide, {
    text: titleText,
    position: { left: left + 16, top: top + 11, width: width - 32, height: 26 },
    fontSize: 18,
    bold: true,
    color: text,
    align: "center",
  });
  if (bodyText) {
    textBox(slide, {
      text: bodyText,
      position: { left: left + 14, top: top + 40, width: width - 28, height: Math.max(26, height - 46) },
      fontSize: 14,
      color: muted,
      align: "center",
    });
  }
}

// Slide 1
{
  const slide = addSlide();
  shape(slide, {
    geometry: "rect",
    position: { left: 0, top: 0, width: W, height: H },
    fill: "linear(135deg, #06101f 0%, #0b2140 58%, #102b3c 100%)",
    line: { fill: "none", width: 0 },
  });
  textBox(slide, {
    text: "MiniRISC-16 单周期 CPU 与 8 位 GPIO",
    position: { left: 76, top: 130, width: 960, height: 132 },
    fontSize: 44,
    bold: true,
  });
  textBox(slide, {
    text: "Verilog RTL 设计与 Vivado XSim 功能验证",
    position: { left: 80, top: 286, width: 780, height: 42 },
    fontSize: 24,
    color: accent,
  });
  textBox(slide, {
    text: "EES331 Zynq-7020 FPGA，PL 侧自定义软核 CPU",
    position: { left: 80, top: 348, width: 730, height: 34 },
    fontSize: 20,
    color: muted,
  });
  card(slide, 80, 462, 306, 116, "设计对象", "16 位数据宽度，4 个通用寄存器，8 位 PC", accent);
  card(slide, 414, 462, 306, 116, "执行方式", "非流水线单周期结构，每个周期提交一条指令", accent2);
  card(slide, 748, 462, 306, 116, "验证结果", "六个 testbench PASS，Failures 为 0", accent3);
  setNotes(slide, "这一页先说明项目主题。本设计不是 Zynq PS 里的 ARM，而是在 Zynq-7020 的 PL 可编程逻辑中实现一个自定义 MiniRISC-16 软核 CPU。汇报重点是 RTL 设计、GPIO 外设和 Vivado XSim 功能验证。");
}

// Slide 2
{
  const slide = addSlide();
  title(slide, "项目目标与阶段边界", 2);
  footer(slide);
  card(slide, 64, 142, 350, 386, "已完成内容", "Verilog RTL、模块级 testbench、系统级 testbench、机器码程序、回归脚本、仿真日志和波形截图。", accent2);
  card(slide, 466, 142, 350, 386, "设计规格", "16 位数据宽度，4 个寄存器，8 位 PC，13 个有效 opcode，3 个安全保留 opcode。", accent);
  card(slide, 868, 142, 350, 386, "本阶段不包含", "XDC、综合时序、bitstream、ILA 和上板验证。这些工作需要后续管脚和板级约束。", accent3);
  textBox(slide, {
    text: "目标是在仿真阶段证明 CPU 和 GPIO 的功能正确，为后续上板保留清晰顶层边界。",
    position: { left: 118, top: 578, width: 1040, height: 44 },
    fontSize: 22,
    color: text,
    align: "center",
  });
  setNotes(slide, "这一页讲范围。当前阶段已经完成可综合 RTL、测试平台、机器码程序、XSim 回归和波形证据。暂时不声明上板完成，因为还没有 XDC、时钟约束和物理管脚分配。这样说比较严谨，也方便后续继续扩展。");
}

// Slide 3
{
  const slide = addSlide();
  title(slide, "系统架构与外部端口", 3);
  footer(slide);
  textBox(slide, {
    text: "简化 Harvard 架构：指令通路和 I/O 通路分离",
    position: { left: 70, top: 126, width: 680, height: 32 },
    fontSize: 23,
    bold: true,
    color: accent,
  });
  addBox(slide, 72, 238, 190, 96, "reset_conditioner", "resetn 转换为同步 rst");
  addBox(slide, 338, 170, 218, 116, "instruction_memory", "256 × 16 组合读 ROM");
  addBox(slide, 632, 172, 218, 116, "cpu_core", "控制器、数据通路\nALU、寄存器组", "#173557");
  addBox(slide, 926, 170, 218, 116, "gpio8", "OUT、IN、DIR 地址映射");
  addBox(slide, 928, 386, 216, 94, "gpio[7:0]", "顶层形成逐位三态引脚", "#15324a");
  addConnector(slide, 556, 228, 632, 228);
  addConnector(slide, 850, 228, 926, 228);
  addConnector(slide, 1036, 286, 1036, 386);
  addConnector(slide, 262, 286, 338, 286, accent2);
  addConnector(slide, 262, 286, 632, 286, accent2);
  const table = slide.tables.add({
    rows: 4,
    columns: 3,
    left: 78,
    top: 414,
    width: 668,
    height: 156,
    columnWidths: [152, 110, 406],
    values: [
      ["顶层端口", "方向", "说明"],
      ["clk", "input", "系统时钟"],
      ["resetn", "input", "低有效复位"],
      ["gpio[7:0]", "inout", "8 位双向 GPIO 引脚"],
    ],
  });
  styleTable(table, { rows: 4, columns: 3, bodySize: 14 });
  setNotes(slide, "这一页说明总体连接。CPU 通过 mem_addr 读取 instruction_memory，通过独立 I/O 接口访问 gpio8，所以可以称为简化 Harvard 架构。顶层对外只有 clk、resetn 和 8 位 gpio，内部再拆成输入、输出和方向控制。");
}

// Slide 4
{
  const slide = addSlide();
  title(slide, "指令集与控制器", 4);
  footer(slide);
  const isa = slide.tables.add({
    rows: 8,
    columns: 3,
    left: 64,
    top: 138,
    width: 680,
    height: 390,
    columnWidths: [126, 188, 366],
    values: [
      ["类别", "指令", "功能"],
      ["数据传送", "MOVI、MOVR", "立即数写寄存器，寄存器间传送"],
      ["算术运算", "ADDI、ADDR、SUB", "16 位加减，自然截断"],
      ["逻辑运算", "XOR、AND、OR", "按位逻辑运算并写回 Rd"],
      ["比较", "CMP", "只更新 Z，不写 Rd"],
      ["控制流", "JZ、JUMP", "JZ 使用此前 CMP 保存的 Z"],
      ["I/O", "INP、OUP", "通过独立 I/O 总线访问 GPIO"],
      ["保留", "D、E、F", "安全 NOP，PC 顺序递增"],
    ],
  });
  styleTable(isa, { rows: 8, columns: 3, bodySize: 12.5 });
  textBox(slide, {
    text: "控制器是纯组合逻辑",
    position: { left: 812, top: 144, width: 340, height: 34 },
    fontSize: 25,
    bold: true,
    color: accent,
  });
  bullets(slide, [
    "先给所有控制信号安全默认值",
    "再按 opcode 覆盖 ALU、写回、分支和 I/O 控制",
    "保留 opcode 不写寄存器，不写 Z，不访问 I/O",
    "不使用隐式锁存，方便综合和验证",
  ], 804, 204, 360, 214, { fontSize: 19 });
  textBox(slide, {
    text: "1010 是 JUMP；0111 在本设计中是 AND",
    position: { left: 804, top: 484, width: 360, height: 42 },
    fontSize: 19,
    bold: true,
    color: accent3,
  });
  setNotes(slide, "这一页讲指令集。MiniRISC-16 当前支持 13 个有效 opcode，D、E、F 作为安全保留操作。控制器采用组合逻辑，先给默认安全值，再按 opcode 覆盖，这样可以避免未定义指令造成寄存器或外设被错误写入。");
}

// Slide 5
{
  const slide = addSlide();
  title(slide, "单周期数据通路", 5);
  footer(slide);
  addBox(slide, 74, 190, 150, 78, "PC", "8 位指令地址", "#173557");
  addBox(slide, 282, 190, 184, 78, "ROM", "组合读指令", "#173557");
  addBox(slide, 524, 156, 178, 78, "controller", "opcode 译码", "#15324a");
  addBox(slide, 524, 276, 178, 78, "register_file", "组合读，同步写", "#15324a");
  addBox(slide, 760, 216, 150, 78, "ALU", "PASS、ADD、SUB\n逻辑运算", "#173557");
  addBox(slide, 966, 216, 162, 78, "writeback", "ALU 或 io_rdata", "#173557");
  addConnector(slide, 224, 229, 282, 229);
  addConnector(slide, 466, 229, 524, 194);
  addConnector(slide, 466, 229, 524, 314);
  addConnector(slide, 702, 314, 760, 255);
  addConnector(slide, 910, 255, 966, 255);
  addConnector(slide, 1047, 294, 1047, 440, accent2);
  shape(slide, {
    geometry: "line",
    position: { left: 150, top: 440, width: 897, height: 0 },
    line: { style: "solid", fill: accent2, width: 2 },
  });
  shape(slide, {
    geometry: "line",
    position: { left: 150, top: 268, width: 0, height: 172 },
    line: { style: "solid", fill: accent2, width: 2 },
  });
  label(slide, "一个非复位时钟周期提交一条指令", 418, 104, 450, accent);
  bullets(slide, [
    "当前 PC 组合读出指令，控制器和寄存器组同时产生操作数",
    "ALU 或 I/O 读数据形成写回值",
    "时钟上升沿同时提交 PC、Rd、Z 和 GPIO 写操作",
    "只有 CMP 更新 Z，JZ 使用此前保存的 Z",
  ], 128, 504, 1030, 112, { fontSize: 19, spaceAfterPoints: 5 });
  setNotes(slide, "这一页是数据通路。它没有流水线、没有多周期状态机，也没有指令寄存器。当前 PC 先组合取指，随后译码、读寄存器、ALU 或 I/O 读、写回选择和下一 PC 计算都在一个周期内完成，最后在上升沿一起提交。");
}

// Slide 6
{
  const slide = addSlide();
  title(slide, "GPIO 外设与地址映射", 6);
  footer(slide);
  const map = slide.tables.add({
    rows: 5,
    columns: 4,
    left: 64,
    top: 138,
    width: 674,
    height: 246,
    columnWidths: [106, 138, 154, 276],
    values: [
      ["地址", "名称", "访问", "行为"],
      ["0x10", "GPIO_OUT", "读写", "保存输出数据，只使用 io_wdata[7:0]"],
      ["0x11", "GPIO_IN", "只读", "返回两级同步后的输入，高 8 位补零"],
      ["0x12", "GPIO_DIR", "读写", "1 为输出，0 为输入"],
      ["其他", "未映射", "无", "读零，写入无副作用"],
    ],
  });
  styleTable(map, { rows: 5, columns: 4, bodySize: 12.5 });
  addBox(slide, 820, 170, 260, 72, "gpio_oe = 1", "驱动 gpio_o 到外部引脚", "#14395a");
  addBox(slide, 820, 284, 260, 72, "gpio_oe = 0", "引脚保持高阻，作为输入", "#14395a");
  addBox(slide, 820, 426, 260, 72, "输入同步", "外部输入经过两级触发器", "#14395a");
  bullets(slide, [
    "GPIO_OUT 和 GPIO_DIR 复位清零，默认全部为输入",
    "I/O 读数据统一扩展为 16 位",
    "顶层才形成真正的 inout 三态端口",
  ], 92, 454, 610, 116, { fontSize: 20 });
  setNotes(slide, "这一页讲 GPIO。GPIO 内部不是直接写 inout 端口，而是分成 gpio_i、gpio_o 和 gpio_oe。地址 0x10 写输出，0x11 读输入，0x12 写方向。方向为 1 时输出，为 0 时高阻输入，外部输入再经过两级同步器。");
}

// Slide 7
{
  const slide = addSlide();
  title(slide, "人工验证：控制真值表", 7);
  footer(slide);
  textBox(slide, {
    text: "静态核对的核心是逐 opcode 检查控制信号，确认 RTL 与设计 md 一致。",
    position: { left: 70, top: 120, width: 1060, height: 32 },
    fontSize: 19,
    color: muted,
  });
  const values = [
    ["op", "指令", "ALU", "src", "Rd写", "Z写", "JZ", "JMP", "I/O读", "I/O写", "PC"],
    ["0", "MOVI", "PASS_B", "imm", "1", "0", "0", "0", "0", "0", "PC+1"],
    ["1", "MOVR", "PASS_B", "Rs", "1", "0", "0", "0", "0", "0", "PC+1"],
    ["2", "ADDI", "ADD", "imm", "1", "0", "0", "0", "0", "0", "PC+1"],
    ["3", "ADDR", "ADD", "Rs", "1", "0", "0", "0", "0", "0", "PC+1"],
    ["4", "XOR", "XOR", "Rs", "1", "0", "0", "0", "0", "0", "PC+1"],
    ["5", "SUB", "SUB", "Rs", "1", "0", "0", "0", "0", "0", "PC+1"],
    ["6", "CMP", "SUB", "Rs", "0", "1", "0", "0", "0", "0", "PC+1"],
    ["7", "AND", "AND", "Rs", "1", "0", "0", "0", "0", "0", "PC+1"],
    ["8", "JZ", "PASS_B", "Rs", "0", "0", "1", "0", "0", "0", "Z?imm:PC+1"],
    ["9", "OR", "OR", "Rs", "1", "0", "0", "0", "0", "0", "PC+1"],
    ["A", "JUMP", "PASS_B", "Rs", "0", "0", "0", "1", "0", "0", "imm"],
    ["B", "INP", "PASS_B", "Rs", "1", "0", "0", "0", "1", "0", "PC+1"],
    ["C", "OUP", "PASS_B", "Rs", "0", "0", "0", "0", "0", "1", "PC+1"],
    ["D", "保留", "PASS_B", "Rs", "0", "0", "0", "0", "0", "0", "PC+1"],
    ["E", "保留", "PASS_B", "Rs", "0", "0", "0", "0", "0", "0", "PC+1"],
    ["F", "保留", "PASS_B", "Rs", "0", "0", "0", "0", "0", "0", "PC+1"],
  ];
  const table = slide.tables.add({
    rows: values.length,
    columns: values[0].length,
    left: 56,
    top: 170,
    width: 1168,
    height: 420,
    columnWidths: [48, 92, 104, 60, 58, 58, 52, 58, 66, 66, 160],
    values,
  });
  styleTable(table, { rows: values.length, columns: values[0].length, headerSize: 10.5, bodySize: 10.2 });
  table.cells.block({ row: 14, column: 0, rowCount: 3, columnCount: values[0].length }).assign({
    fill: "#18273a",
    textStyle: { typeface: font, fontSize: 10.2, color: "#d8e4f2" },
  });
  textBox(slide, {
    text: "结论：13 个有效 opcode 和 3 个保留 opcode 都有明确安全控制。",
    position: { left: 86, top: 610, width: 900, height: 30 },
    fontSize: 18,
    bold: true,
    color: accent2,
  });
  setNotes(slide, "这一页就是人工验证的核心。人工验证不是跑仿真，而是先看真值表。每个 opcode 对应哪些控制信号、是否写寄存器、是否写 Z、是否访问 I/O、PC 怎样更新，都在表里直接列出。保留指令 D、E、F 全部是安全 NOP。");
}

// Slide 8
{
  const slide = addSlide();
  title(slide, "EDA 验证结果与结论", 8);
  footer(slide);
  const summary = slide.tables.add({
    rows: 8,
    columns: 2,
    left: 66,
    top: 136,
    width: 440,
    height: 318,
    columnWidths: [236, 204],
    values: [
      ["验证项", "结果"],
      ["tb_alu", "PASS"],
      ["tb_controller", "PASS"],
      ["tb_datapath", "PASS"],
      ["tb_reset_conditioner", "PASS"],
      ["tb_gpio8", "PASS"],
      ["tb_system", "PASS"],
      ["总结果", "Failures: 0"],
    ],
  });
  styleTable(summary, { rows: 8, columns: 2, bodySize: 13.5 });
  summary.cells.block({ row: 1, column: 1, rowCount: 7, columnCount: 1 }).assign({
    textStyle: { typeface: font, fontSize: 13.5, bold: true, color: accent2 },
  });
  textBox(slide, {
    text: "系统终态",
    position: { left: 72, top: 486, width: 170, height: 28 },
    fontSize: 20,
    bold: true,
    color: accent,
  });
  textBox(slide, {
    text: "PC=0x21，Z=1，R0～R3=0x00A5\nGPIO_OUT=0xA5，GPIO_DIR=0x0F，GPIO_IN=0xA5",
    position: { left: 72, top: 526, width: 478, height: 82 },
    fontSize: 18,
    color: text,
  });
  const imgPath = path.join(workspaceDir, "reports", "waveforms", "vivado_pass_summary_full_screenshot.png");
  const imgBytes = await fs.readFile(imgPath);
  slide.images.add({
    blob: new Uint8Array(imgBytes),
    contentType: "image/png",
    alt: "Vivado XSim PASS 摘要波形截图",
    fit: "contain",
    position: { left: 560, top: 132, width: 660, height: 414 },
    geometry: "roundRect",
    borderRadius: "rounded-xl",
  });
  textBox(slide, {
    text: "波形截图显示 errors=0、completed=1、opcode_coverage=ffff。",
    position: { left: 578, top: 568, width: 610, height: 34 },
    fontSize: 18,
    bold: true,
    color: accent3,
  });
  setNotes(slide, "最后讲 EDA 验证。六个 testbench 都通过编译、展开和 XSim 自检。系统级测试覆盖全部 opcode，最终日志显示 Failures 为 0。右侧 Vivado 波形截图能看到 errors 等于 0、completed 等于 1、opcode_coverage 等于 ffff，所以功能验证通过。");
}

const requirements = {
  explicitTotalSlideCount: 8,
  requiredNativeTableOwnerSlides: [3, 4, 6, 7, 8],
  requiredNativeChartOwnerSlides: [],
};

const fontPolicy = {
  basis: "design",
  families: [font, codeFont],
  scriptFonts: { ea: font },
};

const stagingDir = path.join(workspaceDir, ".codex-finalizer");
await fs.mkdir(stagingDir, { recursive: true });
const candidatePath = path.join(stagingDir, `minirisc16_chinese_ppt_candidate_v${version}.pptx`);
await (await PresentationFile.exportPptx(presentation)).save(candidatePath);

const result = await finalizePresentation({
  ...requirements,
  workspaceDir,
  candidatePath,
  finalPath: FINAL_PPTX,
  pythonExecutable: RUNTIME_PYTHON,
  integrityValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_package_integrity.py"),
  layoutValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_layout_geometry.py"),
  layoutArgs: [
    "--expected-slide-size-emu", expectedSlideSizeEmu,
    "--validate-bullet-geometry",
    "--validate-heading-fit",
    ...requirements.requiredNativeTableOwnerSlides.flatMap(number => ["--require-native-table-slide", String(number)]),
  ],
  requiredNativeTableOwnerSlides: requirements.requiredNativeTableOwnerSlides,
  fontPolicy,
  verifyArtifactToolImport: false,
  receiptPath: path.join(stagingDir, `${path.basename(FINAL_PPTX)}.validation.json`),
});

const finalDeck = await PresentationFile.importPptx(await FileBlob.load(FINAL_PPTX));
const previewDir = path.join(outDir, `preview_v${version}`);
await fs.mkdir(previewDir, { recursive: true });
for (const [index, slide] of finalDeck.slides.items.entries()) {
  const png = await finalDeck.export({ slide, format: "png", scale: 1 });
  await fs.writeFile(path.join(previewDir, `slide_${String(index + 1).padStart(2, "0")}.png`), new Uint8Array(await png.arrayBuffer()));
}

const inspect = await finalDeck.inspect({ kind: "deck,slide,textbox,table,image,notes", maxChars: 12000 });
await fs.writeFile(path.join(previewDir, "inspect.ndjson"), inspect.ndjson, "utf8");

console.log(JSON.stringify({
  finalPath: FINAL_PPTX,
  previewDir,
  validation: result,
}, null, 2));

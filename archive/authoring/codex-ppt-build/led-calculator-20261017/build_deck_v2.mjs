// Reuse the validated artifact-tool runtime linked in this build directory.
import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const workspaceDir = "C:\\Users\\xieke\\Desktop\\CPU";
const buildDir = path.join(workspaceDir, ".codex-ppt-build", "led-calculator-20261017-v2");
const outputDir = path.join(workspaceDir, "deliverables");
const finalPath = path.join(outputDir, "MiniRISC16_设计与验证答辩稿_v2.pptx");
const skillDir = "C:\\Users\\xieke\\.codex\\plugins\\cache\\openai-primary-runtime\\presentations\\26.1015.12040\\skills\\presentations";
const pythonExecutable = "C:\\Users\\xieke\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe";
const fontFamily = "Microsoft YaHei";
const monoFamily = "Consolas";

const C = {
  bg: "#07111F",
  bg2: "#0B1728",
  panel: "#102238",
  panel2: "#142A43",
  text: "#F4F7FB",
  muted: "#A9B8CA",
  cyan: "#39C6D8",
  orange: "#FF9D3D",
  green: "#66D9A8",
  red: "#FF6B6B",
  line: "#28445F",
};

async function writeBlob(filePath, blob) {
  await fs.writeFile(filePath, new Uint8Array(await blob.arrayBuffer()));
}

function addShape(slide, geometry, left, top, width, height, fill, lineFill = "none", lineWidth = 0, radius) {
  const cfg = {
    geometry,
    position: { left, top, width, height },
    fill,
    line: { style: "solid", fill: lineFill, width: lineWidth },
  };
  if (radius) cfg.borderRadius = radius;
  return slide.shapes.add(cfg);
}

function addText(slide, text, left, top, width, height, size = 24, color = C.text, bold = false, alignment = "left", verticalAlignment = "top", opts = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    position: { left, top, width, height },
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = text;
  shape.text.style = {
    fontSize: size,
    color,
    bold,
    typeface: opts.typeface ?? fontFamily,
    alignment,
    verticalAlignment,
    autoFit: opts.autoFit ?? "shrinkText",
    lineSpacing: opts.lineSpacing ?? 1.0,
  };
  return shape;
}

function addTitle(slide, title, section, accent = C.cyan) {
  addShape(slide, "rect", 0, 0, 1280, 720, C.bg);
  addShape(slide, "rect", 0, 0, 14, 720, accent);
  addText(slide, section, 62, 35, 420, 28, 15, accent, true);
  addText(slide, title, 60, 74, 1120, 58, 34, C.text, true);
  addShape(slide, "rect", 60, 145, 1160, 2, C.line);
}

function addFooter(slide, n) {
  addText(slide, `MiniRISC-16 设计与验证  ·  ${String(n).padStart(2, "0")}`, 60, 681, 400, 18, 11, C.muted);
}

function addCodeBlock(slide, lines, left, top, width, height, accent = C.cyan, fontSize = 18) {
  addShape(slide, "roundRect", left, top, width, height, "#06101A", C.line, 1, "rounded-lg");
  addShape(slide, "rect", left, top, 7, height, accent);
  addText(slide, lines.join("\n"), left + 24, top + 18, width - 44, height - 36, fontSize, C.text, false, "left", "top", { typeface: monoFamily, lineSpacing: 1.08 });
}

function addLedRow(slide, activeIndex, left, top, gap = 55) {
  for (let i = 0; i < 8; i++) {
    const x = left + i * gap;
    const active = i === activeIndex;
    addShape(slide, "ellipse", x, top, 34, 34, active ? C.orange : C.panel2, active ? C.orange : C.line, active ? 2 : 1);
    addText(slide, `L${i}`, x - 3, top + 42, 40, 20, 11, active ? C.orange : C.muted, active, "center");
  }
}

function addMetric(slide, value, label, left, top, width, accent) {
  addText(slide, value, left, top, width, 40, 29, accent, true, "center", "middle");
  addText(slide, label, left, top + 46, width, 35, 15, C.muted, false, "center", "middle");
}

const deck = Presentation.create({ slideSize: { width: 1280, height: 720 } });

// 1. Cover
{
  const s = deck.slides.add();
  addShape(s, "rect", 0, 0, 1280, 720, C.bg);
  addShape(s, "rect", 0, 0, 18, 720, C.orange);
  addText(s, "MiniRISC-16 CPU", 72, 68, 520, 34, 18, C.cyan, true);
  addText(s, "流水灯与交互式计算器", 70, 132, 650, 126, 48, C.text, true, "left", "middle", { lineSpacing: 0.95 });
  addText(s, "系统架构、关键程序与验证结果", 74, 286, 640, 44, 24, C.muted);
  addText(s, "无需现场操作，使用静态结果、关键代码和仿真波形完成讲解", 74, 351, 650, 72, 20, C.text);
  addShape(s, "roundRect", 776, 96, 420, 500, C.bg2, C.line, 2, "rounded-xl");
  addText(s, "01  02  04  08  10  20  40  80", 806, 150, 360, 48, 23, C.orange, true, "center", "middle");
  addLedRow(s, 3, 795, 226, 47);
  addText(s, "2D + 17", 842, 342, 290, 44, 29, C.cyan, true, "center", "middle");
  addShape(s, "roundRect", 843, 412, 288, 82, "#08101A", C.cyan, 2, "rounded-lg");
  addText(s, "2D170044", 858, 427, 258, 50, 31, C.green, true, "center", "middle", { typeface: monoFamily });
  addText(s, "同一指令集驱动两类应用", 810, 538, 350, 30, 17, C.muted, false, "center");
  addText(s, "EES331 · XC7Z020 · 100 MHz", 72, 646, 500, 26, 15, C.muted);
  s.speakerNotes.text = [
    "开场：本项目在 FPGA PL 中实现一个 16 位单周期软核 CPU，并用流水灯和交互式计算器验证其持续取指、运算、分支和 I/O 能力。",
    "本次讲解不依赖现场操作，所有结论由程序、静态输出和仿真结果支撑。",
    "来源：MiniRISC-16-CPU/refactored_design/BOARD_LED_CHASER_GUIDE.md；MiniRISC-16-CPU/refactored_design/calculator_system/README.md",
  ];
}

// 2. Project overview
{
  const s = deck.slides.add();
  addTitle(s, "系统目标与实现边界", "项目概览", C.cyan);
  addText(s, "目标：在 Zynq-7020 的 PL 中实现可编程 CPU，而不是调用 PS 端 ARM 完成计算。", 78, 174, 1120, 52, 26, C.text, true, "center", "middle");

  const cards = [
    ["16 位数据通路", "16 位指令与运算数据\n4 个通用寄存器 R0–R3", C.cyan],
    ["单周期执行", "取指到写回位于一个周期\n普通指令理论 CPI = 1", C.orange],
    ["独立 I/O 空间", "INP / OUP 访问外设\n端口地址位于指令低 8 位", C.green],
  ];
  cards.forEach((c, i) => {
    const x = 72 + i * 390;
    addShape(s, "roundRect", x, 265, 350, 165, C.bg2, c[2], 2, "rounded-xl");
    addText(s, c[0], x + 28, 291, 294, 34, 25, c[2], true, "center");
    addText(s, c[1], x + 28, 344, 294, 62, 18, C.text, false, "center", "middle");
  });

  addShape(s, "roundRect", 72, 478, 1130, 120, C.panel, C.line, 1, "rounded-lg");
  addText(s, "两项应用覆盖的能力", 100, 500, 230, 28, 18, C.muted, true);
  addText(s, "流水灯：循环、比较、条件跳转、延时和 LED 端口写入", 100, 540, 500, 34, 20, C.orange, true);
  addText(s, "计算器：输入锁存、算术逻辑、软件乘除、Flags、数码管输出", 630, 540, 525, 34, 20, C.green, true);
  addFooter(s, 2);
  s.speakerNotes.text = [
    "强调实现边界：CPU、指令 ROM 和外设均在 FPGA PL 内。PS 端 ARM 不参与程序执行。",
    "单周期描述的是状态提交方式，不代表没有取指、译码、执行和写回等逻辑步骤。",
    "计算器版本在基础架构上增加 Z/N/C/V 标志以及更完整的外设子系统。",
    "来源：MiniRISC-16-CPU/docs/design/CPU项目说明_8位GPIO_单周期.md；MiniRISC-16-CPU/refactored_design/calculator_system/rtl/core/status_register.v",
  ];
}

// 3. System architecture
{
  const s = deck.slides.add();
  addTitle(s, "CPU、程序存储器与外设构成完整系统", "系统架构", C.cyan);

  const xs = [58, 285, 565, 875, 1080];
  const widths = [175, 228, 255, 155, 145];
  const labels = [
    ["输入前端", "SW7..0\nS1 去抖与确认", C.green],
    ["指令 ROM", "PC 地址\n16 位指令输出", C.orange],
    ["MiniRISC-16 CPU", "Controller\nDatapath / RegFile / ALU", C.cyan],
    ["I/O 译码", "io_addr\nio_re / io_we", C.green],
    ["输出外设", "LED\n八位数码管", C.orange],
  ];
  labels.forEach((it, i) => {
    addShape(s, "roundRect", xs[i], 220, widths[i], 170, C.bg2, it[2], 2, "rounded-lg");
    addText(s, it[0], xs[i] + 14, 246, widths[i] - 28, 36, 23, it[2], true, "center");
    addText(s, it[1], xs[i] + 14, 303, widths[i] - 28, 66, 17, C.text, false, "center", "middle");
    if (i < labels.length - 1) {
      addShape(s, "rightArrow", xs[i] + widths[i] + 9, 286, xs[i + 1] - (xs[i] + widths[i]) - 18, 34, C.line);
    }
  });

  addShape(s, "roundRect", 565, 430, 510, 120, C.panel, C.line, 1, "rounded-lg");
  addText(s, "Scratchpad 0x40–0x4F", 595, 451, 220, 28, 19, C.green, true);
  addText(s, "保存 A、B、中间结果、商和余数", 595, 489, 430, 34, 18, C.text);
  addShape(s, "upArrow", 927, 391, 42, 32, C.line);

  addText(s, "取指接口与 I/O 接口相互独立；计算器没有依赖通用数据存储器指令，而是通过端口访问 Scratchpad 和外设。", 92, 590, 1090, 52, 22, C.text, true, "center", "middle");
  addFooter(s, 3);
  s.speakerNotes.text = [
    "从左到右讲数据流：拨码与按键先经过输入前端，CPU 由 ROM 取指，I/O 译码器根据端口地址选中外设，输出最终进入 LED 或数码管。",
    "CPU Core 内部仍分成 Controller 和 Datapath。Controller 产生控制信号，Datapath 完成寄存器读取、ALU 运算、写回和下一 PC 选择。",
    "Scratchpad 映射到 0x40 至 0x4F，是 16×16 位寄存器阵列，供程序保存交互状态和中间结果。",
    "来源：MiniRISC-16-CPU/refactored_design/calculator_system/README.md；MiniRISC-16-CPU/refactored_design/calculator_system/rtl/top/calculator_soc.v；MiniRISC-16-CPU/refactored_design/calculator_system/rtl/peripherals/peripheral_subsystem.v",
  ];
}

// 4. Single-cycle data path
{
  const s = deck.slides.add();
  addTitle(s, "单周期执行在相邻时钟沿之间完成", "CPU 数据通路", C.cyan);

  const stages = [
    ["PC / 取指", "mem_addr → ROM"],
    ["译码", "opcode → 控制信号"],
    ["读寄存器", "R[Rd] 与 R[Rs]"],
    ["ALU / I/O", "运算或端口读取"],
    ["写回 / Next PC", "状态在上升沿提交"],
  ];
  stages.forEach((it, i) => {
    const x = 54 + i * 244;
    addShape(s, "roundRect", x, 176, 194, 86, i === 3 ? "#15362C" : C.bg2, i === 3 ? C.green : C.line, 1, "rounded-lg");
    addText(s, it[0], x + 12, 192, 170, 26, 18, i === 3 ? C.green : C.text, true, "center");
    addText(s, it[1], x + 12, 223, 170, 28, 14, C.muted, false, "center");
    if (i < stages.length - 1) addShape(s, "rightArrow", x + 198, 204, 38, 28, C.line);
  });

  const wavePath = path.join(workspaceDir, "MiniRISC-16-CPU", "reports", "waveforms", "module_png", "datapath.png");
  const waveBytes = await fs.readFile(wavePath);
  s.images.add({
    blob: waveBytes.buffer.slice(waveBytes.byteOffset, waveBytes.byteOffset + waveBytes.byteLength),
    contentType: "image/png",
    alt: "MiniRISC-16 数据通路仿真波形，显示 PC、指令、寄存器数据、ALU、写回和下一 PC",
    fit: "contain",
    position: { left: 62, top: 300, width: 790, height: 308 },
  });

  addShape(s, "roundRect", 880, 300, 330, 308, C.bg2, C.line, 1, "rounded-xl");
  addText(s, "关键结构", 910, 326, 270, 32, 22, C.cyan, true);
  addText(s, "ALU-B MUX\n选择寄存器或立即数\n\nWriteback MUX\n选择 ALU 或 I/O 数据\n\nNext-PC MUX\n选择 PC+1、JZ 或 JUMP", 910, 377, 270, 188, 18, C.text, false, "left", "top", { lineSpacing: 1.06 });
  addText(s, "周期必须覆盖最长组合路径", 910, 566, 270, 24, 16, C.orange, true, "center");
  addFooter(s, 4);
  s.speakerNotes.text = [
    "一个周期开始后，PC 驱动组合 ROM，Controller 译码，寄存器组组合读，ALU 和 I/O 路径产生结果。",
    "下一个上升沿同时提交 PC、通用寄存器、标志寄存器或外设写入。阶段之间没有流水寄存器，因此这是非流水线单周期实现。",
    "三类核心选择器是 ALU-B、Writeback 和 Next-PC MUX。JZ 读取此前保存的 Z 标志。",
    "来源：MiniRISC-16-CPU/docs/design/RTL_STRUCTURE_ANALYSIS.md；MiniRISC-16-CPU/reports/waveforms/module_png/datapath.png",
  ];
}

// 5. LED program
{
  const s = deck.slides.add();
  addTitle(s, "流水灯程序把指令执行转化为可见输出", "应用一", C.orange);

  addShape(s, "roundRect", 66, 184, 520, 388, C.bg2, C.line, 2, "rounded-xl");
  addText(s, "逻辑输出序列", 98, 212, 456, 34, 22, C.orange, true, "center");
  addText(s, "01  →  02  →  04  →  08", 98, 275, 456, 42, 28, C.text, true, "center", "middle", { typeface: monoFamily });
  addText(s, "10  →  20  →  40  →  80  →  01", 82, 330, 488, 42, 25, C.text, true, "center", "middle", { typeface: monoFamily });
  addLedRow(s, 4, 108, 410, 54);
  addText(s, "每次仅一位为 1；板上物理排列可能改变视觉方向", 104, 500, 444, 42, 17, C.muted, false, "center", "middle");

  addCodeBlock(s, [
    "MOVI R0, 0x01",
    "OUP  0x30, R0",
    "...                 ; 三层延时循环",
    "INP  R0, 0x30",
    "MOVI R1, 0x80",
    "CMP  R0, R1",
    "JZ   WRAP",
    "ADDR R0, R0        ; 左移一位",
    "OUP  0x30, R0",
  ], 626, 184, 586, 388, C.orange, 18);

  addShape(s, "roundRect", 66, 604, 1146, 50, "#221912", C.orange, 1, "rounded-lg");
  addText(s, "延时决定移动速度，CMP/JZ 负责 80→01 回卷，OUP 0x30 把寄存器值锁存到 LED。", 91, 614, 1096, 30, 19, C.text, true, "center", "middle");
  addFooter(s, 5);
  s.speakerNotes.text = [
    "先解释输出序列：每个值只有一个二进制位为 1。ADDR R0,R0 等价于将当前值乘 2，因此点亮位置逐位移动。",
    "三层 0xFF 倒计数循环产生人眼可见的约 0.5 秒间隔。程序在移位前检测 0x80，避免产生额外的 0x00 全灭节拍。",
    "OUP 0x30,R0 不是直接驱动 LED 引脚的组合逻辑，而是在时钟沿把值写入 LED 外设寄存器。",
    "来源：MiniRISC-16-CPU/refactored_design/sim/programs/board_led_chaser.mem；MiniRISC-16-CPU/refactored_design/BOARD_LED_CHASER_GUIDE.md",
  ];
}

// 6. Calculator architecture
{
  const s = deck.slides.add();
  addTitle(s, "计算器通过端口映射组织输入、状态与输出", "应用二", C.green);

  const flow = ["输入 A", "输入 B", "选择运算", "CPU 执行", "显示结果"];
  flow.forEach((label, i) => {
    const x = 58 + i * 241;
    addShape(s, "roundRect", x, 178, 190, 70, i === 3 ? "#15362C" : C.bg2, i === 3 ? C.green : C.line, 1, "rounded-lg");
    addText(s, label, x + 12, 194, 166, 36, 19, i === 3 ? C.green : C.text, true, "center", "middle");
    if (i < flow.length - 1) addShape(s, "rightArrow", x + 194, 199, 38, 28, C.line);
  });

  addShape(s, "roundRect", 68, 294, 480, 290, C.bg2, C.line, 2, "rounded-xl");
  addText(s, "端口映射", 100, 320, 416, 34, 23, C.green, true);
  const ports = [
    ["0x31", "拨码输入"],
    ["0x33", "确认令牌与输入有效"],
    ["0x20 / 0x21", "数码管低 16 位 / 高 16 位"],
    ["0x30", "LED 与状态输出"],
    ["0x40–0x4F", "16×16 位 Scratchpad"],
  ];
  ports.forEach((p, i) => {
    const y = 370 + i * 38;
    addText(s, p[0], 104, y, 116, 28, 17, i < 2 ? C.orange : C.cyan, true, "left", "middle", { typeface: monoFamily });
    addText(s, p[1], 220, y, 290, 28, 17, C.text, false, "left", "middle");
  });

  addShape(s, "roundRect", 610, 294, 602, 290, C.bg2, C.green, 2, "rounded-xl");
  addText(s, "示例：2D + 17", 650, 326, 522, 38, 25, C.green, true, "center");
  addShape(s, "roundRect", 684, 397, 454, 92, "#071019", C.green, 2, "rounded-lg");
  addText(s, "2D170044", 710, 416, 402, 54, 37, C.green, true, "center", "middle", { typeface: monoFamily });
  addText(s, "A = 2D    B = 17    运算 0 = ADD    结果 = 0044", 650, 514, 522, 34, 18, C.text, true, "center", "middle", { typeface: monoFamily });
  addText(s, "普通结果格式 AABBrrrr；除法格式 AABBqqrr", 86, 614, 1110, 34, 19, C.muted, false, "center", "middle", { typeface: monoFamily });
  addFooter(s, 6);
  s.speakerNotes.text = [
    "交互过程由程序状态控制。用户先输入 A，再输入 B，随后用拨码低三位选择 0 至 7 号运算。",
    "按键控制器将机械按键转化为稳定的确认令牌，并区分短按确认和长按复位。CPU 通过 0x33 读取令牌。",
    "显示寄存器分为高、低 16 位，因此可组成八位十六进制显示。Scratchpad 保存 A、B 和中间结果。",
    "来源：MiniRISC-16-CPU/refactored_design/calculator_system/README.md；MiniRISC-16-CPU/refactored_design/calculator_system/rtl/peripherals/io_decoder.v；MiniRISC-16-CPU/refactored_design/calculator_system/BOARD_TEST_GUIDE.md",
  ];
}

// 7. Calculator code
{
  const s = deck.slides.add();
  addTitle(s, "直接 ALU 运算与软件循环共用同一 CPU", "关键代码", C.green);

  addCodeBlock(s, [
    "OP_ADD:",
    "  INP  R0, 0x40",
    "  INP  R1, 0x41",
    "  ADDR R0, R1",
    "  JUMP ARITH_FINISH",
    "",
    "MUL_LOOP:",
    "  ADDR R0, R2",
    "  SUB  R1, R3",
    "  JZ   MUL_DONE",
    "  JUMP MUL_LOOP",
  ], 70, 182, 555, 404, C.green, 19);

  addShape(s, "roundRect", 670, 182, 540, 178, C.bg2, C.line, 1, "rounded-xl");
  addText(s, "ADD：硬件 ALU 直接完成", 704, 210, 470, 34, 23, C.cyan, true);
  addText(s, "INP 从 Scratchpad 读取 A、B，ADDR 产生 16 位结果，再由公共收尾代码写入结果与 Flags。", 704, 260, 470, 72, 18, C.text);

  addShape(s, "roundRect", 670, 382, 540, 204, C.bg2, C.orange, 1, "rounded-xl");
  addText(s, "MUL / DIV：由程序循环完成", 704, 410, 470, 34, 23, C.orange, true);
  addText(s, "乘法使用重复加法；除法使用比较和重复减法，并先检查除数是否为 0。它们证明 CPU 能组合基础指令实现更复杂算法。", 704, 458, 470, 94, 18, C.text);

  addShape(s, "roundRect", 70, 616, 1140, 40, C.panel, C.green, 1, "rounded-lg");
  addText(s, "八种运算：ADD、SUB、AND、OR、XOR、MUL、DIV、CMP", 95, 622, 1090, 27, 18, C.text, true, "center", "middle");
  addFooter(s, 7);
  s.speakerNotes.text = [
    "左上代码说明加法路径：端口 0x40 和 0x41 保存 A、B，ADDR 使用 ALU 加法，随后统一保存结果。",
    "左下代码说明软件乘法：R0 保存累加结果，R2 保存被乘数，R1 作为循环计数，每轮执行一次加法并递减。",
    "除法采用相同思想，以比较和重复减法得到商与余数。除数为零时转入错误分支并点亮 LED7。",
    "来源：MiniRISC-16-CPU/refactored_design/calculator_system/program/calculator.asm",
  ];
}

// 8. Verification and conclusion
{
  const s = deck.slides.add();
  addTitle(s, "验证覆盖指令、系统功能与实现结果", "验证与结论", C.cyan);

  addShape(s, "roundRect", 64, 177, 500, 420, C.bg2, C.line, 2, "rounded-xl");
  addText(s, "计算器工程验证", 96, 204, 436, 34, 23, C.cyan, true);
  addMetric(s, "15 / 15", "参考模型用例通过", 84, 264, 142, C.green);
  addMetric(s, "9 / 9", "RTL 回归通过", 244, 264, 142, C.green);
  addMetric(s, "+0.559 ns", "100 MHz WNS", 404, 264, 142, C.orange);
  addText(s, "资源", 100, 385, 100, 26, 16, C.muted, true);
  addText(s, "444 LUT    494 Register    42 IOB    1 BUFG", 100, 420, 410, 34, 20, C.text, true, "center", "middle", { typeface: monoFamily });
  addText(s, "流水灯工程：bitstream 已生成；100 MHz WNS +0.683 ns；80→01 边界问题已修复。", 100, 494, 410, 68, 17, C.text, false, "left", "middle");

  const wavePath = path.join(workspaceDir, "MiniRISC-16-CPU", "refactored_design", "instruction_waveforms", "output", "io.png");
  const waveBytes = await fs.readFile(wavePath);
  s.images.add({
    blob: waveBytes.buffer.slice(waveBytes.byteOffset, waveBytes.byteOffset + waveBytes.byteLength),
    contentType: "image/png",
    alt: "MiniRISC-16 I/O 指令仿真波形，显示 INP 与 OUP 的地址、数据和使能",
    fit: "contain",
    position: { left: 600, top: 183, width: 612, height: 330 },
  });
  addText(s, "I/O 波形：INP 读取端口 0x31，OUP 向端口 0x30 写入数据", 620, 520, 572, 35, 17, C.muted, false, "center", "middle");
  addShape(s, "roundRect", 600, 565, 612, 80, "#102B2B", C.green, 1, "rounded-lg");
  addText(s, "结论：CPU 能连续执行程序，通过分支形成控制流程，并用统一 I/O 接口驱动两类应用。", 630, 579, 552, 52, 21, C.text, true, "center", "middle");
  addFooter(s, 8);
  s.speakerNotes.text = [
    "验证分为三层：参考模型检查程序逻辑，RTL 回归检查时序与接口，综合实现检查目标器件资源和 100 MHz 时序。",
    "右侧波形中，INP 与 OUP 对应不同的 io_re/io_we，使端口访问行为可以直接观察。",
    "最终结论应限定为：自动验证、综合实现和 bitstream 已完成。若尚未完成最终人工上板验收，不应把逻辑示意图称为实拍结果。",
    "来源：MiniRISC-16-CPU/refactored_design/calculator_system/README.md；MiniRISC-16-CPU/refactored_design/BOARD_LED_CHASER_GUIDE.md；MiniRISC-16-CPU/refactored_design/instruction_waveforms/output/io.png",
  ];
}

await fs.mkdir(buildDir, { recursive: true });
await fs.mkdir(outputDir, { recursive: true });
const previewDir = path.join(buildDir, "previews");
await fs.mkdir(previewDir, { recursive: true });

for (const [index, slide] of deck.slides.items.entries()) {
  const png = await deck.export({ slide, format: "png", scale: 1 });
  await writeBlob(path.join(previewDir, `slide-${String(index + 1).padStart(2, "0")}.png`), png);
}
const montage = await deck.export({ format: "webp", montage: true });
await writeBlob(path.join(buildDir, "montage.webp"), montage);

const draftPath = path.join(buildDir, "draft.pptx");
await (await PresentationFile.exportPptx(deck)).save(draftPath);

const { finalizePresentation } = await import(pathToFileURL(
  path.join(skillDir, "container_tools", "artifact_tool_utils.mjs"),
).href);

const result = await finalizePresentation({
  explicitTotalSlideCount: 8,
  requiredNativeTableOwnerSlides: [],
  requiredNativeChartOwnerSlides: [],
  workspaceDir,
  candidatePath: draftPath,
  finalPath,
  pythonExecutable,
  integrityValidatorPath: path.join(skillDir, "container_tools", "inspect_presentation_package_integrity.py"),
  layoutValidatorPath: path.join(skillDir, "container_tools", "inspect_presentation_layout_geometry.py"),
  layoutArgs: [
    "--expected-slide-size-emu", "12192000,6858000",
    "--validate-bullet-geometry",
    "--validate-heading-fit",
  ],
  fontPolicy: {
    basis: "design",
    families: [fontFamily, monoFamily],
  },
  expectedSlideSizeEmu: "12192000,6858000",
  verifyArtifactToolImport: false,
  receiptPath: path.join(buildDir, "validation.json"),
});

console.log(JSON.stringify({ finalPath, draftPath, previewDir, result }, null, 2));

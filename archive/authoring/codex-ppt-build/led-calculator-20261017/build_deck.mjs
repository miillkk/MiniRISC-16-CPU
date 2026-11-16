import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const workspaceDir = "C:\\Users\\xieke\\Desktop\\CPU";
const buildDir = path.join(workspaceDir, ".codex-ppt-build", "led-calculator-20261017");
const outputDir = path.join(workspaceDir, "deliverables");
const finalPath = path.join(outputDir, "MiniRISC16_LED_Calculator_Demo_v1.pptx");
const skillDir = "C:\\Users\\xieke\\.codex\\plugins\\cache\\openai-primary-runtime\\presentations\\26.1015.12040\\skills\\presentations";
const pythonExecutable = "C:\\Users\\xieke\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe";
const fontFamily = "Microsoft YaHei";

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
  white: "#FFFFFF",
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
  addText(slide, `MiniRISC-16 现场展示  ·  ${String(n).padStart(2, "0")}`, 60, 679, 380, 20, 12, C.muted, false);
}

function addStep(slide, n, title, body, left, top, width, accent) {
  addShape(slide, "ellipse", left, top, 42, 42, accent);
  addText(slide, String(n), left, top + 1, 42, 38, 19, C.bg, true, "center", "middle");
  addText(slide, title, left + 58, top - 1, width - 58, 30, 21, C.text, true);
  addText(slide, body, left + 58, top + 31, width - 58, 55, 16, C.muted, false);
}

function addCodeLine(slide, text, left, top, width, accent = C.cyan) {
  addShape(slide, "roundRect", left, top, width, 42, C.panel, C.line, 1, "rounded-lg");
  addShape(slide, "rect", left, top, 6, 42, accent);
  addText(slide, text, left + 18, top + 7, width - 28, 28, 17, C.text, false, "left", "middle", { typeface: fontFamily });
}

function addLedRow(slide, activeIndex, left, top, gap = 64) {
  for (let i = 0; i < 8; i++) {
    const x = left + i * gap;
    const active = i === activeIndex;
    addShape(slide, "ellipse", x, top, 34, 34, active ? C.orange : C.panel2, active ? C.orange : C.line, active ? 2 : 1);
    addText(slide, `L${i}`, x - 3, top + 42, 40, 22, 12, active ? C.orange : C.muted, active, "center");
  }
}

const deck = Presentation.create({ slideSize: { width: 1280, height: 720 } });

// 1. Cover
{
  const s = deck.slides.add();
  addShape(s, "rect", 0, 0, 1280, 720, C.bg);
  addShape(s, "rect", 0, 0, 18, 720, C.orange);
  addText(s, "MiniRISC-16 CPU", 72, 68, 520, 34, 18, C.cyan, true);
  addText(s, "流水灯与计算器\n现场展示讲解", 70, 125, 650, 180, 50, C.text, true, "left", "middle", { lineSpacing: 0.95 });
  addText(s, "演示目标、CPU执行证据、上板步骤与仿真波形获取", 74, 330, 700, 48, 22, C.muted, false);
  addShape(s, "roundRect", 776, 96, 420, 500, C.bg2, C.line, 2, "rounded-xl");
  addText(s, "01  02  04  08", 823, 152, 330, 58, 30, C.orange, true, "center", "middle");
  addLedRow(s, 3, 817, 234, 43);
  addText(s, "2D + 17", 842, 345, 290, 50, 31, C.cyan, true, "center", "middle");
  addShape(s, "roundRect", 843, 420, 288, 82, "#08101A", C.cyan, 2, "rounded-lg");
  addText(s, "2D170044", 858, 435, 258, 50, 32, C.green, true, "center", "middle");
  addText(s, "同一个CPU核心执行两套程序", 810, 544, 350, 30, 17, C.muted, false, "center");
  addText(s, "EES331 · XC7Z020 · 100 MHz", 72, 646, 500, 26, 15, C.muted, false);
}

// 2. What the demos prove
{
  const s = deck.slides.add();
  addTitle(s, "两个演示回答同一个问题", "展示逻辑", C.cyan);
  addText(s, "FPGA中的MiniRISC-16能否连续取指、执行运算、访问I/O，并把结果稳定地呈现在板上？", 80, 180, 1120, 58, 27, C.text, true, "center", "middle");
  addShape(s, "roundRect", 495, 274, 290, 180, C.panel2, C.cyan, 2, "rounded-xl");
  addText(s, "MiniRISC-16", 530, 305, 220, 42, 28, C.cyan, true, "center", "middle");
  addText(s, "取指 · 译码 · 运算 · 分支 · I/O", 530, 363, 220, 55, 17, C.text, false, "center", "middle");
  addShape(s, "roundRect", 82, 276, 335, 178, C.bg2, C.orange, 2, "rounded-xl");
  addText(s, "流水灯", 118, 302, 260, 42, 28, C.orange, true, "center");
  addText(s, "持续循环与分支\nOUP写LED\n复位后从第一步重新执行", 118, 355, 260, 78, 18, C.text, false, "center", "middle");
  addShape(s, "roundRect", 862, 276, 335, 178, C.bg2, C.green, 2, "rounded-xl");
  addText(s, "交互式计算器", 898, 302, 260, 42, 28, C.green, true, "center");
  addText(s, "拨码输入与按键确认\n算术和逻辑运算\nFlags、结果显示与状态保持", 898, 355, 260, 78, 18, C.text, false, "center", "middle");
  addText(s, "展示结论", 80, 520, 160, 28, 16, C.cyan, true);
  addText(s, "硬件连接保持不变，改变程序后系统行为随之改变，这正是软核CPU执行程序的直接体现。", 80, 554, 1110, 70, 25, C.text, true, "left", "middle");
  addFooter(s, 2);
}

// 3. LED CPU path
{
  const s = deck.slides.add();
  addTitle(s, "流水灯由CPU程序驱动", "流水灯原理", C.orange);
  const xs = [70, 310, 550, 790, 1030];
  const titles = ["程序ROM", "CPU取指", "算术与分支", "OUP 0x30", "LED寄存器"];
  const bodies = ["board_led_chaser.mem", "PC每周期更新", "移位值与延时循环", "CPU发出I/O写操作", "保持01至80的输出"];
  for (let i = 0; i < 5; i++) {
    addShape(s, "roundRect", xs[i], 205, 180, 118, i === 4 ? "#2A1D12" : C.bg2, i === 4 ? C.orange : C.line, 2, "rounded-lg");
    addText(s, titles[i], xs[i] + 14, 222, 152, 32, 21, i === 4 ? C.orange : C.text, true, "center");
    addText(s, bodies[i], xs[i] + 14, 263, 152, 44, 14, C.muted, false, "center", "middle");
    if (i < 4) addShape(s, "rightArrow", xs[i] + 188, 242, 44, 35, C.line);
  }
  addText(s, "程序中的关键动作", 72, 378, 300, 35, 20, C.orange, true);
  addCodeLine(s, "MOVI / ADDR    产生下一个单灯值", 72, 426, 350, C.orange);
  addCodeLine(s, "SUB / CMP / JZ 构造延时与回卷判断", 458, 426, 365, C.orange);
  addCodeLine(s, "OUP 0x30      把结果写入LED端口", 858, 426, 350, C.orange);
  addText(s, "板上看到的移动不是扫描电路自动生成，而是CPU反复执行程序并写入LED地址。", 72, 522, 1136, 58, 26, C.text, true, "center", "middle");
  addLedRow(s, 0, 382, 598, 66);
  addFooter(s, 3);
}

// 4. LED demo
{
  const s = deck.slides.add();
  addTitle(s, "流水灯现场演示", "演示一", C.orange);
  addStep(s, 1, "下载流水灯bit", "Hardware Manager选择MiniRISC16_EES331_LED_CHASER.bit，Debug probes留空。", 72, 186, 540, C.orange);
  addStep(s, 2, "按下并松开S1", "按住约0.5秒。按下期间LED清零，松开后CPU从地址0重新执行。", 72, 302, 540, C.orange);
  addStep(s, 3, "观察两个完整循环", "每步约0.5秒，数码管保持关闭。重点看80回到01时没有额外全灭节拍。", 72, 418, 540, C.orange);
  addShape(s, "roundRect", 660, 182, 548, 335, C.bg2, C.line, 2, "rounded-xl");
  addText(s, "预期LED逻辑值", 704, 210, 460, 34, 22, C.text, true, "center");
  const seq = ["01", "02", "04", "08", "10", "20", "40", "80", "01"];
  seq.forEach((v, i) => {
    const x = 696 + (i % 5) * 94;
    const y = 274 + Math.floor(i / 5) * 94;
    addShape(s, "ellipse", x, y, 62, 62, i === 8 ? C.orange : C.panel2, C.orange, 2);
    addText(s, v, x, y + 10, 62, 40, 20, i === 8 ? C.bg : C.orange, true, "center", "middle");
  });
  addText(s, "判断CPU确实运行", 694, 464, 480, 28, 17, C.cyan, true, "center");
  addText(s, "稳定节拍、循环回卷、复位重启", 694, 496, 480, 28, 18, C.text, false, "center");
  addShape(s, "roundRect", 74, 565, 1134, 70, "#221912", C.orange, 1, "rounded-lg");
  addText(s, "讲解重点：每次只有一个LED点亮。方向取决于板上LED物理排列，但逻辑顺序必须是01到80。", 98, 582, 1088, 38, 20, C.text, true, "center", "middle");
  addFooter(s, 4);
}

// 5. Calculator mechanism
{
  const s = deck.slides.add();
  addTitle(s, "计算器体现CPU的完整数据处理路径", "计算器原理", C.green);
  const stages = [
    ["A输入", "拨码提供8位操作数"],
    ["B输入", "S1确认后进入下一阶段"],
    ["运算号", "0至7选择八种运算"],
    ["CPU执行", "算术、逻辑或软件循环"],
    ["结果输出", "数码管和Flags LED"],
  ];
  stages.forEach((it, i) => {
    const x = 60 + i * 243;
    addShape(s, "roundRect", x, 188, 196, 112, i === 3 ? "#15362C" : C.bg2, i === 3 ? C.green : C.line, 2, "rounded-lg");
    addText(s, it[0], x + 15, 205, 166, 32, 21, i === 3 ? C.green : C.text, true, "center");
    addText(s, it[1], x + 15, 246, 166, 38, 14, C.muted, false, "center", "middle");
    if (i < 4) addShape(s, "rightArrow", x + 201, 226, 34, 28, C.line);
  });
  addText(s, "八种运算", 72, 350, 180, 30, 19, C.green, true);
  const ops = ["0  ADD", "1  SUB", "2  AND", "3  OR", "4  XOR", "5  MUL", "6  DIV", "7  CMP"];
  ops.forEach((op, i) => {
    const x = 72 + (i % 4) * 285;
    const y = 398 + Math.floor(i / 4) * 58;
    addShape(s, "roundRect", x, y, 250, 42, C.panel, C.line, 1, "rounded-lg");
    addText(s, op, x + 18, y + 7, 214, 28, 18, i >= 5 ? C.orange : C.text, true, "center", "middle");
  });
  addText(s, "MUL和DIV由汇编循环完成，展示CPU不是只会做一次组合运算。", 72, 548, 1136, 40, 23, C.text, true, "center", "middle");
  addText(s, "结果LED：bit2..0运算号，bit3..6对应Z/N/C/V，bit7表示除零错误", 72, 606, 1136, 34, 17, C.muted, false, "center");
  addFooter(s, 5);
}

// 6. Calculator demo
{
  const s = deck.slides.add();
  addTitle(s, "计算器现场演示", "演示二", C.green);
  addShape(s, "roundRect", 72, 180, 470, 400, C.bg2, C.line, 2, "rounded-xl");
  addText(s, "推荐主用例", 110, 208, 390, 34, 22, C.green, true, "center");
  addText(s, "A = 2D", 112, 268, 155, 45, 25, C.text, true, "center", "middle");
  addText(s, "B = 17", 347, 268, 155, 45, 25, C.text, true, "center", "middle");
  addShape(s, "roundRect", 112, 330, 390, 74, "#071019", C.green, 2, "rounded-lg");
  addText(s, "2D170044", 132, 343, 350, 48, 32, C.green, true, "center", "middle");
  addText(s, "编号0  ADD", 112, 430, 390, 30, 19, C.muted, false, "center");
  addText(s, "不按S1时改变拨码，结果应保持不变", 105, 488, 405, 50, 18, C.orange, true, "center", "middle");

  addStep(s, 1, "输入A并短按S1", "界面从A00000xx进入B00000xx。", 610, 182, 560, C.green);
  addStep(s, 2, "输入B并短按S1", "界面进入C000000n，拨码低三位选择运算。", 610, 283, 560, C.green);
  addStep(s, 3, "选择运算并短按S1", "CPU执行程序，显示AABBrrrr或除法格式AABBqqrr。", 610, 384, 560, C.green);
  addStep(s, 4, "长按S1约1.2秒", "任意阶段都应返回A输入界面，LED清零。", 610, 485, 560, C.green);
  addText(s, "补充用例：FF×FF = FFFFFE01；23÷00 = E0012300，LED7点亮", 72, 614, 1136, 32, 18, C.text, true, "center");
  addFooter(s, 6);
}

// 7. Simulation projects
{
  const s = deck.slides.add();
  addTitle(s, "对应的仿真工程与顶层", "Vivado仿真", C.cyan);
  addShape(s, "roundRect", 66, 178, 558, 415, C.bg2, C.orange, 2, "rounded-xl");
  addText(s, "流水灯波形", 98, 205, 492, 38, 25, C.orange, true);
  addText(s, "XPR", 98, 268, 84, 26, 15, C.muted, true);
  addText(s, "board_led_vivado_project/\nMiniRISC16_EES331_LED_CHASER.xpr", 98, 299, 488, 66, 20, C.text, true);
  addText(s, "Simulation Top", 98, 391, 150, 26, 15, C.muted, true);
  addText(s, "tb_board_led_chaser", 98, 423, 440, 36, 23, C.orange, true);
  addText(s, "该testbench缩短延时计数，能在很短时间内看到01至80完整循环。", 98, 487, 480, 70, 17, C.text, false);

  addShape(s, "roundRect", 656, 178, 558, 415, C.bg2, C.green, 2, "rounded-xl");
  addText(s, "计算器CPU波形", 688, 205, 492, 38, 25, C.green, true);
  addText(s, "XPR（需先生成）", 688, 268, 180, 26, 15, C.muted, true);
  addText(s, "calculator_system/vivado_project/\nMiniRISC16_Calculator.xpr", 688, 299, 488, 66, 20, C.text, true);
  addText(s, "Simulation Top", 688, 391, 150, 26, 15, C.muted, true);
  addText(s, "tb_calculator_system", 688, 423, 440, 36, 23, C.green, true);
  addText(s, "当前工作区缺少该XPR。先运行：\nscripts/run.ps1 -Task CreateProject", 688, 481, 480, 76, 17, C.orange, true);
  addShape(s, "roundRect", 66, 616, 1148, 42, C.panel, C.cyan, 1, "rounded-lg");
  addText(s, "若只验证S1短按、去抖和长按复位，可把计算器仿真顶层切换为 tb_calculator_board_top。", 90, 623, 1100, 28, 17, C.text, false, "center", "middle");
  addFooter(s, 7);
}

// 8. Waveform capture
{
  const s = deck.slides.add();
  addTitle(s, "CPU波形的信号组合", "波形讲解", C.cyan);
  addShape(s, "roundRect", 62, 176, 530, 422, C.bg2, C.line, 2, "rounded-xl");
  addText(s, "两套工程都建议加入", 94, 204, 466, 32, 22, C.cyan, true);
  const groups = [
    ["取指", "clk / rst / mem_addr(PC) / instruction"],
    ["运算", "rd_data / rs_data / alu_result / Z N C V"],
    ["I/O", "io_addr / io_wdata / io_re / io_we"],
    ["现象", "LED，或display_high / display_low"],
  ];
  groups.forEach((g, i) => {
    const y = 258 + i * 72;
    addText(s, g[0], 96, y, 76, 28, 17, i === 3 ? C.orange : C.green, true);
    addText(s, g[1], 180, y, 370, 42, 17, C.text, false);
  });
  addText(s, "讲解顺序", 94, 548, 120, 26, 16, C.muted, true);
  addText(s, "PC变化 → 指令变化 → ALU结果 → I/O写使能 → 板级输出变化", 214, 542, 344, 44, 17, C.text, true);

  const wavePath = path.join(workspaceDir, "MiniRISC-16-CPU", "reports", "waveforms", "01_single_cycle_commit.png");
  const waveBytes = await fs.readFile(wavePath);
  s.images.add({
    blob: waveBytes.buffer.slice(waveBytes.byteOffset, waveBytes.byteOffset + waveBytes.byteLength),
    contentType: "image/png",
    alt: "MiniRISC-16单周期CPU已有仿真波形示例",
    fit: "contain",
    position: { left: 630, top: 180, width: 590, height: 336 },
  });
  addText(s, "现有CPU单周期波形示例", 690, 526, 470, 28, 16, C.muted, false, "center");
  addShape(s, "roundRect", 630, 572, 590, 75, "#102B2B", C.green, 1, "rounded-lg");
  addText(s, "最终展示时，用流水灯或计算器工程重新截取同样的信号组，画面即可直接对应板上行为。", 658, 587, 534, 46, 19, C.text, true, "center", "middle");
  addFooter(s, 8);
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
    families: [fontFamily],
  },
  expectedSlideSizeEmu: "12192000,6858000",
  // Verified immediately after finalization with the same first-party importer.
  // The finalizer's nested importer currently crashes in this Windows runtime.
  verifyArtifactToolImport: false,
  receiptPath: path.join(buildDir, "validation.json"),
});

console.log(JSON.stringify({ finalPath, draftPath, previewDir, result }, null, 2));

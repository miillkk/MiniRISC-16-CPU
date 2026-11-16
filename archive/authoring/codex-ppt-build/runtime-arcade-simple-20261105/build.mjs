import fs from "node:fs/promises";
import path from "node:path";
import { Presentation, PresentationFile } from "file:///C:/Program%20Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1104-1290-0_26.1104.1290.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs";

const workspaceDir = "C:/Users/xieke/Desktop/CPU";
const buildDir = path.join(workspaceDir, ".codex-ppt-build/runtime-arcade-detailed-20261106");
const previewDir = path.join(buildDir, "preview");
const draftPath = path.join(buildDir, "MiniRISC16_Runtime_三项目展示_详细版_draft.pptx");
const menuPath = path.join(buildDir, "ppt/media/image.png");
const image2048Path = path.join(buildDir, "ppt/media/image2.png");
const snakePath = path.join(buildDir, "ppt/media/image3.png");

const C = {
  navy: "#10243A", teal: "#10A89A", tealLight: "#DDF5F1",
  orange: "#F59E0B", orangeLight: "#FFF1D6", bg: "#F4F7FA",
  white: "#FFFFFF", ink: "#172033", muted: "#5B6B7D",
  line: "#CDD7E2", blue: "#2F6BFF", blueLight: "#E8F0FF",
};
const FONT = "Microsoft YaHei";

async function writeBlob(filePath, blob) {
  await fs.writeFile(filePath, new Uint8Array(await blob.arrayBuffer()));
}

async function readImageBlob(filePath) {
  const bytes = await fs.readFile(filePath);
  return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
}

function setBg(slide, color = C.bg) {
  slide.background.fill = color;
}

function box(slide, x, y, width, height, fill = "none", lineFill = "none", geometry = "rect", lineWidth = 0) {
  return slide.shapes.add({
    geometry,
    position: { left: x, top: y, width, height },
    fill,
    line: { style: "solid", fill: lineFill, width: lineWidth },
  });
}

function text(slide, value, x, y, width, height, fontSize = 24, color = C.ink, bold = false, alignment = "left") {
  const shape = box(slide, x, y, width, height);
  shape.text = value;
  shape.text.style = {
    fontFamily: FONT,
    fontSize,
    color,
    bold,
    alignment,
    verticalAlignment: "middle",
  };
  return shape;
}

function slideTitle(slide, value, number) {
  text(slide, String(number).padStart(2, "0"), 58, 40, 56, 32, 14, C.teal, true);
  text(slide, value, 58, 72, 1080, 56, 34, C.navy, true);
  box(slide, 58, 140, 1164, 2, C.line);
}

function pill(slide, value, x, y, width, fill, color) {
  const shape = box(slide, x, y, width, 34, fill, "none", "roundRect");
  shape.text = value;
  shape.text.style = {
    fontFamily: FONT, fontSize: 14, color, bold: true,
    alignment: "center", verticalAlignment: "middle",
  };
}

function label(slide, value, x, y, color = C.teal) {
  text(slide, value, x, y, 200, 28, 15, color, true);
}

function imageFrame(slide, blob, alt, x, y, width, height, fit = "contain") {
  box(slide, x - 4, y - 4, width + 8, height + 8, C.white, C.line, "roundRect", 1);
  slide.images.add({
    blob,
    contentType: "image/png",
    alt,
    fit,
    position: { left: x, top: y, width, height },
  });
}

function placeholder(slide, titleValue, subtitle, x, y, width, height) {
  box(slide, x, y, width, height, C.white, C.line, "roundRect", 2);
  text(slide, "图片占位", x + 24, y + height / 2 - 46, width - 48, 28, 18, C.teal, true, "center");
  text(slide, titleValue, x + 24, y + height / 2 - 10, width - 48, 36, 22, C.navy, true, "center");
  text(slide, subtitle, x + 28, y + height / 2 + 34, width - 56, 42, 14, C.muted, false, "center");
}

function addNotes(slide, sources, talk) {
  slide.speakerNotes.text = [talk, "", "资料来源：", ...sources.map((source) => `• ${source}`)].join("\n");
}

async function main() {
  await fs.mkdir(previewDir, { recursive: true });
  const [menuBlob, image2048Blob, snakeBlob] = await Promise.all([
    readImageBlob(menuPath), readImageBlob(image2048Path), readImageBlob(snakePath),
  ]);

  const presentation = Presentation.create({ slideSize: { width: 1280, height: 720 } });

  // 1. Cover
  {
    const slide = presentation.slides.add();
    setBg(slide, C.navy);
    box(slide, 0, 0, 22, 720, C.teal);
    text(slide, "MINIRISC-16 RUNTIME", 66, 64, 470, 32, 16, "#83E1D7", true);
    text(slide, "基于自研 CPU 的\n多程序运行平台", 66, 118, 760, 144, 50, C.white, true);
    text(slide, "流水灯、2048 与贪吃蛇的上板现象和实现原理", 70, 282, 820, 42, 22, "#C6D4E2");
    [["流水灯", "板载 LED"], ["2048", "4×4 棋盘"], ["贪吃蛇", "16×8 游戏"]].forEach((item, index) => {
      const x = 70 + index * 380;
      box(slide, x, 418, 330, 152, "#173550", "#365670", "roundRect", 1);
      text(slide, item[0], x + 24, 444, 282, 38, 28, C.white, true);
      text(slide, item[1], x + 24, 490, 282, 30, 17, "#98ADBF");
      text(slide, "项目图片或实拍", x + 24, 532, 282, 24, 13, "#68CFC4");
    });
    text(slide, "同一套 CPU 硬件，通过加载不同机器码运行三个程序", 70, 626, 1050, 28, 18, "#DCE6EE");
    addNotes(slide, ["runtime_system/README.md"], "开场先说明三个项目属于同一套 Runtime 平台。");
  }

  // 2. Overview
  {
    const slide = presentation.slides.add();
    setBg(slide); slideTitle(slide, "一个 CPU 运行三个程序", 2);
    imageFrame(slide, menuBlob, "MiniRISC-16 Arcade 选择菜单", 58, 178, 670, 330);
    text(slide, "相同硬件", 774, 182, 380, 30, 16, C.teal, true);
    text(slide, "Runtime bitstream\n保持不变", 774, 214, 390, 74, 30, C.navy, true);
    box(slide, 774, 312, 388, 2, C.line);
    text(slide, "不同软件", 774, 336, 380, 30, 16, C.orange, true);
    text(slide, "UART Loader 更换\n程序 RAM 中的机器码", 774, 368, 410, 78, 25, C.ink, true);
    text(slide, "流水灯  174 条有效指令", 774, 474, 408, 28, 17, C.muted);
    text(slide, "2048      534 条有效指令", 774, 510, 408, 28, 17, C.muted);
    text(slide, "贪吃蛇  477 条有效指令", 774, 546, 408, 28, 17, C.muted);
    text(slide, "切换程序时不重新综合 FPGA", 58, 628, 1164, 30, 20, C.navy, true, "center");
    addNotes(slide, ["runtime_system/README.md", "runtime_system/BOARD_TEST_GUIDE.md", "用户提供：选择菜单界面.png"], "这张菜单图说明三个项目由统一启动器选择。");
  }

  // 3. Architecture
  {
    const slide = presentation.slides.add();
    setBg(slide); slideTitle(slide, "Runtime 硬件架构", 3);
    box(slide, 70, 190, 226, 78, C.orangeLight, C.orange, "roundRect", 1);
    text(slide, "UART Loader", 88, 202, 190, 28, 22, C.orange, true, "center");
    text(slide, "SW7=1 写程序", 88, 234, 190, 22, 14, C.muted, false, "center");
    box(slide, 330, 190, 250, 78, C.white, C.line, "roundRect", 1);
    text(slide, "1K×16 程序 RAM", 348, 202, 214, 30, 22, C.navy, true, "center");
    text(slide, "保存当前机器码", 348, 236, 214, 20, 14, C.muted, false, "center");
    box(slide, 614, 176, 298, 106, C.navy, "none", "roundRect");
    text(slide, "MiniRISC-16 CPU", 636, 194, 254, 34, 25, C.white, true, "center");
    text(slide, "Controller + Datapath", 636, 236, 254, 22, 15, "#B9C9D7", false, "center");
    box(slide, 946, 190, 250, 78, C.white, C.line, "roundRect", 1);
    text(slide, "256×16 数据 RAM", 964, 202, 214, 30, 21, C.navy, true, "center");
    text(slide, "保存游戏状态", 964, 236, 214, 20, 14, C.muted, false, "center");
    box(slide, 296, 216, 34, 22, C.orange, "none", "rightArrow");
    box(slide, 580, 216, 34, 22, C.teal, "none", "rightArrow");
    box(slide, 912, 216, 34, 22, C.teal, "none", "rightArrow");
    text(slide, "公共外设", 70, 344, 200, 28, 17, C.teal, true);
    [["UART", "按键与状态帧"], ["Timer", "移动节拍"], ["LFSR", "伪随机数"], ["LED / 数码管", "板级输出"], ["拨码开关", "速度与暂停"]].forEach((item, index) => {
      const x = 70 + index * 226;
      box(slide, x, 390, 198, 106, C.white, C.line, "roundRect", 1);
      text(slide, item[0], x + 18, 408, 162, 30, 20, C.navy, true, "center");
      text(slide, item[1], x + 16, 448, 166, 24, 14, C.muted, false, "center");
    });
    box(slide, 590, 300, 70, 64, C.teal, "none", "downArrow");
    text(slide, "CPU 通过 I/O 地址访问外设，游戏规则由程序执行", 70, 560, 1126, 36, 20, C.navy, true, "center");
    text(slide, "Timer 和 LFSR 提供基础服务，不代替 CPU 计算游戏逻辑", 70, 606, 1126, 30, 17, C.muted, false, "center");
    addNotes(slide, ["runtime_system/README.md", "runtime_system/rtl/top/runtime_soc.v"], "区分 CPU、存储器和外设的责任。");
  }

  // 4. UART modes
  {
    const slide = presentation.slides.add();
    setBg(slide); slideTitle(slide, "串口的两种工作模式", 4);
    box(slide, 56, 170, 558, 452, C.white, C.line, "roundRect", 1);
    box(slide, 666, 170, 558, 452, C.white, C.line, "roundRect", 1);
    pill(slide, "SW7 = 1", 84, 194, 112, C.orangeLight, C.orange);
    text(slide, "程序加载模式", 84, 240, 470, 40, 28, C.navy, true);
    text(slide, "CPU 保持复位", 84, 294, 430, 28, 18, C.ink, true);
    text(slide, "电脑发送 .mem 机器码", 84, 336, 430, 28, 18);
    text(slide, "Loader 写入 1K×16 程序 RAM", 84, 376, 430, 28, 18);
    text(slide, "数码管显示 10AD，LED 给出状态", 84, 416, 430, 28, 18);
    box(slide, 126, 490, 364, 54, C.orangeLight, "none", "roundRect");
    text(slide, "电脑、Loader、程序 RAM", 142, 500, 332, 32, 19, C.orange, true, "center");
    pill(slide, "SW7 = 0", 694, 194, 112, C.tealLight, C.teal);
    text(slide, "程序运行模式", 694, 240, 470, 40, 28, C.navy, true);
    text(slide, "CPU 从 PC=0 开始取指", 694, 294, 430, 28, 18, C.ink, true);
    text(slide, "键盘按键经 UART 送入 CPU", 694, 336, 430, 28, 18);
    text(slide, "CPU 计算后发送状态帧", 694, 376, 430, 28, 18);
    text(slide, "终端只显示结果，不计算游戏", 694, 416, 430, 28, 18);
    box(slide, 736, 490, 364, 54, C.tealLight, "none", "roundRect");
    text(slide, "终端、CPU UART、程序", 752, 500, 332, 32, 19, C.teal, true, "center");
    text(slide, "100 MHz 时钟，868 clocks/bit，串口速率约 115200 baud", 58, 650, 1164, 26, 16, C.muted, false, "center");
    addNotes(slide, ["runtime_system/rtl/top/runtime_soc.v", "runtime_system/BOARD_TEST_GUIDE.md"], "先讲 Loader，再讲运行时 UART。明确电脑端不负责游戏计算。");
  }

  // 5. Running light
  {
    const slide = presentation.slides.add();
    setBg(slide); slideTitle(slide, "流水灯：直接控制板载 LED", 5);
    placeholder(slide, "插入流水灯实板照片", "建议同时拍到 LED、拨码和终端", 58, 176, 650, 430);
    label(slide, "现象", 754, 180, C.teal);
    text(slide, "单灯在 LED0 至 LED7 之间移动\nA / D 改变方向\nSW1..0 调速，SW2 暂停\n边界自动回绕", 754, 214, 452, 116, 18);
    box(slide, 754, 340, 452, 2, C.line);
    label(slide, "实现原理", 754, 358, C.blue);
    text(slide, "CPU 等待 Timer 节拍，读取方向与拨码，计算下一位置，再执行 OUP 0x30 写入 LED。", 754, 392, 452, 88, 18);
    box(slide, 754, 492, 452, 2, C.line);
    label(slide, "CPU 证据", 754, 510, C.orange);
    text(slide, "波形对应 PC、instruction、io_we、io_addr、io_wdata 与 LED，可看到 01 变为 02。", 754, 544, 452, 76, 18);
    addNotes(slide, ["runtime_system/games/running_light/README.md", "runtime_system/reports/waveforms/current_terminal/README.md"], "现场先演示流水灯，把 OUP 指令与物理 LED 变化对应起来。");
  }

  // 6. Running light CPU implementation
  {
    const slide = presentation.slides.add();
    setBg(slide); slideTitle(slide, "流水灯的 CPU 执行过程", 6);
    const steps = [
      ["读取输入", "UART、拨码"],
      ["等待节拍", "INP 0x12"],
      ["读取状态", "LDR 位置和方向"],
      ["更新位置", "比较、加减、回绕"],
      ["输出结果", "LED 与串口帧"],
    ];
    steps.forEach((item, index) => {
      const x = 58 + index * 236;
      const color = [C.orange, C.teal, C.blue, C.orange, C.teal][index];
      box(slide, x, 174, 200, 84, C.white, color, "roundRect", 1);
      text(slide, item[0], x + 16, 188, 168, 28, 19, C.navy, true, "center");
      text(slide, item[1], x + 14, 222, 172, 22, 14, C.muted, false, "center");
      if (index < 4) box(slide, x + 200, 205, 36, 22, color, "none", "rightArrow");
    });
    text(slide, "状态保存在数据 RAM", 58, 300, 500, 34, 22, C.teal, true);
    text(slide, "0x20  当前位置 0..7\n0x21  方向，0 为右，1 为左\n0x22  串口帧序号\n0x23  拨码快照\n0x24  最近一次按键\n0x25  当前 LED pattern", 58, 346, 500, 220, 18, C.ink);
    box(slide, 574, 300, 2, 300, C.line);
    text(slide, "CPU 实际执行的指令", 620, 300, 560, 34, 22, C.orange, true);
    box(slide, 620, 348, 560, 186, C.navy, "none", "roundRect");
    text(slide, "INP  0x12       检查 Timer 节拍\nLDR  [0x20]     读取当前位置\nCMP  + JZ       判断 LED0 或 LED7\nADDI / SUB      位置加一或减一\nADDR R1,R1      反复倍增生成 1 << position\nOUP  0x30,R1    写入板载 LED", 646, 364, 512, 154, 17, C.white);
    text(slide, "随后 CPU 组织 12 字节状态帧，逐字节执行 OUP 0x10 发送到串口。", 620, 554, 560, 52, 17, C.muted);
    addNotes(slide, ["runtime_system/games/running_light/program/running_light.asm"], "回答老师时沿着输入、状态、运算和输出逐步讲。位置并不是硬件计数器更新，而是 CPU 执行 ADDI 或 SUB 修改数据 RAM。");
  }

  // 7. 2048
  {
    const slide = presentation.slides.add();
    setBg(slide); slideTitle(slide, "2048：数据 RAM 与软件算法", 7);
    imageFrame(slide, image2048Blob, "MiniRISC-16 2048 运行界面", 58, 176, 650, 430);
    label(slide, "现象", 754, 180, C.blue);
    text(slide, "4×4 棋盘支持四方向移动\n相同方块合并并累计分数\n有效移动后生成新方块\n支持胜利与无路可走判断", 754, 214, 452, 116, 18);
    box(slide, 754, 340, 452, 2, C.line);
    label(slide, "实现原理", 754, 358, C.teal);
    text(slide, "CPU 用 LDR / STR 访问 16 个棋盘单元，依次完成压缩、相邻比较、合并、写回与计分。", 754, 392, 452, 88, 18);
    box(slide, 754, 492, 452, 2, C.line);
    label(slide, "串口输出", 754, 510, C.orange);
    text(slide, "CPU 发送 27 字节状态帧，终端读取状态、分数和 16 个方块后绘制棋盘。", 754, 544, 452, 76, 18);
    addNotes(slide, ["runtime_system/games/2048/README.md", "runtime_system/games/2048/program/game_2048.asm", "用户提供：ScreenShot_2026-11-05_201605_599.png"], "演示一次明确合并，说明棋盘数据保存在板上数据 RAM。");
  }

  // 8. 2048 CPU implementation
  {
    const slide = presentation.slides.add();
    setBg(slide); slideTitle(slide, "2048 的 CPU 执行过程", 8);
    const steps = [
      ["接收方向", "UART W/A/S/D"],
      ["选择行列", "四条逻辑线"],
      ["读取单元", "LDR 棋盘数据"],
      ["压缩合并", "CMP、JZ、ADDI"],
      ["写回与生成", "STR、LFSR"],
    ];
    steps.forEach((item, index) => {
      const x = 58 + index * 236;
      const color = [C.blue, C.teal, C.orange, C.blue, C.teal][index];
      box(slide, x, 174, 200, 84, C.white, color, "roundRect", 1);
      text(slide, item[0], x + 16, 188, 168, 28, 19, C.navy, true, "center");
      text(slide, item[1], x + 14, 222, 172, 22, 14, C.muted, false, "center");
      if (index < 4) box(slide, x + 200, 205, 36, 22, color, "none", "rightArrow");
    });
    text(slide, "棋盘和中间状态", 58, 300, 480, 34, 22, C.teal, true);
    text(slide, "0x40..0x4F  16 个棋盘单元\n0x50..0x53  一行或一列的临时缓冲\n0x30  当前方向\n0x35  本次是否发生移动\n0x36  16 位分数\n0x38  胜利或失败状态", 58, 346, 500, 190, 18, C.ink);
    text(slide, "方块保存指数：0 为空，1 表示 2，2 表示 4，11 表示 2048。", 58, 550, 500, 52, 17, C.muted);
    box(slide, 574, 300, 2, 306, C.line);
    text(slide, "一次合并怎样完成", 620, 300, 560, 34, 22, C.orange, true);
    box(slide, 620, 346, 560, 112, C.blueLight, "none", "roundRect");
    text(slide, "输入指数   1，1，2，0     表示 2，2，4，空\n输出指数   2，2，0，0     表示 4，4，空，空", 646, 364, 512, 76, 18, C.navy, true);
    text(slide, "CPU 跳过 0，比较最后一个输出单元。相等时执行 ADDI 将指数加一，并用反复 ADDR 计算本次增加的分数。", 620, 476, 560, 74, 17, C.ink);
    text(slide, "只有 moved=1 才读取 LFSR 端口 0x13 生成新方块。棋盘填满后，CPU 再扫描横向和纵向相邻单元判断是否结束。", 620, 558, 560, 70, 17, C.muted);
    addNotes(slide, ["runtime_system/games/2048/program/game_2048.asm"], "重点解释行缓冲。CPU一次处理四个逻辑行或列，每个单元都通过 LDR 读取、比较后用 STR 写回。没有专用 2048 硬件模块。");
  }

  // 9. Snake
  {
    const slide = presentation.slides.add();
    setBg(slide); slideTitle(slide, "贪吃蛇：实时状态与交互控制", 9);
    text(slide, "实时运行画面", 58, 184, 650, 28, 15, C.teal, true, "center");
    imageFrame(slide, snakeBlob, "MiniRISC-16 Snake V2 运行界面", 58, 232, 650, 276);
    text(slide, "CPU 返回 RUNNING、Score、Level、方向和帧序号", 58, 532, 650, 28, 15, C.muted, false, "center");
    label(slide, "现象", 754, 180, C.orange);
    text(slide, "16×8 棋盘与三种地图\n方向控制、暂停和重新开始\n吃食物后增长并提高速度\n碰撞后进入 Game Over", 754, 214, 452, 116, 18);
    box(slide, 754, 340, 452, 2, C.line);
    label(slide, "实现原理", 754, 358, C.teal);
    text(slide, "CPU 在每个 Timer 节拍计算新蛇头，检查边界、障碍与蛇身，再更新位置、食物、分数和速度。", 754, 392, 452, 88, 18);
    box(slide, 754, 492, 452, 2, C.line);
    label(slide, "串口输出", 754, 510, C.blue);
    text(slide, "CPU 发送 140 字节状态帧，包含版本、长度、序号、棋盘数据和 XOR 校验。", 754, 544, 452, 76, 18);
    addNotes(slide, ["runtime_system/README.md", "runtime_system/BOARD_TEST_GUIDE.md", "用户提供：ScreenShot_2026-11-05_201545_180.png"], "展示移动、暂停和碰撞，说明 Timer 与 LFSR 是外设，规则判断由 CPU 程序完成。");
  }

  // 10. Snake CPU implementation
  {
    const slide = presentation.slides.add();
    setBg(slide); slideTitle(slide, "贪吃蛇的 CPU 执行过程", 10);
    const steps = [
      ["读取方向", "拒绝反向输入"],
      ["等待节拍", "INP 0x12"],
      ["计算新蛇头", "坐标加减"],
      ["检查目标格", "边界、墙、蛇身"],
      ["更新状态", "长度、食物、分数"],
    ];
    steps.forEach((item, index) => {
      const x = 58 + index * 236;
      const color = [C.orange, C.teal, C.blue, C.orange, C.teal][index];
      box(slide, x, 174, 200, 84, C.white, color, "roundRect", 1);
      text(slide, item[0], x + 16, 188, 168, 28, 19, C.navy, true, "center");
      text(slide, item[1], x + 14, 222, 172, 22, 14, C.muted, false, "center");
      if (index < 4) box(slide, x + 200, 205, 36, 22, color, "none", "rightArrow");
    });
    text(slide, "坐标和棋盘表示", 58, 300, 500, 34, 22, C.teal, true);
    text(slide, "位置编码 = 行 × 16 + 列\n向上减 0x10，向下加 0x10\n向左减 1，向右加 1\nAND 0x70 检查行边界\nAND 0x0F 检查列边界", 58, 346, 500, 160, 18, C.ink);
    text(slide, "数据 RAM 中 board[0x04 + position]：\n0 为空格，0xFF 为墙，正数表示蛇身剩余寿命。", 58, 520, 500, 76, 17, C.muted);
    box(slide, 574, 300, 2, 306, C.line);
    text(slide, "碰撞、增长和食物生成", 620, 300, 560, 34, 22, C.orange, true);
    text(slide, "每个节拍，CPU 遍历 128 个棋盘单元，对非零蛇身执行 LDR、SUB、STR，使尾部逐步消失。", 620, 346, 560, 66, 17, C.ink);
    text(slide, "新蛇头对应单元非零时进入 GAME_OVER。空格则写入当前蛇长；如果位置等于 food，CPU 增加蛇长、分数和速度等级。", 620, 426, 560, 86, 17, C.ink);
    box(slide, 620, 528, 560, 76, C.orangeLight, "none", "roundRect");
    text(slide, "食物位置来自 INP 0x13，并与 0x7F 相与。CPU 最多随机尝试 16 次，失败后顺序扫描 128 个格子。", 644, 540, 512, 52, 17, C.navy, true);
    addNotes(slide, ["runtime_system/program/snake.asm"], "老师追问时可先讲位置编码，再讲数据 RAM 中的寿命值。蛇身移动不是整体搬移数组，而是每步递减寿命并在新蛇头写入当前长度。");
  }

  // 11. Evidence
  {
    const slide = presentation.slides.add();
    setBg(slide); slideTitle(slide, "运行在自研 CPU 上的证据链", 11);
    const items = [
      ["同一 bitstream", "三次演示共用 Runtime 硬件"],
      ["UART Loader", "只替换程序 RAM 的机器码"],
      ["CPU 执行波形", "PC、指令、RAM 和 I/O 对应"],
      ["实板现象", "LED 与终端状态由 CPU 输出"],
    ];
    items.forEach((item, index) => {
      const x = 58 + index * 296;
      const color = [C.navy, C.orange, C.teal, C.blue][index];
      box(slide, x, 202, 258, 150, C.white, C.line, "roundRect", 1);
      box(slide, x, 202, 258, 10, color);
      text(slide, item[0], x + 26, 224, 210, 32, 21, C.navy, true);
      text(slide, item[1], x + 26, 270, 210, 54, 14, C.muted);
      if (index < 3) box(slide, x + 258, 260, 38, 22, color, "none", "rightArrow");
    });
    box(slide, 58, 400, 1164, 122, C.navy, "none", "roundRect");
    text(slide, "结论", 84, 420, 150, 28, 16, "#77D9CF", true);
    text(slide, "三个项目使用相同的 MiniRISC-16 Runtime 硬件。\n功能差异来自 CPU 执行的不同程序。", 84, 454, 1060, 58, 28, C.white, true);
    text(slide, "实现结果：100 MHz，WNS +0.157 ns，1204 LUT，750 FF，DRC 0 Error", 58, 570, 1164, 30, 17, C.navy, true, "center");
    text(slide, "现场顺序：流水灯、2048、贪吃蛇、CPU波形与综合层级", 58, 620, 1164, 28, 16, C.muted, false, "center");
    addNotes(slide, ["runtime_system/README.md", "runtime_system/reports/waveforms/current_terminal/README.md"], "结束时回到同一 bitstream 和不同程序镜像这一核心证据。");
  }

  for (const [index, slide] of presentation.slides.items.entries()) {
    const png = await presentation.export({ slide, format: "png", scale: 1 });
    await writeBlob(path.join(previewDir, `slide_${String(index + 1).padStart(2, "0")}.png`), png);
  }
  const montage = await presentation.export({ format: "webp", montage: true });
  await writeBlob(path.join(buildDir, "montage.webp"), montage);
  const inspect = await presentation.inspect({ kind: "slide,textbox,shape,image,notes,layout", maxChars: 30000 });
  await fs.writeFile(path.join(buildDir, "inspect.ndjson"), inspect.ndjson, "utf8");
  const draft = await PresentationFile.exportPptx(presentation);
  await draft.save(draftPath);
  console.log(JSON.stringify({ draftPath, slideCount: presentation.slides.items.length, previewDir }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

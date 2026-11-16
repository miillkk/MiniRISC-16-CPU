import fs from 'node:fs/promises';
import path from 'node:path';
import {Presentation,PresentationFile} from 'file:///C:/Program%20Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1105-1297-0_26.1105.1297.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';
const root='C:/Users/xieke/Desktop/CPU', build=path.join(root,'.codex-ppt-build/runtime-arcade-compact-20261110'), preview=path.join(build,'preview');
const imgRoot='C:/Users/xieke/Desktop/新建文件夹 (2)';
const C={bg:'#0B1424',panel:'#12233A',white:'#F5F8FC',muted:'#A9BBCD',teal:'#43D9CE',orange:'#FFB65C',line:'#35516D',red:'#FF7777'};
const p=Presentation.create({slideSize:{width:1280,height:720}});
async function blob(fp){let b=await fs.readFile(fp);return b.buffer.slice(b.byteOffset,b.byteOffset+b.byteLength)}
async function write(fp,b){await fs.writeFile(fp,new Uint8Array(await b.arrayBuffer()))}
function shape(s,x,y,w,h,fill='none',stroke='none',sw=0,geometry='rect'){return s.shapes.add({geometry,position:{left:x,top:y,width:w,height:h},fill,line:{style:'solid',fill:stroke,width:sw}})}
function text(s,v,x,y,w,h,size=22,color=C.white,bold=false,align='left'){let q=shape(s,x,y,w,h);q.text=v;q.text.style={fontFamily:'Arial',fontSize:size,color,bold,alignment:align,verticalAlignment:'middle'};return q}
function base(title,n){let s=p.slides.add();s.background.fill=C.bg;shape(s,0,0,13,720,C.teal);text(s,title,58,32,1130,54,34,C.white,true);shape(s,58,105,1162,2,C.line);text(s,String(n).padStart(2,'0'),1160,36,55,28,15,C.teal,true,'right');return s}
function image(s,b,alt,x,y,w,h){shape(s,x-4,y-4,w+8,h+8,C.panel,C.line,1);s.images.add({blob:b,contentType:'image/png',alt,fit:'contain',position:{left:x,top:y,width:w,height:h}})}
function code(s,v,x,y,w,h,fs=21){shape(s,x,y,w,h,C.panel,C.line,1);text(s,v,x+18,y+10,w-36,h-20,fs,C.white)}
function note(s,body,sources){s.speakerNotes.text=`讲解提示：\n${body}\n\n资料来源：\n${sources.map(x=>'• '+x).join('\n')}`}
await fs.mkdir(preview,{recursive:true});
const [menu,g2048,g2048end,snake1,snake2,snakeEnd]=await Promise.all(['选择菜单界面.png','2048.png','2048结束.png','贪吃蛇1.png','贪吃蛇2.png','贪吃蛇游戏结束.png'].map(n=>blob(path.join(imgRoot,n))));

// 1. outcome
{
let s=base('上板运行：同一套硬件，三个程序',1);image(s,menu,'电脑端统一菜单',58,150,709,350);
text(s,'电脑端选择与上传',805,158,385,40,26,C.teal,true);
text(s,'SW7=1：加载机器码\nSW7=0：CPU 运行\n终端接收板上的状态帧',805,220,385,172,25);
shape(s,805,428,385,2,C.line);text(s,'流水灯  /  2048  /  贪吃蛇',805,460,385,50,23,C.orange,true);
text(s,'统一菜单在电脑端；板上一次运行一个程序，切换时无需重新生成 bitstream。',58,557,1130,75,24,C.white,true);
note(s,'约 45 秒。承接 CPU 设计部分。强调统一菜单在电脑端，一次运行一个程序，三个程序共用 Runtime bitstream。',['用户图片：选择菜单界面.png','runtime_system/README.md']);
}
// 2. UART
{
let s=base('UART：程序上传与运行交互',2);
text(s,'SW7 = 1  加载模式',61,150,500,40,27,C.orange,true);text(s,'电脑传机器码；Loader 写程序 RAM；CPU 复位',61,205,530,70,22);
text(s,'SW7 = 0  运行模式',663,150,500,40,27,C.teal,true);text(s,'CPU 取指执行；电脑传按键；CPU 返回状态帧',663,205,530,70,22);
shape(s,625,152,2,137,C.line);
code(s,"wire cpu_rst = rst | load_mode;\nassign uart_tx = load_mode\n    ? loader_uart_tx : cpu_uart_tx;",59,336,564,149,22);
code(s,"0x10  数据：接收按键 / 发送字节\n0x11  状态：rx_valid / tx_ready\nINP 0x11 → 检查状态\nOUP 0x10 → 发送数据",657,336,565,194,21);
text(s,'板载 CP2103 实现 USB 转串口；FPGA 内部 UART 收发和 CPU 端口由 Verilog 实现。',61,584,1140,64,21,C.muted);
note(s,'约 1 分 30 秒。SW7=1 时 Loader 接管 UART，两个 8 位字节合成一个 16 位程序字，写入 1K×16 程序 RAM；SW7=0 时 CPU 从 0x000 取指，经 0x10/0x11 访问 UART。电脑终端负责显示。',['runtime_system/rtl/top/runtime_soc.v','runtime_system/rtl/peripherals/program_loader.v','runtime_system/rtl/peripherals/uart_port.v','runtime_system/rtl/peripherals/io_decoder.v']);
}
// 3. running light combined
{
let s=base('流水灯：运行现象与 CPU 控制',3);
text(s,'现场演示：移动、反向、调速、暂停',60,148,1110,39,24,C.teal,true);
shape(s,60,205,1160,137,C.panel,C.line,1);
for(let i=0;i<8;i++){let x=105+i*145;shape(s,x,232,49,49,i===3?C.orange:C.panel,i===3?C.orange:C.line,2,'ellipse');text(s,`LED${i}`,x-8,288,65,25,16,C.muted,false,'center')}
code(s,"LDR  R0, R3      ; RAM 读位置\nCMP  R0, R1      ; 判断边界\nADDI R0, 0x01    ; 更新位置\nSTR  R3, R0      ; 写回 RAM",60,389,535,192,21);
code(s,"MOVI R1, 0x01   ; 单灯图案\nADDR R1, R1     ; 每次加倍\nOUP  0x30, R1   ; 输出到 LED",642,389,578,163,21);
text(s,'Timer 端口 0x12 给节拍；LED RTL 寄存器只保存 CPU 写入的 8 位结果。',60,610,1150,49,21,C.white);
note(s,'约 1 分 25 秒，包含现场演示。RAM 0x20 保存位置、0x21 保存方向。CPU 读定时器事件，计算下一位置，到边界回绕，从 1 反复自加生成 8 位图案，再 OUP 0x30。说明图中的 LED3 是可编辑示意图，现场实际亮灯会变化。',['runtime_system/games/running_light/program/running_light.asm','runtime_system/rtl/peripherals/led8.v','runtime_system/rtl/peripherals/tick_timer.v']);
}
// 4. 2048 combined
{
let s=base('2048：画面与合并规则',4);
image(s,g2048,'2048运行画面',56,145,548,393);
image(s,g2048end,'2048结束画面',662,145,548,393);
text(s,'运行中：方向键移动、合并与计分',61,544,550,34,20,C.teal,true,'center');
text(s,'满盘且无可合并方块：游戏结束',658,544,555,34,20,C.red,true,'center');
code(s,"LDR  R1, R3  →  ADDI R1, 0x01  →  STR  R3, R1",60,594,670,64,19);
text(s,'16格存指数；合并指数加1，有效移动后生成新块。',750,586,465,84,18,C.white);
note(s,'约 1 分 45 秒。左图展示正常运行和分数，右图展示满盘且无可合并方块。16 格以指数存于 RAM 0x40–0x4F：0空、1=2、2=4。每条逻辑行跳过零值、压缩和合并，0x50–0x53 是临时行；合并标记防止同一方块本轮重复合并。底部代码是合并关键指令的讲解性摘录。只有棋盘变化才生成新方块。',['用户图片：2048.png','用户图片：2048结束.png','runtime_system/games/2048/program/game_2048.asm','runtime_system/rtl/peripherals/lfsr8.v']);
}
// 5. snake combined
{
let s=base('贪吃蛇：画面与地图更新',5);
image(s,snake1,'贪吃蛇初始画面',58,144,550,225);
image(s,snake2,'贪吃蛇成长与加速画面',668,144,550,225);
text(s,'初始：分数 0，移动节拍 1.00 s',61,371,550,31,18,C.teal,true,'center');
text(s,'成长：分数 6，等级 3，节拍 0.125 s',665,371,550,31,18,C.orange,true,'center');
image(s,snakeEnd,'贪吃蛇游戏结束画面',58,428,440,176);
text(s,'另一局的结束画面',61,609,438,27,18,C.red,true,'center');
code(s,"位置 = 行×16 + 列\nAND  R3, R2   ; 检查边界\nSUB  R0, R1   ; 蛇身寿命减 1\nSTR  R3, R0   ; 写回地图",540,431,676,184,20);
text(s,'RAM 0x04–0x83 共 128 格；0=空，0xFF=墙。CPU 更新蛇身、判断碰撞与食物。',540,622,674,54,18,C.white);
note(s,'约 1 分 45 秒。三张图展示初始、得分加速和结束；结束图来自另一局，不要当作右上图的连续下一帧。讲 16×8 地图、行×16+列的坐标，上下 ±0x10、左右 ±1。CPU 遍历 RAM 0x04–0x83，蛇身寿命减一，新头写当前长度，检查目标格与食物。140 字节状态帧送到终端绘图。',['用户图片：贪吃蛇1.png','用户图片：贪吃蛇2.png','用户图片：贪吃蛇游戏结束.png','runtime_system/program/snake.asm']);
}
// 6. summary
{
let s=base('三个项目共用的上板运行方式',6);
text(s,'输入',64,159,156,37,23,C.teal,true);text(s,'CPU 程序处理',323,159,316,37,23,C.teal,true);text(s,'RAM 状态',729,159,244,37,23,C.teal,true);text(s,'输出',1060,159,150,37,23,C.teal,true);
shape(s,60,207,1160,2,C.line);
const rows=[['按键 / 拨码 / 节拍','位置与位图计算','灯位、方向','LED + UART'],['方向键','压缩、合并、计分','16 格棋盘','UART 画面'],['方向键 / 节拍','坐标、碰撞、蛇身更新','128 格地图','UART 画面']];
rows.forEach((r,i)=>{let y=229+i*116;text(s,r[0],64,y,248,63,20,C.white);text(s,r[1],322,y,384,63,20,C.white);text(s,r[2],728,y,312,63,20,C.white);text(s,r[3],1058,y,157,63,20,C.white);shape(s,60,y+88,1160,1,C.line)});
text(s,'同一套 Runtime 硬件，UART Loader 更换机器码，CPU 执行相应程序。',60,613,1159,52,24,C.orange,true,'center');
note(s,'约 45 秒。总结共同流程：外部输入，CPU执行程序，RAM更新，LED/UART输出。剩余时间用于回到现场画面或老师提问。',['deliverables/上板展示_详细讲稿_v1.md','runtime_system/README.md']);
}
for(let i=0;i<p.slides.items.length;i++)await write(path.join(preview,`slide_${String(i+1).padStart(2,'0')}.png`),await p.export({slide:p.slides.items[i],format:'png',scale:1}));
await write(path.join(build,'montage.webp'),await p.export({format:'webp',montage:true}));
await (await PresentationFile.exportPptx(p)).save(path.join(build,'上板展示_紧凑版_draft.pptx'));
console.log(JSON.stringify({slides:p.slides.items.length,build}));

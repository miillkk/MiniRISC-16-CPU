import fs from 'node:fs/promises';
import path from 'node:path';
import { Presentation, PresentationFile } from 'file:///C:/Program%20Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1105-1297-0_26.1105.1297.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';

const root='C:/Users/xieke/Desktop/CPU';
const build=path.join(root,'.codex-ppt-build/runtime-arcade-talk-20261110');
const preview=path.join(build,'preview');
const imageRoot='C:/Users/xieke/Desktop/新建文件夹 (2)';
const draft=path.join(build,'上板展示_10分钟讲解_draft.pptx');
const C={bg:'#0B1424',panel:'#12233A',panel2:'#162A43',white:'#F5F8FC',muted:'#A9BBCD',teal:'#43D9CE',orange:'#FFB65C',line:'#35516D',red:'#FF7777',green:'#66DE91'};
const FONT='Arial';
const pres=Presentation.create({slideSize:{width:1280,height:720}});
const allNotes=[];

async function bytes(p){const b=await fs.readFile(p);return b.buffer.slice(b.byteOffset,b.byteOffset+b.byteLength)}
async function writeBlob(p,b){await fs.writeFile(p,new Uint8Array(await b.arrayBuffer()))}
function rect(s,x,y,w,h,fill='none',stroke='none',sw=0,geo='rect'){return s.shapes.add({geometry:geo,position:{left:x,top:y,width:w,height:h},fill,line:{style:'solid',fill:stroke,width:sw}})}
function txt(s,v,x,y,w,h,size=22,color=C.white,bold=false,align='left') {const q=rect(s,x,y,w,h);q.text=v;q.text.style={fontFamily:FONT,fontSize:size,color,bold,alignment:align,verticalAlignment:'middle'};return q}
function base(title,n){const s=pres.slides.add();s.background.fill=C.bg;rect(s,0,0,13,720,C.teal);txt(s,title,58,32,1140,55,34,C.white,true);rect(s,58,105,1162,2,C.line);txt(s,String(n).padStart(2,'0'),1165,36,50,30,15,C.teal,true,'right');return s}
function note(s,spoken,sources){s.speakerNotes.text=`讲解提示：\n${spoken}\n\n资料来源：\n${sources.map(x=>'• '+x).join('\n')}`}
function img(s,b,alt,x,y,w,h){rect(s,x-4,y-4,w+8,h+8,C.panel,C.line,1);s.images.add({blob:b,contentType:'image/png',alt,fit:'contain',position:{left:x,top:y,width:w,height:h}})}
function code(s,lines,x,y,w,h,size=20){rect(s,x,y,w,h,C.panel,C.line,1);txt(s,lines,x+20,y+14,w-40,h-28,size,C.white,false)}
function band(s,label,body,x,y,w,accent=C.teal){txt(s,label,x,y,w,32,19,accent,true);txt(s,body,x,y+38,w,95,22,C.white)}

await fs.mkdir(preview,{recursive:true});
const [menu,g2048,g2048end,snake1,snake2,snakeEnd]=await Promise.all(['选择菜单界面.png','2048.png','2048结束.png','贪吃蛇1.png','贪吃蛇2.png','贪吃蛇游戏结束.png'].map(n=>bytes(path.join(imageRoot,n))));

// 1: outcome and PC-side launcher
{
 const s=base('上板运行：同一套硬件，三个程序',1);
 img(s,menu,'电脑端统一选择菜单',60,145,720,355);
 txt(s,'电脑端菜单选择程序',825,151,375,44,26,C.teal,true);
 txt(s,'UART 上传对应机器码\nCPU 运行所选程序\n终端显示板上返回的状态',825,207,367,180,24,C.white);
 rect(s,825,429,363,2,C.line);
 txt(s,'流水灯   2048   贪吃蛇',825,462,370,43,25,C.orange,true);
 txt(s,'一次只运行一个程序\n切换时无需重新生成 bitstream',60,548,1120,80,23,C.white,true);
 note(s,'承接前一位同学的 CPU 设计。说明统一菜单在电脑端，三个应用共用 FPGA 中的 CPU、RAM 和外设。不要说三个程序同时运行。建议 45 秒。',['用户提供：选择菜单界面.png','runtime_system/README.md']);
}
// 2: UART one-slide, two modes plus code
{
 const s=base('UART：上传程序与运行时交互',2);
 txt(s,'SW7 = 1  加载模式',63,145,500,35,26,C.orange,true);
 txt(s,'电脑发送 16 位机器码\nLoader 写入程序 RAM\nCPU 保持复位',63,191,480,137,23);
 txt(s,'SW7 = 0  运行模式',668,145,500,35,26,C.teal,true);
 txt(s,'CPU 从 0x000 取指\n电脑发送按键\nCPU 返回状态帧',668,191,480,137,23);
 rect(s,620,150,2,182,C.line);
 code(s,"wire cpu_rst = rst | load_mode;\nassign uart_tx = load_mode\n    ? loader_uart_tx : cpu_uart_tx;",62,364,565,128,21);
 code(s,"0x10  UART 数据：读按键 / 写字节\n0x11  UART 状态：rx_valid / tx_ready\n\nINP R0, 0x11   → 检查接收状态\nOUP 0x10, R0   → 发送状态字节",655,364,565,178,20);
 txt(s,'板载 CP2103 完成 USB 转串口；FPGA 内部 UART 收发与 CPU 端口由 Verilog 实现',62,584,1156,58,20,C.muted);
 txt(s,'Loader：两个 8 位字节拼成一条 16 位指令，写入 1K×16 程序 RAM。',62,643,1156,37,19,C.white);
 note(s,'先讲 SW7=1 的 Loader：PC 菜单选镜像，Loader 两个 8 位字节拼成 16 位指令写入 1K×16 程序 RAM。再讲 SW7=0：CPU 读取 0x11 状态，读写 0x10 数据。电脑绘图，游戏规则由板上程序处理。这里总共约 1 分 20 秒。',['runtime_system/rtl/top/runtime_soc.v','runtime_system/rtl/peripherals/uart_port.v','runtime_system/rtl/peripherals/io_decoder.v','runtime_system/rtl/peripherals/program_loader.v']);
}
// 3: running light effect with editable LED diagram and photo slot
{
 const s=base('流水灯：板载 LED 的运行现象',3);
 txt(s,'现场演示：移动、反向、变速、暂停',62,143,800,40,25,C.teal,true);
 rect(s,60,207,1160,204,C.panel,C.line,1);
 for(let i=0;i<8;i++){const x=119+i*143;rect(s,x,254,55,55,i===3?C.orange:C.panel2,i===3?C.orange:C.line,2,'ellipse');txt(s,`LED${i}`,x-12,328,80,30,17,C.muted,false,'center')}
 txt(s,'示意：当前点亮 LED3，下一次节拍由 CPU 更新位置',75,369,1120,29,18,C.muted,false,'center');
 rect(s,60,449,730,172,C.panel,C.line,1);
 txt(s,'现场操作顺序',86,470,660,37,25,C.white,true);
 txt(s,'观察循环移动 → 按 A/D 反向\n改变 SW1..0 调速 → 用 SW2 暂停\nLED7 到 LED0 自动回绕',86,518,660,86,20,C.muted);
 txt(s,'LED0–7 循环移动\n状态保存在 RAM\n终端显示位置与方向',830,462,370,134,22,C.white);
 note(s,'先现场演示。LED 示意图是可编辑的板上八灯状态图，便于指向当前点亮位置。现有图片文件夹没有流水灯实拍，本页无需依赖静态照片。本页讲述及操作约 50 秒。',['runtime_system/games/running_light/README.md','runtime_system/games/running_light/program/running_light.asm']);
}
// 4: running light implementation
{
 const s=base('流水灯：位置运算怎样变成灯光',4);
 txt(s,'RAM 0x20 保存位置，0x21 保存方向',61,143,1110,36,23,C.teal,true);
 code(s,"LDR  R0, R3     ; 读当前位置\nCMP  R0, R1     ; 是否到 LED7\nJZ   RIGHT_WRAP\nADDI R0, 0x01   ; 向右移一格\nSTR  R3, R0     ; 写回位置",60,201,559,235,22);
 code(s,"MOVI R1, 0x01  ; 0000 0001\nADDR R1, R1    ; 每次加倍\n...\nOUP  0x30, R1  ; 写 LED 端口",660,201,560,235,22);
 txt(s,'CPU 读定时器 0x12',62,480,335,31,21,C.orange,true);
 txt(s,'更新位置',448,480,250,31,21,C.orange,true);
 txt(s,'生成 8 位图案',744,480,350,31,21,C.orange,true);
 txt(s,'位置 7 继续向右时回到 0；位置 0 向左时回到 7。',62,528,1140,37,20,C.muted);
 txt(s,'LED RTL 只保存 CPU 写入的 8 位数据：write_enable 时 led <= write_data',62,573,1140,62,21,C.white);
 txt(s,'图案从 0000 0001 开始，寄存器每次自加相当于左移一位。',62,646,1140,34,19,C.muted);
 note(s,'逐段讲：读 RAM 位置；到边界跳转；加一写回；从 1 反复自加相当于左移；OUP 0x30 经译码写入 led8 寄存器。片段省略了标签和循环条件，PPT仅展示关键指令。约 1 分钟。',['runtime_system/games/running_light/program/running_light.asm','runtime_system/rtl/peripherals/led8.v','runtime_system/rtl/peripherals/tick_timer.v']);
}
// 5: 2048 effect
{
 const s=base('2048：棋盘更新与游戏结束',5);
 img(s,g2048,'2048运行画面，分数84',60,154,550,469);
 img(s,g2048end,'2048结束画面，分数1264',668,154,550,469);
 txt(s,'正常运行：移动、合并、计分',60,632,555,35,21,C.teal,true,'center');
 txt(s,'满盘且无可合并方块：结束',665,632,555,35,21,C.red,true,'center');
 note(s,'左图说明 4×4 棋盘和分数。右图说明 GAME OVER；先检查空格，再检查横向、纵向是否有相同相邻块。注意两张图是不同时间状态，不要声称它们构成完整连续操作录像。约 45 秒。',['用户提供：2048.png','用户提供：2048结束.png','runtime_system/games/2048/README.md']);
}
// 6: 2048 algorithm
{
 const s=base('2048：CPU 完成压缩、合并与计分',6);
 txt(s,'RAM 0x40–0x4F：16 个格子；0x50–0x53：单行临时缓冲',60,145,1160,40,23,C.teal,true);
 rect(s,60,207,1160,90,C.panel,C.line,1);
 txt(s,'输入',82,224,100,28,17,C.muted,true);txt(s,'2   空   2   4',183,219,394,38,28,C.white,true);
 txt(s,'左移后',666,224,125,28,17,C.muted,true);txt(s,'4   4   空   空',798,219,375,38,28,C.orange,true);
 code(s,"LDR  R1, R3\nADDI R1, 0x01\nSTR  R3, R1",60,343,440,159,23);
 txt(s,'相同指数合并后加 1\n例如 2+2：指数 1 变为 2',539,340,631,90,23,C.white);
 txt(s,'四条逻辑行共用一套处理代码；每个方块一次移动最多合并一次。',60,534,1160,41,21,C.white);
 txt(s,'只有棋盘发生变化，CPU 才从 LFSR 端口 0x13 取随机数并生成新方块。',60,590,1160,52,21,C.muted);
 txt(s,'计分由 CPU 重复加倍算出合并方块数值，再累加到 16 位分数。',60,645,1160,34,19,C.white);
 note(s,'约 1 分 20 秒。讲指数存储：0空，1=2，2=4。四方向改变的是逻辑行读取顺序。程序跳过零值，和临时行最后一块比较，合并过的标志避免 2+2+2+2 一步合为 8。CPU写回新棋盘，与旧值比较决定是否生成新方块。计分用重复自加求 2 的幂。',['runtime_system/games/2048/program/game_2048.asm','runtime_system/rtl/peripherals/lfsr8.v']);
}
// 7: snake images
{
 const s=base('贪吃蛇：移动、成长与结束',7);
 img(s,snake1,'贪吃蛇初始状态',58,152,543,230);
 img(s,snake2,'贪吃蛇得分与加速状态',674,152,543,230);
 img(s,snakeEnd,'贪吃蛇游戏结束状态',351,423,575,232);
 txt(s,'起始状态',60,385,540,32,20,C.teal,true,'center');
 txt(s,'得分 6，等级 3，节拍 0.125 s',674,385,543,32,20,C.orange,true,'center');
 note(s,'三图用于展示不同状态：初始、成长加速、GAME OVER。游戏结束图是另一局，不能当作右上图的连续下一帧。现场可演示方向键与碰撞。约 55 秒。',['用户提供：贪吃蛇1.png','用户提供：贪吃蛇2.png','用户提供：贪吃蛇游戏结束.png']);
}
// 8: snake implementation
{
 const s=base('贪吃蛇：坐标计算与蛇身更新',8);
 txt(s,'位置 = 行 × 16 + 列',60,149,523,40,27,C.teal,true);
 txt(s,'上 −0x10   下 +0x10   左 −1   右 +1',60,202,1160,38,23,C.white);
 code(s,"AND  R3, R2    ; 取列号 0x0F\nCMP  R3, R2    ; 是否最右列\nJZ   GAME_OVER\nADDI R0, 0x01  ; 向右一格",60,274,552,190,21);
 code(s,"LDR  R0, R3    ; 读地图格\nCMP  R0, R1    ; 判断墙 / 空格\nJZ   DECAY_NEXT  ; 需要时跳过\n...\nSUB  R0, R1    ; 蛇身寿命减一\nSTR  R3, R0    ; 写回地图",661,274,557,190,20);
 txt(s,'RAM 0x04–0x83 保存 128 格：0 = 空，0xFF = 墙，其他非零值 = 蛇身寿命',60,514,1160,70,22,C.white);
 txt(s,'CPU 遍历地图、判断碰撞和食物，再把 140 字节状态帧经 UART 发给终端。',60,605,1160,44,21,C.muted);
 txt(s,'食物由随机数端口选空格；16 次未命中后顺序扫描，避免无限重试。',60,655,1160,34,19,C.white);
 note(s,'约 1 分 20 秒。解释 16 列使得上下移动为加减 0x10；AND 0x0F 检查左右边界。每次步进遍历 128 格，蛇身寿命减 1，尾部归零，新的头格写当前长度。新头读目标格判断墙/蛇身，再比较食物位置。食物从 LFSR 取随机数，16 次失败后顺序扫描。代码只截关键行，讲述中说明实际循环还有跳转与地址增量。',['runtime_system/program/snake.asm']);
}
// 9: conclusion
{
 const s=base('三个项目的共同运行机制',9);
 const rows=[['流水灯','位置、方向','定时更新和位图计算','LED + UART'],['2048','16 个棋盘格','压缩、合并、计分','UART 画面'],['贪吃蛇','128 格地图','坐标、碰撞、蛇身更新','UART 画面']];
 txt(s,'项目',73,163,218,40,20,C.teal,true);txt(s,'RAM 中的状态',308,163,246,40,20,C.teal,true);txt(s,'CPU 程序处理',583,163,354,40,20,C.teal,true);txt(s,'输出',989,163,180,40,20,C.teal,true);
 rect(s,60,208,1160,2,C.line);
 rows.forEach((r,i)=>{let y=228+i*113;txt(s,r[0],74,y,210,48,25,C.white,true);txt(s,r[1],310,y,238,48,21,C.white);txt(s,r[2],580,y,380,50,21,C.white);txt(s,r[3],988,y,220,48,21,C.white);rect(s,60,y+79,1160,1,C.line)});
 txt(s,'同一套 Runtime 硬件，UART Loader 更换程序镜像，CPU 执行对应规则。',60,600,1160,66,24,C.orange,true,'center');
 note(s,'用 30–40 秒收束。三项目共同流程是输入、CPU读端口、RAM更新、外设输出。不要展开 CPU 内部设计，也暂不单列运行证据。',['deliverables/上板展示_详细讲稿_v1.md','runtime_system/README.md']);
}

for(let i=0;i<pres.slides.items.length;i++){const b=await pres.export({slide:pres.slides.items[i],format:'png',scale:1});await writeBlob(path.join(preview,`slide_${String(i+1).padStart(2,'0')}.png`),b)}
await writeBlob(path.join(build,'montage.webp'),await pres.export({format:'webp',montage:true}));
await (await PresentationFile.exportPptx(pres)).save(draft);
console.log(JSON.stringify({draft,slides:pres.slides.items.length,preview}));

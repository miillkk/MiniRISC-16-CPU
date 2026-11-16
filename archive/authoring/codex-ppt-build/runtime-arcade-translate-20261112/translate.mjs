import fs from 'node:fs/promises';
import path from 'node:path';
import {FileBlob,PresentationFile} from 'file:///C:/Program%20Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1111-570-0_26.1111.570.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';

const source='C:/Users/xieke/Desktop/CPU/deliverables/上板展示_三项目_9页图文版_v6.pptx';
const build='C:/Users/xieke/Desktop/CPU/.codex-ppt-build/runtime-arcade-translate-20261112';
const draft=path.join(build,'On_Board_Demo_English_draft.pptx');
const preview=path.join(build,'preview');
await fs.mkdir(preview,{recursive:true});
const p=await PresentationFile.importPptx(await FileBlob.load(source));

const replacements={
 'sh/547294r6':'On-board Operation: One Platform, Three Programs',
 'sh/sryl4zqx':'Select a Program in the PC Terminal',
 'sh/fu94fe98':'UART uploads the machine code\nThe CPU runs the selected program\nThe terminal displays board-generated state',
 'sh/wn6dc7eh':'Running Lights   2048   Snake',
 'sh/hofulsf2':'Only one program runs at a time\nNo new bitstream is needed to switch programs',
 'sh/9072xkry':'UART: Program Upload and Runtime I/O',
 'sh/a10jqpsj':'SW7 = 1  Upload Mode',
 'sh/x4r21kru':'PC sends 16-bit machine code\nLoader writes program RAM\nCPU stays in reset',
 'sh/w3i1sfa9':'SW7 = 0  Run Mode',
 'sh/r65knqtk':'CPU fetches from address 0x000\nPC sends control keys\nCPU returns state frames',
 'sh/nu58f2hs':'0x10  UART data: read key / write byte\n0x11  UART status: rx_valid / tx_ready\n\nINP R0, 0x11   checks receive status\nOUP 0x10, R0   sends a state byte',
 'sh/wjy9sry9':'The board’s CP2103 bridges USB and UART. Verilog implements the UART controller and CPU port interface.',
 'sh/xk7qlczu':'The loader combines two 8-bit bytes into one 16-bit instruction and writes the 1K×16 program RAM.',
 'sh/cza94vmx':'2048: Board Updates and Game Over',
 'sh/298ryl4v':'03',
 'sh/n6ls3alk':'Running: move, merge, and score',
 'sh/n2l4fq98':'Full board with no valid merge: game over',
 'sh/1cj2d8b6':'2048: Compression, Merging, and Scoring',
 'sh/rm1k7yt4':'04',
 'sh/ql8jytsj':'RAM 0x40–0x4F: 16 cells; 0x50–0x53: one-line buffer',
 'sh/sna103ap':'Input',
 'sh/3ihk3et8':'2   empty   2   4',
 'sh/ih8ju9sn':'Move left',
 'sh/kbm987y5':'4   4   empty   empty',
 'sh/jadsz2xk':'Equal exponents merge by adding 1\n2 + 2: exponent 1 becomes 2',
 'sh/w72947yt':'All four logical lines use one routine; a tile merges at most once per move.',
 'sh/x8vaxsfe':'Only a changed board triggers a new tile using random data from LFSR port 0x13.',
 'sh/a5kr2xg3':'The CPU computes the merged tile value by repeated doubling and updates the 16-bit score.',
 'sh/dgbulwnm':'Snake: Movement, Growth, and Game Over',
 'sh/z2tcnm5s':'05',
 'sh/x4vedgvm':'Initial state',
 'sh/ahkvi1cb':'Score 6, level 3, 0.125 s per step',
 'sh/yhg7epsj':'Snake: Coordinates and Body Updates',
 'sh/87ipkzal':'06',
 'sh/98rqt4r6':'Position = row × 16 + column',
 'sh/ml07i9sv':'Up −0x10   Down +0x10   Left −1   Right +1',
 'sh/oryp8fah':'AND  R3, R2    ; isolate column (0x0F)\nCMP  R3, R2    ; rightmost column?\nJZ   GAME_OVER\nADDI R0, 0x01  ; one cell right',
 'sh/h4bupgn6':'LDR  R0, R3    ; read map cell\nCMP  R0, R1    ; wall or empty?\nJZ   DECAY_NEXT ; skip if needed\n...\nSUB  R0, R1    ; decrease body lifetime\nSTR  R3, R0    ; write map cell',
 'sh/w32twb6l':'RAM 0x04–0x83 holds 128 cells: 0 = empty, 0xFF = wall, other values = body lifetime',
 'sh/v2tcn650':'The CPU scans the map, checks collisions and food, then sends a 140-byte state frame over UART.',
 'sh/u1kbu1ov':'Food uses a random empty cell; after 16 misses, a linear scan prevents endless retries.',
};

const original=await p.inspect({select:'$.slides[*].elements[*]',include:['id','text']});
let replaced=0;
for(const e of original.records){
 if(typeof e.text!=='string' || !e.text.trim())continue;
 const translated=replacements[e.id];
 if(translated===undefined){
   if(/[\u3400-\u9fff]/u.test(e.text))throw new Error(`Untranslated text ${e.id}: ${e.text}`);
   continue;
 }
 const target=p.resolve(e.id);
 target.text.replace(e.text,translated);
 replaced++;
}
const noteText=[
 'Transition from the CPU design section. The launcher runs on the PC. All three applications use the same FPGA CPU, RAM, and peripherals. Only one program runs at a time. About 45 seconds.\n\nSources: user-provided menu screenshot; runtime_system/README.md.',
 'First explain SW7=1: the PC selects a program, and the loader combines two 8-bit bytes into each 16-bit instruction in the 1K×16 program RAM. With SW7=0, the CPU reads UART status at 0x11 and transfers data through 0x10. The PC draws the display; the CPU computes game rules. About 80 seconds.\n\nSources: runtime_soc.v; uart_port.v; io_decoder.v; program_loader.v.',
 'The left screenshot shows the 4×4 board and score. The right shows GAME OVER. The CPU first checks for empty cells, then for horizontally or vertically adjacent equal tiles. The images show different moments, not a continuous recorded sequence. About 45 seconds.\n\nSources: user-provided 2048 screenshots; games/2048/README.md.',
 'Tiles are exponents: 0=empty, 1=2, 2=4. The direction changes the order in which four logical lines are read. The program skips zero cells, compares the current tile with the last output tile, and uses a merged flag to prevent a second merge. It writes back the board and spawns a tile only if the board changed. Repeated doubling computes the score increment. About 80 seconds.\n\nSources: game_2048.asm; lfsr8.v.',
 'The three screenshots illustrate initial play, faster movement after scoring, and GAME OVER. The game-over image comes from another round and is not the next frame after the upper-right image. About 55 seconds.\n\nSources: user-provided Snake screenshots.',
 'With 16 columns, vertical moves add or subtract 0x10; AND 0x0F extracts the column for horizontal boundary checks. Each step scans 128 map cells, decreases body lifetimes, clears the tail, and writes the new head. The CPU checks collision and food. After 16 unsuccessful random food positions, it scans the board linearly. The code shown is an excerpt. About 80 seconds.\n\nSources: program/snake.asm.',
];
for(let i=0;i<p.slides.items.length;i++)p.slides.items[i].speakerNotes.text=noteText[i];
for(let i=0;i<p.slides.items.length;i++){
 const b=await p.export({slide:p.slides.items[i],format:'png',scale:1});
 await fs.writeFile(path.join(preview,`slide_${i+1}.png`),new Uint8Array(await b.arrayBuffer()));
}
const montage=await p.export({format:'webp',montage:true});
await fs.writeFile(path.join(build,'montage.webp'),new Uint8Array(await montage.arrayBuffer()));
await (await PresentationFile.exportPptx(p)).save(draft);
console.log(JSON.stringify({draft,slides:p.slides.items.length,replaced}));

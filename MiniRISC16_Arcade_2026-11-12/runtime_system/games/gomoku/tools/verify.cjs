const fs=require('fs'),path=require('path'),assert=require('assert');
const rom=fs.readFileSync(path.join(__dirname,'../program/gomoku.mem'),'utf8').split(/\r?\n/).filter(x=>/^[0-9a-f]{4}$/i.test(x)).map(x=>parseInt(x,16));
let r,m,pc,z,rx,tx,cycles=0;
function reset(){r=[0,0,0,0];m=Array(256).fill(0);pc=0;z=false;rx=[];tx=[]}
function frame(cmd){if(cmd!==undefined)rx.push(cmd);tx=[];for(let k=0;k<30000000;k++){
let w=rom[pc],op=w>>>12,d=w>>10&3,s=w>>8&3,a=w&255,old=pc;pc=(pc+1)&1023;cycles++;
switch(op){case 0:r[d]=a;break;case 1:r[d]=r[s];break;case 2:r[d]+=a;break;case 3:r[d]+=r[s];break;case 4:r[d]^=r[s];break;case 5:r[d]-=r[s];break;case 6:z=r[d]===r[s];break;case 7:r[d]&=r[s];break;case 8:if(z)pc=(old&768)|a;break;case 10:pc=(old&768)|a;break;case 11:r[d]=a===17?2+(rx.length?1:0):(rx.shift()||0);break;case 12:if(a===16)tx.push(r[s]&255);break;case 13:r[d]=m[r[s]&255];break;case 14:m[r[d]&255]=r[s];break;case 15:pc=w&1023;break;default:throw Error('opcode '+op)}r=r.map(x=>x&65535);
if(tx.length===231){assert.equal(tx.reduce((a,b)=>a^b,0),0);return tx.slice()}}
throw Error('timeout '+pc)}
function fresh(mode=240){reset();frame();return frame(mode)}
fresh();let f=frame(112);assert.equal(f[117],1);assert.equal(f[2],2);assert.deepEqual(frame(112),f);assert.deepEqual(frame(239),f);
for(const [start,delta] of [[30,1],[2,15],[0,16],[14,14]]){fresh();for(let i=0;i<4;i++){frame(start+i*delta);frame(210+i*2)}f=frame(start+4*delta);assert.equal(f[3],1);assert.deepEqual(frame(100),f)}
fresh();for(const i of [13,14,15,16])m[i]=1;m[228]=4;f=frame(17);assert.equal(f[3],0,'row wrapping must not win');
fresh(241);let before=cycles;f=frame(112);assert.equal(f[4],2);assert.equal(f[2],1);assert.equal(f.slice(5,230).filter(x=>x===2).length,1);console.log('AI opening cycles:',cycles-before);
// Seed legal tactical positions at command boundary, then submit human move.
fresh(241);for(let i=0;i<4;i++){m[i]=2;m[30+i*2]=1}m[228]=8;f=frame(100);assert.equal(f[9],2);assert.equal(f[3],2,'AI must win now');
fresh(241);for(let i=0;i<4;i++)m[i]=1;m[40]=2;m[60]=2;m[80]=2;m[228]=7;f=frame(100);assert.equal(f[9],2,'AI must block four');assert.equal(f[3],0);
// Full board pattern without any five, leaving one final empty cell.
fresh();for(let y=0;y<15;y++)for(let x=0;x<15;x++)m[y*15+x]=1+((x+2*y)%4<2?0:1);m[224]=0;m[228]=224;m[226]=1;f=frame(224);assert.equal(f[3],3);
console.log('PASS: four win directions, no wrap, occupied/reserved rejection, terminal lock, draw, AI legal/win/block, checksums.');

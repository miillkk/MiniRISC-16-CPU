const fs=require('fs'),path=require('path'),assert=require('assert');
const base=path.join(__dirname,'../program');
const rom=fs.readFileSync(path.join(base,'chess.mem'),'utf8').split(/\r?\n/).filter(x=>/^[0-9a-f]{4}$/i.test(x)).map(x=>parseInt(x,16));
const vars=JSON.parse(fs.readFileSync(path.join(base,'symbols.json'))).variables;
let labels={},addr=0;for(const line of fs.readFileSync(path.join(base,'chess.asm'),'utf8').split(/\r?\n/)){let s=line.trim();if(!s||s.startsWith(';'))continue;if(s.endsWith(':'))labels[s.slice(0,-1)]=addr;else addr++}
class CPU{
 constructor(){this.r=[0,0,0,0];this.m=Array(256).fill(0);this.pc=0;this.z=false;this.rx=[];this.tx=[];this.cycles=0}
 step(){let {r,m}=this,w=rom[this.pc],op=w>>>12,d=w>>10&3,s=w>>8&3,a=w&255,old=this.pc;this.pc=(old+1)&4095;this.cycles++;
 switch(op){case 0:r[d]=a;break;case 1:r[d]=r[s];break;case 2:r[d]+=a;break;case 3:r[d]+=r[s];break;case 4:r[d]^=r[s];break;case 5:r[d]-=r[s];break;case 6:this.z=r[d]===r[s];break;case 7:r[d]&=r[s];break;case 8:if(this.z)this.pc=(old&3840)|a;break;case 9:r[d]|=r[s];break;case 10:this.pc=(old&3840)|a;break;case 11:r[d]=a===17?2+(this.rx.length?1:0):(this.rx.shift()||0);break;case 12:if(a===16)this.tx.push(r[s]&255);break;case 13:r[d]=m[r[s]&255];break;case 14:m[r[d]&255]=r[s];break;case 15:this.pc=w&4095;break;default:throw Error('opcode '+op)}for(let i=0;i<4;i++)r[i]&=65535;
 }
 frame(bytes=[]){this.rx.push(...bytes);this.tx=[];for(let i=0;i<10000000;i++){this.step();if(this.tx.length===70){assert.equal(this.tx[0],165);assert.equal(this.tx[1],7);assert.equal(this.tx.reduce((a,b)=>a^b,0),0);return this.tx.slice()}}throw Error('timeout PC '+this.pc)}
 legal(from,to){this.m[vars.from]=from;this.m[vars.to]=to;this.pc=labels.LEGAL;for(let i=0;i<100000;i++){this.step();if(this.pc===labels.end_LEGAL)return this.m[vars.ok]}throw Error('legal timeout')}
}
const sq=s=>(+s[1]-1)*16+s.charCodeAt(0)-97;
const move=(c,a,b,p=0)=>c.frame([242,sq(a),sq(b),p]);
function fresh(){let c=new CPU;c.frame();return c}
function fixture(pieces,side=0){let c=fresh();c.m.fill(0,0,128);for(const [s,p]of Object.entries(pieces))c.m[sq(s)]=p;c.m[vars.side]=side;c.m[vars.ep]=255;for(let i=0;i<4;i++)c.m[vars['right'+i]]=0;return c}
function legalMoves(c){let found=[];for(let a=0;a<128;a++){if(a&136)continue;for(let b=0;b<128;b++){if(b&136)continue;if(c.legal(a,b))found.push([a,b])}}return found}
if(require.main===module){
let c=fresh(),initial=c.m.slice();let moves=legalMoves(c);assert.equal(moves.length,20,'initial legal moves');assert.deepEqual(c.m.slice(0,128),initial.slice(0,128),'trial restores board');
let total=0;for(const [a,b]of moves){let d=fresh();d.frame([242,a,b,0]);total+=legalMoves(d).length}assert.equal(total,400,'perft depth 2');console.log('Initial legal-move counts: 20 / 400 PASS');
c=fresh();c.m.fill(0,0,128);
'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R'.split('/').forEach((rank,y)=>{let x=0;for(const p of rank){if(/[1-8]/.test(p))x+=+p;else c.m[(7-y)*16+x++]=' pnbrqk'.indexOf(p.toLowerCase())+(p===p.toLowerCase()?8:0)}});
assert.equal(legalMoves(c).length,48,'Kiwipete legal-move count');
c=fresh();assert.equal(move(c,'e2','e5')[4],1);assert.equal(move(c,'e2','e4')[4],0);assert.equal(c.m[vars.ep],sq('e3'));assert.equal(move(c,'e7','e5')[4],0);assert.equal(move(c,'g1','f3')[4],0);
c=fresh();move(c,'f2','f3');move(c,'e7','e5');move(c,'g2','g4');assert.equal(move(c,'d8','h4')[3],3,'Fools mate');let board=c.m.slice(0,128);move(c,'e2','e4');assert.deepEqual(c.m.slice(0,128),board);
c=fixture({e1:6,a1:4,h1:4,e8:14});c.m[vars.right0]=c.m[vars.right1]=1;assert.equal(move(c,'e1','g1')[4],0);assert.equal(c.m[sq('f1')],4);assert.equal(c.m[sq('h1')],0);
c=fixture({e1:6,a1:4,h1:4,e8:14,f8:12});c.m[vars.right0]=1;assert.equal(move(c,'e1','g1')[4],1,'cannot castle through check');
c=fixture({e1:6,a1:4,e8:14});c.m[vars.right1]=1;assert.equal(move(c,'e1','c1')[4],0);assert.equal(c.m[sq('d1')],4);
c=fixture({e1:6,e8:14,e5:1,d7:9},8);move(c,'d7','d5');assert.equal(move(c,'e5','d6')[4],0);assert.equal(c.m[sq('d5')],0);assert.equal(c.m[sq('d6')],1);
c=fixture({h5:6,e8:14,g5:1,f7:9,a5:12},8);move(c,'f7','f5');assert.equal(move(c,'g5','f6')[4],1,'EP cannot expose own king');
for(let p=2;p<=5;p++){c=fixture({e1:6,h8:14,a7:1});assert.equal(move(c,'a7','a8',p)[4],0);assert.equal(c.m[sq('a8')],p)}
c=fixture({a1:6,e8:14,h2:9},8);move(c,'h2','h1',2);assert.equal(c.m[sq('h1')],10);
c=fixture({e1:6,e2:4,e8:12,a8:14});assert.equal(move(c,'e2','f2')[4],1,'pinned rook');
c=fixture({f7:6,g5:5,h8:14});assert.equal(move(c,'g5','g6')[3],4,'stalemate');
console.log('PASS: illegal moves, turn, mate/lock, castling/path check, EP/self-check, all promotions, pin, stalemate, frame XOR.');
}
module.exports={CPU,sq,move,fresh,fixture,legalMoves,vars,labels,rom};


// Chess rules compiled to the existing MiniRISC instruction set, with 12-bit PC.
const fs=require('fs'),path=require('path');
const out=path.join(__dirname,'../program');
let code=[],pc=0,id=0,next=128,vars={},returns={},active;
const V=n=>vars[n]??(vars[n]=next++);
function e(s){code.push('    '+s);pc++}function lab(s){code.push(s+':')}function j(s){e('JMPA '+s)}
function bz(s){if((pc&255)>252)while(pc&255)e('MOVR R0, R0');let l='b'+id++;e('JZ '+l);j(l+'e');lab(l);j(s);lab(l+'e')}
function l(x,r=0){if(typeof x==='number'){if(x<0){e(`MOVI R${r}, 0`);e(`MOVI R${r===0?1:2}, ${-x}`);e(`SUB R${r}, R${r===0?1:2}`)}else e(`MOVI R${r}, ${x}`)}else{e('MOVI R3, '+V(x));e(`LDR R${r}, R3`)}}
function s(x,r=0){e('MOVI R3, '+V(x));e(`STR R3, R${r}`)}
function set(x,y){l(y);s(x)}
function op(x,a,oper,b){l(a);l(b,1);e(oper+' R0, R1');s(x)}
function eq(a,b,t){l(a);l(b,1);e('CMP R0, R1');bz(t)}
function nz(a,t){let n='nz'+id++;eq(a,0,n);j(t);lab(n)}
function read(x,a){l(a);e('LDR R0, R0');s(x)}
function write(a,x){l(a);l(x,1);e('STR R0, R1')}
function call(n){let a=(returns[n]??=[]),label='ret'+id++;a.push(label);set('ret_'+n,a.length);j(n);lab(label)}
function fn(n){active=n;lab(n)}function ret(){j('end_'+active)}
function result(v){set('ok',v);ret()}
function invalidSquare(x,t){op('mask',x,'AND',136);nz('mask',t)}
// Piece encoding: type 1 pawn,2 knight,3 bishop,4 rook,5 queen,6 king;
// black adds 8. White starts ranks 1/2 (indices 0..23), moves +16.
for(let i=0;i<4;i++)V('right'+i);
set('mode',0);j('RESET');
fn('PSEUDO');set('ok',0);invalidSquare('pf','P_BAD');invalidSquare('pt','P_BAD');eq('pf','pt','P_BAD');read('piece','pf');eq('piece',0,'P_BAD');op('color','piece','AND',8);eq('color','pc','P_OWN');j('P_BAD');lab('P_OWN');read('dest','pt');op('type','piece','AND',7);op('delta','pt','SUB','pf');
eq('attack',1,'P_TYPE');eq('dest',0,'P_TYPE');op('dc','dest','AND',8);eq('dc','pc','P_BAD');op('dt','dest','AND',7);eq('dt',6,'P_BAD');
lab('P_TYPE');eq('type',1,'PAWN');eq('type',2,'KNIGHT');eq('type',6,'KING');
// Sliding pieces: test rays, rejecting 0x88 boundaries and blocking pieces.
set('dir',0);lab('RAY_DIR');eq('dir',8,'P_BAD');eq('type',5,'RAY_PICK');eq('type',3,'BISHOP_DIR');op('mask','dir','AND',4);nz('mask','P_BAD');j('RAY_PICK');lab('BISHOP_DIR');op('mask','dir','AND',4);nz('mask','RAY_PICK');set('dir',4);
lab('RAY_PICK');
const dirs=[1,-1,16,-16,15,-15,17,-17];
for(let i=0;i<8;i++)eq('dir',i,'DIR'+i);
for(let i=0;i<8;i++){lab('DIR'+i);set('step',dirs[i]);j('RAY_START')}
lab('RAY_START');set('walk','pf');lab('RAY');op('walk','walk','ADDR','step');invalidSquare('walk','RAY_NEXT');eq('walk','pt','P_GOOD');read('temp','walk');nz('temp','RAY_NEXT');j('RAY');lab('RAY_NEXT');op('dir','dir','ADDR',1);j('RAY_DIR');
lab('KNIGHT');for(const d of [14,-14,18,-18,31,-31,33,-33])eq('delta',d,'P_GOOD');j('P_BAD');
lab('KING');for(const d of dirs)eq('delta',d,'P_GOOD');j('P_BAD');
lab('PAWN');eq('pc',0,'PAWN_WHITE');set('forward',-16);set('startRank',96);j('PAWN_READY');lab('PAWN_WHITE');set('forward',16);set('startRank',16);lab('PAWN_READY');op('temp','forward','ADDR',1);eq('delta','temp','PAWN_CAPTURE');op('temp','forward','SUB',1);eq('delta','temp','PAWN_CAPTURE');eq('attack',1,'P_BAD');nz('dest','P_BAD');eq('delta','forward','P_GOOD');op('temp','forward','ADDR','forward');eq('delta','temp','PAWN_DOUBLE');j('P_BAD');lab('PAWN_DOUBLE');op('temp','pf','AND',112);eq('temp','startRank','PAWN_PATH');j('P_BAD');lab('PAWN_PATH');op('temp','pf','ADDR','forward');read('temp','temp');eq('temp',0,'P_GOOD');j('P_BAD');lab('PAWN_CAPTURE');eq('attack',1,'P_GOOD');nz('dest','P_GOOD');eq('pt','ep','PAWN_EP');j('P_BAD');lab('PAWN_EP');op('temp','pt','SUB','forward');read('temp','temp');op('enemyPawn','pc','XOR',8);op('enemyPawn','enemyPawn','ADDR',1);eq('temp','enemyPawn','P_GOOD');j('P_BAD');
lab('P_GOOD');result(1);lab('P_BAD');result(0);
fn('ATTACK');set('ai',0);set('attack',1);lab('A_LOOP');invalidSquare('ai','A_NEXT');read('temp','ai');eq('temp',0,'A_NEXT');op('temp','temp','AND',8);eq('temp','aside','A_TRY');j('A_NEXT');lab('A_TRY');set('pf','ai');set('pt','target');set('pc','aside');call('PSEUDO');eq('ok',1,'A_YES');lab('A_NEXT');op('ai','ai','ADDR',1);eq('ai',128,'A_NO');j('A_LOOP');lab('A_YES');result(1);lab('A_NO');result(0);
fn('CHECK');set('ki',0);op('king','side','ADDR',6);lab('K_FIND');invalidSquare('ki','K_NEXT');read('temp','ki');eq('temp','king','K_FOUND');lab('K_NEXT');op('ki','ki','ADDR',1);eq('ki',128,'K_MISSING');j('K_FIND');lab('K_FOUND');set('target','ki');op('aside','side','XOR',8);call('ATTACK');ret();lab('K_MISSING');result(1);
// LEGAL leaves move metadata available after restoring the trial board.
fn('LEGAL');set('ok',0);invalidSquare('from','L_BAD');invalidSquare('to','L_BAD');eq('from','to','L_BAD');read('lp','from');eq('lp',0,'L_BAD');op('lc','lp','AND',8);eq('lc','side','L_OWN');j('L_BAD');lab('L_OWN');read('captured','to');op('lt','lp','AND',7);set('epcap',255);set('rf',255);set('rt',255);set('newEp',255);
eq('lt',6,'L_KING');j('L_NORMAL');lab('L_KING');op('diff','to','SUB','from');eq('diff',2,'CASTLE');eq('diff',-2,'CASTLE');j('L_NORMAL');
lab('CASTLE');eq('side',0,'C_WHITE');set('home',116);set('rb',2);j('C_HOME');lab('C_WHITE');set('home',4);set('rb',0);lab('C_HOME');eq('from','home','C_RIGHTS');j('L_BAD');lab('C_RIGHTS');eq('diff',2,'C_SHORT');op('rb','rb','ADDR',1);op('rf','home','SUB',4);op('rt','home','SUB',1);op('extra','home','SUB',3);read('temp','extra');nz('temp','L_BAD');j('C_PATH');lab('C_SHORT');op('rf','home','ADDR',3);op('rt','home','ADDR',1);lab('C_PATH');op('rightsAddr','rb','ADDR',V('right0'));read('temp','rightsAddr');eq('temp',0,'L_BAD');read('temp','rf');op('rook','side','ADDR',4);eq('temp','rook','C_ROOK');j('L_BAD');lab('C_ROOK');read('temp','rt');nz('temp','L_BAD');nz('captured','L_BAD');call('CHECK');nz('ok','L_BAD');write('from',0);write('rt','lp');set('target','rt');op('aside','side','XOR',8);call('ATTACK');write('rt',0);write('from','lp');nz('ok','L_BAD');j('L_TRIAL');
lab('L_NORMAL');set('pf','from');set('pt','to');set('pc','side');set('attack',0);call('PSEUDO');eq('ok',0,'L_BAD');eq('lt',1,'L_PAWN');j('L_TRIAL');lab('L_PAWN');eq('side',0,'L_PWHITE');set('lfwd',-16);j('L_PREADY');lab('L_PWHITE');set('lfwd',16);lab('L_PREADY');eq('to','ep','L_EP');j('L_DOUBLE');lab('L_EP');nz('captured','L_DOUBLE');op('epcap','to','SUB','lfwd');lab('L_DOUBLE');op('diff','to','SUB','from');op('temp','lfwd','ADDR','lfwd');eq('diff','temp','L_NEWEP');j('L_TRIAL');lab('L_NEWEP');op('newEp','from','ADDR','lfwd');
lab('L_TRIAL');write('from',0);write('to','lp');eq('epcap',255,'L_ROOK');read('epold','epcap');write('epcap',0);lab('L_ROOK');eq('rf',255,'L_CHECK');read('rookold','rf');write('rf',0);write('rt','rookold');lab('L_CHECK');call('CHECK');set('unsafe','ok');write('from','lp');write('to','captured');eq('epcap',255,'L_UNROOK');write('epcap','epold');lab('L_UNROOK');eq('rf',255,'L_VERDICT');write('rf','rookold');write('rt',0);lab('L_VERDICT');eq('unsafe',1,'L_BAD');result(1);lab('L_BAD');result(0);
// Allocate consecutive castling rights before initializing.
for(let i=0;i<4;i++)V('right'+i);
lab('RESET');set('idx',0);lab('INIT_CLEAR');write('idx',0);op('idx','idx','ADDR',1);eq('idx',128,'INIT_PIECES');j('INIT_CLEAR');lab('INIT_PIECES');for(let i=0;i<8;i++){write(i,[4,2,3,5,6,3,2,4][i]);write(16+i,1);write(96+i,9);write(112+i,[12,10,11,13,14,11,10,12][i])}set('side',0);set('status',0);set('error',0);set('ep',255);for(let i=0;i<4;i++)set('right'+i,1);j('SEND');
fn('RX');lab('RX_WAIT');e('INP R0, 17');e('MOVI R1, 1');e('AND R0, R1');e('CMP R0, R1');bz('RX_READ');j('RX_WAIT');lab('RX_READ');e('INP R0, 16');s('byte');ret();
lab('MAIN');call('RX');eq('byte',240,'RESET');eq('byte',244,'MODE_AI');eq('byte',245,'MODE_PVP');eq('byte',242,'MOVE_RX');j('SEND');lab('MODE_AI');set('mode',64);j('RESET');lab('MODE_PVP');set('mode',0);j('RESET');lab('MOVE_RX');call('RX');set('from','byte');call('RX');set('to','byte');call('RX');set('promotion','byte');set('error',0);eq('status',0,'MOVE_TRY');eq('status',1,'MOVE_TRY');j('SEND');lab('MOVE_TRY');call('LEGAL');eq('ok',0,'REJECT');
// Promotion chosen by user; reject invalid choices before altering position.
set('promoted','lp');eq('lt',1,'PROMO_CHECK');j('COMMIT');lab('PROMO_CHECK');op('rank','to','AND',112);eq('rank',0,'PROMO');eq('rank',112,'PROMO');j('COMMIT');lab('PROMO');eq('promotion',0,'PROMO_DEFAULT');for(let i=2;i<=5;i++)eq('promotion',i,'PROMO_OK');j('REJECT');lab('PROMO_DEFAULT');set('promotion',5);lab('PROMO_OK');op('promoted','side','ADDR','promotion');
lab('COMMIT');write('from',0);write('to','promoted');eq('epcap',255,'COMMIT_ROOK');write('epcap',0);lab('COMMIT_ROOK');eq('rf',255,'COMMIT_RIGHTS');write('rf',0);write('rt','rookold');lab('COMMIT_RIGHTS');set('ep','newEp');
for(const [sq,rights] of [[4,[0,1]],[116,[2,3]],[7,[0]],[0,[1]],[119,[2]],[112,[3]]]){let t='clear'+sq,end=t+'end';eq('from',sq,t);eq('to',sq,t);j(end);lab(t);for(const i of rights)set('right'+i,0);lab(end)}
op('side','side','XOR',8);call('CHECK');set('inCheck','ok');set('status','ok');set('searchFrom',0);lab('SEARCH_FROM');invalidSquare('searchFrom','SEARCH_NEXT_FROM');read('temp','searchFrom');eq('temp',0,'SEARCH_NEXT_FROM');op('temp','temp','AND',8);eq('temp','side','SEARCH_START_TO');j('SEARCH_NEXT_FROM');lab('SEARCH_START_TO');set('searchTo',0);lab('SEARCH_TO');invalidSquare('searchTo','SEARCH_NEXT_TO');set('from','searchFrom');set('to','searchTo');call('LEGAL');eq('ok',1,'TURN_READY');lab('SEARCH_NEXT_TO');op('searchTo','searchTo','ADDR',1);eq('searchTo',128,'SEARCH_NEXT_FROM');j('SEARCH_TO');lab('SEARCH_NEXT_FROM');op('searchFrom','searchFrom','ADDR',1);eq('searchFrom',128,'NO_MOVES');j('SEARCH_FROM');lab('NO_MOVES');eq('inCheck',0,'STALEMATE');eq('side',0,'BLACK_WINS');set('status',2);j('SEND');lab('BLACK_WINS');set('status',3);j('SEND');lab('STALEMATE');set('status',4);j('SEND');lab('REJECT');set('error',1);j('SEND');
require('./ai.cjs')({lab,j,set,op,eq,nz,read,write,call,fn,ret,invalidSquare});
// A5, version 7, side 0/8, status 0/1(check)/2(white win)/3/4, error,
// board a1..h8 (64 bytes), XOR. 70 bytes total.
fn('TX');l('byte');l('sum',1);e('XOR R1, R0');s('sum',1);lab('TX_WAIT');e('INP R1, 17');e('MOVI R2, 2');e('AND R1, R2');e('CMP R1, R2');bz('TX_WRITE');j('TX_WAIT');lab('TX_WRITE');e('OUP 16, R0');ret();
lab('SEND');op('wireSide','side','OR','mode');set('sum',0);for(const value of [165,7,'wireSide','status','error']){set('byte',value);call('TX')}set('idx',0);lab('SEND_BOARD');invalidSquare('idx','SEND_NEXT');read('byte','idx');call('TX');lab('SEND_NEXT');op('idx','idx','ADDR',1);eq('idx',128,'SEND_SUM');j('SEND_BOARD');lab('SEND_SUM');set('byte','sum');call('TX');j('MAIN');
for(const [name,targets] of Object.entries(returns)){lab('end_'+name);for(let i=0;i<targets.length;i++)eq('ret_'+name,i+1,targets[i]);j('RESET')}
if(next>256)throw Error('RAM '+next);if(pc>4096)throw Error('ROM '+pc);
fs.writeFileSync(path.join(out,'chess.asm'),'; Generated CPU chess rules (4K runtime required).\n'+code.join('\n')+'\n');
fs.writeFileSync(path.join(out,'symbols.json'),JSON.stringify({words:pc,variables:vars},null,2));
console.log(`Chess: ${pc}/4096 instructions, RAM variables ${128}..${next-1}`);



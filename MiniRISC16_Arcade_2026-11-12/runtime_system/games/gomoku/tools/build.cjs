// Generate page-safe MiniRISC-16 assembly. All decisions run on the CPU.
const fs=require('fs'),path=require('path');
let lines=[],pc=0,seq=0;
function emit(s){lines.push('    '+s);pc++}
function label(s){lines.push(s+':')}
function jump(s){emit('JMPA '+s)}
function eq(s){if((pc&255)>252){while(pc&255)emit('MOVR R0, R0')}let l='branch_'+seq++;emit('JZ '+l);emit('JMPA '+l+'_end');label(l);jump(s);label(l+'_end')}
function set(a,v){emit('MOVI R0, '+v);store(a)}
function load(a,r='R0'){emit('MOVI R3, '+a);emit('LDR '+r+', R3')}
function store(a,r='R0'){emit('MOVI R3, '+a);emit('STR R3, '+r)}
function test(a,v,to){load(a);emit('MOVI R1, '+v);emit('CMP R0, R1');eq(to)}
// 0..224 board; 225 mode,226 player,227 status,228 count,229 candidate,
// 230 phase (0 actual,1 AI win,2 AI block),231 scan index,232 row,233 col,
// 234 scan color,235 direction,236 walk index,237 walk row,238 walk col,239 run.
set(225,0);jump('RESET');
label('RESET');emit('MOVI R0, 0');emit('MOVI R1, 0');label('CLEAR');emit('STR R0, R1');emit('ADDI R0, 1');emit('MOVI R2, 225');emit('CMP R0, R2');eq('CLEARED');jump('CLEAR');
label('CLEARED');set(226,1);set(227,0);set(228,0);jump('SEND');
label('MAIN');emit('INP R0, 0x11');emit('MOVI R1, 1');emit('AND R0, R1');emit('CMP R0, R1');eq('READ');jump('MAIN');
label('READ');emit('INP R0, 0x10');store(229);
for(const [v,l] of [[240,'PVP'],[241,'PVE'],[242,'RESET'],[243,'SEND']]){emit('MOVI R1, '+v);emit('CMP R0, R1');eq(l)}
// Reject all remaining reserved byte values using high-nibble range walk.
emit('MOVI R1, 225');label('BAD_LOOP');emit('CMP R0, R1');eq('SEND');emit('ADDI R1, 1');emit('MOVI R2, 256 & 255'); // range loop ends at 256 in 16 bits
emit('MOVI R2, 255');emit('ADDI R2, 1');emit('CMP R1, R2');eq('PLACE');jump('BAD_LOOP');
label('PVP');set(225,0);jump('RESET');label('PVE');set(225,1);jump('RESET');
label('PLACE');test(227,0,'PLACE_OK');jump('SEND');label('PLACE_OK');load(229);emit('LDR R1, R0');emit('MOVI R2, 0');emit('CMP R1, R2');eq('COMMIT');jump('SEND');
label('COMMIT');load(226,'R1');load(229);emit('STR R0, R1');load(228);emit('ADDI R0, 1');store(228);set(230,0);jump('SCAN');
label('ACTUAL_DONE');test(227,0,'NO_WIN');jump('SEND');label('NO_WIN');test(228,225,'DRAW');load(226);emit('MOVI R1, 3');emit('SUB R1, R0');store(226,'R1');test(225,1,'MAY_AI');jump('SEND');label('MAY_AI');test(226,2,'AI_START');jump('SEND');label('DRAW');set(227,3);jump('SEND');
label('AI_START');set(230,1);set(229,0);jump('AI_TRY');
label('AI_TRY');load(229);emit('LDR R1, R0');emit('MOVI R2, 0');emit('CMP R1, R2');eq('AI_EMPTY');jump('AI_NEXT');
label('AI_EMPTY');load(230);emit('MOVI R1, 3');emit('SUB R1, R0');load(229);emit('STR R0, R1');jump('SCAN');
label('AI_RESULT');load(229);emit('MOVI R1, 0');emit('STR R0, R1');test(227,0,'AI_NEXT');set(227,0);jump('COMMIT');
label('AI_NEXT');load(229);emit('ADDI R0, 1');store(229);emit('MOVI R1, 225');emit('CMP R0, R1');eq('AI_PHASE_END');jump('AI_TRY');
label('AI_PHASE_END');test(230,1,'AI_BLOCK');jump('FALLBACK');label('AI_BLOCK');set(230,2);set(229,0);jump('AI_TRY');
// Prefer the closest vacant cell to the centre via expanding square rings.
label('FALLBACK');set(229,112);set(240,0);set(241,0);set(242,0);set(243,0);set(244,255);
label('SCORE_LOOP');load(241);emit('LDR R1, R0');emit('MOVI R2, 0');emit('CMP R1, R2');eq('SCORE_EMPTY');jump('SCORE_NEXT');
label('SCORE_EMPTY');set(245,0);
for(const a of [242,243]){load(a);emit('MOVI R1, 7');emit('SUB R0, R1');emit('MOVI R1, 128');emit('AND R1, R0');emit('MOVI R2, 0');emit('CMP R1, R2');let p='positive_'+a;eq(p);emit('MOVI R1, 0');emit('SUB R1, R0');emit('MOVR R0, R1');label(p);load(245,'R1');emit('ADDR R0, R1');store(245)}
// compare distance by walking 0..28 (CPU ISA has equality only).
set(246,0);label('COMPARE');load(246);load(244,'R1');emit('CMP R0, R1');eq('SCORE_NEXT');load(245,'R1');emit('CMP R0, R1');eq('BETTER');emit('ADDI R0, 1');store(246);jump('COMPARE');
label('BETTER');load(245);store(244);load(241);store(229);
label('SCORE_NEXT');load(241);emit('ADDI R0, 1');store(241);emit('MOVI R1, 225');emit('CMP R0, R1');eq('COMMIT');load(243);emit('ADDI R0, 1');store(243);emit('MOVI R1, 15');emit('CMP R0, R1');eq('SCORE_ROW');jump('SCORE_LOOP');label('SCORE_ROW');set(243,0);load(242);emit('ADDI R0, 1');store(242);jump('SCORE_LOOP');
// Full-board four-direction scan. Never wraps a row or column.
label('SCAN');set(227,0);set(231,0);set(232,0);set(233,0);
label('SCAN_CELL');load(231);emit('LDR R1, R0');store(234,'R1');emit('MOVI R2, 0');emit('CMP R1, R2');eq('SCAN_NEXT');set(235,0);
label('DIRECTION');for(const [a,b] of [[231,236],[232,237],[233,238]]){load(a);store(b)}set(239,1);
label('WALK');test(235,0,'STEP_RIGHT');test(235,1,'STEP_DOWN');test(235,2,'STEP_DIAG');jump('STEP_LEFT_DIAG');
label('STEP_RIGHT');test(238,14,'DIR_NEXT');load(238);emit('ADDI R0, 1');store(238);load(236);emit('ADDI R0, 1');jump('CHECK_STONE');
label('STEP_DOWN');test(237,14,'DIR_NEXT');load(237);emit('ADDI R0, 1');store(237);load(236);emit('ADDI R0, 15');jump('CHECK_STONE');
label('STEP_DIAG');test(237,14,'DIR_NEXT');test(238,14,'DIR_NEXT');load(237);emit('ADDI R0, 1');store(237);load(238);emit('ADDI R0, 1');store(238);load(236);emit('ADDI R0, 16');jump('CHECK_STONE');
label('STEP_LEFT_DIAG');test(237,14,'DIR_NEXT');test(238,0,'DIR_NEXT');load(237);emit('ADDI R0, 1');store(237);load(238);emit('MOVI R1, 1');emit('SUB R0, R1');store(238);load(236);emit('ADDI R0, 14');
label('CHECK_STONE');store(236);emit('LDR R1, R0');load(234,'R2');emit('CMP R1, R2');eq('MATCH');jump('DIR_NEXT');label('MATCH');load(239);emit('ADDI R0, 1');store(239);emit('MOVI R1, 5');emit('CMP R0, R1');eq('WIN');jump('WALK');
label('DIR_NEXT');load(235);emit('ADDI R0, 1');store(235);emit('MOVI R1, 4');emit('CMP R0, R1');eq('SCAN_NEXT');jump('DIRECTION');
label('SCAN_NEXT');load(231);emit('ADDI R0, 1');store(231);emit('MOVI R1, 225');emit('CMP R0, R1');eq('SCAN_DONE');load(233);emit('ADDI R0, 1');store(233);emit('MOVI R1, 15');emit('CMP R0, R1');eq('SCAN_ROW');jump('SCAN_CELL');label('SCAN_ROW');set(233,0);load(232);emit('ADDI R0, 1');store(232);jump('SCAN_CELL');label('WIN');load(234);store(227);label('SCAN_DONE');test(230,0,'ACTUAL_DONE');jump('AI_RESULT');
// Frame: A5, mode, player, status, count, 225 tiles, XOR (231 bytes).
label('SEND');set(247,0);set(248,0);emit('MOVI R0, 165');jump('TX');label('TX_NEXT');load(248);emit('ADDI R0, 1');store(248);for(const [v,l] of [[1,'TX_MODE'],[2,'TX_PLAYER'],[3,'TX_STATUS'],[4,'TX_COUNT'],[230,'TX_SUM'],[231,'MAIN']]){emit('MOVI R1, '+v);emit('CMP R0, R1');eq(l)}emit('MOVI R1, 5');emit('SUB R0, R1');emit('LDR R0, R0');jump('TX');for(const [l,a] of [['TX_MODE',225],['TX_PLAYER',226],['TX_STATUS',227],['TX_COUNT',228],['TX_SUM',247]]){label(l);load(a);jump('TX')}
label('TX');load(247,'R1');emit('XOR R1, R0');store(247,'R1');label('TX_WAIT');emit('INP R1, 0x11');emit('MOVI R2, 2');emit('AND R1, R2');emit('CMP R1, R2');eq('TX_WRITE');jump('TX_WAIT');label('TX_WRITE');emit('OUP 0x10, R0');jump('TX_NEXT');
lines=lines.map(x=>x.replace('256 & 255','0'));
if(pc>1024)throw Error('Program too large: '+pc);
fs.writeFileSync(path.join(__dirname,'../program/gomoku.asm'),'; Generated by tools/build.cjs\n'+lines.join('\n')+'\n');console.log(pc+' words generated');

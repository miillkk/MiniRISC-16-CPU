// All emitted instructions execute on MiniRISC-16; host does not score moves.
module.exports=function({lab,j,set,op,eq,nz,read,write,call,fn,ret,invalidSquare}){
lab('TURN_READY');eq('mode',64,'AI_TURN');j('SEND');lab('AI_TURN');eq('side',8,'AI_BEGIN');j('SEND');
lab('AI_BEGIN');set('bestScore',0);set('bestFrom',255);set('afrom',0);
lab('AI_FROM');invalidSquare('afrom','AI_NEXT_FROM');read('temp','afrom');eq('temp',0,'AI_NEXT_FROM');op('temp','temp','AND',8);eq('temp','side','AI_START_TO');j('AI_NEXT_FROM');
lab('AI_START_TO');set('ato',0);lab('AI_TO');invalidSquare('ato','AI_NEXT_TO');set('from','afrom');set('to','ato');call('LEGAL');eq('ok',0,'AI_NEXT_TO');
// Material gained, with en passant and automatic queen promotion included.
set('score',128);set('valueIn','captured');call('VALUE');op('score','score','ADDR','weight');eq('epcap',255,'AI_PROMOTION');op('score','score','ADDR',10);
lab('AI_PROMOTION');set('aiPiece','lp');eq('lt',1,'AI_PAWN');j('AI_CENTRE');lab('AI_PAWN');op('temp','to','AND',112);eq('temp',0,'AI_QUEEN');eq('temp',112,'AI_QUEEN');j('AI_CENTRE');lab('AI_QUEEN');op('aiPiece','side','ADDR',5);op('score','score','ADDR',80);
lab('AI_CENTRE');op('temp','to','AND',7);eq('temp',3,'AI_CENTRE_FILE');eq('temp',4,'AI_CENTRE_FILE');j('AI_RANK');lab('AI_CENTRE_FILE');op('score','score','ADDR',2);lab('AI_RANK');op('temp','to','AND',112);eq('temp',48,'AI_CENTRE_RANK');eq('temp',64,'AI_CENTRE_RANK');j('AI_TRIAL');lab('AI_CENTRE_RANK');op('score','score','ADDR',2);
// Evaluate exposure on the resulting board, including special-move effects.
lab('AI_TRIAL');write('from',0);write('to','aiPiece');eq('epcap',255,'AI_ROOK');write('epcap',0);lab('AI_ROOK');eq('rf',255,'AI_ATTACK');write('rf',0);write('rt','rookold');lab('AI_ATTACK');set('target','to');op('aside','side','XOR',8);call('ATTACK');set('aiAttacked','ok');
write('from','lp');write('to','captured');eq('epcap',255,'AI_UNROOK');write('epcap','epold');lab('AI_UNROOK');eq('rf',255,'AI_SCORE');write('rf','rookold');write('rt',0);
lab('AI_SCORE');eq('aiAttacked',0,'AI_COMPARE');set('valueIn','aiPiece');call('VALUE');op('score','score','SUB','weight');
// Equality-only ISA: the lower score is reached first by this counter.
lab('AI_COMPARE');set('scoreWalk',0);lab('AI_COMPARE_LOOP');eq('scoreWalk','score','AI_NEXT_TO');eq('scoreWalk','bestScore','AI_BEST');op('scoreWalk','scoreWalk','ADDR',1);j('AI_COMPARE_LOOP');lab('AI_BEST');set('bestScore','score');set('bestFrom','from');set('bestTo','to');
lab('AI_NEXT_TO');op('ato','ato','ADDR',1);eq('ato',128,'AI_NEXT_FROM');j('AI_TO');lab('AI_NEXT_FROM');op('afrom','afrom','ADDR',1);eq('afrom',128,'AI_PLAY');j('AI_FROM');
lab('AI_PLAY');eq('bestFrom',255,'NO_MOVES');set('from','bestFrom');set('to','bestTo');set('promotion',0);set('error',0);j('MOVE_TRY');
fn('VALUE');op('valueType','valueIn','AND',7);for(const [type,value]of [[1,10],[2,30],[3,30],[4,50],[5,90]])eq('valueType',type,'VALUE_'+type);set('weight',0);ret();for(const [type,value]of [[1,10],[2,30],[3,30],[4,50],[5,90]]){lab('VALUE_'+type);set('weight',value);ret()}
};

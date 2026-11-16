const assert=require('assert');
const {CPU,sq,move,fresh,fixture,legalMoves,vars,labels}=require('./verify.cjs');
function aiTurn(c){
 const saved=c.m.slice(),legal=legalMoves(c).map(([a,b])=>a+','+b);
 c.m=saved.slice();c.m[vars.mode]=64;c.pc=labels.AI_BEGIN;
 const start=c.cycles,frame=c.frame(),a=c.m[vars.bestFrom],b=c.m[vars.bestTo];
 assert(legal.includes(a+','+b),'AI must choose a legal move');
 const oracle=fresh();oracle.m=saved.slice();oracle.m[vars.mode]=0;oracle.pc=labels.MAIN;
 const expected=oracle.frame([242,a,b,0]);
 assert.deepEqual(frame.slice(3,69),expected.slice(3,69),'AI trials must restore all board changes');
 for(const name of ['ep','right0','right1','right2','right3'])assert.equal(c.m[vars[name]],oracle.m[vars[name]],name);
 return {a,b,frame,cycles:c.cycles-start};
}
let c=fresh();let f=c.frame([244]);assert.equal(f[2],64);let start=c.cycles;f=move(c,'e2','e4');assert.equal(f[2],64);assert.equal(f[4],0);assert.equal(c.m.filter((x,i)=>i<128&&x===9).length,8);assert.equal(c.m[vars.side],0);console.log('AI opening cycles:',c.cycles-start);
const unchanged=c.m.slice(0,128);f=move(c,'e4','e7');assert.equal(f[4],1);assert.deepEqual(c.m.slice(0,128),unchanged,'illegal human move must not trigger AI');
assert.equal(c.frame([240])[2],64,'restart preserves mode');assert.equal(c.frame([245])[2],0,'PVP selection');move(c,'e2','e4');assert.equal(c.m[vars.side],8,'PVP must not auto reply');
c=fixture({a1:6,h8:14,d8:12,d4:5},8);let result=aiTurn(c);assert.equal(result.b,sq('d4'),'capture hanging queen');
c=fixture({a1:6,h8:14,d8:13,d4:1,e3:1},8);result=aiTurn(c);assert.notEqual(result.b,sq('d4'),'avoid losing queen for defended pawn');
c=fixture({a1:6,h8:14,a8:4,f7:9},8);result=aiTurn(c);assert.equal(result.frame[3]<2,true,'escape check legally');
c=fixture({h1:6,h8:14,a2:9},8);result=aiTurn(c);assert.equal(c.m[sq('a1')],13,'AI promotes to queen');
c=fixture({e1:6,e8:14,a8:12,h8:12,b2:1},8);c.m[vars.right2]=c.m[vars.right3]=1;aiTurn(c);
c=fixture({e1:6,e8:14,e4:1,d4:9},8);c.m[vars.ep]=sq('e3');aiTurn(c);
// A human mating move must end the game without an AI reply.
c=fixture({f6:6,g6:5,h8:14});c.m[vars.mode]=64;f=move(c,'g6','g7');assert.equal(f[3],2);assert.equal(c.m[sq('h8')],14);
c=fixture({f7:6,g5:5,h8:14});c.m[vars.mode]=64;assert.equal(move(c,'g5','g6')[3],4);
console.log('AI PASS: mode/reset, auto reply, illegal input, capture scoring, exposure penalty, check evasion, promotion, castling/EP trial restoration, mate/stalemate.');


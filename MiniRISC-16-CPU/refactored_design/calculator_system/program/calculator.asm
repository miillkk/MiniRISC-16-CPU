; MiniRISC-16 interactive calculator
; SW7..0=data. S1 short press changes the confirmation token;
; S1 long press resets the complete calculator system.
; Scratchpad: 40=A, 41=B, 42=op, 43=previous confirmation token, 44=result,
;             45=quotient, 46=remainder, 47=temp, 48=input mask, 49=AABB.

START:
    MOVI R0, 0x01
    OUP  0x22, R0
    INP  R0, 0x33
    MOVI R1, 0x01
    AND  R0, R1
    OUP  0x43, R0

ENTER_A:
    MOVI R3, 0x00
    MOVI R0, 0xFF
    OUP  0x48, R0
    MOVI R0, 0xA0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    OUP  0x21, R0
    JUMP POLL_INPUT

ENTER_B:
    MOVI R3, 0x01
    MOVI R0, 0xB0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    OUP  0x21, R0
    JUMP POLL_INPUT

ENTER_OP:
    MOVI R3, 0x02
    MOVI R0, 0x07
    OUP  0x48, R0
    MOVI R0, 0xC0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    OUP  0x21, R0
    JUMP POLL_INPUT

POLL_INPUT:
    INP  R1, 0x31
    INP  R2, 0x48
    AND  R1, R2
    OUP  0x20, R1
    INP  R0, 0x33
    MOVI R2, 0x01
    AND  R0, R2
    INP  R2, 0x43
    CMP  R0, R2
    JZ   POLL_INPUT
    OUP  0x43, R0
    MOVI R2, 0x00
    CMP  R3, R2
    JZ   LATCH_A
    MOVI R2, 0x01
    CMP  R3, R2
    JZ   LATCH_B
    OUP  0x42, R1
    JUMP DISPATCH

LATCH_A:
    OUP  0x40, R1
    JUMP ENTER_B

LATCH_B:
    OUP  0x41, R1
    INP  R0, 0x40
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    OR   R0, R1
    OUP  0x49, R0
    JUMP ENTER_OP

DISPATCH:
    MOVI R2, 0x00
    CMP  R1, R2
    JZ   OP_ADD
    MOVI R2, 0x01
    CMP  R1, R2
    JZ   OP_SUB
    MOVI R2, 0x02
    CMP  R1, R2
    JZ   OP_AND
    MOVI R2, 0x03
    CMP  R1, R2
    JZ   OP_OR
    MOVI R2, 0x04
    CMP  R1, R2
    JZ   OP_XOR
    MOVI R2, 0x05
    CMP  R1, R2
    JZ   OP_MUL
    MOVI R2, 0x06
    CMP  R1, R2
    JZ   OP_DIV
    JUMP OP_CMP

OP_ADD:
    INP  R0, 0x40
    INP  R1, 0x41
    ADDR R0, R1
    JUMP ARITH_FINISH

OP_SUB:
    INP  R0, 0x40
    INP  R1, 0x41
    SUB  R0, R1

ARITH_FINISH:
    OUP  0x44, R0
    INP  R2, 0x32
    INP  R3, 0x42
    OR   R2, R3
    OUP  0x30, R2
    JUMP DISPLAY_RESULT

OP_AND:
    INP  R0, 0x40
    INP  R1, 0x41
    AND  R0, R1
    JUMP LOGIC_FINISH

OP_OR:
    INP  R0, 0x40
    INP  R1, 0x41
    OR   R0, R1
    JUMP LOGIC_FINISH

OP_XOR:
    INP  R0, 0x40
    INP  R1, 0x41
    XOR  R0, R1

LOGIC_FINISH:
    OUP  0x44, R0
    MOVI R1, 0x00
    CMP  R0, R1
    INP  R2, 0x32
    MOVI R1, 0x18
    AND  R2, R1
    INP  R3, 0x42
    OR   R2, R3
    OUP  0x30, R2
    JUMP DISPLAY_RESULT

OP_MUL:
    INP  R2, 0x40
    INP  R1, 0x41
    MOVI R0, 0x00
    MOVI R3, 0x00
    CMP  R1, R3
    JZ   MUL_DONE
MUL_LOOP:
    ADDR R0, R2
    MOVI R3, 0x01
    SUB  R1, R3
    JZ   MUL_DONE
    JUMP MUL_LOOP
MUL_DONE:
    JUMP LOGIC_FINISH

OP_DIV:
    INP  R0, 0x40
    INP  R1, 0x41
    MOVI R2, 0x00
    CMP  R1, R2
    JZ   DIV_ZERO
    OUP  0x45, R2
DIV_LOOP:
    CMP  R0, R1
    INP  R3, 0x32
    OUP  0x45, R2
    MOVI R2, 0x20
    AND  R3, R2
    CMP  R3, R2
    JZ   DIV_SUBTRACT
    JUMP DIV_DONE
DIV_SUBTRACT:
    INP  R2, 0x45
    SUB  R0, R1
    ADDI R2, 0x01
    JUMP DIV_LOOP
DIV_DONE:
    OUP  0x46, R0
    INP  R2, 0x45
    MOVR R0, R2
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    INP  R1, 0x46
    OR   R0, R1
    OUP  0x44, R0
    MOVI R0, 0x00
    CMP  R2, R0
    INP  R3, 0x32
    MOVI R0, 0x18
    AND  R3, R0
    MOVI R0, 0x06
    OR   R3, R0
    OUP  0x30, R3
    JUMP DISPLAY_RESULT

DIV_ZERO:
    MOVI R0, 0x86
    OUP  0x30, R0
    JUMP DISPLAY_ERROR

OP_CMP:
    INP  R0, 0x40
    INP  R1, 0x41
    CMP  R0, R1
    INP  R2, 0x32
    OUP  0x47, R2
    JZ   CMP_EQUAL
    MOVI R3, 0x20
    AND  R2, R3
    CMP  R2, R3
    JZ   CMP_GREATER
    MOVI R0, 0x00
    JUMP CMP_SAVE
CMP_EQUAL:
    MOVI R0, 0x01
    JUMP CMP_SAVE
CMP_GREATER:
    MOVI R0, 0x02
CMP_SAVE:
    OUP  0x44, R0
    INP  R2, 0x47
    MOVI R3, 0x07
    OR   R2, R3
    OUP  0x30, R2

DISPLAY_RESULT:
    INP  R0, 0x49
    OUP  0x21, R0
    INP  R0, 0x44
    OUP  0x20, R0
    JUMP RESULT_READY

DISPLAY_ERROR:
    INP  R0, 0x49
    OUP  0x20, R0
    MOVI R0, 0xE0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDI R0, 0x01
    OUP  0x21, R0

RESULT_READY:
RESULT_WAIT:
    INP  R0, 0x33
    MOVI R1, 0x01
    AND  R0, R1
    INP  R1, 0x43
    CMP  R0, R1
    JZ   RESULT_WAIT
    OUP  0x43, R0
    MOVI R0, 0x00
    OUP  0x30, R0
    JUMP ENTER_A

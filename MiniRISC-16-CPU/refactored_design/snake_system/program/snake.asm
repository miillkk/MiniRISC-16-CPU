; MiniRISC-16 serial Snake, 8x8 board.
; UART: 115200 8N1. Controls: W/A/S/D, R restarts.
; Data RAM packet: A5, status, score, food, then 64 cell-age bytes.

INIT:
    MOVI R0, 0x00
    MOVI R1, 0x00
CLEAR_LOOP:
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R2, 0x44
    CMP  R0, R2
    JZ   CLEAR_DONE
    JUMP CLEAR_LOOP
CLEAR_DONE:
    MOVI R0, 0x1B
    OUP  0x40, R0
    MOVI R0, 0x01
    OUP  0x41, R0
    MOVI R0, 0x03
    OUP  0x42, R0
    MOVI R0, 0x00
    OUP  0x43, R0
    OUP  0x45, R0
    OUP  0x20, R0
    MOVI R0, 0x01
    OUP  0x22, R0
    MOVI R0, 0x5A
    OUP  0x21, R0
    MOVI R0, 0x1D
    MOVI R1, 0x01
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R1, 0x02
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R1, 0x03
    STR  R0, R1
    JUMP NEW_FOOD

MAIN:
    INP  R0, 0x11
    MOVI R1, 0x01
    AND  R0, R1
    CMP  R0, R1
    JZ   READ_KEY
    JUMP TIMER_CHECK
READ_KEY:
    INP  R0, 0x10
    MOVI R1, 0x57
    CMP  R0, R1
    JZ   SET_UP
    MOVI R1, 0x44
    CMP  R0, R1
    JZ   SET_RIGHT
    MOVI R1, 0x53
    CMP  R0, R1
    JZ   SET_DOWN
    MOVI R1, 0x41
    CMP  R0, R1
    JZ   SET_LEFT
    MOVI R1, 0x52
    CMP  R0, R1
    JZ   INIT
    MOVI R1, 0x72
    CMP  R0, R1
    JZ   INIT
    JUMP TIMER_CHECK
SET_UP:
    INP  R1, 0x41
    MOVI R2, 0x02
    CMP  R1, R2
    JZ   TIMER_CHECK
    MOVI R0, 0x00
    OUP  0x41, R0
    JUMP TIMER_CHECK
SET_RIGHT:
    INP  R1, 0x41
    MOVI R2, 0x03
    CMP  R1, R2
    JZ   TIMER_CHECK
    MOVI R0, 0x01
    OUP  0x41, R0
    JUMP TIMER_CHECK
SET_DOWN:
    INP  R1, 0x41
    MOVI R2, 0x00
    CMP  R1, R2
    JZ   TIMER_CHECK
    MOVI R0, 0x02
    OUP  0x41, R0
    JUMP TIMER_CHECK
SET_LEFT:
    INP  R1, 0x41
    MOVI R2, 0x01
    CMP  R1, R2
    JZ   TIMER_CHECK
    MOVI R0, 0x03
    OUP  0x41, R0

TIMER_CHECK:
    INP  R0, 0x12
    MOVI R1, 0x01
    AND  R0, R1
    CMP  R0, R1
    JZ   STEP
    JUMP MAIN

STEP:
    INP  R0, 0x40
    INP  R1, 0x41
    MOVI R2, 0x00
    CMP  R1, R2
    JZ   MOVE_UP
    MOVI R2, 0x01
    CMP  R1, R2
    JZ   MOVE_RIGHT
    MOVI R2, 0x02
    CMP  R1, R2
    JZ   MOVE_DOWN
    JUMP MOVE_LEFT

MOVE_UP:
    MOVR R3, R0
    MOVI R2, 0x38
    AND  R3, R2
    MOVI R2, 0x00
    CMP  R3, R2
    JZ   GAME_OVER
    MOVI R2, 0x08
    SUB  R0, R2
    JUMP MOVE_READY
MOVE_RIGHT:
    MOVR R3, R0
    MOVI R2, 0x07
    AND  R3, R2
    CMP  R3, R2
    JZ   GAME_OVER
    ADDI R0, 0x01
    JUMP MOVE_READY
MOVE_DOWN:
    MOVR R3, R0
    MOVI R2, 0x38
    AND  R3, R2
    CMP  R3, R2
    JZ   GAME_OVER
    ADDI R0, 0x08
    JUMP MOVE_READY
MOVE_LEFT:
    MOVR R3, R0
    MOVI R2, 0x07
    AND  R3, R2
    MOVI R2, 0x00
    CMP  R3, R2
    JZ   GAME_OVER
    MOVI R2, 0x01
    SUB  R0, R2

MOVE_READY:
    OUP  0x46, R0
    MOVI R3, 0x04
DECAY_LOOP:
    LDR  R0, R3
    MOVI R1, 0x00
    CMP  R0, R1
    JZ   DECAY_NEXT
    MOVI R1, 0x01
    SUB  R0, R1
    STR  R3, R0
DECAY_NEXT:
    ADDI R3, 0x01
    MOVI R1, 0x44
    CMP  R3, R1
    JZ   CHECK_CELL
    JUMP DECAY_LOOP

CHECK_CELL:
    INP  R0, 0x46
    MOVR R3, R0
    ADDI R3, 0x04
    LDR  R1, R3
    MOVI R2, 0x00
    CMP  R1, R2
    JZ   CELL_FREE
    JUMP GAME_OVER
CELL_FREE:
    INP  R1, 0x44
    CMP  R0, R1
    JZ   EAT_FOOD
    INP  R2, 0x42
    STR  R3, R2
    OUP  0x40, R0
    JUMP PREP_FRAME

EAT_FOOD:
    INP  R2, 0x42
    ADDI R2, 0x01
    OUP  0x42, R2
    STR  R3, R2
    OUP  0x40, R0
    INP  R1, 0x43
    ADDI R1, 0x01
    OUP  0x43, R1
    OUP  0x20, R1

NEW_FOOD:
    INP  R0, 0x13
    MOVI R1, 0x3F
    AND  R0, R1
    MOVR R3, R0
    ADDI R3, 0x04
    LDR  R2, R3
    MOVI R1, 0x00
    CMP  R2, R1
    JZ   FOOD_OK
    JUMP NEW_FOOD
FOOD_OK:
    OUP  0x44, R0

PREP_FRAME:
    MOVI R0, 0x00
    MOVI R1, 0xA5
    STR  R0, R1
    ADDI R0, 0x01
    INP  R1, 0x41
    ADDI R1, 0x10
    STR  R0, R1
    OUP  0x30, R1
    ADDI R0, 0x01
    INP  R1, 0x43
    STR  R0, R1
    ADDI R0, 0x01
    INP  R1, 0x44
    STR  R0, R1

SEND_BEGIN:
    MOVI R3, 0x00
SEND_LOOP:
    LDR  R0, R3
TX_WAIT:
    INP  R1, 0x11
    MOVI R2, 0x02
    AND  R1, R2
    CMP  R1, R2
    JZ   TX_SEND
    JUMP TX_WAIT
TX_SEND:
    OUP  0x10, R0
    ADDI R3, 0x01
    MOVI R2, 0x44
    CMP  R3, R2
    JZ   SEND_DONE
    JUMP SEND_LOOP
SEND_DONE:
    INP  R0, 0x45
    MOVI R1, 0x01
    CMP  R0, R1
    JZ   GAME_WAIT
    JUMP MAIN

GAME_OVER:
    MOVI R0, 0x01
    OUP  0x45, R0
    MOVI R0, 0x01
    MOVI R1, 0x80
    STR  R0, R1
    OUP  0x30, R1
    MOVI R0, 0xDE
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    ADDR R0, R0
    MOVI R1, 0xAD
    OR   R0, R1
    OUP  0x21, R0
    JUMP SEND_BEGIN

GAME_WAIT:
    INP  R0, 0x11
    MOVI R1, 0x01
    AND  R0, R1
    CMP  R0, R1
    JZ   GAME_KEY
    JUMP GAME_WAIT
GAME_KEY:
    INP  R0, 0x10
    MOVI R1, 0x52
    CMP  R0, R1
    JZ   INIT
    MOVI R1, 0x72
    CMP  R0, R1
    JZ   INIT
    JUMP GAME_WAIT

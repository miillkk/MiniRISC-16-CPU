; MiniRISC-16 serial Snake V2, 16x8 board, 1024-word runtime image.
; UART: 115200 8N1. Controls: W/A/S/D, R restarts.
; Packet: A5, status, score, food, 128 cells, high score, level,
;         switches, flags, version, length, sequence and XOR checksum
;         (140 bytes total).

INIT:
    MOVI R0, 0x00
    MOVI R1, 0x00
CLEAR_LOOP:
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R2, 0x8C
    CMP  R0, R2
    JZ   CLEAR_DONE
    JUMP CLEAR_LOOP
CLEAR_DONE:
    MOVI R0, 0x37
    OUP  0x40, R0
    MOVI R0, 0x01
    OUP  0x41, R0
    MOVI R0, 0x03
    OUP  0x42, R0
    MOVI R0, 0x00
    OUP  0x43, R0
    OUP  0x45, R0
    OUP  0x48, R0
    OUP  0x20, R0
    MOVI R0, 0x01
    OUP  0x22, R0
    MOVI R0, 0x5A
    OUP  0x21, R0
    MOVI R0, 0x39
    MOVI R1, 0x01
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R1, 0x02
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R1, 0x03
    STR  R0, R1
    JMPA V2_NEW_GAME

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
    MOVI R2, 0x70
    AND  R3, R2
    MOVI R2, 0x00
    CMP  R3, R2
    JZ   GAME_OVER
    MOVI R2, 0x10
    SUB  R0, R2
    JUMP MOVE_READY
MOVE_RIGHT:
    MOVR R3, R0
    MOVI R2, 0x0F
    AND  R3, R2
    CMP  R3, R2
    JZ   GAME_OVER
    ADDI R0, 0x01
    JUMP MOVE_READY
MOVE_DOWN:
    MOVR R3, R0
    MOVI R2, 0x70
    AND  R3, R2
    CMP  R3, R2
    JZ   GAME_OVER
    ADDI R0, 0x10
    JUMP MOVE_READY
MOVE_LEFT:
    MOVR R3, R0
    MOVI R2, 0x0F
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
    MOVI R1, 0xFF
    CMP  R0, R1
    JZ   DECAY_NEXT
    MOVI R1, 0x00
    CMP  R0, R1
    JZ   DECAY_NEXT
    MOVI R1, 0x01
    SUB  R0, R1
    STR  R3, R0
DECAY_NEXT:
    ADDI R3, 0x01
    MOVI R1, 0x84
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
    JMPA V2_AFTER_EAT

NEW_FOOD:
    JMPA V2_NEW_FOOD

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
    JMPA V2_FRAME_META

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
    MOVI R2, 0x8C
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
    JMPA V2_GAME_OVER

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

.ORG 0x100

; Page 1 contains V2 services reached with the absolute JMPA instruction.
; SW4..3 select one of three connected maps when a game starts:
; 00=open, 01=maze, 10/11=hard. Wall addresses are board position + 4.
V2_NEW_GAME:
    MOVI R0, 0x00
    OUP  0x14, R0
    OUP  0x46, R0
    MOVI R1, 0xFF
    INP  R2, 0x31
    MOVI R3, 0x18
    AND  R2, R3
    MOVI R3, 0x00
    CMP  R2, R3
    JZ   V2_MAP_OPEN
    MOVI R3, 0x08
    CMP  R2, R3
    JZ   V2_MAP_MAZE
    JUMP V2_MAP_HARD

; Open map: four short balanced bars and a small center-bottom bar.
V2_MAP_OPEN:
    MOVI R0, 0x17
    STR  R0, R1
    MOVI R0, 0x18
    STR  R0, R1
    MOVI R0, 0x19
    STR  R0, R1
    MOVI R0, 0x1E
    STR  R0, R1
    MOVI R0, 0x1F
    STR  R0, R1
    MOVI R0, 0x20
    STR  R0, R1
    MOVI R0, 0x57
    STR  R0, R1
    MOVI R0, 0x58
    STR  R0, R1
    MOVI R0, 0x5F
    STR  R0, R1
    MOVI R0, 0x60
    STR  R0, R1
    MOVI R0, 0x6B
    STR  R0, R1
    MOVI R0, 0x6C
    STR  R0, R1
    JMPA V2_NEW_FOOD

; Maze map: staggered walls with deliberate gaps; every free cell remains in
; one connected region, so food cannot appear in a sealed pocket.
V2_MAP_MAZE:
    MOVI R0, 0x17
    STR  R0, R1
    MOVI R0, 0x27
    STR  R0, R1
    MOVI R0, 0x37
    STR  R0, R1
    MOVI R0, 0x57
    STR  R0, R1
    MOVI R0, 0x67
    STR  R0, R1
    MOVI R0, 0x2C
    STR  R0, R1
    MOVI R0, 0x2D
    STR  R0, R1
    MOVI R0, 0x2E
    STR  R0, R1
    MOVI R0, 0x2F
    STR  R0, R1
    MOVI R0, 0x30
    STR  R0, R1
    MOVI R0, 0x40
    STR  R0, R1
    MOVI R0, 0x50
    STR  R0, R1
    MOVI R0, 0x5B
    STR  R0, R1
    MOVI R0, 0x5C
    STR  R0, R1
    MOVI R0, 0x5D
    STR  R0, R1
    MOVI R0, 0x5E
    STR  R0, R1
    JMPA V2_NEW_FOOD

; Hard map: denser staggered gates, but still no closed region and no wall in
; the initial snake or its first right/down destination.
V2_MAP_HARD:
    MOVI R0, 0x16
    STR  R0, R1
    MOVI R0, 0x26
    STR  R0, R1
    MOVI R0, 0x46
    STR  R0, R1
    MOVI R0, 0x56
    STR  R0, R1
    MOVI R0, 0x66
    STR  R0, R1
    MOVI R0, 0x21
    STR  R0, R1
    MOVI R0, 0x31
    STR  R0, R1
    MOVI R0, 0x41
    STR  R0, R1
    MOVI R0, 0x61
    STR  R0, R1
    MOVI R0, 0x71
    STR  R0, R1
    MOVI R0, 0x1A
    STR  R0, R1
    MOVI R0, 0x1B
    STR  R0, R1
    MOVI R0, 0x1C
    STR  R0, R1
    MOVI R0, 0x1D
    STR  R0, R1
    MOVI R0, 0x2C
    STR  R0, R1
    MOVI R0, 0x48
    STR  R0, R1
    MOVI R0, 0x49
    STR  R0, R1
    MOVI R0, 0x4A
    STR  R0, R1
    MOVI R0, 0x5C
    STR  R0, R1
    MOVI R0, 0x5D
    STR  R0, R1
    MOVI R0, 0x5E
    STR  R0, R1
    MOVI R0, 0x5F
    STR  R0, R1
    MOVI R0, 0x69
    STR  R0, R1
    MOVI R0, 0x6A
    STR  R0, R1
    MOVI R0, 0x6B
    STR  R0, R1
    JMPA V2_NEW_FOOD

; Score is still in R1. Each level requires two foods:
; score 0..1 -> level 0, 2..3 -> 1, 4..5 -> 2, 6+ -> 3.
V2_AFTER_EAT:
    OUP  0x46, R1
    MOVI R0, 0x01
    CMP  R1, R0
    JZ   V2_LEVEL_ZERO
    MOVI R0, 0x02
    CMP  R1, R0
    JZ   V2_LEVEL_ONE
    MOVI R0, 0x03
    CMP  R1, R0
    JZ   V2_LEVEL_ONE
    MOVI R0, 0x04
    CMP  R1, R0
    JZ   V2_LEVEL_TWO
    MOVI R0, 0x05
    CMP  R1, R0
    JZ   V2_LEVEL_TWO
    MOVI R0, 0x03
    OUP  0x14, R0
    JMPA V2_NEW_FOOD
V2_LEVEL_ZERO:
    MOVI R0, 0x00
    OUP  0x14, R0
    JMPA V2_NEW_FOOD
V2_LEVEL_ONE:
    MOVI R0, 0x01
    OUP  0x14, R0
    JMPA V2_NEW_FOOD
V2_LEVEL_TWO:
    MOVI R0, 0x02
    OUP  0x14, R0
    JMPA V2_NEW_FOOD

; Try at most 16 random cells, then scan all 128 cells deterministically.
; The bounded fallback prevents an infinite random loop on a crowded map.
V2_NEW_FOOD:
    MOVI R0, 0x00
    OUP  0x49, R0
V2_FOOD_RANDOM:
    INP  R0, 0x13
    MOVI R1, 0x7F
    AND  R0, R1
    MOVR R3, R0
    ADDI R3, 0x04
    LDR  R2, R3
    MOVI R1, 0x00
    CMP  R2, R1
    JZ   V2_FOOD_OK
    INP  R2, 0x49
    ADDI R2, 0x01
    OUP  0x49, R2
    MOVI R1, 0x10
    CMP  R2, R1
    JZ   V2_FOOD_SCAN_INIT
    JUMP V2_FOOD_RANDOM
V2_FOOD_SCAN_INIT:
    MOVI R0, 0x00
    OUP  0x49, R0
V2_FOOD_SCAN:
    INP  R0, 0x49
    MOVR R3, R0
    ADDI R3, 0x04
    LDR  R2, R3
    MOVI R1, 0x00
    CMP  R2, R1
    JZ   V2_FOOD_OK
    ADDI R0, 0x01
    MOVI R1, 0x80
    CMP  R0, R1
    JZ   V2_BOARD_FULL
    OUP  0x49, R0
    JUMP V2_FOOD_SCAN
V2_FOOD_OK:
    OUP  0x44, R0
    JMPA PREP_FRAME
V2_BOARD_FULL:
    JMPA GAME_OVER

; Append diagnostics and a self-describing protocol trailer to every frame.
V2_FRAME_META:
    MOVI R0, 0x84
    INP  R1, 0x47
    STR  R0, R1
    ADDI R0, 0x01
    INP  R1, 0x14
    STR  R0, R1
    ADDI R0, 0x01
    INP  R1, 0x31
    STR  R0, R1
    ADDI R0, 0x01
    INP  R1, 0x32
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R1, 0x03
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R1, 0x8C
    STR  R0, R1
    ADDI R0, 0x01
    INP  R1, 0x48
    STR  R0, R1
    ADDI R1, 0x01
    OUP  0x48, R1
    MOVI R0, 0x00
    MOVI R1, 0x00
V2_CHECKSUM_LOOP:
    LDR  R2, R0
    XOR  R1, R2
    ADDI R0, 0x01
    MOVI R3, 0x8B
    CMP  R0, R3
    JZ   V2_CHECKSUM_DONE
    JUMP V2_CHECKSUM_LOOP
V2_CHECKSUM_DONE:
    STR  R0, R1
    JMPA SEND_BEGIN

; CMP supplies unsigned A>=B through C. Reading the flags port lets software
; update the persistent high score without adding a new conditional opcode.
V2_GAME_OVER:
    INP  R0, 0x43
    INP  R1, 0x47
    CMP  R0, R1
    INP  R2, 0x32
    MOVI R3, 0x20
    AND  R2, R3
    CMP  R2, R3
    JZ   V2_SAVE_HIGH
    JMPA V2_FRAME_META
V2_SAVE_HIGH:
    OUP  0x47, R0
    JMPA V2_FRAME_META

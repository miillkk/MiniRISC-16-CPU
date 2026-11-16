; MiniRISC-16 running-light demo.
; Controls: A/Left = move left, D/Right = move right, R = restart.
; Board switches: SW1..0 speed, SW2 pause.
;
; Protocol v4, 12 bytes:
; A5, version, length, game-id, sequence, pattern, position, direction,
; speed, switches, last-key, XOR checksum.

INIT:
    MOVI R0, 0x00
    MOVI R1, 0x00
INIT_CLEAR:
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R2, 0x27
    CMP  R0, R2
    JZ   INIT_READY
    JUMP INIT_CLEAR
INIT_READY:
    MOVI R0, 0x01
    OUP  0x30, R0
    MOVI R3, 0x25
    STR  R3, R0
    MOVI R0, 0x01
    OUP  0x22, R0
    JUMP PREP_FRAME

MAIN:
    INP  R0, 0x11
    MOVI R1, 0x01
    AND  R0, R1
    CMP  R0, R1
    JZ   READ_KEY
    JUMP CHECK_SWITCH

READ_KEY:
    INP  R0, 0x10
    MOVI R3, 0x24
    STR  R3, R0
    MOVI R1, 0x52
    CMP  R0, R1
    JZ   INIT
    MOVI R1, 0x72
    CMP  R0, R1
    JZ   INIT
    MOVI R1, 0x41
    CMP  R0, R1
    JZ   SET_LEFT
    MOVI R1, 0x61
    CMP  R0, R1
    JZ   SET_LEFT
    MOVI R1, 0x44
    CMP  R0, R1
    JZ   SET_RIGHT
    MOVI R1, 0x64
    CMP  R0, R1
    JZ   SET_RIGHT
    JUMP MAIN

SET_LEFT:
    MOVI R0, 0x01
    MOVI R3, 0x21
    STR  R3, R0
    JUMP PREP_FRAME
SET_RIGHT:
    MOVI R0, 0x00
    MOVI R3, 0x21
    STR  R3, R0
    JUMP PREP_FRAME

CHECK_SWITCH:
    INP  R0, 0x31
    MOVI R3, 0x23
    LDR  R1, R3
    CMP  R0, R1
    JZ   CHECK_TICK
    STR  R3, R0
    JUMP PREP_FRAME

CHECK_TICK:
    INP  R0, 0x12
    MOVI R1, 0x01
    AND  R0, R1
    CMP  R0, R1
    JZ   STEP
    JUMP MAIN

STEP:
    MOVI R3, 0x21
    LDR  R0, R3
    MOVI R1, 0x00
    CMP  R0, R1
    JZ   MOVE_RIGHT
    JUMP MOVE_LEFT

MOVE_RIGHT:
    MOVI R3, 0x20
    LDR  R0, R3
    MOVI R1, 0x07
    CMP  R0, R1
    JZ   RIGHT_WRAP
    ADDI R0, 0x01
    STR  R3, R0
    JUMP RENDER_PATTERN
RIGHT_WRAP:
    MOVI R0, 0x00
    STR  R3, R0
    JUMP RENDER_PATTERN

MOVE_LEFT:
    MOVI R3, 0x20
    LDR  R0, R3
    MOVI R1, 0x00
    CMP  R0, R1
    JZ   LEFT_WRAP
    MOVI R1, 0x01
    SUB  R0, R1
    STR  R3, R0
    JUMP RENDER_PATTERN
LEFT_WRAP:
    MOVI R0, 0x07
    STR  R3, R0

RENDER_PATTERN:
    MOVI R3, 0x20
    LDR  R0, R3
    MOVI R1, 0x01
PATTERN_LOOP:
    MOVI R2, 0x00
    CMP  R0, R2
    JZ   PATTERN_READY
    ADDR R1, R1
    MOVI R2, 0x01
    SUB  R0, R2
    JUMP PATTERN_LOOP
PATTERN_READY:
    OUP  0x30, R1
    MOVI R3, 0x25
    STR  R3, R1

PREP_FRAME:
    MOVI R0, 0x00
    MOVI R1, 0xA5
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R1, 0x04
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R1, 0x0C
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R1, 0x03
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R3, 0x22
    LDR  R1, R3
    STR  R0, R1
    ADDI R1, 0x01
    STR  R3, R1
    ADDI R0, 0x01
    MOVI R3, 0x25
    LDR  R1, R3
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R3, 0x20
    LDR  R1, R3
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R3, 0x21
    LDR  R1, R3
    STR  R0, R1
    ADDI R0, 0x01
    INP  R1, 0x31
    MOVI R3, 0x23
    STR  R3, R1
    MOVR R2, R1
    MOVI R3, 0x03
    AND  R2, R3
    STR  R0, R2
    ADDI R0, 0x01
    STR  R0, R1
    ADDI R0, 0x01
    MOVI R3, 0x24
    LDR  R1, R3
    STR  R0, R1

CHECKSUM_INIT:
    MOVI R0, 0x00
    MOVI R1, 0x00
CHECKSUM_LOOP:
    LDR  R2, R0
    XOR  R1, R2
    ADDI R0, 0x01
    MOVI R3, 0x0B
    CMP  R0, R3
    JZ   CHECKSUM_DONE
    JUMP CHECKSUM_LOOP
CHECKSUM_DONE:
    STR  R0, R1
    MOVI R3, 0x00

SEND_LOOP:
    LDR  R0, R3
SEND_WAIT:
    INP  R1, 0x11
    MOVI R2, 0x02
    AND  R1, R2
    CMP  R1, R2
    JZ   SEND_BYTE
    JUMP SEND_WAIT
SEND_BYTE:
    OUP  0x10, R0
    ADDI R3, 0x01
    MOVI R2, 0x0C
    CMP  R3, R2
    JZ   SEND_DONE
    JUMP SEND_LOOP
SEND_DONE:
    JUMP MAIN

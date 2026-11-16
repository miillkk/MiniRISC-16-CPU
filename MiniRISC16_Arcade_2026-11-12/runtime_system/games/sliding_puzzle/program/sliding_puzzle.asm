; Commands: 3..6 initialize size; wasd move blank; ? snapshot.
; Snapshot: A5, size, then N*N tile bytes. Board lives at RAM 0..35.
; RAM 64=size, 65=count, 66=blank, 67=row, 68=column.
    MOVI R0, 4
    JMPA INIT
MAIN:
    INP R0, 0x11
    MOVI R1, 1
    AND R0, R1
    CMP R0, R1
    JZ READ
    JUMP MAIN
READ:
    INP R0, 0x10
    MOVI R1, 51
    CMP R0, R1
    JZ SIZE
    ADDI R1, 1
    CMP R0, R1
    JZ SIZE
    ADDI R1, 1
    CMP R0, R1
    JZ SIZE
    ADDI R1, 1
    CMP R0, R1
    JZ SIZE
    MOVI R1, 119
    CMP R0, R1
    JZ UP
    MOVI R1, 115
    CMP R0, R1
    JZ DOWN
    MOVI R1, 97
    CMP R0, R1
    JZ LEFT
    MOVI R1, 100
    CMP R0, R1
    JZ RIGHT
    JMPA SEND
SIZE:
    MOVI R1, 48
    SUB R0, R1
INIT:
    MOVI R3, 64
    STR R3, R0
    MOVR R1, R0
    MOVI R2, 0
MULT:
    ADDR R2, R0
    MOVI R3, 1
    SUB R1, R3
    MOVI R3, 0
    CMP R1, R3
    JZ FILL_START
    JUMP MULT
FILL_START:
    MOVI R3, 65
    STR R3, R2
    MOVI R3, 1
    SUB R2, R3
    SUB R0, R3
    MOVI R3, 66
    STR R3, R2
    ADDI R3, 1
    STR R3, R0
    ADDI R3, 1
    STR R3, R0
    MOVI R0, 0
    MOVI R1, 1
FILL:
    STR R0, R1
    ADDI R0, 1
    ADDI R1, 1
    CMP R0, R2
    JZ ZERO
    JUMP FILL
ZERO:
    MOVI R1, 0
    STR R0, R1
    JMPA SEND
UP:
    MOVI R3, 67
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ INVALID
    MOVI R1, 1
    SUB R0, R1
    STR R3, R0
    MOVI R3, 64
    LDR R1, R3
    MOVI R3, 66
    LDR R0, R3
    SUB R0, R1
    JUMP SWAP
DOWN:
    MOVI R3, 64
    LDR R1, R3
    MOVI R2, 1
    SUB R1, R2
    MOVI R3, 67
    LDR R0, R3
    CMP R0, R1
    JZ INVALID
    ADDI R0, 1
    STR R3, R0
    ADDI R1, 1
    MOVI R3, 66
    LDR R0, R3
    ADDR R0, R1
    JUMP SWAP
LEFT:
    MOVI R3, 68
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ INVALID
    MOVI R1, 1
    SUB R0, R1
    STR R3, R0
    MOVI R3, 66
    LDR R0, R3
    SUB R0, R1
    JUMP SWAP
RIGHT:
    MOVI R3, 64
    LDR R1, R3
    MOVI R2, 1
    SUB R1, R2
    MOVI R3, 68
    LDR R0, R3
    CMP R0, R1
    JZ INVALID
    ADDI R0, 1
    STR R3, R0
    MOVI R3, 66
    LDR R0, R3
    ADDI R0, 1
SWAP:
    LDR R1, R0
    LDR R2, R3
    STR R2, R1
    MOVI R1, 0
    STR R0, R1
    STR R3, R0
INVALID:
SEND:
    MOVI R0, 165
WAIT_HEADER:
    INP R1, 0x11
    MOVI R2, 2
    AND R1, R2
    CMP R1, R2
    JZ HEADER
    JUMP WAIT_HEADER
HEADER:
    OUP 0x10, R0
    MOVI R3, 64
    LDR R0, R3
WAIT_SIZE:
    INP R1, 0x11
    MOVI R2, 2
    AND R1, R2
    CMP R1, R2
    JZ SIZE_OUT
    JUMP WAIT_SIZE
SIZE_OUT:
    OUP 0x10, R0
    MOVI R3, 0
NEXT:
    LDR R0, R3
WAIT_TILE:
    INP R1, 0x11
    MOVI R2, 2
    AND R1, R2
    CMP R1, R2
    JZ TILE_OUT
    JUMP WAIT_TILE
TILE_OUT:
    OUP 0x10, R0
    ADDI R3, 1
    MOVI R2, 65
    LDR R1, R2
    CMP R3, R1
    JZ DONE
    JUMP NEXT
DONE:
    JMPA MAIN

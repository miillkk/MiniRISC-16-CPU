; Generated CPU chess rules (4K runtime required).
    MOVI R0, 0
    MOVI R3, 132
    STR R3, R0
    JMPA RESET
PSEUDO:
    MOVI R0, 0
    MOVI R3, 133
    STR R3, R0
    MOVI R3, 134
    LDR R0, R3
    MOVI R1, 136
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b1
    JMPA b1e
b1:
    JMPA nz0
b1e:
    JMPA P_BAD
nz0:
    MOVI R3, 136
    LDR R0, R3
    MOVI R1, 136
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b3
    JMPA b3e
b3:
    JMPA nz2
b3e:
    JMPA P_BAD
nz2:
    MOVI R3, 134
    LDR R0, R3
    MOVI R3, 136
    LDR R1, R3
    CMP R0, R1
    JZ b4
    JMPA b4e
b4:
    JMPA P_BAD
b4e:
    MOVI R3, 134
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 137
    STR R3, R0
    MOVI R3, 137
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b5
    JMPA b5e
b5:
    JMPA P_BAD
b5e:
    MOVI R3, 137
    LDR R0, R3
    MOVI R1, 8
    AND R0, R1
    MOVI R3, 138
    STR R3, R0
    MOVI R3, 138
    LDR R0, R3
    MOVI R3, 139
    LDR R1, R3
    CMP R0, R1
    JZ b6
    JMPA b6e
b6:
    JMPA P_OWN
b6e:
    JMPA P_BAD
P_OWN:
    MOVI R3, 136
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 140
    STR R3, R0
    MOVI R3, 137
    LDR R0, R3
    MOVI R1, 7
    AND R0, R1
    MOVI R3, 141
    STR R3, R0
    MOVI R3, 136
    LDR R0, R3
    MOVI R3, 134
    LDR R1, R3
    SUB R0, R1
    MOVI R3, 142
    STR R3, R0
    MOVI R3, 143
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b7
    JMPA b7e
b7:
    JMPA P_TYPE
b7e:
    MOVI R3, 140
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b8
    JMPA b8e
b8:
    JMPA P_TYPE
b8e:
    MOVI R3, 140
    LDR R0, R3
    MOVI R1, 8
    AND R0, R1
    MOVI R3, 144
    STR R3, R0
    MOVI R3, 144
    LDR R0, R3
    MOVI R3, 139
    LDR R1, R3
    CMP R0, R1
    JZ b9
    JMPA b9e
b9:
    JMPA P_BAD
b9e:
    MOVI R3, 140
    LDR R0, R3
    MOVI R1, 7
    AND R0, R1
    MOVI R3, 145
    STR R3, R0
    MOVI R3, 145
    LDR R0, R3
    MOVI R1, 6
    CMP R0, R1
    JZ b10
    JMPA b10e
b10:
    JMPA P_BAD
b10e:
P_TYPE:
    MOVI R3, 141
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b11
    JMPA b11e
b11:
    JMPA PAWN
b11e:
    MOVI R3, 141
    LDR R0, R3
    MOVI R1, 2
    CMP R0, R1
    JZ b12
    JMPA b12e
b12:
    JMPA KNIGHT
b12e:
    MOVI R3, 141
    LDR R0, R3
    MOVI R1, 6
    CMP R0, R1
    JZ b13
    JMPA b13e
b13:
    JMPA KING
b13e:
    MOVI R0, 0
    MOVI R3, 146
    STR R3, R0
RAY_DIR:
    MOVI R3, 146
    LDR R0, R3
    MOVI R1, 8
    CMP R0, R1
    JZ b14
    JMPA b14e
b14:
    JMPA P_BAD
b14e:
    MOVI R3, 141
    LDR R0, R3
    MOVI R1, 5
    CMP R0, R1
    JZ b15
    JMPA b15e
b15:
    JMPA RAY_PICK
b15e:
    MOVI R3, 141
    LDR R0, R3
    MOVI R1, 3
    CMP R0, R1
    JZ b16
    JMPA b16e
b16:
    JMPA BISHOP_DIR
b16e:
    MOVI R3, 146
    LDR R0, R3
    MOVI R1, 4
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b18
    JMPA b18e
b18:
    JMPA nz17
b18e:
    JMPA P_BAD
nz17:
    JMPA RAY_PICK
BISHOP_DIR:
    MOVI R3, 146
    LDR R0, R3
    MOVI R1, 4
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b20
    JMPA b20e
b20:
    JMPA nz19
b20e:
    JMPA RAY_PICK
nz19:
    MOVI R0, 4
    MOVI R3, 146
    STR R3, R0
RAY_PICK:
    MOVI R3, 146
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b21
    JMPA b21e
b21:
    JMPA DIR0
b21e:
    MOVI R3, 146
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b22
    JMPA b22e
b22:
    JMPA DIR1
b22e:
    MOVI R3, 146
    LDR R0, R3
    MOVI R1, 2
    CMP R0, R1
    JZ b23
    JMPA b23e
b23:
    JMPA DIR2
b23e:
    MOVI R3, 146
    LDR R0, R3
    MOVI R1, 3
    CMP R0, R1
    JZ b24
    JMPA b24e
b24:
    JMPA DIR3
b24e:
    MOVI R3, 146
    LDR R0, R3
    MOVI R1, 4
    CMP R0, R1
    JZ b25
    JMPA b25e
b25:
    JMPA DIR4
b25e:
    MOVI R3, 146
    LDR R0, R3
    MOVI R1, 5
    CMP R0, R1
    JZ b26
    JMPA b26e
b26:
    JMPA DIR5
b26e:
    MOVI R3, 146
    LDR R0, R3
    MOVI R1, 6
    CMP R0, R1
    JZ b27
    JMPA b27e
b27:
    JMPA DIR6
b27e:
    MOVI R3, 146
    LDR R0, R3
    MOVI R1, 7
    CMP R0, R1
    JZ b28
    JMPA b28e
b28:
    JMPA DIR7
b28e:
DIR0:
    MOVI R0, 1
    MOVI R3, 147
    STR R3, R0
    JMPA RAY_START
DIR1:
    MOVI R0, 0
    MOVI R1, 1
    SUB R0, R1
    MOVI R3, 147
    STR R3, R0
    JMPA RAY_START
DIR2:
    MOVI R0, 16
    MOVI R3, 147
    STR R3, R0
    JMPA RAY_START
DIR3:
    MOVI R0, 0
    MOVI R1, 16
    SUB R0, R1
    MOVI R3, 147
    STR R3, R0
    JMPA RAY_START
DIR4:
    MOVI R0, 15
    MOVI R3, 147
    STR R3, R0
    JMPA RAY_START
DIR5:
    MOVI R0, 0
    MOVI R1, 15
    SUB R0, R1
    MOVI R3, 147
    STR R3, R0
    JMPA RAY_START
DIR6:
    MOVI R0, 17
    MOVI R3, 147
    STR R3, R0
    JMPA RAY_START
DIR7:
    MOVI R0, 0
    MOVI R1, 17
    SUB R0, R1
    MOVI R3, 147
    STR R3, R0
    JMPA RAY_START
RAY_START:
    MOVI R3, 134
    LDR R0, R3
    MOVI R3, 148
    STR R3, R0
RAY:
    MOVI R3, 148
    LDR R0, R3
    MOVI R3, 147
    LDR R1, R3
    ADDR R0, R1
    MOVI R3, 148
    STR R3, R0
    MOVI R3, 148
    LDR R0, R3
    MOVI R1, 136
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b30
    JMPA b30e
b30:
    JMPA nz29
b30e:
    JMPA RAY_NEXT
nz29:
    MOVI R3, 148
    LDR R0, R3
    MOVI R3, 136
    LDR R1, R3
    CMP R0, R1
    JZ b31
    JMPA b31e
b31:
    JMPA P_GOOD
b31e:
    MOVI R3, 148
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b33
    JMPA b33e
b33:
    JMPA nz32
b33e:
    JMPA RAY_NEXT
nz32:
    JMPA RAY
RAY_NEXT:
    MOVI R3, 146
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 146
    STR R3, R0
    JMPA RAY_DIR
KNIGHT:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 14
    CMP R0, R1
    JZ b34
    JMPA b34e
b34:
    JMPA P_GOOD
b34e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 0
    MOVI R2, 14
    SUB R1, R2
    CMP R0, R1
    JZ b35
    JMPA b35e
b35:
    JMPA P_GOOD
b35e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 18
    CMP R0, R1
    JZ b36
    JMPA b36e
b36:
    JMPA P_GOOD
b36e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 0
    MOVI R2, 18
    SUB R1, R2
    CMP R0, R1
    JZ b37
    JMPA b37e
b37:
    JMPA P_GOOD
b37e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 31
    CMP R0, R1
    JZ b38
    JMPA b38e
b38:
    JMPA P_GOOD
b38e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 0
    MOVI R2, 31
    SUB R1, R2
    CMP R0, R1
    JZ b39
    JMPA b39e
b39:
    JMPA P_GOOD
b39e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 33
    CMP R0, R1
    JZ b40
    JMPA b40e
b40:
    JMPA P_GOOD
b40e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 0
    MOVI R2, 33
    SUB R1, R2
    CMP R0, R1
    JZ b41
    JMPA b41e
b41:
    JMPA P_GOOD
b41e:
    JMPA P_BAD
KING:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b42
    JMPA b42e
b42:
    JMPA P_GOOD
b42e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 0
    MOVI R2, 1
    SUB R1, R2
    CMP R0, R1
    JZ b43
    JMPA b43e
b43:
    JMPA P_GOOD
b43e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 16
    CMP R0, R1
    JZ b44
    JMPA b44e
b44:
    JMPA P_GOOD
b44e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 0
    MOVI R2, 16
    SUB R1, R2
    CMP R0, R1
    JZ b45
    JMPA b45e
b45:
    JMPA P_GOOD
b45e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 15
    CMP R0, R1
    JZ b46
    JMPA b46e
b46:
    JMPA P_GOOD
b46e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 0
    MOVI R2, 15
    SUB R1, R2
    CMP R0, R1
    JZ b47
    JMPA b47e
b47:
    JMPA P_GOOD
b47e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 17
    CMP R0, R1
    JZ b48
    JMPA b48e
b48:
    JMPA P_GOOD
b48e:
    MOVI R3, 142
    LDR R0, R3
    MOVI R1, 0
    MOVI R2, 17
    SUB R1, R2
    CMP R0, R1
    JZ b49
    JMPA b49e
b49:
    JMPA P_GOOD
b49e:
    JMPA P_BAD
PAWN:
    MOVI R3, 139
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b50
    JMPA b50e
b50:
    JMPA PAWN_WHITE
b50e:
    MOVI R0, 0
    MOVI R1, 16
    SUB R0, R1
    MOVI R3, 150
    STR R3, R0
    MOVI R0, 96
    MOVI R3, 151
    STR R3, R0
    JMPA PAWN_READY
PAWN_WHITE:
    MOVI R0, 16
    MOVI R3, 150
    STR R3, R0
    MOVI R0, 16
    MOVI R3, 151
    STR R3, R0
PAWN_READY:
    MOVI R3, 150
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 142
    LDR R0, R3
    MOVI R3, 149
    LDR R1, R3
    CMP R0, R1
    JZ b51
    JMPA b51e
b51:
    JMPA PAWN_CAPTURE
b51e:
    MOVI R3, 150
    LDR R0, R3
    MOVI R1, 1
    SUB R0, R1
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 142
    LDR R0, R3
    MOVI R3, 149
    LDR R1, R3
    CMP R0, R1
    JZ b52
    JMPA b52e
b52:
    JMPA PAWN_CAPTURE
b52e:
    MOVI R3, 143
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b53
    JMPA b53e
b53:
    JMPA P_BAD
b53e:
    MOVI R3, 140
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b55
    JMPA b55e
b55:
    JMPA nz54
b55e:
    JMPA P_BAD
nz54:
    MOVI R3, 142
    LDR R0, R3
    MOVI R3, 150
    LDR R1, R3
    CMP R0, R1
    JZ b56
    JMPA b56e
b56:
    JMPA P_GOOD
b56e:
    MOVI R3, 150
    LDR R0, R3
    MOVI R3, 150
    LDR R1, R3
    ADDR R0, R1
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 142
    LDR R0, R3
    MOVI R3, 149
    LDR R1, R3
    CMP R0, R1
    JZ b57
    JMPA b57e
b57:
    JMPA PAWN_DOUBLE
b57e:
    JMPA P_BAD
PAWN_DOUBLE:
    MOVI R3, 134
    LDR R0, R3
    MOVI R1, 112
    AND R0, R1
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R3, 151
    LDR R1, R3
    CMP R0, R1
    JZ b58
    JMPA b58e
b58:
    JMPA PAWN_PATH
b58e:
    JMPA P_BAD
PAWN_PATH:
    MOVI R3, 134
    LDR R0, R3
    MOVI R3, 150
    LDR R1, R3
    ADDR R0, R1
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b59
    JMPA b59e
b59:
    JMPA P_GOOD
b59e:
    JMPA P_BAD
PAWN_CAPTURE:
    MOVI R3, 143
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b60
    JMPA b60e
b60:
    JMPA P_GOOD
b60e:
    MOVI R3, 140
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b62
    JMPA b62e
b62:
    JMPA nz61
b62e:
    JMPA P_GOOD
nz61:
    MOVI R3, 136
    LDR R0, R3
    MOVI R3, 152
    LDR R1, R3
    CMP R0, R1
    JZ b63
    JMPA b63e
b63:
    JMPA PAWN_EP
b63e:
    JMPA P_BAD
PAWN_EP:
    MOVI R3, 136
    LDR R0, R3
    MOVI R3, 150
    LDR R1, R3
    SUB R0, R1
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 139
    LDR R0, R3
    MOVI R1, 8
    XOR R0, R1
    MOVI R3, 153
    STR R3, R0
    MOVI R3, 153
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 153
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R3, 153
    LDR R1, R3
    CMP R0, R1
    JZ b64
    JMPA b64e
b64:
    JMPA P_GOOD
b64e:
    JMPA P_BAD
P_GOOD:
    MOVI R0, 1
    MOVI R3, 133
    STR R3, R0
    JMPA end_PSEUDO
P_BAD:
    MOVI R0, 0
    MOVI R3, 133
    STR R3, R0
    JMPA end_PSEUDO
ATTACK:
    MOVI R0, 0
    MOVI R3, 154
    STR R3, R0
    MOVI R0, 1
    MOVI R3, 143
    STR R3, R0
A_LOOP:
    MOVI R3, 154
    LDR R0, R3
    MOVI R1, 136
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b66
    JMPA b66e
b66:
    JMPA nz65
b66e:
    JMPA A_NEXT
nz65:
    MOVI R3, 154
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b67
    JMPA b67e
b67:
    JMPA A_NEXT
b67e:
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 8
    AND R0, R1
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R3, 155
    LDR R1, R3
    CMP R0, R1
    JZ b68
    JMPA b68e
b68:
    JMPA A_TRY
b68e:
    JMPA A_NEXT
A_TRY:
    MOVI R3, 154
    LDR R0, R3
    MOVI R3, 134
    STR R3, R0
    MOVI R3, 156
    LDR R0, R3
    MOVI R3, 136
    STR R3, R0
    MOVI R3, 155
    LDR R0, R3
    MOVI R3, 139
    STR R3, R0
    MOVI R0, 1
    MOVI R3, 157
    STR R3, R0
    JMPA PSEUDO
ret69:
    MOVI R3, 133
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b70
    JMPA b70e
b70:
    JMPA A_YES
b70e:
A_NEXT:
    MOVI R3, 154
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 154
    STR R3, R0
    MOVI R3, 154
    LDR R0, R3
    MOVI R1, 128
    CMP R0, R1
    JZ b71
    JMPA b71e
b71:
    JMPA A_NO
b71e:
    JMPA A_LOOP
A_YES:
    MOVI R0, 1
    MOVI R3, 133
    STR R3, R0
    JMPA end_ATTACK
A_NO:
    MOVI R0, 0
    MOVI R3, 133
    STR R3, R0
    JMPA end_ATTACK
CHECK:
    MOVI R0, 0
    MOVI R3, 158
    STR R3, R0
    MOVI R3, 159
    LDR R0, R3
    MOVI R1, 6
    ADDR R0, R1
    MOVI R3, 160
    STR R3, R0
K_FIND:
    MOVI R3, 158
    LDR R0, R3
    MOVI R1, 136
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b73
    JMPA b73e
b73:
    JMPA nz72
b73e:
    JMPA K_NEXT
nz72:
    MOVI R3, 158
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R3, 160
    LDR R1, R3
    CMP R0, R1
    JZ b74
    JMPA b74e
b74:
    JMPA K_FOUND
b74e:
K_NEXT:
    MOVI R3, 158
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 158
    STR R3, R0
    MOVI R3, 158
    LDR R0, R3
    MOVI R1, 128
    CMP R0, R1
    JZ b75
    JMPA b75e
b75:
    JMPA K_MISSING
b75e:
    JMPA K_FIND
K_FOUND:
    MOVI R3, 158
    LDR R0, R3
    MOVI R3, 156
    STR R3, R0
    MOVI R3, 159
    LDR R0, R3
    MOVI R1, 8
    XOR R0, R1
    MOVI R3, 155
    STR R3, R0
    MOVI R0, 1
    MOVI R3, 161
    STR R3, R0
    JMPA ATTACK
ret76:
    JMPA end_CHECK
K_MISSING:
    MOVI R0, 1
    MOVI R3, 133
    STR R3, R0
    JMPA end_CHECK
LEGAL:
    MOVI R0, 0
    MOVI R3, 133
    STR R3, R0
    MOVI R3, 162
    LDR R0, R3
    MOVI R1, 136
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b78
    JMPA b78e
b78:
    JMPA nz77
b78e:
    JMPA L_BAD
nz77:
    MOVI R3, 163
    LDR R0, R3
    MOVI R1, 136
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b80
    JMPA b80e
b80:
    JMPA nz79
b80e:
    JMPA L_BAD
nz79:
    MOVI R3, 162
    LDR R0, R3
    MOVI R3, 163
    LDR R1, R3
    CMP R0, R1
    JZ b81
    JMPA b81e
b81:
    JMPA L_BAD
b81e:
    MOVI R3, 162
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 164
    STR R3, R0
    MOVI R3, 164
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b82
    JMPA b82e
b82:
    JMPA L_BAD
b82e:
    MOVI R3, 164
    LDR R0, R3
    MOVI R1, 8
    AND R0, R1
    MOVI R3, 165
    STR R3, R0
    MOVI R3, 165
    LDR R0, R3
    MOVI R3, 159
    LDR R1, R3
    CMP R0, R1
    JZ b83
    JMPA b83e
b83:
    JMPA L_OWN
b83e:
    JMPA L_BAD
L_OWN:
    MOVI R3, 163
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 166
    STR R3, R0
    MOVI R3, 164
    LDR R0, R3
    MOVI R1, 7
    AND R0, R1
    MOVI R3, 167
    STR R3, R0
    MOVI R0, 255
    MOVI R3, 168
    STR R3, R0
    MOVI R0, 255
    MOVI R3, 169
    STR R3, R0
    MOVI R0, 255
    MOVI R3, 170
    STR R3, R0
    MOVI R0, 255
    MOVI R3, 171
    STR R3, R0
    MOVI R3, 167
    LDR R0, R3
    MOVI R1, 6
    CMP R0, R1
    JZ b84
    JMPA b84e
b84:
    JMPA L_KING
b84e:
    JMPA L_NORMAL
L_KING:
    MOVI R3, 163
    LDR R0, R3
    MOVI R3, 162
    LDR R1, R3
    SUB R0, R1
    MOVI R3, 172
    STR R3, R0
    MOVI R3, 172
    LDR R0, R3
    MOVI R1, 2
    CMP R0, R1
    JZ b85
    JMPA b85e
b85:
    JMPA CASTLE
b85e:
    MOVI R3, 172
    LDR R0, R3
    MOVI R1, 0
    MOVI R2, 2
    SUB R1, R2
    CMP R0, R1
    JZ b86
    JMPA b86e
b86:
    JMPA CASTLE
b86e:
    JMPA L_NORMAL
CASTLE:
    MOVI R3, 159
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b87
    JMPA b87e
b87:
    JMPA C_WHITE
b87e:
    MOVI R0, 116
    MOVI R3, 173
    STR R3, R0
    MOVI R0, 2
    MOVI R3, 174
    STR R3, R0
    JMPA C_HOME
C_WHITE:
    MOVI R0, 4
    MOVI R3, 173
    STR R3, R0
    MOVI R0, 0
    MOVI R3, 174
    STR R3, R0
C_HOME:
    MOVI R3, 162
    LDR R0, R3
    MOVI R3, 173
    LDR R1, R3
    CMP R0, R1
    JZ b88
    JMPA b88e
b88:
    JMPA C_RIGHTS
b88e:
    JMPA L_BAD
C_RIGHTS:
    MOVI R3, 172
    LDR R0, R3
    MOVI R1, 2
    CMP R0, R1
    JZ b89
    JMPA b89e
b89:
    JMPA C_SHORT
b89e:
    MOVI R3, 174
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 174
    STR R3, R0
    MOVI R3, 173
    LDR R0, R3
    MOVI R1, 4
    SUB R0, R1
    MOVI R3, 169
    STR R3, R0
    MOVI R3, 173
    LDR R0, R3
    MOVI R1, 1
    SUB R0, R1
    MOVI R3, 170
    STR R3, R0
    MOVI R3, 173
    LDR R0, R3
    MOVI R1, 3
    SUB R0, R1
    MOVI R3, 175
    STR R3, R0
    MOVI R3, 175
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b91
    JMPA b91e
b91:
    JMPA nz90
b91e:
    JMPA L_BAD
nz90:
    JMPA C_PATH
C_SHORT:
    MOVI R3, 173
    LDR R0, R3
    MOVI R1, 3
    ADDR R0, R1
    MOVI R3, 169
    STR R3, R0
    MOVI R3, 173
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 170
    STR R3, R0
C_PATH:
    MOVI R3, 174
    LDR R0, R3
    MOVI R1, 128
    ADDR R0, R1
    MOVI R3, 176
    STR R3, R0
    MOVI R3, 176
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b92
    JMPA b92e
b92:
    JMPA L_BAD
b92e:
    MOVI R3, 169
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 159
    LDR R0, R3
    MOVI R1, 4
    ADDR R0, R1
    MOVI R3, 177
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R3, 177
    LDR R1, R3
    CMP R0, R1
    JZ b93
    JMPA b93e
b93:
    JMPA C_ROOK
b93e:
    JMPA L_BAD
C_ROOK:
    MOVI R3, 170
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b95
    JMPA b95e
b95:
    JMPA nz94
b95e:
    JMPA L_BAD
nz94:
    MOVI R3, 166
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b97
    JMPA b97e
b97:
    JMPA nz96
b97e:
    JMPA L_BAD
nz96:
    MOVI R0, 1
    MOVI R3, 178
    STR R3, R0
    JMPA CHECK
ret98:
    MOVI R3, 133
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b100
    JMPA b100e
b100:
    JMPA nz99
b100e:
    JMPA L_BAD
nz99:
    MOVI R3, 162
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
    MOVI R3, 170
    LDR R0, R3
    MOVI R3, 164
    LDR R1, R3
    STR R0, R1
    MOVI R3, 170
    LDR R0, R3
    MOVI R3, 156
    STR R3, R0
    MOVI R3, 159
    LDR R0, R3
    MOVI R1, 8
    XOR R0, R1
    MOVI R3, 155
    STR R3, R0
    MOVI R0, 2
    MOVI R3, 161
    STR R3, R0
    JMPA ATTACK
ret101:
    MOVI R3, 170
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
    MOVI R3, 162
    LDR R0, R3
    MOVI R3, 164
    LDR R1, R3
    STR R0, R1
    MOVI R3, 133
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b103
    JMPA b103e
b103:
    JMPA nz102
b103e:
    JMPA L_BAD
nz102:
    JMPA L_TRIAL
L_NORMAL:
    MOVI R3, 162
    LDR R0, R3
    MOVI R3, 134
    STR R3, R0
    MOVI R3, 163
    LDR R0, R3
    MOVI R3, 136
    STR R3, R0
    MOVI R3, 159
    LDR R0, R3
    MOVI R3, 139
    STR R3, R0
    MOVI R0, 0
    MOVI R3, 143
    STR R3, R0
    MOVI R0, 2
    MOVI R3, 157
    STR R3, R0
    JMPA PSEUDO
ret104:
    MOVI R3, 133
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b105
    JMPA b105e
b105:
    JMPA L_BAD
b105e:
    MOVI R3, 167
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b106
    JMPA b106e
b106:
    JMPA L_PAWN
b106e:
    JMPA L_TRIAL
L_PAWN:
    MOVI R3, 159
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b107
    JMPA b107e
b107:
    JMPA L_PWHITE
b107e:
    MOVI R0, 0
    MOVI R1, 16
    SUB R0, R1
    MOVI R3, 179
    STR R3, R0
    JMPA L_PREADY
L_PWHITE:
    MOVI R0, 16
    MOVI R3, 179
    STR R3, R0
L_PREADY:
    MOVI R3, 163
    LDR R0, R3
    MOVI R3, 152
    LDR R1, R3
    CMP R0, R1
    JZ b108
    JMPA b108e
b108:
    JMPA L_EP
b108e:
    JMPA L_DOUBLE
L_EP:
    MOVI R3, 166
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b110
    JMPA b110e
b110:
    JMPA nz109
b110e:
    JMPA L_DOUBLE
nz109:
    MOVI R3, 163
    LDR R0, R3
    MOVI R3, 179
    LDR R1, R3
    SUB R0, R1
    MOVI R3, 168
    STR R3, R0
L_DOUBLE:
    MOVI R3, 163
    LDR R0, R3
    MOVI R3, 162
    LDR R1, R3
    SUB R0, R1
    MOVI R3, 172
    STR R3, R0
    MOVI R3, 179
    LDR R0, R3
    MOVI R3, 179
    LDR R1, R3
    ADDR R0, R1
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 172
    LDR R0, R3
    MOVI R3, 149
    LDR R1, R3
    CMP R0, R1
    JZ b111
    JMPA b111e
b111:
    JMPA L_NEWEP
b111e:
    JMPA L_TRIAL
L_NEWEP:
    MOVI R3, 162
    LDR R0, R3
    MOVI R3, 179
    LDR R1, R3
    ADDR R0, R1
    MOVI R3, 171
    STR R3, R0
L_TRIAL:
    MOVI R3, 162
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
    MOVI R3, 163
    LDR R0, R3
    MOVI R3, 164
    LDR R1, R3
    STR R0, R1
    MOVI R3, 168
    LDR R0, R3
    MOVI R1, 255
    CMP R0, R1
    JZ b112
    JMPA b112e
b112:
    JMPA L_ROOK
b112e:
    MOVI R3, 168
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 180
    STR R3, R0
    MOVI R3, 168
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
L_ROOK:
    MOVI R3, 169
    LDR R0, R3
    MOVI R1, 255
    CMP R0, R1
    JZ b113
    JMPA b113e
b113:
    JMPA L_CHECK
b113e:
    MOVI R3, 169
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 181
    STR R3, R0
    MOVI R3, 169
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
    MOVI R3, 170
    LDR R0, R3
    MOVI R3, 181
    LDR R1, R3
    STR R0, R1
L_CHECK:
    MOVI R0, 2
    MOVI R3, 178
    STR R3, R0
    JMPA CHECK
ret114:
    MOVI R3, 133
    LDR R0, R3
    MOVI R3, 182
    STR R3, R0
    MOVI R3, 162
    LDR R0, R3
    MOVI R3, 164
    LDR R1, R3
    STR R0, R1
    MOVI R3, 163
    LDR R0, R3
    MOVI R3, 166
    LDR R1, R3
    STR R0, R1
    MOVI R3, 168
    LDR R0, R3
    MOVI R1, 255
    CMP R0, R1
    JZ b115
    JMPA b115e
b115:
    JMPA L_UNROOK
b115e:
    MOVI R3, 168
    LDR R0, R3
    MOVI R3, 180
    LDR R1, R3
    STR R0, R1
L_UNROOK:
    MOVI R3, 169
    LDR R0, R3
    MOVI R1, 255
    CMP R0, R1
    JZ b116
    JMPA b116e
b116:
    JMPA L_VERDICT
b116e:
    MOVI R3, 169
    LDR R0, R3
    MOVI R3, 181
    LDR R1, R3
    STR R0, R1
    MOVI R3, 170
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
L_VERDICT:
    MOVI R3, 182
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b117
    JMPA b117e
b117:
    JMPA L_BAD
b117e:
    MOVI R0, 1
    MOVI R3, 133
    STR R3, R0
    JMPA end_LEGAL
L_BAD:
    MOVI R0, 0
    MOVI R3, 133
    STR R3, R0
    JMPA end_LEGAL
RESET:
    MOVI R0, 0
    MOVI R3, 183
    STR R3, R0
INIT_CLEAR:
    MOVI R3, 183
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
    MOVI R3, 183
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 183
    STR R3, R0
    MOVI R3, 183
    LDR R0, R3
    MOVI R1, 128
    CMP R0, R1
    JZ b118
    JMPA b118e
b118:
    JMPA INIT_PIECES
b118e:
    JMPA INIT_CLEAR
INIT_PIECES:
    MOVI R0, 0
    MOVI R1, 4
    STR R0, R1
    MOVI R0, 16
    MOVI R1, 1
    STR R0, R1
    MOVI R0, 96
    MOVI R1, 9
    STR R0, R1
    MOVI R0, 112
    MOVI R1, 12
    STR R0, R1
    MOVI R0, 1
    MOVI R1, 2
    STR R0, R1
    MOVI R0, 17
    MOVI R1, 1
    STR R0, R1
    MOVI R0, 97
    MOVI R1, 9
    STR R0, R1
    MOVI R0, 113
    MOVI R1, 10
    STR R0, R1
    MOVI R0, 2
    MOVI R1, 3
    STR R0, R1
    MOVI R0, 18
    MOVI R1, 1
    STR R0, R1
    MOVI R0, 98
    MOVI R1, 9
    STR R0, R1
    MOVI R0, 114
    MOVI R1, 11
    STR R0, R1
    MOVI R0, 3
    MOVI R1, 5
    STR R0, R1
    MOVI R0, 19
    MOVI R1, 1
    STR R0, R1
    MOVI R0, 99
    MOVI R1, 9
    STR R0, R1
    MOVI R0, 115
    MOVI R1, 13
    STR R0, R1
    MOVI R0, 4
    MOVI R1, 6
    STR R0, R1
    MOVI R0, 20
    MOVI R1, 1
    STR R0, R1
    MOVI R0, 100
    MOVI R1, 9
    STR R0, R1
    MOVI R0, 116
    MOVI R1, 14
    STR R0, R1
    MOVI R0, 5
    MOVI R1, 3
    STR R0, R1
    MOVI R0, 21
    MOVI R1, 1
    STR R0, R1
    MOVI R0, 101
    MOVI R1, 9
    STR R0, R1
    MOVI R0, 117
    MOVI R1, 11
    STR R0, R1
    MOVI R0, 6
    MOVI R1, 2
    STR R0, R1
    MOVI R0, 22
    MOVI R1, 1
    STR R0, R1
    MOVI R0, 102
    MOVI R1, 9
    STR R0, R1
    MOVI R0, 118
    MOVI R1, 10
    STR R0, R1
    MOVI R0, 7
    MOVI R1, 4
    STR R0, R1
    MOVI R0, 23
    MOVI R1, 1
    STR R0, R1
    MOVI R0, 103
    MOVI R1, 9
    STR R0, R1
    MOVI R0, 119
    MOVI R1, 12
    STR R0, R1
    MOVI R0, 0
    MOVI R3, 159
    STR R3, R0
    MOVI R0, 0
    MOVI R3, 184
    STR R3, R0
    MOVI R0, 0
    MOVI R3, 185
    STR R3, R0
    MOVI R0, 255
    MOVI R3, 152
    STR R3, R0
    MOVI R0, 1
    MOVI R3, 128
    STR R3, R0
    MOVI R0, 1
    MOVI R3, 129
    STR R3, R0
    MOVI R0, 1
    MOVI R3, 130
    STR R3, R0
    MOVI R0, 1
    MOVI R3, 131
    STR R3, R0
    JMPA SEND
RX:
RX_WAIT:
    INP R0, 17
    MOVI R1, 1
    AND R0, R1
    CMP R0, R1
    JZ b119
    JMPA b119e
b119:
    JMPA RX_READ
b119e:
    JMPA RX_WAIT
RX_READ:
    INP R0, 16
    MOVI R3, 186
    STR R3, R0
    JMPA end_RX
MAIN:
    MOVI R0, 1
    MOVI R3, 187
    STR R3, R0
    JMPA RX
ret120:
    MOVI R3, 186
    LDR R0, R3
    MOVI R1, 240
    CMP R0, R1
    JZ b121
    JMPA b121e
b121:
    JMPA RESET
b121e:
    MOVI R3, 186
    LDR R0, R3
    MOVI R1, 244
    CMP R0, R1
    MOVR R0, R0
    JZ b122
    JMPA b122e
b122:
    JMPA MODE_AI
b122e:
    MOVI R3, 186
    LDR R0, R3
    MOVI R1, 245
    CMP R0, R1
    JZ b123
    JMPA b123e
b123:
    JMPA MODE_PVP
b123e:
    MOVI R3, 186
    LDR R0, R3
    MOVI R1, 242
    CMP R0, R1
    JZ b124
    JMPA b124e
b124:
    JMPA MOVE_RX
b124e:
    JMPA SEND
MODE_AI:
    MOVI R0, 64
    MOVI R3, 132
    STR R3, R0
    JMPA RESET
MODE_PVP:
    MOVI R0, 0
    MOVI R3, 132
    STR R3, R0
    JMPA RESET
MOVE_RX:
    MOVI R0, 2
    MOVI R3, 187
    STR R3, R0
    JMPA RX
ret125:
    MOVI R3, 186
    LDR R0, R3
    MOVI R3, 162
    STR R3, R0
    MOVI R0, 3
    MOVI R3, 187
    STR R3, R0
    JMPA RX
ret126:
    MOVI R3, 186
    LDR R0, R3
    MOVI R3, 163
    STR R3, R0
    MOVI R0, 4
    MOVI R3, 187
    STR R3, R0
    JMPA RX
ret127:
    MOVI R3, 186
    LDR R0, R3
    MOVI R3, 188
    STR R3, R0
    MOVI R0, 0
    MOVI R3, 185
    STR R3, R0
    MOVI R3, 184
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b128
    JMPA b128e
b128:
    JMPA MOVE_TRY
b128e:
    MOVI R3, 184
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b129
    JMPA b129e
b129:
    JMPA MOVE_TRY
b129e:
    JMPA SEND
MOVE_TRY:
    MOVI R0, 1
    MOVI R3, 189
    STR R3, R0
    JMPA LEGAL
ret130:
    MOVI R3, 133
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b131
    JMPA b131e
b131:
    JMPA REJECT
b131e:
    MOVI R3, 164
    LDR R0, R3
    MOVI R3, 190
    STR R3, R0
    MOVI R3, 167
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b132
    JMPA b132e
b132:
    JMPA PROMO_CHECK
b132e:
    JMPA COMMIT
PROMO_CHECK:
    MOVI R3, 163
    LDR R0, R3
    MOVI R1, 112
    AND R0, R1
    MOVI R3, 191
    STR R3, R0
    MOVI R3, 191
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b133
    JMPA b133e
b133:
    JMPA PROMO
b133e:
    MOVI R3, 191
    LDR R0, R3
    MOVI R1, 112
    CMP R0, R1
    JZ b134
    JMPA b134e
b134:
    JMPA PROMO
b134e:
    JMPA COMMIT
PROMO:
    MOVI R3, 188
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b135
    JMPA b135e
b135:
    JMPA PROMO_DEFAULT
b135e:
    MOVI R3, 188
    LDR R0, R3
    MOVI R1, 2
    CMP R0, R1
    JZ b136
    JMPA b136e
b136:
    JMPA PROMO_OK
b136e:
    MOVI R3, 188
    LDR R0, R3
    MOVI R1, 3
    CMP R0, R1
    JZ b137
    JMPA b137e
b137:
    JMPA PROMO_OK
b137e:
    MOVI R3, 188
    LDR R0, R3
    MOVI R1, 4
    CMP R0, R1
    JZ b138
    JMPA b138e
b138:
    JMPA PROMO_OK
b138e:
    MOVI R3, 188
    LDR R0, R3
    MOVI R1, 5
    CMP R0, R1
    JZ b139
    JMPA b139e
b139:
    JMPA PROMO_OK
b139e:
    JMPA REJECT
PROMO_DEFAULT:
    MOVI R0, 5
    MOVI R3, 188
    STR R3, R0
PROMO_OK:
    MOVI R3, 159
    LDR R0, R3
    MOVI R3, 188
    LDR R1, R3
    ADDR R0, R1
    MOVI R3, 190
    STR R3, R0
COMMIT:
    MOVI R3, 162
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
    MOVI R3, 163
    LDR R0, R3
    MOVI R3, 190
    LDR R1, R3
    STR R0, R1
    MOVI R3, 168
    LDR R0, R3
    MOVI R1, 255
    CMP R0, R1
    JZ b140
    JMPA b140e
b140:
    JMPA COMMIT_ROOK
b140e:
    MOVI R3, 168
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
COMMIT_ROOK:
    MOVI R3, 169
    LDR R0, R3
    MOVI R1, 255
    CMP R0, R1
    JZ b141
    JMPA b141e
b141:
    JMPA COMMIT_RIGHTS
b141e:
    MOVI R3, 169
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
    MOVI R3, 170
    LDR R0, R3
    MOVI R3, 181
    LDR R1, R3
    STR R0, R1
COMMIT_RIGHTS:
    MOVI R3, 171
    LDR R0, R3
    MOVI R3, 152
    STR R3, R0
    MOVI R3, 162
    LDR R0, R3
    MOVI R1, 4
    CMP R0, R1
    JZ b142
    JMPA b142e
b142:
    JMPA clear4
b142e:
    MOVI R3, 163
    LDR R0, R3
    MOVI R1, 4
    CMP R0, R1
    JZ b143
    JMPA b143e
b143:
    JMPA clear4
b143e:
    JMPA clear4end
clear4:
    MOVI R0, 0
    MOVI R3, 128
    STR R3, R0
    MOVI R0, 0
    MOVI R3, 129
    STR R3, R0
clear4end:
    MOVI R3, 162
    LDR R0, R3
    MOVI R1, 116
    CMP R0, R1
    JZ b144
    JMPA b144e
b144:
    JMPA clear116
b144e:
    MOVI R3, 163
    LDR R0, R3
    MOVI R1, 116
    CMP R0, R1
    JZ b145
    JMPA b145e
b145:
    JMPA clear116
b145e:
    JMPA clear116end
clear116:
    MOVI R0, 0
    MOVI R3, 130
    STR R3, R0
    MOVI R0, 0
    MOVI R3, 131
    STR R3, R0
clear116end:
    MOVI R3, 162
    LDR R0, R3
    MOVI R1, 7
    CMP R0, R1
    JZ b146
    JMPA b146e
b146:
    JMPA clear7
b146e:
    MOVI R3, 163
    LDR R0, R3
    MOVI R1, 7
    CMP R0, R1
    JZ b147
    JMPA b147e
b147:
    JMPA clear7
b147e:
    JMPA clear7end
clear7:
    MOVI R0, 0
    MOVI R3, 128
    STR R3, R0
clear7end:
    MOVI R3, 162
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b148
    JMPA b148e
b148:
    JMPA clear0
b148e:
    MOVI R3, 163
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b149
    JMPA b149e
b149:
    JMPA clear0
b149e:
    JMPA clear0end
clear0:
    MOVI R0, 0
    MOVI R3, 129
    STR R3, R0
clear0end:
    MOVI R3, 162
    LDR R0, R3
    MOVI R1, 119
    CMP R0, R1
    JZ b150
    JMPA b150e
b150:
    JMPA clear119
b150e:
    MOVI R3, 163
    LDR R0, R3
    MOVI R1, 119
    CMP R0, R1
    JZ b151
    JMPA b151e
b151:
    JMPA clear119
b151e:
    JMPA clear119end
clear119:
    MOVI R0, 0
    MOVI R3, 130
    STR R3, R0
clear119end:
    MOVI R3, 162
    LDR R0, R3
    MOVI R1, 112
    CMP R0, R1
    JZ b152
    JMPA b152e
b152:
    JMPA clear112
b152e:
    MOVI R3, 163
    LDR R0, R3
    MOVI R1, 112
    CMP R0, R1
    JZ b153
    JMPA b153e
b153:
    JMPA clear112
b153e:
    JMPA clear112end
clear112:
    MOVI R0, 0
    MOVI R3, 131
    STR R3, R0
clear112end:
    MOVI R3, 159
    LDR R0, R3
    MOVI R1, 8
    XOR R0, R1
    MOVI R3, 159
    STR R3, R0
    MOVI R0, 3
    MOVI R3, 178
    STR R3, R0
    JMPA CHECK
ret154:
    MOVI R3, 133
    LDR R0, R3
    MOVI R3, 192
    STR R3, R0
    MOVI R3, 133
    LDR R0, R3
    MOVI R3, 184
    STR R3, R0
    MOVI R0, 0
    MOVI R3, 193
    STR R3, R0
SEARCH_FROM:
    MOVI R3, 193
    LDR R0, R3
    MOVI R1, 136
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b156
    JMPA b156e
b156:
    JMPA nz155
b156e:
    JMPA SEARCH_NEXT_FROM
nz155:
    MOVI R3, 193
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b157
    JMPA b157e
b157:
    JMPA SEARCH_NEXT_FROM
b157e:
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 8
    AND R0, R1
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R3, 159
    LDR R1, R3
    CMP R0, R1
    JZ b158
    JMPA b158e
b158:
    JMPA SEARCH_START_TO
b158e:
    JMPA SEARCH_NEXT_FROM
SEARCH_START_TO:
    MOVI R0, 0
    MOVI R3, 194
    STR R3, R0
SEARCH_TO:
    MOVI R3, 194
    LDR R0, R3
    MOVI R1, 136
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b160
    JMPA b160e
b160:
    JMPA nz159
b160e:
    JMPA SEARCH_NEXT_TO
nz159:
    MOVI R3, 193
    LDR R0, R3
    MOVI R3, 162
    STR R3, R0
    MOVI R3, 194
    LDR R0, R3
    MOVI R3, 163
    STR R3, R0
    MOVI R0, 2
    MOVI R3, 189
    STR R3, R0
    JMPA LEGAL
ret161:
    MOVI R3, 133
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b162
    JMPA b162e
b162:
    JMPA TURN_READY
b162e:
SEARCH_NEXT_TO:
    MOVI R3, 194
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 194
    STR R3, R0
    MOVI R3, 194
    LDR R0, R3
    MOVI R1, 128
    CMP R0, R1
    JZ b163
    JMPA b163e
b163:
    JMPA SEARCH_NEXT_FROM
b163e:
    JMPA SEARCH_TO
SEARCH_NEXT_FROM:
    MOVI R3, 193
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 193
    STR R3, R0
    MOVI R3, 193
    LDR R0, R3
    MOVI R1, 128
    CMP R0, R1
    JZ b164
    JMPA b164e
b164:
    JMPA NO_MOVES
b164e:
    JMPA SEARCH_FROM
NO_MOVES:
    MOVI R3, 192
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b165
    JMPA b165e
b165:
    JMPA STALEMATE
b165e:
    MOVI R3, 159
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b166
    JMPA b166e
b166:
    JMPA BLACK_WINS
b166e:
    MOVI R0, 2
    MOVI R3, 184
    STR R3, R0
    JMPA SEND
BLACK_WINS:
    MOVI R0, 3
    MOVI R3, 184
    STR R3, R0
    JMPA SEND
STALEMATE:
    MOVI R0, 4
    MOVI R3, 184
    STR R3, R0
    JMPA SEND
REJECT:
    MOVI R0, 1
    MOVI R3, 185
    STR R3, R0
    JMPA SEND
TURN_READY:
    MOVI R3, 132
    LDR R0, R3
    MOVI R1, 64
    CMP R0, R1
    JZ b167
    JMPA b167e
b167:
    JMPA AI_TURN
b167e:
    JMPA SEND
AI_TURN:
    MOVI R3, 159
    LDR R0, R3
    MOVI R1, 8
    CMP R0, R1
    JZ b168
    JMPA b168e
b168:
    JMPA AI_BEGIN
b168e:
    JMPA SEND
AI_BEGIN:
    MOVI R0, 0
    MOVI R3, 195
    STR R3, R0
    MOVI R0, 255
    MOVI R3, 196
    STR R3, R0
    MOVI R0, 0
    MOVI R3, 197
    STR R3, R0
AI_FROM:
    MOVI R3, 197
    LDR R0, R3
    MOVI R1, 136
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b170
    JMPA b170e
b170:
    JMPA nz169
b170e:
    JMPA AI_NEXT_FROM
nz169:
    MOVI R3, 197
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b171
    JMPA b171e
b171:
    JMPA AI_NEXT_FROM
b171e:
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 8
    AND R0, R1
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R3, 159
    LDR R1, R3
    CMP R0, R1
    JZ b172
    JMPA b172e
b172:
    JMPA AI_START_TO
b172e:
    JMPA AI_NEXT_FROM
AI_START_TO:
    MOVI R0, 0
    MOVI R3, 198
    STR R3, R0
AI_TO:
    MOVI R3, 198
    LDR R0, R3
    MOVI R1, 136
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b174
    JMPA b174e
b174:
    JMPA nz173
b174e:
    JMPA AI_NEXT_TO
nz173:
    MOVI R3, 197
    LDR R0, R3
    MOVI R3, 162
    STR R3, R0
    MOVI R3, 198
    LDR R0, R3
    MOVI R3, 163
    STR R3, R0
    MOVI R0, 3
    MOVI R3, 189
    STR R3, R0
    JMPA LEGAL
ret175:
    MOVI R3, 133
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b176
    JMPA b176e
b176:
    JMPA AI_NEXT_TO
b176e:
    MOVI R0, 128
    MOVI R3, 199
    STR R3, R0
    MOVI R3, 166
    LDR R0, R3
    MOVI R3, 200
    STR R3, R0
    MOVI R0, 1
    MOVI R3, 201
    STR R3, R0
    JMPA VALUE
ret177:
    MOVI R3, 199
    LDR R0, R3
    MOVI R3, 202
    LDR R1, R3
    ADDR R0, R1
    MOVI R3, 199
    STR R3, R0
    MOVI R3, 168
    LDR R0, R3
    MOVI R1, 255
    CMP R0, R1
    JZ b178
    JMPA b178e
b178:
    JMPA AI_PROMOTION
b178e:
    MOVI R3, 199
    LDR R0, R3
    MOVI R1, 10
    ADDR R0, R1
    MOVI R3, 199
    STR R3, R0
AI_PROMOTION:
    MOVI R3, 164
    LDR R0, R3
    MOVI R3, 203
    STR R3, R0
    MOVI R3, 167
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b179
    JMPA b179e
b179:
    JMPA AI_PAWN
b179e:
    JMPA AI_CENTRE
AI_PAWN:
    MOVI R3, 163
    LDR R0, R3
    MOVI R1, 112
    AND R0, R1
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b180
    JMPA b180e
b180:
    JMPA AI_QUEEN
b180e:
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 112
    CMP R0, R1
    JZ b181
    JMPA b181e
b181:
    JMPA AI_QUEEN
b181e:
    JMPA AI_CENTRE
AI_QUEEN:
    MOVI R3, 159
    LDR R0, R3
    MOVI R1, 5
    ADDR R0, R1
    MOVI R3, 203
    STR R3, R0
    MOVI R3, 199
    LDR R0, R3
    MOVI R1, 80
    ADDR R0, R1
    MOVI R3, 199
    STR R3, R0
AI_CENTRE:
    MOVI R3, 163
    LDR R0, R3
    MOVI R1, 7
    AND R0, R1
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 3
    CMP R0, R1
    JZ b182
    JMPA b182e
b182:
    JMPA AI_CENTRE_FILE
b182e:
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 4
    CMP R0, R1
    JZ b183
    JMPA b183e
b183:
    JMPA AI_CENTRE_FILE
b183e:
    JMPA AI_RANK
AI_CENTRE_FILE:
    MOVI R3, 199
    LDR R0, R3
    MOVI R1, 2
    ADDR R0, R1
    MOVI R3, 199
    STR R3, R0
AI_RANK:
    MOVI R3, 163
    LDR R0, R3
    MOVI R1, 112
    AND R0, R1
    MOVI R3, 149
    STR R3, R0
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 48
    CMP R0, R1
    JZ b184
    JMPA b184e
b184:
    JMPA AI_CENTRE_RANK
b184e:
    MOVI R3, 149
    LDR R0, R3
    MOVI R1, 64
    CMP R0, R1
    JZ b185
    JMPA b185e
b185:
    JMPA AI_CENTRE_RANK
b185e:
    JMPA AI_TRIAL
AI_CENTRE_RANK:
    MOVI R3, 199
    LDR R0, R3
    MOVI R1, 2
    ADDR R0, R1
    MOVI R3, 199
    STR R3, R0
AI_TRIAL:
    MOVI R3, 162
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
    MOVI R3, 163
    LDR R0, R3
    MOVI R3, 203
    LDR R1, R3
    STR R0, R1
    MOVI R3, 168
    LDR R0, R3
    MOVI R1, 255
    CMP R0, R1
    JZ b186
    JMPA b186e
b186:
    JMPA AI_ROOK
b186e:
    MOVI R3, 168
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
AI_ROOK:
    MOVI R3, 169
    LDR R0, R3
    MOVI R1, 255
    CMP R0, R1
    JZ b187
    JMPA b187e
b187:
    JMPA AI_ATTACK
b187e:
    MOVI R3, 169
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
    MOVI R3, 170
    LDR R0, R3
    MOVI R3, 181
    LDR R1, R3
    STR R0, R1
AI_ATTACK:
    MOVI R3, 163
    LDR R0, R3
    MOVI R3, 156
    STR R3, R0
    MOVI R3, 159
    LDR R0, R3
    MOVI R1, 8
    XOR R0, R1
    MOVI R3, 155
    STR R3, R0
    MOVI R0, 3
    MOVI R3, 161
    STR R3, R0
    JMPA ATTACK
ret188:
    MOVI R3, 133
    LDR R0, R3
    MOVI R3, 204
    STR R3, R0
    MOVI R3, 162
    LDR R0, R3
    MOVI R3, 164
    LDR R1, R3
    STR R0, R1
    MOVI R3, 163
    LDR R0, R3
    MOVI R3, 166
    LDR R1, R3
    STR R0, R1
    MOVI R3, 168
    LDR R0, R3
    MOVI R1, 255
    CMP R0, R1
    JZ b189
    JMPA b189e
b189:
    JMPA AI_UNROOK
b189e:
    MOVI R3, 168
    LDR R0, R3
    MOVI R3, 180
    LDR R1, R3
    STR R0, R1
AI_UNROOK:
    MOVI R3, 169
    LDR R0, R3
    MOVI R1, 255
    CMP R0, R1
    JZ b190
    JMPA b190e
b190:
    JMPA AI_SCORE
b190e:
    MOVI R3, 169
    LDR R0, R3
    MOVI R3, 181
    LDR R1, R3
    STR R0, R1
    MOVI R3, 170
    LDR R0, R3
    MOVI R1, 0
    STR R0, R1
AI_SCORE:
    MOVI R3, 204
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b191
    JMPA b191e
b191:
    JMPA AI_COMPARE
b191e:
    MOVI R3, 203
    LDR R0, R3
    MOVI R3, 200
    STR R3, R0
    MOVI R0, 2
    MOVI R3, 201
    STR R3, R0
    JMPA VALUE
ret192:
    MOVI R3, 199
    LDR R0, R3
    MOVI R3, 202
    LDR R1, R3
    SUB R0, R1
    MOVI R3, 199
    STR R3, R0
AI_COMPARE:
    MOVI R0, 0
    MOVI R3, 205
    STR R3, R0
AI_COMPARE_LOOP:
    MOVI R3, 205
    LDR R0, R3
    MOVI R3, 199
    LDR R1, R3
    CMP R0, R1
    JZ b193
    JMPA b193e
b193:
    JMPA AI_NEXT_TO
b193e:
    MOVI R3, 205
    LDR R0, R3
    MOVI R3, 195
    LDR R1, R3
    CMP R0, R1
    JZ b194
    JMPA b194e
b194:
    JMPA AI_BEST
b194e:
    MOVI R3, 205
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 205
    STR R3, R0
    JMPA AI_COMPARE_LOOP
AI_BEST:
    MOVI R3, 199
    LDR R0, R3
    MOVI R3, 195
    STR R3, R0
    MOVI R3, 162
    LDR R0, R3
    MOVI R3, 196
    STR R3, R0
    MOVI R3, 163
    LDR R0, R3
    MOVI R3, 206
    STR R3, R0
AI_NEXT_TO:
    MOVI R3, 198
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 198
    STR R3, R0
    MOVI R3, 198
    LDR R0, R3
    MOVI R1, 128
    CMP R0, R1
    JZ b195
    JMPA b195e
b195:
    JMPA AI_NEXT_FROM
b195e:
    JMPA AI_TO
AI_NEXT_FROM:
    MOVI R3, 197
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 197
    STR R3, R0
    MOVI R3, 197
    LDR R0, R3
    MOVI R1, 128
    CMP R0, R1
    JZ b196
    JMPA b196e
b196:
    JMPA AI_PLAY
b196e:
    JMPA AI_FROM
AI_PLAY:
    MOVI R3, 196
    LDR R0, R3
    MOVI R1, 255
    CMP R0, R1
    JZ b197
    JMPA b197e
b197:
    JMPA NO_MOVES
b197e:
    MOVI R3, 196
    LDR R0, R3
    MOVI R3, 162
    STR R3, R0
    MOVI R3, 206
    LDR R0, R3
    MOVI R3, 163
    STR R3, R0
    MOVI R0, 0
    MOVI R3, 188
    STR R3, R0
    MOVI R0, 0
    MOVI R3, 185
    STR R3, R0
    JMPA MOVE_TRY
VALUE:
    MOVI R3, 200
    LDR R0, R3
    MOVI R1, 7
    AND R0, R1
    MOVI R3, 207
    STR R3, R0
    MOVI R3, 207
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b198
    JMPA b198e
b198:
    JMPA VALUE_1
b198e:
    MOVI R3, 207
    LDR R0, R3
    MOVI R1, 2
    CMP R0, R1
    JZ b199
    JMPA b199e
b199:
    JMPA VALUE_2
b199e:
    MOVI R3, 207
    LDR R0, R3
    MOVI R1, 3
    CMP R0, R1
    JZ b200
    JMPA b200e
b200:
    JMPA VALUE_3
b200e:
    MOVI R3, 207
    LDR R0, R3
    MOVI R1, 4
    CMP R0, R1
    JZ b201
    JMPA b201e
b201:
    JMPA VALUE_4
b201e:
    MOVI R3, 207
    LDR R0, R3
    MOVI R1, 5
    CMP R0, R1
    JZ b202
    JMPA b202e
b202:
    JMPA VALUE_5
b202e:
    MOVI R0, 0
    MOVI R3, 202
    STR R3, R0
    JMPA end_VALUE
VALUE_1:
    MOVI R0, 10
    MOVI R3, 202
    STR R3, R0
    JMPA end_VALUE
VALUE_2:
    MOVI R0, 30
    MOVI R3, 202
    STR R3, R0
    JMPA end_VALUE
VALUE_3:
    MOVI R0, 30
    MOVI R3, 202
    STR R3, R0
    JMPA end_VALUE
VALUE_4:
    MOVI R0, 50
    MOVI R3, 202
    STR R3, R0
    JMPA end_VALUE
VALUE_5:
    MOVI R0, 90
    MOVI R3, 202
    STR R3, R0
    JMPA end_VALUE
TX:
    MOVI R3, 186
    LDR R0, R3
    MOVI R3, 208
    LDR R1, R3
    XOR R1, R0
    MOVI R3, 208
    STR R3, R1
TX_WAIT:
    INP R1, 17
    MOVI R2, 2
    AND R1, R2
    CMP R1, R2
    JZ b203
    JMPA b203e
b203:
    JMPA TX_WRITE
b203e:
    JMPA TX_WAIT
TX_WRITE:
    OUP 16, R0
    JMPA end_TX
SEND:
    MOVI R3, 159
    LDR R0, R3
    MOVI R3, 132
    LDR R1, R3
    OR R0, R1
    MOVI R3, 209
    STR R3, R0
    MOVI R0, 0
    MOVI R3, 208
    STR R3, R0
    MOVI R0, 165
    MOVI R3, 186
    STR R3, R0
    MOVI R0, 1
    MOVI R3, 210
    STR R3, R0
    JMPA TX
ret204:
    MOVI R0, 7
    MOVI R3, 186
    STR R3, R0
    MOVI R0, 2
    MOVI R3, 210
    STR R3, R0
    JMPA TX
ret205:
    MOVI R3, 209
    LDR R0, R3
    MOVI R3, 186
    STR R3, R0
    MOVI R0, 3
    MOVI R3, 210
    STR R3, R0
    JMPA TX
ret206:
    MOVI R3, 184
    LDR R0, R3
    MOVI R3, 186
    STR R3, R0
    MOVI R0, 4
    MOVI R3, 210
    STR R3, R0
    JMPA TX
ret207:
    MOVI R3, 185
    LDR R0, R3
    MOVI R3, 186
    STR R3, R0
    MOVI R0, 5
    MOVI R3, 210
    STR R3, R0
    JMPA TX
ret208:
    MOVI R0, 0
    MOVI R3, 183
    STR R3, R0
SEND_BOARD:
    MOVI R3, 183
    LDR R0, R3
    MOVI R1, 136
    AND R0, R1
    MOVI R3, 135
    STR R3, R0
    MOVI R3, 135
    LDR R0, R3
    MOVI R1, 0
    CMP R0, R1
    JZ b210
    JMPA b210e
b210:
    JMPA nz209
b210e:
    JMPA SEND_NEXT
nz209:
    MOVI R3, 183
    LDR R0, R3
    LDR R0, R0
    MOVI R3, 186
    STR R3, R0
    MOVI R0, 6
    MOVI R3, 210
    STR R3, R0
    JMPA TX
ret211:
SEND_NEXT:
    MOVI R3, 183
    LDR R0, R3
    MOVI R1, 1
    ADDR R0, R1
    MOVI R3, 183
    STR R3, R0
    MOVI R3, 183
    LDR R0, R3
    MOVI R1, 128
    CMP R0, R1
    JZ b212
    JMPA b212e
b212:
    JMPA SEND_SUM
b212e:
    JMPA SEND_BOARD
SEND_SUM:
    MOVI R3, 208
    LDR R0, R3
    MOVI R3, 186
    STR R3, R0
    MOVI R0, 7
    MOVI R3, 210
    STR R3, R0
    JMPA TX
ret213:
    JMPA MAIN
end_PSEUDO:
    MOVI R3, 157
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b214
    JMPA b214e
b214:
    JMPA ret69
b214e:
    MOVI R3, 157
    LDR R0, R3
    MOVI R1, 2
    CMP R0, R1
    JZ b215
    JMPA b215e
b215:
    JMPA ret104
b215e:
    JMPA RESET
end_ATTACK:
    MOVI R3, 161
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b216
    JMPA b216e
b216:
    JMPA ret76
b216e:
    MOVI R3, 161
    LDR R0, R3
    MOVI R1, 2
    CMP R0, R1
    JZ b217
    JMPA b217e
b217:
    JMPA ret101
b217e:
    MOVI R3, 161
    LDR R0, R3
    MOVI R1, 3
    CMP R0, R1
    JZ b218
    JMPA b218e
b218:
    JMPA ret188
b218e:
    JMPA RESET
end_CHECK:
    MOVI R3, 178
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b219
    JMPA b219e
b219:
    JMPA ret98
b219e:
    MOVI R3, 178
    LDR R0, R3
    MOVI R1, 2
    CMP R0, R1
    JZ b220
    JMPA b220e
b220:
    JMPA ret114
b220e:
    MOVI R3, 178
    LDR R0, R3
    MOVI R1, 3
    CMP R0, R1
    JZ b221
    JMPA b221e
b221:
    JMPA ret154
b221e:
    JMPA RESET
end_RX:
    MOVI R3, 187
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b222
    JMPA b222e
b222:
    JMPA ret120
b222e:
    MOVI R3, 187
    LDR R0, R3
    MOVI R1, 2
    CMP R0, R1
    JZ b223
    JMPA b223e
b223:
    JMPA ret125
b223e:
    MOVI R3, 187
    LDR R0, R3
    MOVI R1, 3
    CMP R0, R1
    JZ b224
    JMPA b224e
b224:
    JMPA ret126
b224e:
    MOVI R3, 187
    LDR R0, R3
    MOVI R1, 4
    CMP R0, R1
    JZ b225
    JMPA b225e
b225:
    JMPA ret127
b225e:
    JMPA RESET
end_LEGAL:
    MOVI R3, 189
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b226
    JMPA b226e
b226:
    JMPA ret130
b226e:
    MOVI R3, 189
    LDR R0, R3
    MOVI R1, 2
    CMP R0, R1
    JZ b227
    JMPA b227e
b227:
    JMPA ret161
b227e:
    MOVI R3, 189
    LDR R0, R3
    MOVI R1, 3
    CMP R0, R1
    JZ b228
    JMPA b228e
b228:
    JMPA ret175
b228e:
    JMPA RESET
end_VALUE:
    MOVI R3, 201
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b229
    JMPA b229e
b229:
    JMPA ret177
b229e:
    MOVI R3, 201
    LDR R0, R3
    MOVI R1, 2
    CMP R0, R1
    JZ b230
    JMPA b230e
b230:
    JMPA ret192
b230e:
    JMPA RESET
end_TX:
    MOVI R3, 210
    LDR R0, R3
    MOVI R1, 1
    CMP R0, R1
    JZ b231
    JMPA b231e
b231:
    JMPA ret204
b231e:
    MOVI R3, 210
    LDR R0, R3
    MOVI R1, 2
    CMP R0, R1
    JZ b232
    JMPA b232e
b232:
    JMPA ret205
b232e:
    MOVI R3, 210
    LDR R0, R3
    MOVI R1, 3
    CMP R0, R1
    JZ b233
    JMPA b233e
b233:
    JMPA ret206
b233e:
    MOVI R3, 210
    LDR R0, R3
    MOVI R1, 4
    CMP R0, R1
    JZ b234
    JMPA b234e
b234:
    JMPA ret207
b234e:
    MOVI R3, 210
    LDR R0, R3
    MOVI R1, 5
    CMP R0, R1
    JZ b235
    JMPA b235e
b235:
    JMPA ret208
b235e:
    MOVI R3, 210
    LDR R0, R3
    MOVI R1, 6
    CMP R0, R1
    JZ b236
    JMPA b236e
b236:
    JMPA ret211
b236e:
    MOVI R3, 210
    LDR R0, R3
    MOVI R1, 7
    CMP R0, R1
    JZ b237
    JMPA b237e
b237:
    JMPA ret213
b237e:
    JMPA RESET

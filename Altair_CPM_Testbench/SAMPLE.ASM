BDOS    EQU 5
WCONF   EQU 2
CR  EQU 13
LF  EQU 10

    ORG 100H

START:  MVI C,1
NEXTR:  MVI B,1
NEXTC:  MOV A,C
    CALL    PRNUM
    MVI E,120
    CALL    PCHAR
    MOV A,B
    CALL    PRNUM
    MVI E,61
    CALL    PCHAR
    MOV A,C
    MOV D,B
    CALL    MULT
    CALL    PRNUM
    MVI E,9
    CALL    PCHAR
    INR B
    MOV A,B
    CPI 10
    JNZ NEXTC
    MVI E,CR
    CALL    PCHAR
    MVI E,LF
    CALL    PCHAR
    INR C
    MOV A,C
    CPI 10
    JNZ NEXTR
    JMP 0

MULT:   PUSH    B
    MOV B,A
    XRA A
MLOOP:  ADD B
    DCR D
    JNZ MLOOP
    POP B
    RET

PRNUM:  PUSH    B
    PUSH    D
    MVI D,0
PLOOP:  CPI 10
    JC  PDIG
    SUI 10
    INR D
    JMP PLOOP
PDIG:   MOV E,A
    MOV A,D
    CPI 0
    JZ  PONE
    ADI 48
    MOV E,A
    CALL    PCHAR
PONE:   MOV A,E
    ADI 48
    MOV E,A
    CALL    PCHAR
    POP D
    POP B
    RET

PCHAR:  PUSH    B
    PUSH    D
    PUSH    H
    MVI C,WCONF
    CALL    BDOS
    POP H
    POP D
    POP B
    RET

    END

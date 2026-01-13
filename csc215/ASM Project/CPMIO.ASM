CR  EQU 0DH
LF  EQU 0AH
CTRLZ   EQU 1AH

RCONF   EQU 1
WCONF   EQU 2

RBOOT   EQU 0
BDOS    EQU 5
TPA EQU 100H
    ORG TPA

START:  LXI SP,STAK
START1: CALL    CI
    CPI CTRLZ
    JZ  RBOOT
    CALL    CO
    JMP START1

CI: PUSH    B
    PUSH    D
    PUSH    H
    MVI C,RCONF
    CALL    BDOS
    ANI 7FH
    POP H
    POP D
    POP B
    RET

CO: PUSH    B
    PUSH    D
    PUSH    H
    MVI C,WCONF
    MOV E,A
    CALL    BDOS
    POP H
    POP D
    POP B
    RET

    DS  64
STAK:   DB  0

    END
CR  EQU 0DH
LF  EQU 0AH
CTRLZ   EQU 1AH

RCONF   EQU 1
WCONF   EQU 2

RBOOT   EQU 0
BDOS    EQU 5
TPA EQU 100H
    ORG TPA

START:  LXI SP,STAK     ; Initialize stack pointer
    XRA A           ; A = 0 (XOR A with itself)
    STA COUNTER     ; Store 0 to counter low byte
    STA COUNTER+1   ; Store 0 to counter high byte
START1: CALL    CI      ; Read character from console
    CPI CTRLZ       ; Compare with Ctrl-Z
    JZ  RBOOT       ; If Ctrl-Z, reboot CP/M
    ; Validate input is a digit (0-9)
    CPI '0'         ; Compare with ASCII '0'
    JC  START1      ; If less than '0', ignore and loop
    CPI '9'+1       ; Compare with ASCII '9'+1
    JNC START1      ; If >= ':', ignore and loop
    ; Convert ASCII digit to numeric value (0-9)
    SUI '0'         ; Subtract ASCII '0' to get numeric value
    ; Add digit value to 16-bit counter
    PUSH    PSW     ; Save digit value on stack
    LHLD    COUNTER ; Load counter into HL (H=high, L=low)
    MOV E,A         ; Move digit to E
    MVI D,0         ; D = 0, so DE = digit (0-9)
    DAD D           ; HL = HL + DE (16-bit addition)
    SHLD    COUNTER ; Store result back to counter
    POP PSW         ; Restore A (not used, but maintains stack)
    ; Output carriage return and line feed
    MVI A,CR        ; Load CR character
    CALL    CO      ; Print CR
    MVI A,LF        ; Load LF character
    CALL    CO      ; Print LF (complete newline)
    ; Display the new counter value
    CALL    PRINTNUM    ; Print counter as decimal
    ; Add blank line for readability
    MVI A,CR        ; Load CR
    CALL    CO      ; Print CR
    MVI A,LF        ; Load LF
    CALL    CO      ; Print LF
    JMP START1      ; Loop back for next input

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

; Print 16-bit number as decimal
; Converts counter value to ASCII digits and prints them
PRINTNUM:
    PUSH    B           ; Save registers
    PUSH    D
    PUSH    H
    LHLD    COUNTER     ; Load counter value into HL
    LXI D,NUMBUF+5      ; DE points to end of 6-byte buffer
    XRA A               ; A = 0
    STAX    D           ; Store null terminator at end
    ; Extract digits by repeated division by 10
PNLOOP: CALL    DIV16       ; HL = HL / 10, A = remainder (0-9)
    ADI '0'         ; Convert digit to ASCII ('0'-'9')
    DCX D           ; Move buffer pointer left
    STAX    D           ; Store ASCII digit in buffer
    MOV A,H         ; Check if quotient is zero
    ORA L           ; Set flags based on H OR L
    JNZ PNLOOP      ; If HL != 0, continue extracting digits
    ; Print digits from buffer (left to right)
PNPRINT:
    LDAX    D           ; Load character from buffer
    ORA A           ; Check if null terminator
    JZ  PNDONE      ; If null, done printing
    CALL    CO          ; Print character
    INX D           ; Move to next character
    JMP PNPRINT     ; Loop
PNDONE: POP H           ; Restore registers
    POP D
    POP B
    RET

; Divide HL by 10 using repeated subtraction
; Input:  HL = dividend (16-bit number to divide)
; Output: HL = quotient (HL / 10)
;         A  = remainder (HL mod 10, range 0-9)
; Uses:   BC as quotient accumulator
DIV16:  PUSH    B           ; Save BC register
    LXI B,0         ; BC = 0 (quotient counter)
DIV16L: ; Check if HL >= 10
    MOV A,H         ; Load high byte
    ORA A           ; Test if H != 0
    JNZ DIV16S      ; If H != 0, then HL >= 256 >= 10
    MOV A,L         ; Load low byte
    CPI 10          ; Compare L with 10
    JC  DIV16D      ; If L < 10, we're done
DIV16S: ; Subtract 10 from HL (16-bit subtraction)
    MOV A,L         ; Get low byte
    SUI 10          ; Subtract 10 from low byte
    MOV L,A         ; Store result in L
    MOV A,H         ; Get high byte
    SBI 0           ; Subtract borrow from high byte
    MOV H,A         ; Store result in H
    ; Increment quotient counter
    INX B           ; BC = BC + 1
    JMP DIV16L      ; Loop back to check again
DIV16D: ; HL now contains remainder (< 10)
    MOV A,L         ; Move remainder to A
    MOV H,B         ; Move quotient from BC to HL
    MOV L,C
    POP B           ; Restore BC
    RET

COUNTER:    DW  0       ; 16-bit counter
NUMBUF: DS  6       ; Buffer for number string

    DS  64
STAK:   DB  0

    END

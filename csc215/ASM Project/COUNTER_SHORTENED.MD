# COUNTER.ASM - Concise Reference

## Program Overview
Accumulating decimal counter for CP/M. Reads single digits (0-9), adds them to a 16-bit counter (max 65535), displays result.

**Flow**: Initialize → Read char → Validate digit → Add to counter → Display → Loop

---

## Constants
```assembly
CR      EQU 0DH         ; Carriage return
LF      EQU 0AH         ; Line feed
CTRLZ   EQU 1AH         ; Exit program
RCONF   EQU 1           ; BDOS: Read console
WCONF   EQU 2           ; BDOS: Write console
RBOOT   EQU 0           ; CP/M warm boot
BDOS    EQU 5           ; BDOS entry point
TPA     EQU 100H        ; Program load address
```

---

## Initialization
```assembly
LXI SP,STAK         ; Initialize stack pointer
XRA A               ; A = 0 (faster than MVI A,0)
STA COUNTER         ; Zero counter low byte
STA COUNTER+1       ; Zero counter high byte
```

---

## Main Loop: Input Validation
```assembly
CALL CI             ; Read character → A
CPI CTRLZ           ; Check for Ctrl-Z
JZ RBOOT            ; Exit if Ctrl-Z
CPI '0'             ; Check if < '0'
JC START1           ; Reject if below '0'
CPI '9'+1           ; Check if > '9'
JNC START1          ; Reject if above '9'
```

---

## Convert and Add
```assembly
SUI '0'             ; ASCII → numeric (e.g., '5' → 5)
PUSH PSW            ; Save digit
LHLD COUNTER        ; Load 16-bit counter → HL
MOV E,A             ; Digit → E
MVI D,0             ; DE = 16-bit digit
DAD D               ; HL = HL + DE (16-bit add)
SHLD COUNTER        ; Store new counter
POP PSW             ; Restore (balance stack)
```

---

## Display Counter
```assembly
MVI A,CR            ; Print newline
CALL CO
MVI A,LF
CALL CO
CALL PRINTNUM       ; Print counter as decimal
JMP START1          ; Loop back
```

---

## Subroutines

### CI - Console Input
```assembly
CI:     PUSH B/D/H      ; Save registers
        MVI C,RCONF     ; BDOS function 1
        CALL BDOS       ; Read char → A
        ANI 7FH         ; Strip high bit (7-bit ASCII)
        POP H/D/B       ; Restore registers
        RET
```

### CO - Console Output
```assembly
CO:     PUSH B/D/H      ; Save registers
        MVI C,WCONF     ; BDOS function 2
        MOV E,A         ; Char to print → E
        CALL BDOS       ; Print it
        POP H/D/B       ; Restore registers
        RET
```

### PRINTNUM - Binary to Decimal
Converts 16-bit binary in HL to decimal ASCII string.

```assembly
PRINTNUM:
    LHLD COUNTER        ; Load counter → HL
    LXI D,NUMBUF+5      ; Point to buffer end
    XRA A
    STAX D              ; Null terminator

PNLOOP:
    CALL DIV16          ; HL/10 → HL=quotient, A=remainder
    ADI '0'             ; Convert digit to ASCII
    DCX D               ; Move pointer left
    STAX D              ; Store digit
    MOV A,H
    ORA L               ; Check if HL == 0
    JNZ PNLOOP          ; Continue if more digits

PNPRINT:
    LDAX D              ; Get character
    ORA A               ; Check null terminator
    JZ PNDONE
    CALL CO             ; Print character
    INX D               ; Next character
    JMP PNPRINT
```

### DIV16 - Divide by 10
Divides 16-bit HL by 10 using repeated subtraction.
**Returns**: HL = quotient, A = remainder

```assembly
DIV16:
    LXI B,0             ; BC = quotient counter

DIV16L:
    MOV A,H
    ORA A               ; If H != 0, must be >= 10
    JNZ DIV16S
    MOV A,L
    CPI 10              ; If L < 10, done
    JC DIV16D

DIV16S:
    MOV A,L
    SUI 10              ; Subtract 10 from L
    MOV L,A
    MOV A,H
    SBI 0               ; Subtract borrow from H
    MOV H,A
    INX B               ; Increment quotient
    JMP DIV16L

DIV16D:
    MOV A,L             ; Remainder → A
    MOV H,B             ; Quotient BC → HL
    MOV L,C
    RET
```

---

## Data Section
```assembly
COUNTER:    DW  0       ; 16-bit counter
NUMBUF:     DS  6       ; Buffer for 5 digits + null
            DS  64      ; Stack space
STAK:       DB  0       ; Stack top marker
```

---

## Key 8080 Instructions

### Specialized/Important Instructions
- **DAD rp**: 16-bit add (HL = HL + register pair)
- **LHLD addr**: Load HL from memory (16-bit)
- **SHLD addr**: Store HL to memory (16-bit)
- **SBI data**: Subtract immediate with borrow (for 16-bit subtraction)
- **LDAX/STAX rp**: Load/store A indirect via BC/DE
- **XRA A**: Fast way to zero A (A XOR A = 0)
- **LXI rp,data**: Load 16-bit immediate into register pair

### Data Movement
- **MOV r1,r2**: Copy register to register
- **MVI r,data**: Load immediate into register
- **LDA/STA addr**: Load/store A direct

### Arithmetic
- **ADI/SUI data**: Add/subtract immediate from A
- **INR/DCR r**: Increment/decrement register (8-bit)
- **INX/DCX rp**: Increment/decrement register pair (16-bit)

### Logical
- **ANI/ORI/XRI data**: AND/OR/XOR immediate with A
- **ORA r**: OR register with A (common for testing zero)

### Comparison & Branching
- **CPI data**: Compare immediate with A (sets flags)
- **JMP/JZ/JNZ/JC/JNC addr**: Jump (unconditional/zero/not-zero/carry/no-carry)

### Stack & Subroutines
- **PUSH/POP rp**: Push/pop register pair to/from stack
- **CALL addr**: Call subroutine
- **RET**: Return from subroutine

### Assembler Directives
- **ORG addr**: Set assembly address
- **EQU value**: Define constant
- **DW value**: Define word (16-bit)
- **DS count**: Reserve storage bytes
- **DB value**: Define byte

---

## Registers
- **A**: Accumulator (arithmetic/logic operations)
- **B,C,D,E,H,L**: General purpose (8-bit)
- **BC,DE,HL**: Register pairs (16-bit operations)
- **SP**: Stack pointer
- **Flags**: Zero, Carry (most commonly used)

---

## BDOS Functions
- **Function 1**: Read console with echo (C=1, returns char in A)
- **Function 2**: Write console (C=2, char in E)

---

## Algorithm: Binary to Decimal
To convert 16-bit number to decimal string:
1. Divide by 10 → quotient and remainder
2. Remainder is rightmost digit (convert to ASCII)
3. Repeat with quotient until 0
4. Print digits in reverse order

**Example**: 347 → 347/10=34r7 → 34/10=3r4 → 3/10=0r3 → "347"

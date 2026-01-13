# COUNTER.ASM - Line-by-Line Documentation

## Overview
COUNTER.ASM is an accumulating decimal counter. It reads single digit inputs (0-9) from the user, adds them to a running total, and displays the result. Due to being limited to an unsigned 16-bit integer, the maximum value the counter can hold is 65,535 before wrapping back to 0, but with user inputs being limited to 0-9, reaching that value in basically any use case is unlikely.

## Program Flow
1. Initialize stack and counter to 0
2. Read a character from console
3. If Ctrl-Z, exit (reboot) to CP/M
4. If not a digit (0-9), ignore and loop back
5. Convert ASCII digit to numeric value
6. Add to 16-bit counter
7. Display counter value in decimal
8. Loop back to step 2

---

## Line-by-Line Explanation

### Lines 1-11: Constants and Setup
```assembly
CR  EQU 0DH
```
- **EQU**: Equate directive - defines a constant
- **CR**: Carriage Return character (ASCII 13, 0x0D)
- Returns cursor to beginning of line

```assembly
LF  EQU 0AH
```
- **LF**: Line Feed character (ASCII 10, 0x0A)
- Moves cursor down one line
- CR + LF together create a newline on most systems

```assembly
CTRLZ   EQU 1AH
```
- **CTRLZ**: Control-Z character (ASCII 26, 0x1A)
- Traditional CP/M end-of-file marker
- Used to exit the program

```assembly
RCONF   EQU 1
WCONF   EQU 2
```
- **RCONF**: BDOS function 1 - Read console with echo
- **WCONF**: BDOS function 2 - Write character to console

```assembly
RBOOT   EQU 0
BDOS    EQU 5
```
- **RBOOT**: Address 0 - CP/M warm boot (restart CP/M)
- **BDOS**: Address 5 - Entry point for BDOS (Basic Disk Operating System) calls

```assembly
TPA EQU 100H
    ORG TPA
```
- **TPA**: Transient Program Area - where CP/M programs load (address 0x0100)
- **ORG**: Origin directive - sets the assembly address
- All CP/M .COM files start at 0x0100

---

### Lines 13-16: Initialization
```assembly
START:  LXI SP,STAK
```
- **LXI**: Load register pair Immediate
- **SP**: Stack Pointer register
- **STAK**: Label pointing to stack space (defined at end of program)
- Loads the address of STAK into SP, initializing the stack

```assembly
    XRA A
```
- **XRA**: XOR Accumulator with register
- **A**: Accumulator register
- XOR-ing A with itself always produces 0
- Faster/smaller than `MVI A,0`

```assembly
    STA COUNTER
    STA COUNTER+1
```
- **STA**: Store Accumulator (direct addressing)
- Stores A (which is 0) to memory location COUNTER
- COUNTER is a 16-bit value (2 bytes)
- Initializes both low byte (COUNTER) and high byte (COUNTER+1) to 0

---

### Lines 17-24: Main Loop - Input and Validation
```assembly
START1: CALL    CI
```
- **CALL**: Call subroutine
- **CI**: Console Input routine (defined at line 49)
- Reads one character from keyboard, returns it in register A

```assembly
    CPI CTRLZ
```
- **CPI**: Compare Immediate
- Compares A with CTRLZ (0x1A)
- Sets Zero flag if equal

```assembly
    JZ  RBOOT
```
- **JZ**: Jump if Zero flag is set
- If user pressed Ctrl-Z, jump to address 0 (warm boot CP/M)
- This exits the program

```assembly
    CPI '0'
```
- Compares A with ASCII '0' (0x30)
- Checks if character is less than '0'

```assembly
    JC  START1
```
- **JC**: Jump if Carry flag is set
- Carry is set when A < '0'
- Ignores characters like space, punctuation, control codes

```assembly
    CPI '9'+1
```
- Compares A with ASCII ':' (which is '9' + 1, or 0x3A)

```assembly
    JNC START1
```
- **JNC**: Jump if No Carry
- Carry is clear when A >= '9'+1
- Ignores letters and other characters above '9'
- Together with previous check, only allows '0'-'9' through

---

### Lines 25-34: Convert and Add
```assembly
    SUI '0'
```
- **SUI**: Subtract Immediate
- Subtracts ASCII '0' (0x30) from the character
- Converts ASCII '0'-'9' to numeric 0-9
- Example: '5' (0x35) - '0' (0x30) = 5

```assembly
    PUSH    PSW
```
- **PUSH**: Push register pair onto stack
- **PSW**: Program Status Word (A register + flags)
- Saves the digit value temporarily

```assembly
    LHLD    COUNTER
```
- **LHLD**: Load HL Direct
- Loads 16-bit value from memory address COUNTER
- L = COUNTER (low byte), H = COUNTER+1 (high byte)

```assembly
    MOV E,A
```
- **MOV**: Move register to register
- Copies A to E
- Digit value now in E

```assembly
    MVI D,0
```
- **MVI**: Move Immediate to register
- Sets D = 0
- Now DE = 16-bit value of digit (0-9)

```assembly
    DAD D
```
- **DAD**: Double Add (16-bit addition)
- HL = HL + DE
- Adds the digit to the counter

```assembly
    SHLD    COUNTER
```
- **SHLD**: Store HL Direct
- Stores HL to memory address COUNTER
- Saves the new counter value

```assembly
    POP PSW
```
- **POP**: Pop from stack to register pair
- Restores A and flags (not actually used, but balances the stack)

---

### Lines 35-46: Output
```assembly
    MVI A,CR
    CALL    CO
```
- **MVI**: Move Immediate
- Loads CR character into A
- Calls Console Output to print carriage return

```assembly
    MVI A,LF
    CALL    CO
```
- Loads LF character into A
- Prints line feed
- Together with CR, creates a newline

```assembly
    CALL    PRINTNUM
```
- Calls subroutine to print the counter value as decimal

```assembly
    MVI A,CR
    CALL    CO
    MVI A,LF
    CALL    CO
```
- Prints another newline for spacing
- Separates counter output from next user input

```assembly
    JMP START1
```
- **JMP**: Unconditional jump
- Loops back to read next character

---

### Lines 49-58: CI (Console Input) Subroutine
```assembly
CI: PUSH    B
    PUSH    D
    PUSH    H
```
- **PUSH**: Save registers B, D, H (and their pairs BC, DE, HL)
- Preserves caller's register values

```assembly
    MVI C,RCONF
```
- Loads function number 1 (Read Console) into C

```assembly
    CALL    BDOS
```
- Calls BDOS (Basic Disk Operating System)
- Function 1 reads a character and echoes it
- Returns character in A

```assembly
    ANI 7FH
```
- **ANI**: AND Immediate
- Masks with 0x7F (01111111 binary)
- Strips the high bit (parity or extended ASCII)
- Ensures character is 7-bit ASCII

```assembly
    POP H
    POP D
    POP B
    RET
```
- **POP**: Restore saved registers in reverse order
- **RET**: Return from subroutine
- Character is in A when we return

---

### Lines 60-69: CO (Console Output) Subroutine
```assembly
CO: PUSH    B
    PUSH    D
    PUSH    H
```
- Save registers

```assembly
    MVI C,WCONF
```
- Loads function number 2 (Write Console) into C

```assembly
    MOV E,A
```
- BDOS function 2 expects character in E
- Copies A to E

```assembly
    CALL    BDOS
```
- Calls BDOS to print the character

```assembly
    POP H
    POP D
    POP B
    RET
```
- Restore registers and return

---

### Lines 73-100: PRINTNUM Subroutine
This routine converts a 16-bit binary number to decimal ASCII digits.

```assembly
PRINTNUM:
    PUSH    B
    PUSH    D
    PUSH    H
```
- Save all working registers

```assembly
    LHLD    COUNTER
```
- Load the counter value into HL

```assembly
    LXI D,NUMBUF+5
```
- **LXI**: Load register pair immediate
- NUMBUF is 6 bytes long (can hold 5 digits + null)
- Points DE to the END of the buffer
- We'll build the string right-to-left

```assembly
    XRA A
    STAX    D
```
- **STAX**: Store A at address in register pair
- Stores 0 (null terminator) at end of buffer

#### Digit Extraction Loop (Lines 82-88)
```assembly
PNLOOP: CALL    DIV16
```
- Divides HL by 10
- Returns: HL = quotient, A = remainder (0-9)
- Remainder is the rightmost digit

```assembly
    ADI '0'
```
- **ADI**: Add Immediate
- Converts digit (0-9) to ASCII ('0'-'9')
- Example: 7 + 0x30 = 0x37 ('7')

```assembly
    DCX D
```
- **DCX**: Decrement register pair
- Moves buffer pointer left

```assembly
    STAX    D
```
- Stores ASCII digit in buffer

```assembly
    MOV A,H
    ORA L
```
- **ORA**: OR Accumulator
- Tests if HL == 0
- Sets Zero flag if both H and L are 0

```assembly
    JNZ PNLOOP
```
- **JNZ**: Jump if Not Zero
- Continues if more digits remain

#### Print Loop (Lines 90-96)
```assembly
PNPRINT:
    LDAX    D
```
- **LDAX**: Load A from address in register pair
- Gets character from buffer

```assembly
    ORA A
    JZ  PNDONE
```
- Tests if we hit the null terminator
- Exits if zero

```assembly
    CALL    CO
```
- Prints the character

```assembly
    INX D
```
- **INX**: Increment register pair
- Moves to next character

```assembly
    JMP PNPRINT
```
- Loops back

```assembly
PNDONE: POP H
    POP D
    POP B
    RET
```
- Restore registers and return

---

### Lines 107-131: DIV16 Subroutine
Divides a 16-bit number by 10 using repeated subtraction.

```assembly
DIV16:  PUSH    B
```
- Save BC (we'll use it as quotient counter)

```assembly
    LXI B,0
```
- BC = 0 (quotient starts at zero)

#### Division Loop (Lines 109-125)
```assembly
DIV16L: MOV A,H
    ORA A
    JNZ DIV16S
```
- If high byte (H) is not zero, HL must be >= 256
- Therefore HL >= 10, so subtract

```assembly
    MOV A,L
    CPI 10
    JC  DIV16D
```
- If H was 0, check low byte
- If L < 10, we're done (can't subtract 10 anymore)

```assembly
DIV16S: MOV A,L
    SUI 10
    MOV L,A
```
- Subtract 10 from low byte
- SUI sets Carry flag if result goes negative (borrow needed)

```assembly
    MOV A,H
    SBI 0
    MOV H,A
```
- **SBI**: Subtract Immediate with Borrow
- Subtracts 0 and any borrow from high byte
- Completes the 16-bit subtraction

```assembly
    INX B
```
- Increment quotient counter

```assembly
    JMP DIV16L
```
- Loop back to subtract again

#### Finish (Lines 126-131)
```assembly
DIV16D: MOV A,L
```
- Remainder (what's left in HL) is now < 10
- Move it to A for return value

```assembly
    MOV H,B
    MOV L,C
```
- Move quotient from BC to HL
- HL now contains the quotient (original HL / 10)

```assembly
    POP B
    RET
```
- Restore BC and return

---

### Lines 133-137: Data Area
```assembly
COUNTER:    DW  0
```
- **DW**: Define Word (16-bit value)
- Reserves 2 bytes for the counter
- Initialized to 0

```assembly
NUMBUF: DS  6
```
- **DS**: Define Storage
- Reserves 6 bytes for ASCII digit buffer
- Can hold up to 5 digits + null terminator (max 65535)

```assembly
    DS  64
STAK:   DB  0
```
- **DS**: Reserves 64 bytes for stack space
- **DB**: Define Byte
- **STAK**: Label marking top of stack
- Stack grows downward from this address

---

## 8080 Instruction Summary

### Data Movement
- **MOV r1,r2**: Copy register to register
- **MVI r,data**: Load immediate value into register
- **LXI rp,data**: Load 16-bit immediate into register pair
- **LDA addr**: Load A from memory address
- **STA addr**: Store A to memory address
- **LHLD addr**: Load HL from memory address (16-bit)
- **SHLD addr**: Store HL to memory address (16-bit)
- **LDAX rp**: Load A from address in register pair (BC or DE)
- **STAX rp**: Store A to address in register pair (BC or DE)

### Arithmetic
- **ADD r**: Add register to A
- **ADI data**: Add immediate to A
- **SUB r**: Subtract register from A
- **SUI data**: Subtract immediate from A
- **SBI data**: Subtract immediate with borrow from A
- **INR r**: Increment register
- **DCR r**: Decrement register
- **INX rp**: Increment register pair (16-bit)
- **DCX rp**: Decrement register pair (16-bit)
- **DAD rp**: Add register pair to HL (16-bit)

### Logical
- **ANA r**: AND register with A
- **ANI data**: AND immediate with A
- **ORA r**: OR register with A
- **ORI data**: OR immediate with A
- **XRA r**: XOR register with A
- **XRI data**: XOR immediate with A

### Compare
- **CMP r**: Compare register with A (sets flags)
- **CPI data**: Compare immediate with A (sets flags)

### Jumps
- **JMP addr**: Unconditional jump
- **JZ addr**: Jump if Zero flag set
- **JNZ addr**: Jump if Zero flag clear
- **JC addr**: Jump if Carry flag set
- **JNC addr**: Jump if Carry flag clear

### Subroutines
- **CALL addr**: Call subroutine (push return address, jump)
- **RET**: Return from subroutine (pop return address, jump)

### Stack
- **PUSH rp**: Push register pair onto stack
- **POP rp**: Pop stack into register pair
- **LXI SP,addr**: Load stack pointer

### Special
- **ORG addr**: Assembler directive - set assembly address
- **EQU value**: Assembler directive - define constant
- **DB value**: Define byte(s) in memory
- **DW value**: Define word (16-bit) in memory
- **DS count**: Define storage (reserve bytes)

---

## Register Usage

### 8080 Registers
- **A**: Accumulator (8-bit) - primary register for arithmetic/logic
- **B, C, D, E, H, L**: General purpose (8-bit)
- **BC, DE, HL**: Register pairs (16-bit) - can be used together
- **SP**: Stack Pointer (16-bit)
- **PC**: Program Counter (16-bit) - automatically updated
- **Flags**: Zero, Carry, Sign, Parity, Auxiliary Carry

### This Program's Register Conventions
- **A**: Input/output characters, digit values, temporary calculations
- **HL**: 16-bit counter value, division operations
- **DE**: Buffer pointer for string building
- **BC**: Quotient counter in DIV16
- **SP**: Stack pointer (initialized to STAK)

---

## CP/M BDOS Functions Used

### Function 1: Read Console with Echo
- **Entry**: C = 1
- **Exit**: A = character read
- Waits for keyboard input, echoes character to screen

### Function 2: Write Console
- **Entry**: C = 2, E = character to print
- **Exit**: Character displayed on screen

---

## Algorithm: Decimal Conversion

### Problem
Convert 16-bit binary number (0-65535) to decimal ASCII string.

### Solution
Repeatedly divide by 10, collecting remainders:
1. Divide number by 10
2. Remainder is rightmost digit
3. Quotient becomes new number
4. Repeat until quotient is 0
5. Print digits in reverse order (they were collected right-to-left)

### Example: Converting 347 to ASCII
```
347 / 10 = 34 remainder 7  → Store '7'
 34 / 10 =  3 remainder 4  → Store '4'
  3 / 10 =  0 remainder 3  → Store '3'

Result: "347"
```

---

## Memory Map

```
Address     Contents
---------   --------
0x0000      CP/M warm boot vector
0x0005      BDOS entry point
...
0x0100      START: Program begins (TPA)
            Code section
            CI subroutine
            CO subroutine
            PRINTNUM subroutine
            DIV16 subroutine
0x01xx      COUNTER: 2 bytes (counter value)
0x01xx      NUMBUF: 6 bytes (ASCII buffer)
0x01xx      Stack space: 64 bytes
0x01xx      STAK: Top of stack marker
```

---

## Testing Example

```
User Input:  1
Counter:     1

User Input:  2
Counter:     3

User Input:  3
Counter:     6

User Input:  9
Counter:     15

User Input:  5
Counter:     20
```

Maximum value: 65535 (16-bit limit)
After 65535, counter wraps to 0 (overflow).

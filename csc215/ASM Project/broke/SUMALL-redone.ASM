; SUMALL.ASM - Sum all numbers in a file and write result to RESULT.TXT
; Rewritten to use library code from textbook_files
; Library code is inlined for standalone CP/M execution

CR  EQU 0DH
LF  EQU 0AH
CTRLZ   EQU 1AH

RCONF   EQU 1
WCONF   EQU 2
RBUFF   EQU 10

INITF   EQU 13
OPENF   EQU 15
CLOSF   EQU 16
FINDF   EQU 17
DELEF   EQU 19
READF   EQU 20
WRITF   EQU 21
MAKEF   EQU 22
SDMAF   EQU 26

RBOOT   EQU 0
DRIVE   EQU 4
BDOS    EQU 5
MEMAX   EQU 7
TFCB    EQU 5CH
FCBTY   EQU 65H
FCBEX   EQU 68H
FCBS2   EQU 6AH
FCBRC   EQU 6BH
FCBCR   EQU 88H
TPA EQU 100H

BDAOK   EQU 0
BDER1   EQU 1
BDER2   EQU 2
BDERR   EQU 0FFH
STAK    EQU 0FFFFH

ORG 100H

START:  LXI SP,STAK     ; Initialize stack pointer
    XRA A           ; A = 0 (XOR A with itself)
    STA COUNTER     ; Store 0 to counter low byte
    STA COUNTER+1   ; Store 0 to counter high byte
    STA TEMPNUM     ; Store 0 to temp accumulator low byte
    STA TEMPNUM+1   ; Store 0 to temp accumulator high byte
    STA INNUM       ; Not currently in a number

    ; Parse command line for filename
    ; CP/M command tail is at 80H: byte 0 = length, bytes 1-127 = command
    LDA 80H         ; Get command tail length
    ORA A           ; Check if zero
    JZ  NOARG       ; No argument provided

    ; Parse the command line and copy to FCB
    ; CP/M places first parsed FCB at 5CH (default FCB1)
    ; We'll copy it to our INFCB
    LXI H,5CH       ; HL = default FCB1 (parsed by CP/M)
    LXI D,INFCB     ; DE = our input FCB
    MVI B,36        ; Copy 36 bytes (entire FCB)
COPYFCB:
    MOV A,M         ; Get byte from default FCB
    STAX    D           ; Store to our FCB
    INX H
    INX D
    DCR B
    JNZ COPYFCB

    ; Check if a filename was actually provided (first char of name != space)
    LDA 5DH         ; Get first character of filename (5CH+1 = 5DH)
    CPI ' '         ; Check if space (no filename)
    JZ  NOARG       ; No valid filename

    ; Open input file
    LXI D,INFCB     ; DE points to input FCB
    MVI C,OPENF     ; Open file function
    CALL    BDOS
    CPI 0FFH        ; 0FFH = file not found
    JZ  NOFILE      ; Jump if file not found

    ; Set DMA to input buffer
    LXI D,DMABUF
    MVI C,SDMAF
    CALL    BDOS

READLOOP:
    ; Read from input file
    LXI D,INFCB
    MVI C,READF
    CALL    BDOS
    CPI 0           ; 0 = successful read
    JNZ READDONE    ; Non-zero = EOF or error

    ; Process buffer - parse numbers and add to counter
    LXI H,DMABUF    ; HL points to start of buffer
    MVI B,128       ; B = bytes to process (CP/M sector size)

PROCBUF:
    MOV A,M         ; Get character from buffer
    CPI CTRLZ       ; Check for EOF marker
    JZ  ENDNUM      ; Finalize current number if any, then done
    CPI CR          ; Check for carriage return
    JZ  SEPARATOR
    CPI LF          ; Check for line feed
    JZ  SEPARATOR
    CPI ' '         ; Check for space
    JZ  SEPARATOR
    CPI 9           ; Check for tab
    JZ  SEPARATOR
    CPI '0'         ; Check if digit
    JC  NEXTCHAR    ; Less than '0', skip
    CPI 3AH         ; Check if digit ('9'+1 = 3AH = ':')
    JNC NEXTCHAR    ; Greater than '9', skip

    ; Valid digit - accumulate into TEMPNUM
    SUI '0'         ; Convert ASCII to numeric (0-9)
    PUSH    H           ; Save buffer pointer
    PUSH    B           ; Save loop counter
    PUSH    PSW         ; Save digit value

    ; Mark that we're in a number
    MVI A,1
    STA INNUM

    ; Multiply TEMPNUM by 10
    LHLD    TEMPNUM     ; Load current temp number
    CALL    MUL10       ; HL = HL * 10

    ; Add the new digit
    POP PSW         ; Restore digit value (0-9)
    MOV E,A
    MVI D,0         ; DE = digit
    DAD D           ; HL = HL + digit
    SHLD    TEMPNUM     ; Store back to TEMPNUM

    POP B           ; Restore loop counter
    POP H           ; Restore buffer pointer
    JMP NEXTCHAR

SEPARATOR:
    ; Hit a separator (space, CR, LF, tab)
    ; If we were in a number, add TEMPNUM to COUNTER and reset
    PUSH    H
    PUSH    B
    LDA INNUM
    ORA A           ; Check if we were in a number
    JZ  SEPSKIP     ; Not in a number, skip

    ; Add TEMPNUM to COUNTER
    LHLD    COUNTER
    XCHG                ; DE = COUNTER
    LHLD    TEMPNUM
    DAD D           ; HL = TEMPNUM + COUNTER
    SHLD    COUNTER     ; Store result

    ; Reset TEMPNUM and INNUM
    XRA A
    STA TEMPNUM
    STA TEMPNUM+1
    STA INNUM

SEPSKIP:
    POP B
    POP H
    JMP NEXTCHAR

NEXTCHAR:
    INX H           ; Move to next character
    DCR B           ; Decrement counter
    JNZ PROCBUF     ; Continue if more characters

    JMP READLOOP    ; Read next sector

ENDNUM:
    ; Finalize any number in progress before ending
    LDA INNUM
    ORA A
    JZ  READDONE    ; No number in progress, done

    ; Add TEMPNUM to COUNTER
    LHLD    COUNTER
    XCHG                ; DE = COUNTER
    LHLD    TEMPNUM
    DAD D           ; HL = TEMPNUM + COUNTER
    SHLD    COUNTER     ; Store result

READDONE:
    ; Close input file
    LXI D,INFCB
    MVI C,CLOSF
    CALL    BDOS

    ; Convert counter to decimal string
    LHLD    COUNTER     ; Load counter value into HL
    LXI D,NUMEND        ; DE points to end of 6-byte buffer
    XRA A               ; A = 0
    STAX    D           ; Store null terminator at end

    ; Extract digits by repeated division by 10
CONVLOOP:
    CALL    DIV16       ; HL = HL / 10, A = remainder (0-9)
    ADI '0'         ; Convert digit to ASCII ('0'-'9')
    DCX D           ; Move buffer pointer left
    STAX    D           ; Store ASCII digit in buffer
    MOV A,H         ; Check if quotient is zero
    ORA L           ; Set flags based on H OR L
    JNZ CONVLOOP    ; If HL != 0, continue extracting digits

    ; DE now points to first digit of number string
    XCHG                ; HL now points to first digit
    SHLD    NUMPTR      ; Save pointer to number string

    ; Print "Sum: " to console
    PUSH    H           ; Save number pointer
    LXI H,SUMMSG
    CALL    COMSG       ; Use library routine
    POP H           ; Restore number pointer

    ; Print number to console
    CALL    COMSG       ; Use library routine

    ; Print newline to console
    CALL    CCRLF       ; Use library routine

    ; Now write to output file
    ; Create output file
    LXI D,OUTFCB
    MVI C,MAKEF
    CALL    BDOS
    CPI 0FFH        ; 0FFH = directory full
    JZ  CANTCREATE

    ; Copy result to DMA buffer for writing to file
    LHLD    NUMPTR      ; Load pointer to number string
    LXI D,DMABUF    ; DE = destination

COPYLOOP:
    MOV A,M         ; Get character from number buffer
    ORA A           ; Check for null terminator
    JZ  COPYDONE
    STAX    D           ; Store in DMA buffer
    INX H           ; Next source
    INX D           ; Next destination
    JMP COPYLOOP

COPYDONE:
    ; Add CR/LF to output file
    MVI A,CR
    STAX    D
    INX D
    MVI A,LF
    STAX    D
    INX D

    ; Pad rest of sector with Ctrl-Z (EOF marker)
    ; DE now points to position after CR/LF
    ; Calculate how many bytes to pad: 128 - (DE - DMABUF)
    XCHG                ; HL = current position in buffer
    LXI D,DMABUF    ; DE = start of buffer
    MOV A,L         ; Get low byte of current position
    SUB E           ; Subtract start position low byte
    MOV B,A         ; B = bytes written
    MVI A,128       ; A = total buffer size
    SUB B           ; A = bytes remaining to pad
    MOV B,A         ; B = pad count
    MVI A,CTRLZ     ; A = pad character
PADLOOP:
    MOV M,A         ; Write CTRLZ at HL
    INX H           ; Next position
    DCR B           ; Decrement counter
    JNZ PADLOOP     ; Loop if not done

    ; Set DMA to output buffer
    LXI D,DMABUF
    MVI C,SDMAF
    CALL    BDOS

    ; Write to output file
    LXI D,OUTFCB
    MVI C,WRITF
    CALL    BDOS
    CPI 0           ; 0 = success
    JNZ WRITEERR

    ; Close output file
    LXI D,OUTFCB
    MVI C,CLOSF
    CALL    BDOS

    ; Print success message to console
    LXI H,DONEMSG
    CALL    COMSG       ; Use library routine

    JMP RBOOT       ; Return to CP/M

NOARG:
    LXI H,USAGEMSG
    CALL    COMSG       ; Use library routine
    JMP RBOOT

NOFILE:
    LXI H,NOFMSG
    CALL    COMSG       ; Use library routine
    JMP RBOOT

CANTCREATE:
    LXI H,CANTMSG
    CALL    COMSG       ; Use library routine
    JMP RBOOT

WRITEERR:
    LXI H,WRITERRMSG
    CALL    COMSG       ; Use library routine
    JMP RBOOT

;============== BEGIN CPMIO.LIB - Console I/O Routines ==============
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
;============== END CPMIO.LIB ==============

;============== BEGIN CH13.LIB - Basic I/O Functions ==============
CCRLF:  MVI A,CR
    CALL    CO
    MVI A,LF
    JMP CO

COMSG:  MOV A,M
    ORA A
    RZ
    CALL    CO
    INX H
    JMP COMSG

CIMSG:  PUSH    B
    PUSH    D
    PUSH    H
    LXI H,INBUF1
    MVI M,0
    DCX H
    MVI M,80
    XCHG
    MVI C,RBUFF
    CALL    BDOS
    LXI H,INBUF1
    MOV E,M
    MVI D,0
    DAD D
    INX H
    MVI M,0
    POP H
    POP D
    POP B
    RET

TWOCR:  CALL    CCRLF
    JMP CCRLF
;============== END CH13.LIB ==============
; Note: INBUF is defined in data section below, not here

; Multiply HL by 10
; Input:  HL = value to multiply
; Output: HL = HL * 10
; Method: HL * 10 = (HL * 8) + (HL * 2) = (HL << 3) + (HL << 1)
; Uses:   DE for temporary storage (DE is destroyed)
MUL10:  MOV D,H         ; DE = HL (save original)
    MOV E,L
    ; HL << 1 (multiply by 2)
    DAD H           ; HL = HL * 2
    ; Save HL * 2 in BC temporarily via stack
    PUSH    H           ; Save HL * 2
    ; HL << 2 more (to get HL * 8 total)
    DAD H           ; HL = HL * 4
    DAD H           ; HL = HL * 8
    ; Add HL * 2 (from stack) to HL * 8
    POP D           ; DE = HL * 2
    DAD D           ; HL = (HL * 8) + (HL * 2) = HL * 10
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

; Input File Control Block (FCB)
; Format: 1 byte drive (0=default), 8 bytes filename, 3 bytes extension
INFCB:  DB  0,0,0,0,0,0,0,0,0,0,0,0    ; 12 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0    ; 12 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0    ; 12 bytes (36 total)

; Output File Control Block
OUTFCB: DB  0           ; Drive (0 = default)
    DB  'RESULT  '  ; 8-character filename
    DB  'TXT'       ; 3-character extension
    DB  0,0,0,0,0,0,0,0,0,0,0,0    ; 12 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0    ; 12 bytes (24 total)

; Messages (null-terminated for COMSG)
USAGEMSG:   DB  'Usage: SUMALL filename.txt',CR,LF,0
SUMMSG: DB  'Sum: ',0
NOFMSG: DB  'Input file not found.',CR,LF,0
CANTMSG:    DB  'Cannot create RESULT.TXT.',CR,LF,0
WRITERRMSG: DB  'Error writing to RESULT.TXT.',CR,LF,0
DONEMSG:    DB  'Sum written to RESULT.TXT.',CR,LF,0

COUNTER:    DW  0       ; 16-bit counter (sum of all numbers)
TEMPNUM:    DW  0       ; 16-bit temporary accumulator for current number
INNUM:  DB  0       ; Flag: 1 if currently parsing a number, 0 otherwise
NUMPTR: DW  0       ; Pointer to number string
NUMBUF: DB  0,0,0,0,0    ; Buffer for number string (5 bytes)
NUMEND: DB  0           ; End of buffer (NUMBUF+5)
INBUF:  DB  0           ; INBUF byte 0 (length field for CIMSG)
INBUF1: DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 20 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 20 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 20 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 22 bytes (82 total, 83 with INBUF)
DMABUF: DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 16 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 16 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 16 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 16 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 16 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 16 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 16 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 16 bytes (128 total)

    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; Stack space: 16 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 16 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 16 bytes
    DB  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; 16 bytes (64 total)

    END START

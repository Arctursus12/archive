; SUMALL.ASM - Sum all single decimal digits in a file
; Usage: SUMALL filename.txt
; Output: Displays sum and writes to RESULT.TXT
;
; This program reads a text file and sums all single digit values (0-9)
; found in it, ignoring all other characters.
; Uses library code from DISKEQU.LIB, CPMIO.LIB, and CH13.LIB

;============== BEGIN DISKEQU.LIB - CP/M System Equates ==============
; ASCII Characters
CR  EQU 0DH
LF  EQU 0AH
CTRLZ   EQU 1AH

; CP/M BDOS Functions
RCONF   EQU 1
WCONF   EQU 2
RBUFF   EQU 10

; CP/M Disk Functions
INITF   EQU 13
OPENF   EQU 15
CLOSF   EQU 16
DELEF   EQU 19
READF   EQU 20
WRITF   EQU 21
MAKEF   EQU 22
SDMAF   EQU 26

; CP/M Addresses
RBOOT   EQU 0
BDOS    EQU 5
TFCB    EQU 5CH
TPA EQU 100H

; CP/M Error Codes
BDERR   EQU 255
;============== END DISKEQU.LIB ==============

    ORG TPA

START:  LXI SP,STAK     ; Initialize stack pointer
    XRA A           ; A = 0
    STA COUNTER     ; Initialize counter to 0
    STA COUNTER+1

    ; Clear output FCB (except drive and filename)
    LXI H,OUTFCB+12 ; Start at EX field
    MVI B,24        ; Clear 24 bytes
CLRFCB: MVI M,0
    INX H
    DCR B
    JNZ CLRFCB

    ; Check if filename was provided on command line
    ; CP/M parses first argument into default FCB at 5CH
    LDA TFCB+1      ; Get first character of filename
    CPI ' '         ; Check if space (no filename)
    JZ  NOARG       ; No filename provided

    ; Copy default FCB to our input FCB
    LXI H,TFCB      ; Source: default FCB
    LXI D,INFCB     ; Destination: our FCB
    MVI B,36        ; Copy entire FCB (36 bytes)
COPYFCB:
    MOV A,M
    STAX    D
    INX H
    INX D
    DCR B
    JNZ COPYFCB

    ; Open input file
    LXI D,INFCB
    MVI C,OPENF
    CALL    BDOS
    CPI BDERR       ; Check for error (255)
    JZ  NOFILE

    ; Set DMA address to our buffer
    LXI D,DMABUF
    MVI C,SDMAF
    CALL    BDOS

    ; Read and process file
READLOOP:
    LXI D,INFCB
    MVI C,READF
    CALL    BDOS
    ORA A           ; Check if successful (A=0)
    JNZ READDONE    ; EOF or error

    ; Process the 128-byte buffer
    LXI H,DMABUF
    MVI B,128       ; Process 128 bytes

PROCBUF:
    MOV A,M         ; Get character
    CPI CTRLZ       ; Check for EOF marker
    JZ  READDONE
    CPI '0'         ; Check if >= '0'
    JC  NEXTCHAR    ; Skip if less
    CPI '9'+1       ; Check if <= '9'
    JNC NEXTCHAR    ; Skip if greater

    ; Valid digit - add to counter
    SUI '0'         ; Convert ASCII to value (0-9)
    MOV E,A
    MVI D,0         ; DE = digit value
    XCHG                ; HL = digit, DE = buffer ptr
    PUSH    D           ; Save buffer pointer
    PUSH    B           ; Save loop counter
    XCHG                ; DE = digit
    LHLD    COUNTER     ; HL = current counter
    DAD D           ; HL = counter + digit
    SHLD    COUNTER     ; Save new counter
    POP B
    POP H           ; Restore buffer pointer

NEXTCHAR:
    INX H
    DCR B
    JNZ PROCBUF

    JMP READLOOP

READDONE:
    ; Close input file
    LXI D,INFCB
    MVI C,CLOSF
    CALL    BDOS

    ; Convert counter to decimal string
    LHLD    COUNTER
    LXI D,NUMBUF+5  ; Point to end of buffer
    XRA A
    STAX    D           ; Null terminator

CONVLOOP:
    CALL    DIV16       ; Divide by 10, remainder in A
    ADI '0'         ; Convert to ASCII
    DCX D
    STAX    D
    MOV A,H
    ORA L
    JNZ CONVLOOP

    ; DE now points to first digit
    XCHG                ; HL = pointer to number string
    SHLD    NUMPTR

    ; Display result to console
    PUSH    H
    LXI H,SUMMSG
    CALL    COMSG
    POP H
    CALL    COMSG
    CALL    CCRLF

    ; Reset disk system before file operations
    MVI C,INITF
    CALL    BDOS

    ; Delete any existing RESULT.TXT
    LXI D,OUTFCB
    MVI C,DELEF
    CALL    BDOS

    ; Create output file
    LXI D,OUTFCB
    MVI C,MAKEF
    CALL    BDOS
    CPI BDERR
    JZ  CANTCREATE

    ; Fill entire buffer with CTRLZ first
    LXI H,DMABUF
    MVI B,128
    MVI A,CTRLZ
FILLLOOP:
    MOV M,A
    INX H
    DCR B
    JNZ FILLLOOP

    ; Copy result to start of buffer
    LHLD    NUMPTR
    LXI D,DMABUF
COPYLOOP:
    MOV A,M
    ORA A
    JZ  COPYDONE
    STAX    D
    INX H
    INX D
    JMP COPYLOOP

COPYDONE:
    ; Add CR/LF
    MVI A,CR
    STAX    D
    INX D
    MVI A,LF
    STAX    D

    ; Set DMA and write
    LXI D,DMABUF
    MVI C,SDMAF
    CALL    BDOS

    LXI D,OUTFCB
    MVI C,WRITF
    CALL    BDOS
    ORA A
    JNZ WRITEERR

    ; Close file
    LXI D,OUTFCB
    MVI C,CLOSF
    CALL    BDOS
    CPI BDERR
    JZ  WRITEERR

    ; Display success message
    LXI H,DONEMSG
    CALL    COMSG
    JMP RBOOT

;============== Error Handlers ==============
NOARG:
    LXI H,USAGEMSG
    CALL    COMSG
    JMP RBOOT

NOFILE:
    LXI H,NOFMSG
    CALL    COMSG
    JMP RBOOT

CANTCREATE:
    LXI H,CANTMSG
    CALL    COMSG
    JMP RBOOT

WRITEERR:
    LXI H,WRITERRMSG
    CALL    COMSG
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
    LXI H,INBUF+1
    MVI M,0
    DCX H
    MVI M,80
    XCHG
    MVI C,RBUFF
    CALL    BDOS
    LXI H,INBUF+1
    MOV E,M
    MVI D,0
    DAD D
    INX H
    MVI M,0
    POP H
    POP D
    POP B
    RET
;============== END CH13.LIB ==============

;============== Utility Routines ==============
; Compare HL and DE
; Returns: Zero flag set if equal
CMPHD:  MOV A,H
    CMP D
    RNZ
    MOV A,L
    CMP E
    RET

; Divide HL by 10 (from COUNTER.ASM)
; Input:  HL = dividend
; Output: HL = quotient, A = remainder (0-9)
DIV16:  PUSH    B
    LXI B,0         ; Quotient counter
DIV16L: MOV A,H
    ORA A
    JNZ DIV16S
    MOV A,L
    CPI 10
    JC  DIV16D
DIV16S: MOV A,L
    SUI 10
    MOV L,A
    MOV A,H
    SBI 0
    MOV H,A
    INX B
    JMP DIV16L
DIV16D: MOV A,L         ; Remainder to A
    MOV H,B         ; Quotient to HL
    MOV L,C
    POP B
    RET

;============== Data Areas ==============
; File Control Blocks
INFCB:  DS  36          ; Input file FCB
OUTFCB: DB  4           ; Output FCB - Drive D:
    DB  'RESULT  '
    DB  'TXT'
    DS  24

; Messages (null-terminated)
USAGEMSG:   DB  'Usage: SUMALL filename.txt',CR,LF,0
SUMMSG: DB  'Sum: ',0
NOFMSG: DB  'File not found.',CR,LF,0
CANTMSG:    DB  'Cannot create RESULT.TXT.',CR,LF,0
WRITERRMSG: DB  'Error writing RESULT.TXT.',CR,LF,0
DONEMSG:    DB  'Sum written to RESULT.TXT.',CR,LF,0

; Variables
COUNTER:    DW  0           ; 16-bit sum
NUMPTR: DW  0           ; Pointer to number string
NUMBUF: DS  6           ; Number conversion buffer
INBUF:  DS  83          ; Input buffer for CIMSG
DMABUF: DS  128         ; DMA buffer (CP/M sector size)

    DS  64          ; Stack space
STAK:   DB  0

    END

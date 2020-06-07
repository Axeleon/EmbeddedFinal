	.cdecls C, LIST, "msp430fg4618.h"

	.sect ".sysmem"

	.text
	.global _START
;----------------------------------
;		Program Initialization
;----------------------------------

START	mov.w #300h, SP

StopWDT	mov.w	#WDTPW+WDTHOLD, &WDTCTL  ;Stop watchdog timer
SetupP2	bis.b	#04h, &P2DIR 	 		 ; Set port 2 bit 1 as output

		call 	#Init_UART		; Initialize UART for use
		call 	#prompt			; Prints '>'
		jmp 	Start


;----------------------------------
;			Main Program
;----------------------------------
Main
		call 	#CRLF			; Go to next line in terminal
		call 	#prompt			; Print '>'
Start
		call	#INCHAR_UART	; Get input from keyboard
		call	#OUTA_UART		; Print input to terminal

		cmp.b	#'M', R4
		jne		TestH
		call	#modmem			; Run Manipulate Memory if 'M' is input
		jmp		Main			; Run program indefinitely

TestH
		cmp.b	#'H', R4		; Run Hex Calculator if 'H' is input
		jne		Main
		call	#hexcalc
		jmp		Main

		jmp 	Main

;---------------------------------------------------
; Project Step 1
; Prints 2 ASCII numbers in HEX format
;---------------------------------------------------
hex2out
		push.w 	R5			; Push hex input to save original
		rra.b 	R5			; Shift 4 bits right
		rra.b	R5
		rra.b	R5
		rra.b	R5

		and.b	#0x0F, R5	; Retrieve only lower 4 bits
		cmp.b	#0x0A, R5	; Check lower 4 bits for A-F
		jlo		Hexnum1		; If not A-F, must be 0-9

		add.b	#0x37, R5	; Convert A-F hex value to it's ASCII equivalence
		jmp		HexLp1

Hexnum1
		add.b	#0x30, R5	; Convert 0-9 hex value to it's ASCII equivalence

HexLp1
		mov.b	R5, R4
		call	#OUTA_UART	; Print lower 4 bits

		pop.w	R5			; Pop hex input off to get original
		push.w	R5			; Push hex input back to save original again

		and.b	#0x0F, R5	; Retrieve only upper 4 bits
		cmp.b	#0x0A, R5	; Check upper 4 bits for A-F
		jlo		Hexnum2

		add.b	#0x37, R5	; Convert A-F hex value to it's ASCII equivalence
		jmp		HexLp2

Hexnum2
		add.b	#0x30, R5	; Convert 0-9 hex value to it's ASCII equivalence

HexLp2
		mov.b	R5, R4
		call	#OUTA_UART	; Print upper 4 bits
		pop.w	R5			; Pop original hex input off stack
		ret

;-------------------------------------------------------
; Project Step 2
; Inputs two valid ASCII HEX format values from keyboard
; Values stored in R5
;-------------------------------------------------------
hex2in
HeInLp
		call 	#INCHAR_UART	; Retrieve first value
		cmp.b 	#0x30, R4		; If R4 < 0, try again
		jlo 	HeInLp

		cmp.b 	#0x47, R4		; If R4 > F, try again
		jhs 	HeInLp

		cmp.b 	#0x3A, R4		; Jump to 0-9 conversion
		jlo 	HeInNum1

		cmp.b 	#0x41, R4		; Jump to A-F conversion
		jhs 	HeInLet1

		jmp 	HeInLp			; If some other value, try again

HeInNum1
		call 	#OUTA_UART		; Print value
		sub.b	#0x30, R4		; Convert to Hex
		jmp		HeInLp1

HeInLet1
		call 	#OUTA_UART		; Print first value
		sub.b 	#0x37, R4		; Convert to Hex

HeInLp1
		rla.b	R4				; Shift first value 4 bits left
		rla.b	R4
		rla.b	R4
		rla.b	R4
		clr.w	R5
		add.b 	R4, R5			; Store in R5

HeInLp2
		call 	#INCHAR_UART	; Retrieve second value
		cmp.b 	#0x30, R4		; If R4 < 0, try again
		jlo		HeInLp2

		cmp.b	#0x47, R4		; If R4 > F, try again
		jhs		HeInLp2

		cmp.b	#0x3A, R4		; Jump to 0-9 conversion
		jlo		HeInNum2

		cmp.b	#0x41, R4		; Jump to A-F conversion
		jhs		HeInLet2

		jmp		HeInLp2			; If some other value, try again

HeInNum2
		call	#OUTA_UART		; Print second value
		sub.b	#0x30, R4		; Convert to Hex
		jmp		HeInLp3

HeInLet2
		call	#OUTA_UART		; Print second value
		sub.b	#0x37, R4		; Convert to hex

HeInLp3
		add.b	R4, R5			; Add both values together, store them in R5
		ret

;-----------------------------------------------------------------
; Project Step 3
; Prints 4 ASCII numbers in HEX format to terminal
;-----------------------------------------------------------------
hex4out
		push.w 	R5			; Push R5 to save original value
		swpb	R5			; Swap lower and upper 4 bits
		call	#hex2out	; Print upper 2 bits

		swpb	R5			; Swap lower and upper 4 bits
		call 	#hex2out	; Print lower 2 bits
		pop.w	R5			; Pop original value
		ret

;-----------------------------------------------------------------
; Project Step 4
; Inputs 4 valid ASCII HEX format values from keyboard
; Values stored in R5
;-----------------------------------------------------------------
hex4in
		call	#hex2in			; Retrieve upper 2 bits
		mov.b	R5, R6
		swpb	R6				; Swaps lower and upper four bits
		call	#hex2in			; Retrieve lower 2 bits
		add.w	R6, R5			; Add upper and lower bits together, store in R5
		ret

;--------------------------------------------------------------------
; Project Step 5
; Inputs 8 valid ASCII HEX format characters from keyboard
; First 4 stored in R5, second 4 stored in R6
;--------------------------------------------------------------------
hex8in
		call	#hex4in		; Get first 4 values
		push.w	R5			; Push first 4 values to save them
		call	#space		; Print ' '
		call	#hex4in		; Get second 4 values
		mov.w	R5, R6		; Move second 4 to R6
		pop.w	R5			; Pop first 4 values and store in R5
		ret

;-------------------------------------------------
; Project Step 6
; Prints carriage return and line feed to terminal
;-------------------------------------------------
CRLF
		mov.w 	#0x0A, R4
		call 	#OUTA_UART	; Print carriage return

		mov.w 	#0x0D, R4
		call 	#OUTA_UART	; Print line feed
		ret

;---------------------------------------------------------------------------------------------------------------
; Project Step 7
; Manipulates data (QQQQ) at memory address (XXXX)
; Format: M XXXX QQQQ
; QQQQ is the 4-digit HEX number to be stored in location XXXX
; QQQQ is the ASCII input of 'P' which skips present line and moves to the next higher address XXXX+1
; QQQQ is the ASCII input of 'N' which skips present line and moves to the next lower address XXXX-1
; QQQQ is the ASCII input of ' ', exits the modify memory routine and returns the user to the input prompt
; calls subroutine hex4in to read initial address, and a modded Hex2aug to compensate for command inputs
; and hex2in to read the last two in case it is a Hex input
;----------------------------------------------------------------------------------------------------------------
modmem
		call 	#space
		call 	#hex4in		; Get starting memory address, store in R5
		mov.w 	R5, R7		; Move starting memory address to R7

		and.w	#0x01, R5
		cmp.w	#0x01, R5	; Check input address for even value
		jeq		exitmod		; If odd, jump out of Memory Manipulation
		jmp 	startmod	; If even, being Memory Manipulation

ShowAddress
		call 	#CRLF		; Move to next line in terminal
		call	#prompt		; Print '>'
		mov.w	#'M', R4
		call	#OUTA_UART	; Print 'M'
		call	#space		; Print ' '
		mov.w	R7, R5
		call	#hex4out	; Print current memory address

startmod
		call	#space		; Print ' '
		call	#hex2inAug	; Get upper two hex values or 'P' or 'N'
		cmp.b	#'P', R8	; If 'P' move to next address
		jeq		Pos
		cmp.b	#'N', R8	; If 'N' move to previous address
		jeq		Neg
		cmp.b	#0x20, R8	; If ' ' exit Memory Manipulation
		jeq		exitmod

		mov.b	R5, R6
		swpb	R6			; Swap upper and lower 4 bits
		call	#hex2in		; Get lower 2 hex values
		add.w	R6, R5		; Add all 4 hex values together to get full 4-bit hex value

		mov.w	R5, 0(R7)	; Move QQQQ to XXXX
		jmp		ShowAddress


;--------------------------
; Increment memory address
;--------------------------
Pos
		mov.w	R8, R4
		call 	#OUTA_UART	; Print 'P'
		incd.w	R7			; Increment address
		jmp		ShowAddress ; Print current memory address

;--------------------------
; Decrement memory address
;--------------------------
Neg
		mov.w	R8, R4
		call 	#OUTA_UART	; Print 'N'
		decd.w	R7			; Decrement address
		jmp		ShowAddress	; Print current memory address

exitmod
		ret

;-------------------------------------------------------------
; Helper subroutine for Manipulate Memory
; Works the same as hex2in subroutine, but allows 'P' or 'N'
; if 'P' or 'N' is input, return to Manipulate Memory
;-------------------------------------------------------------

hex2inAug
HeInLpAug
		call 	#INCHAR_UART	;grabs first input

		cmp.b	#'P', R4
		jeq		command
		cmp.b	#'N', R4
		jeq		command
		cmp.b	#0x20, R4
		jeq		command

		jmp		HexAnal			;) not a command, so analyze Hex number

command
		mov.w	R4, R8			; saves command to R8
		ret

HexAnal
								;past this point, must be a number or invalid input
		cmp.b 	#0x30, R4		;checks if R4 < 0, invald input, request again
		jlo 	HeInLpAug
		cmp.b 	#0x47, R4		;checks if R4 > F, invald input, request again
		jhs 	HeInLpAug
		cmp.b 	#0x3A, R4		;checks if R4 < 9, valid number
		jlo 	HeInNum1Aug
		cmp.b 	#0x41, R4		;checks if R4 > A, valid letter
		jhs 	HeInLet1Aug
		jmp 	HeInLpAug		;cases of inputs between '9' and 'A'

HeInNum1Aug
		call 	#OUTA_UART		;echoes input
		sub.b	#0x30, R4		;subtracts 0x30 to convert to hex (0-9)
		jmp		HeInLp1Aug

HeInLet1Aug
		call 	#OUTA_UART		;echoes input
		sub.b 	#0x37, R4		;subtracts 0x37 to convert to hex (A-F)

HeInLp1Aug
		rla.b	R4				;shifts R4 left 4 places
		rla.b	R4
		rla.b	R4
		rla.b	R4
		clr.w	R5
		add.b 	R4,R5			;puts high 4 bites of input into R5

HeInLp2Aug
		call 	#INCHAR_UART		;grabs second input
		cmp.b 	#0x30, R4			;refer to HeInLp for processing valid input
		jlo		HeInLp2Aug
		cmp.b	#0x47, R4
		jhs		HeInLp2Aug
		cmp.b	#0x3A, R4
		jlo		HeInNum2Aug
		cmp.b	#0x41, R4
		jhs		HeInLet2Aug
		jmp		HeInLp2Aug

HeInNum2Aug
		call	#OUTA_UART
		sub.b	#0x30, R4
		jmp		HeInLp3Aug

HeInLet2Aug
		call	#OUTA_UART
		sub.b	#0x37, R4

HeInLp3Aug
		add.b	R4, R5			;combines result into R5
		clr.w	R8				;since R8 is not a command, clear it
		ret

;--------------------------------------------------------------------------------
; Project Step 9
; 16-bit Addition(HA)/Subtraction(HS) Hexadecimal Calculator
; Format: Command Input1 Input2 Result
; Example:	HA 0012 0034 R=0046
;--------------------------------------------------------------------------------
hexcalc:
operation
		call	#INCHAR_UART
		cmp.b 	#'A', R4
		jeq		addition		; Do addition if 'A' is input
		cmp.b	#'S', R4
		jeq		subtraction		; Do subtraction if 'S' is input
		jmp		operation		; Input another value

addition
		call	#OUTA_UART		; Prints 'A'
		call	#space			; Prints ' '

		call	#hex8in			; Retrieve values to add
		add.w	R6, R5			; Perform the addition, store in R5
		mov.w 	SR, R7			; Save status flags in R7

		call	#space			; Prints ' '
		mov.w	#'R', R4
		call	#OUTA_UART		; Prints 'R'
		call	#equal			; Prints '='
		call	#hex4out		; Prints result of addition
		call	#Status			; Prints status flags
		ret

subtraction
		call	#OUTA_UART		; Prints 'A'
		call	#space			; Prints ' '

		call	#hex8in			; Retrieve values to subtract
		sub.w	R6, R5			; Perform the subtraction, store in R5
		mov.w 	SR, R7			; Save status flags in R7

		call	#space			; Prints ' '
		mov.w	#'R', R4
		call	#OUTA_UART		; Prints 'R'
		call	#equal			; Prints '='
		call	#hex4out		; Prints result of subtraction
		call	#Status			; Prints status flags
		ret

;----------------------------------------------------
; Helper subroutine for the hexadecimal calculator.
; Prints status flags updated during calculations.
; Status Flags are stored in R7 during calculation.
; z = zero, n = negative, c = carry, v = overflow
; z = 0x0002, n = 0x0004, c = 0x0001, v = 0x0100
;----------------------------------------------------
Status
		call	#CRLF		; Start a new line
		mov.w	R7, R8		; Unmanipulated flag values stored in R8

;----------------
;	Carry Flag
;----------------
CFlag
		mov.w	#'c', R4
		call	#OUTA_UART	; Print 'c'
		call	#equal		; Print '='

		and.w	#0x0001, R8	; Apply bitmask to get carry flag
		cmp.w	#0x0001, R8	; Check for carry
		jeq		C1			; Print '1' if carry detected
		call	#zero		; Print '0' if no carry detected
		jmp		Zbit

C1
		call 	#one

;----------------
;	Zero Flag
;----------------
Zbit

		mov.w	R7, R8		; Copy of original flag values stored in R8
		call 	#space		; Print ' '
		mov.w	#'z', R4
		call	#OUTA_UART	; Print 'z'
		call	#equal		; Print '='

		and.w	#0x0002, R8	; Apply bitmask to get zero flag
		cmp.w	#0x0002, R8	; Check for zero
		jeq		Z1			; Print '1' if zero detected
		call	#zero		; Print '0' if no zero detected
		jmp		Nbit

Z1
		call	#one

;------------------
;	Negative Flag
;------------------
Nbit
		mov.w	R7, R8		; Copy of original flag values stored in R8
		call	#space		; Print ' '
		mov.w	#'n', R4
		call	#OUTA_UART	; Print 'n'
		call	#equal		; Print '='

		and.w	#0x0004, R8	; Apply bitmask to get negative flag
		cmp.w	#0x0004, R8	; Check for negative
		jeq		N1			; Print '1' if negative detected
		call	#zero		; Print '0' if no negative detected
		jmp		Vbit

N1
		call	#one

;------------------
;	Overflow Flag
;------------------
Vbit
		mov.w	R7, R8		; Copy of original flag values stored in R8
		call	#space		; Print ' '
		mov.w	#'v', R4
		call	#OUTA_UART	; Print 'v'
		call	#equal		; Print '='

		and.w	#0x0100, R8	; Apply bitmask to get overflow flag
		cmp.w	#0x0100, R8	; Check for overflow
		jeq		V1			; Print '1' if overflow detected
		call	#zero		; Print '0' if no overflow detected
		ret
V1
		call	#one
		ret


;--------------------------------------------
; The following subroutines are helpers
; for quick printing of various characters
;--------------------------------------------

;--------------------------------------------
; Prints ' ' character to terminal
;--------------------------------------------
space
		mov.w 	#0x20, R4
		call 	#OUTA_UART
		ret

;-----------------------------------------
; Print '>' character to terminal
;-----------------------------------------
prompt
		mov.w 	#'>', R4
		call 	#OUTA_UART
		ret

;----------------------------------------
; Print '=' character to terminal
;----------------------------------------
equal
		mov.w	#'=', R4
		call	#OUTA_UART
		ret

;----------------------------------------
; Print '.' character to terminal
;-----------------------------------------
period
		mov.w 	#'.', R4
		call	#OUTA_UART
		ret

;----------------------------------------
; Print '0' character to terminal
;----------------------------------------
zero
		mov.w	#'0', R4
		call	#OUTA_UART
		ret

;----------------------------------------
; Print '1' character to terminal
;----------------------------------------
one
		mov.w	#'1',R4
		call	#OUTA_UART
		ret


;---------------------------------------
; The following subroutines all deal
; with the terminal
;---------------------------------------

;--------------------------------------
; Sends character to terminal
;--------------------------------------
OUTA_UART
		push R5
lpa		mov.b &IFG2, R5
		and.b #0x02, R5
		cmp.b #0x00, R5
		jz lpa

		mov.b R4, &UCA0TXBUF
		pop R5
		ret

;--------------------------------------
; Retrieves character from terminal
;--------------------------------------
INCHAR_UART
		push R5
lpb		mov.b &IFG2, R5
		and.b #0x01, R5
		cmp.b #0x00, R5
		jz lpb
		mov.b &UCA0RXBUF, R4
		pop R5
		ret

;--------------------------------------
; Initialize terminal for input/output
;--------------------------------------
Init_UART
		mov.b #0x30, &P2SEL
		mov.b #0x00, &UCA0CTL0
		mov.b #0x41, &UCA0CTL1
		mov.b #0x00, &UCA0BR1
		mov.b #0x03, &UCA0BR0
		mov.b #0x06, &UCA0MCTL
		mov.b #0x00, &UCA0STAT
		mov.b #0x40, &UCA0CTL1
		mov.b #0x00, &IE2

		ret

;----------------------------------------------
;			Interrupt Vectors
;----------------------------------------------
		.sect ".reset"
		.short START
		.end

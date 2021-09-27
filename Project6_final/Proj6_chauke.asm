TITLE String Primitives and Macros by Kent Chau

; Author: Kent Chau
; Last Modified: 6/6/21
; OSU email address: chauke@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:   6              Due Date: 6/6/21
; Description: This program will take input from user as strings within limits
;				conver them to integers and then convert back to strings for display


INCLUDE Irvine32.inc

SIZE1 = 12

.data

intro		BYTE	"Designing  low - level I/O procedures by Kent Chau.", 13, 10, 0
prompt1		BYTE	"Please provide 10 signed decimal integers. "
					db "Each number needs to be small enough to fit inside a 32 bit register. "
					db "After you have finisehd inputting the raw numbers I will display a list "
					db "of the integers, their sum, and their average value.", 13, 10, 0
prompt2		BYTE	"Please enter a signed number: ", 0
prompt3		BYTE	"Please try again: ", 0
userString	BYTE	SIZE1 DUP(?)
slength		DWORD	?

entered		BYTE	"You entered the following numbers: ", 13, 10, 0
error		BYTE	"ERROR: you did not enter a signed number or your number was too big.", 13, 10, 0
average		BYTE	"The rounded average is: ", 0
tenArray	SDWORD	10 DUP(?)
typeTen		SDWORD	TYPE tenArray
lenTen		SDWORD	LENGTHOF tenArray
sizeTen		SDWORD	SIZEOF tenArray


test2Array	BYTE	100 DUP(?)

sumMessage	BYTE	"The sum of these numbers is: ", 0

sums		SDWORD	1 DUP(?)
sumInt		SDWORD	0
sizeSums	SDWORD	SiZEOF sums
sumString	BYTE	100 DUP(?)
convert		BYTE	?
averageIt	SDWORD	1 DUP(?)
aveString	BYTE	100 DUP(?)
sizeAve		SDWORD	SIZEOF averageIt

buffer1		SDWORD	0
buffer2		SDWORD	0

bye			BYTE	"I wish I could say this project was a pleasure...but ya 'know...ciao for now.", 13, 10, 0

.code
main PROC

;----------------------------------------------------
;name: mGetString - gets user input as string, limited to numerics, and '+' or '1';
;					also must fit within 32 bit register
;preconditions: cannot be a letter or symbol outside of plus and minus, must be within
;				-2147483648 and 2147483647
;receives: string global, max, Dword array address, length of array
;returns: string witin limits
;----------------------------------------------------
mGetString MACRO prompt, max, array, len

	push	edx
	push	ecx
	push	edi
	mov		edi, array
	mov		ecx, max
	mov		al, 0
	rep		stosb

	mov		edx,  prompt
	call	WriteString
	mov		edx, array
	mov		ecx, max
	call	ReadString
	
	mov		array, edx
	mov		len, eax
	mov		eax, 0
	pop		edi
	pop		ecx
	pop		edx
ENDM

;----------------------------------------------------
;name: mDisplayString will take in an array and display it
;preconditions: the array must be BYTE string format
;receives: array of string/characters, size of that array
;returns: none, displays string
;----------------------------------------------------
mDisplayString MACRO array, sizeof
	push ecx
	push edx
	push edi

	mov		edx, array
	add		edx, 1
	call	WriteString

	pop edi
	pop edx
	pop ecx



ENDM


push	OFFSET prompt1
push	OFFSET intro
call	introduction

; setting up loop or read val -----------------------
mov		ecx, lenTen				
mov		edi, OFFSET tenArray
_readval:
push	buffer2		
push	buffer1		
push	OFFSET convert		
push	OFFSET prompt3 
push	OFFSET error 
push	slength   
push	OFFSET tenArray  
push	typeTen 
push	lenTen  
push	sizeTen   
push	OFFSET prompt2 
push	OFFSET userString 
call	ReadVal
								
mov		[edi], edx
add		edi, 4
LOOP	_readval
;-----------------------------------------------------

push	OFFSET entered		
push	OFFSET tenArray		
push	OFFSET test2Array	
push	sizeTen				
call	WriteVal

push	OFFSET sumInt				
push	lenTen				
push	OFFSET tenArray		
push	OFFSET sums				
call	sumit

push	OFFSET sumMessage		
push	OFFSET sums		
push	OFFSET sumString	
push	sizeSums			
call	WriteVal

push	OFFSET averageIt  
push	sumInt			
call	averageProc

push	OFFSET average		
push	OFFSET averageIt	
push	OFFSET aveString	
push	sizeAve			
call	WriteVal

push	OFFSET bye
call	byebye


	Invoke ExitProcess,0	; exit to operating system
main ENDP
;----------------------------------------------------
;name: Instruction procedure, display program
;		instructions and display instructions
;preconditions: mDisplayString
;postconditions: none
;receives: prompt1, intro
;returns: none
;----------------------------------------------------
introduction PROC
	push	ebp
	mov		ebp, esp
	push	edx
	mov	    edx, [ebp +8]
	dec		edx
	
	mDisplayString edx
	call	CrLf
	mov		edx, [ebp +12]
	dec		edx
	mDisplayString edx

	call	CrLf
	pop		edx
	pop		ebp
	ret		8
introduction	ENDP

;----------------------------------------------------
;name: will get input from user read them as strings
;preconditions: user inputs must be numeric, and
;				not larger or smaller than allowed in
;				32 bit registers, symbols outside of
;				'+' or '-' not allowed, and no letters,
;				mGetString macro
;postconditions: passing back value from edx
;receives: buffer1, buffer2, convert, prompt3, error,
;			slength, tenArray, typeTen, lenTen, sizeTen,
;			prompt2, userString
;returns: user input, numeric converted string, modifies
;			edx register, tenArray, userString, convert,
;			buffer1, buffer2, slength
;----------------------------------------------------
ReadVal PROC
	push	ebp
	mov		ebp, esp
	
	push	edi
	push	ecx
	mov		edi, [ebp +44]	;store number conversion as string byte
	_prompting:
	mGetString [ebp +12], SIZE1, [ebp +8], [ebp +32]
	
	_stringreceived:
	
	mov		esi, [ebp +8]	;userString
	mov		ecx, [ebp +32]	;slength

	_validate:				; do checks of sign and number against ascii
	LODSB					; puts byte in AL
	cmp		al, 43
	je		_itsfine
	cmp		al, 45
	je		_itsfine

	cmp		al, 48
	jl		_error
	cmp		al, 57
	jg		_error
	
	_itsfine:
	LOOP	_validate
	
	mov		eax, 0 
	mov		ecx, [ebp +32]
	
	_convert:				; jump dependent on sign or not signed
	mov		esi, [ebp +8]
	LODSB
	cmp		al, 43
	je		_convertplus
	cmp		al, 45
	je		_convertwithsign
	mov		edx, 0
	
	_convertunsign:
	push	ecx
	sub		al, 48
	movzx	ecx, al			; move al to edx a larger register
	mov		eax, 10
	mov		ebx, edx 
	mul		ebx
	add		eax, ecx
	mov		edx, eax
	pop		ecx
	
	LODSB
	LOOP	_convertunsign

	imul	edx, 1			;test and watch flag for overflow/sign
	js		_error
	jmp		_xconvert
	
	_convertplus:
	mov		eax, 0			;clear eax
	dec		ecx
	mov		edx, 0			;store the answer
	
	_tests:
	LODSB
	push	ecx
	sub		al, 48
	movsx	ecx, al			; move al to edx
	mov		eax, 10
	mov		ebx, edx 
	mul		ebx
	add		eax, ecx
	mov		edx, eax
	pop		ecx

	LOOP	_tests

	imul	eax, 1			;test and check for overflow with sign flag
	js		_error
	jmp		_xconvert

	_convertwithsign:
	dec		ecx
	mov		eax, 0			
	mov		edx, 0			

	_convertwithsignII:		;negativ handling	
	LODSB
	push	ecx
	sub		al, 48
	movsx	ecx, al			; move al to edx 
	mov		eax, 10
	mov		ebx, edx 
	mul		ebx
	add		eax, ecx
	mov		edx, eax
	pop		ecx

	LOOP	_convertwithsignII

	imul	eax, -1
	jns		_error
	neg		edx
	
	_xconvert:
	jmp		_xerror

	_error:
	mov		edx, [ebp +36]	;error
	dec		edx
	mDisplayString edx
	mGetString [ebp +40], SIZE1, [ebp +8], [ebp +32]
	jmp		_stringreceived

	_xerror:
	pop		ecx
	pop		edi

	pop		ebp
	ret		48
readVal ENDP

;----------------------------------------------------
;name: change array of integers to array of strings and display
;preconditions: validated inputs, array of valid inputs, DWORD array,
;				mDisplayString
;postconditions: must be integers array valid inputs
;receives: first call: entered, tenArray, test2Array, sizeTen,
;			second call: sumMessage, sums, sumString, sizeSum
;			third call: average, averageIt, aveString, sizeAve
;returns: first call: test2Array
;			scond call: sumString
;			third call: aveString
;----------------------------------------------------
WriteVal PROC
push	ebp
mov		ebp, esp

push	eax
push	ebx
push	ecx
push	edx
call	CrLf
push	edx
mov		edx, [ebp +20]		;entered
dec		edx
mDisplayString edx
pop		edx

mov		esi, [ebp +16]		;OFFSET testArray
mov		edi, [ebp +12]		;OFFSET test2Array
add		edi, [ebp +8]		;SIZEOF testArray
add		edi, 3
mov		ecx, [ebp +8]		;SIZEOF testArray
push	eax
mov		al, 0
std
stosb
pop		eax

_toptest:					; loop through array, changing elements
sub		ecx, 4
mov		eax, [esi +ecx]
cmp		eax, 0
push	eax
mov		al, 32
stosb
pop		eax
mov		ebx, 10

_signedcheck:				; handlng negative numbers
js		_signed

_top:						;loop conversion
mov		edx, 0
idiv	ebx
add		edx, 48 
push	eax
mov		eax, edx
std
stosb
pop		eax
cmp		eax, 0
jne		_top

_backfromsigned:
cmp		ecx, 0
jne		_toptest
jmp		_xsigned

_signed:
neg		eax

_top2:						;loop conversion
mov		edx, 0
idiv	ebx
add		edx, 48 
push	eax
mov		eax, edx
std
stosb
pop		eax
cmp		eax, 0
jne		_top2
push	eax
mov		al, 45
std
stosb
pop		eax
jmp		_backfromsigned


_xsigned:
mDisplayString edi, [ebp +8]

call	CrLf
pop		edx
pop		ecx
pop		ebx
pop		eax

pop		ebp
ret		12
WriteVal ENDP

;----------------------------------------------------
;name: To sum the number given in the array
;preconditions: validated user inputs 
;postconditions: mDisplayString
;receives: sumInt, lenTen, tenArray, sums
;returns: sums, sumInt
;----------------------------------------------------
sumit PROC
push	ebp
mov		ebp, esp
push	ecx
push	ebx
push	edx
push	edi
push	eax

mov		ecx, [ebp +16]		;len
mov		ebx, 0
mov		edx, [ebp +12]		;array addy
mov		edi, 0

_loopA:						;loop for adding
mov		eax, [edx +ebx]
add		edi, eax
add		ebx, 4
LOOP	_loopA
call	CrLf
push	eax
mov		eax, [ebp +8]
mov		[eax], edi
mov		eax, [ebp +20]
mov		[eax], edi
pop		eax
pop		eax
pop		edi
pop		edx
pop		ebx
pop		ecx

pop		ebp
ret		12
sumit ENDP

;----------------------------------------------------
;name:  Calculate the average of the given array
;preconditions: validated user inputs
;postconditions: mDisplayString
;receives: averageIt, sumInt
;returns: averageIt
;----------------------------------------------------
averageProc PROC
push	ebp
mov		ebp, esp

mov		eax, [ebp +8]	;sumInt
cmp		eax, 0			;handling neg values
js		_signed
cdq
mov		edx, 0
mov		ebx, 10			;get the average
idiv	ebx
push	eax
imul	edx, 10			;multiply remainder by 10
mov		eax, edx
mov		edx, 0
cdq
idiv	ebx				;div to get remainder value from tenths place
mov		ecx, eax		;number to compare and either add one or leave as is
pop		eax
cmp		ecx, 5
jge		_addit
jmp		_xaddit

_signed:				;negative handling
neg		eax
cdq
mov		edx, 0
mov		ebx, 10
idiv	ebx

push	eax
imul	edx, 10
mov		eax, edx
mov		edx, 0
cdq
idiv	ebx
mov		ecx, eax		;number to compare
pop		eax
cmp		ecx, 5
jge		_additsign
neg		eax
jmp		_xaddit

_additsign:				;handling negative
sub		eax, 1
neg		eax
jmp		_xaddit

_xsigned:
_addit:
add		eax, 1

_xaddit:
mov		ebx, [ebp +12]
mov		[ebx], eax

pop		ebp
ret		8
averageProc ENDP

;----------------------------------------------------
;name: bybye procedure, display farewell
;preconditions: mDisplayString
;postconditions: none
;receives: bye global
;returns: none
;----------------------------------------------------
byebye PROC
push	ebp
mov		ebp, esp
call	CrLf
push	edx
mov		edx, [ebp +8]
dec		edx
mDisplayString edx
pop		edx
pop		ebp
ret		8
byebye ENDP
END main

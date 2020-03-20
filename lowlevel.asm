TITLE Low-level I/O     (low_level.asm)

; Author: Marissa Castillo
; Last Modified: 03/13/2020
; Description: 	Reads user input of 10 numbers the hard way instead of relying on Irvine.
;				Uses macros to display and read all user input.
;				After users enters 10 numbers, program will validate that the entry is
;				a number, and will fit in a 32-bit register. It then repeats the numbers
;				back, and displays the sum and floored average.


INCLUDE Irvine32.inc


; 	------ displayString Macro ------
	;	Macro that displays the string stored in the given memory address
	;
	;	Receives: memory location of where string is stored
	;	Returns: none
	;	Preconditions: none
	;	Registers changed: edx

displayString	MACRO	memAddr
	push		edx

	mov			edx, memAddr
	call		WriteString

	pop			edx
ENDM


; 	------ getString Macro ------
	;	Macro that prompts the user for a number, reads input as a string, then stores input
	;	in the given address
	;
	;	Receives: message prompt punctuation, memory location of where string will be stored
	;	Returns: ebx- number of characters entered from user; memAddr- string from user
	;	Preconditions: none
	;	Registers changed: eax, edx, ecx, ebx

getString	MACRO	msgPunct, memAddr
	push		eax
	push		edx
	push		ecx

	displayString msgPunct
	mov			edx, memAddr
	mov			ecx, 32
	call		ReadString
	mov			ebx, eax

	pop			ecx
	pop			edx
	pop			eax
ENDM


.data

introMess		BYTE	"Using Low-level I/O Procedures", 0Ah
				BYTE	"   By Marissa Castillo", 0Ah, 0Ah, 0
instructMess	BYTE	"Please provide 10 signed decimal integers.", 0Ah
				BYTE	"Each number must be small enough to fit in a 32bit register.", 0Ah
				BYTE	"Afterwards, I will display a list of the integers,"
				BYTE	" their sum, and their average value.", 0Ah
				BYTE	"Note: the range of signed integers that can be entered is "
				BYTE	"[-2 147 483 648, +2 147 483 647]", 0Ah
				BYTE	"This program will accept these numbers, but does not account "
				BYTE	"for the total not fitting into a 32-bit register.", 0Ah, 0Ah, 0
				BYTE	"During input, your entries will be"
				BYTE	"numbered with running subtotal!", 0Ah, 0Ah, 0

integerPrompt	BYTE	"Please enter 10 signed numbers:", 0Ah, 0
errorMessage	BYTE	"BEEP: Your entry either was not a signed number or was too big.", 0Ah, 0

entryMessage	BYTE	0Ah, "You entered these numbers:", 0Ah, 0
sumMessage		BYTE	0Ah, "The sum of these numbers is: ", 0
raveMessage		BYTE	0Ah, "The rounded average is: ", 0
subtotalMess	BYTE	"   Subtotal: ", 0
goodbyeMess		BYTE	0Ah, 0Ah, "Thanks for playing! Ta-tah for now.", 0Ah, 0Ah, 0


array			DWORD	10 DUP(0)
inString		DWORD	10 DUP(0)
reversedString	DWORD	10 DUP(0)

numCount		DWORD	1, 2, 3, 4, 5, 6, 7, 8, 9, 10
ncPunct			BYTE	". ", 0
comma			BYTE	", ", 0
negSign			BYTE	"-", 0

total			DWORD	0
average			DWORD	?
confirmNeg		DWORD	?


.code
main PROC

	; Display intro and instructions, and greet user
		push		OFFSET introMess
		push		OFFSET instructMess
		call		introduction

	; Fills array by geting input from the user
	;	fillArray will call readVal
		push		OFFSET negSign
		push		OFFSET reversedString
		push		OFFSET confirmNeg
		push		OFFSET subtotalMess
		push		OFFSET total
		push		OFFSET inString
		push		OFFSET array
		push		OFFSET numCount
		push		OFFSET integerPrompt
		push 		OFFSET errorMessage
		push		OFFSET ncPunct
		call		fillArray

	; Get rounded average
		push		OFFSET total
		push		OFFSET average
		call		calculations

	; Displays numerical array into string of digits
		push		OFFSET average
		push		OFFSET total
		push		OFFSET negSign
		push		OFFSET entryMessage
		push		OFFSET sumMessage
		push		OFFSET raveMessage
		push		OFFSET array			
		push		OFFSET inString		
		push		OFFSET reversedString
		push		OFFSET comma			
		call		displayAll

	; Say goodbye, just one last time
		push		OFFSET goodbyeMess
		call		farewell
	
exit
main ENDP


; 	------ introduction ------
	;	Welcomes the user, then provides instructions on how to use the program.
	;		EC Message is also displayed.
	;
	;	Receives: addresses of strings ecMess, instructMess, introMess on stack
	;	Returns: none
	;	Preconditions: none
	;	Registers changed: edx

	;	@ instructMess		[ebp + 8]
	;	@ introMess			[ebp + 12]

introduction PROC
	push	ebp
	mov		ebp, esp
	pushad

	displayString	[ebp + 12]
	displayString	[ebp + 8]

	popad
	pop	ebp
	ret	8
introduction ENDP


; 	------ fillArray ------
	;	Begins loop for gettting numeral input from user to store into the array named array.
	;		Also displays running subtotal
	;
	;	Receives: addresses on stack, see commented stack below
	;	Returns: keeps edi as array@ for readVal to store numbers in; keeps running total value 
	;	Preconditions: size of arrays is DWORD
	;	Registers changed: esi, edi, eax, ebx, ecx, edx

	;	@ ncPunct			[ebp + 8]
	;	@ errorMessage		[ebp + 12]
	;	@ integerPrompt		[ebp + 16]
	;	@ numCount			[ebp + 20]
	;	@ array				[ebp + 24]
	;	@ inString			[ebp + 28]
	;	@ total				[ebp + 32]
	;	@ subtotalMess		[ebp + 36]
	;	@ confirmNeg		[ebp + 40]
	;	@ reversedString	[ebp + 44]
	;	@ negSign			[ebp + 48]

fillArray PROC
	push	ebp
	mov		ebp, esp
	pushad

		; Prompt for 10 numbers from user and store in array if valid
			mov				ecx, 10
			mov				edi, [ebp + 24]
			displayString	[ebp + 16]

	filling:
	
		push		ecx

		; Get input from user then validate
			push		[ebp + 24]
			push		[ebp + 32]
			push		[ebp + 48]
			push		[ebp + 44]
			push		[ebp + 20]
			push		[ebp + 40]
			push		[ebp + 8]
			push		[ebp + 28]
			push		[ebp + 12]
			call		readVal

		; Display running subtotal
			displayString	[ebp + 36]
			mov			ebx, [ebp + 32]

			push		[ebp + 48]
			push		[ebp + 44]
			push		[ebp + 28]
			push		[ebx]
			call		writeVal
			call		Crlf

		; increase numCount
			mov			ebx, 4
			add			[ebp + 20], ebx

		; move to next element in array
			add			[ebp + 24], ebx

		pop			ecx
		loop		filling

	popad
	pop ebp
	ret 44
fillArray ENDP


; 	------ readVal ------
	;	Gets input from the user: reads the input as a string then converts to numeric form.
	;		Validates that the user enters a number (no non-digits (+ or - are acceptable)), and
	;		the number fits into 32-bit registers. Each input from the user is put into an array.
	;
	;	Receives: addresses on stack, see commented stack below
	;	Returns: eax: running total; string value from user as a number in inString
	;	Preconditions: size of arrays are DWORD
	;	Registers changed: esi, edi, eax, ebx, ecx, edx

	;	@ array				[ebp + 40]
	;	@ total				[ebp + 36]
	; 	@ negSign			[ebp + 32]
	; 	@ reversedString	[ebp + 28]
	;	@ numCount			[ebp + 24]
	;	@ confirmNeg		[ebp + 20]
	;	@ ncPunct			[ebp + 16]
	;	@ inString			[ebp + 12]
	;	@ errorMessage		[ebp + 8]

readVal PROC
	push	ebp
	mov		ebp, esp
	pushad	

	beginInput:

		mov		edi, [ebp + 40]

		; Reset negative check
			mov			ebx, 0
			mov			edx, [ebp + 20]
			mov			[edx], ebx

		; Number entries
			mov			edx, [ebp + 24]

			push		[ebp + 32]
			push		[ebp + 28]
			push		[ebp + 12]
			push		[edx]
			call		writeVal

			mov			eax, 0
			mov			ebx, [ebp + 12]
			mov			[ebx], eax

		; Get input from user with numbered list, then store input in inString
			getString	[ebp + 16], [ebp+ 12]
			mov			esi, [ebp + 12]

		; Loop by number of digits from user input
			mov			ecx, ebx

			cld

			mov			eax, 0
			mov			ebx, 0
			mov			edx, ecx

		; Validate that input is a number and fits into a 32bit register

		validateNo:

			lodsb

 			; Account for +- signs in the beginning
			;	Check if program is reading the first character		

				sub			edx, ecx
				cmp			edx, 0
				jne			validSign

				; Check if +- is entered
					cmp			al, 45
					je			negativeSign
					cmp			al, 43
					je			positiveSign
					jmp			validSign

					negativeSign:
						mov			ebx, 1
						mov			edx, [ebp + 20]
						mov			[edx], ebx
						mov			ebx, 0

					positiveSign:
						loop 		validateNo

			validSign:

				; Check that input is number
					cmp			al, 48
					jb			inputError
					cmp			al, 57
					ja			inputError

				; Convert string to number
					sub			al, 48

				; Account for which place the number is by 10s
					push		eax
					mov			eax, ebx
					mov			ebx, 10
					mul			ebx

					; Error if carry sign is set
						jc		inputErrorC

					mov			ebx, eax
					pop			eax

					; Combine new digit to number in progress
						add			ebx, eax
					
					; Error if carry sign is set
						jc			inputError

					mov			eax, 0

				loop		validateNo

			; Validate size of number

				mov			eax, ebx

				; Check if negative number
					mov			edx, [ebp + 20]
					mov			ecx, [edx]
					mov			eax, 1
					cmp			ecx, 1
					jne			pos

					cmp			ebx, 2147483648d
					ja			inputError
					test		eax, eax		; Clear OF
					mov			eax, ebx
					jo			inputError
					jmp			validNo

				pos:
					test		eax, eax		; Clear OF
					mov			eax, ebx
					jo			inputError
					cmp			ebx, 2147483647d
					ja			inputError
					jmp			validNo

		; Display message if user enters an invalid input

			inputErrorC:
				pop			eax

			inputError:
				displayString	[ebp + 8]
				jmp				beginInput

		; If all characters are valid, store number

		validNo:

			; Check if negative number

				mov			ebx, [ebp + 20]
				mov			edx, [ebx]
				cmp			edx, 1
				jne			continue

				; If negative:
				; 	Negate number and reset check
				
				neg			eax
				mov			edx, 0
				mov			[ebx], edx

			continue:
				stosd

			mov	edx, [ebp + 36]
			add	eax, [edx]
			mov	[edx], eax

	popad
	pop ebp
	ret 36
readVal ENDP


; 	------ calculations ------
	;	Calculate the rounded average of the array
	;
	;	Receives: addresses of total and rounded average
	;	Returns: stored value of rounded average in average
	;	Preconditions: none
	;	Registers changed: edx, eax, ebx, ecx

	; @ total		[ebp + 12]
	; @ average		[ebp + 8]

calculations	PROC

	push	ebp
	mov		ebp, esp
	pushad

		mov		edx, 0
		mov		eax, 0
		mov		ebx, 0
		mov		ecx, 0

		; Divide total by 10 to get average 
			mov			ecx, [ebp + 12]
			mov			eax, [ecx]

			; Account for negative number
				test		eax, 80000000h
				jns			posdivide

				neg			eax
				mov			ebx, 10
				div			ebx
				neg			eax

				jmp			store

		posdivide:
			mov			ebx, 10
			div			ebx

		store:
			mov			ecx, [ebp + 8]
			mov			[ecx], eax

	popad
	pop		ebp
	ret 8
calculations ENDP


; 	------ displayAll ------
	;	Display the numbers from the user along with its total and average
	;
	;	Receives: addresses on stack, see commented stack below
	;	Returns: none
	;	Preconditions: size of arrays are DWORD
	;	Registers changed: esi, edi, eax, ebx, ecx, edx

	;	@ average				[ebp + 44]
	;	@ total					[ebp + 40]
	;	@ negSign				[ebp + 36]
	;	@ entryMessage			[ebp + 32]
	;	@ sumMessage			[ebp + 28]
	;	@ raveMessage			[ebp + 24]
	;	@ array					[ebp + 20]
	;	@ inString				[ebp + 16]
	;	@ reversedString		[ebp + 12]
	;	@ comma					[ebp + 8]

displayAll	PROC

	push	ebp
	mov		ebp, esp

		; Show numbers entered
			displayString	[ebp + 32]
			mov				esi, [ebp + 20]
			mov				ecx, 10

			printing:
				push		ecx

				push		[ebp + 36]
				push		[ebp + 12]
				push		[ebp + 16]
				push		[esi]
				call		WriteVal

				; Go to next element in array
					add			esi, 4

					pop			ecx
					cmp			ecx, 1
					je			lastNo
					displayString		[ebp + 8]
				
				; Do not display comma after last number
					lastNo:
					loop		printing

		; Show sum
			displayString	[ebp + 28]
			mov				ecx, [ebp + 40]

			push		[ebp + 36]
			push		[ebp + 12]
			push		[ebp + 16]
			push		[ecx]
			call		WriteVal

		; Show rounded average
			displayString	[ebp + 24]
			mov				ecx, [ebp + 44]

			push		[ebp + 36]
			push		[ebp + 12]
			push		[ebp + 16]
			push		[ecx]
			call		WriteVal

	pop	ebp
	ret 40
displayAll ENDP

; 	------ writeVal ------
	;	Converts the number passed so it can be displayed as a string. Uses
	;		macro to display that number as string.
	;
	;	Receives: value (variable), address of inString, reversedString, negSign
	;	Returns: none
	;	Preconditions: none
	;	Registers changed: esi, edi, eax, ebx, ecx, edx

	;	var: value				[ebp + 8]
	;	@ inString				[ebp + 12]
	;	@ reversedString		[ebp + 16]
	;	@ negSign				[ebp + 20]

writeVal	PROC

	push	ebp
	mov		ebp, esp
	push	esi
	push	edi
	push	ecx

		; Get passed number and set inString as destination
			mov			esi, [ebp + 8]
			mov			edi, [ebp + 12]

			mov			ecx, 0						; begin counter for the number of digits
			mov			eax, 0

			mov			eax, esi

		; Check for negative number
			test 		eax, 80000000h
			jns			getConversion
			displayString	[ebp + 20]
			neg 		eax

		getConversion:
			mov			edx, 0
			mov			ebx, 10
			div			ebx
			add			edx, 48

			; Store remainder
				push		eax
				mov			eax, edx

				stosb
				
				pop			eax

				inc			ecx
			
			; End conversion at end of string (no remainder)
				cmp			eax, 0
				jne			getConversion

			stosb

		; -- Reverse code from Paulson Demo6.asm --
			mov			esi, [ebp + 12]	
			add			esi, ecx
			dec			esi
			mov			edi, [ebp + 16]	

			reverseNo:
				std
				lodsb
				cld
				stosb
			
			loop		reverseNo

		; Store 0 to mark the end
			mov			eax, 0
			stosb

		; Display number
			displayString		[ebp + 16]	

	pop	ecx
	pop	edi
	pop	esi
	pop	ebp
	ret 16
writeVal ENDP


; 	------ farewell ------
	;	Bids the user farewell for the last time
	;
	;	Receives: address of goodbye string
	;	Returns: none
	;	Preconditions: none
	;	Registers changed: edx

	; @ goodbyeMess		[ebp + 8]

farewell PROC
	push	ebp
	mov		ebp, esp
	pushad

	displayString	[ebp + 8]

	popad
	pop		ebp
	ret 4
farewell ENDP


END main
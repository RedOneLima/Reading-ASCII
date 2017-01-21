	
NULL		EQU	0
Minus		EQU	0x2D		;Ascii of Carriage Return
Enter		EQU	0x0A	 	;Ascii of Line Feeder
LetterChar	EQU	0x41		;Ascii of A
ConvertChar	EQU	0x37		;value to convert from ascii letter symbol to Hex
Divisor		EQU	0xA		;divisor for converting from hex to dec
MaxNegValue	EQU	0x80000000	;special case

	AREA	ReadingAscii, CODE
	ENTRY
;-------------------------------------------------------------------------
;			Register Allocation
;-------------------------------------------------------------------------
;		Kyle Hewitt 	CS2400	Homework 5
;
;
;R0: reserved for SWI commands		R1: Counter for input loop
;R2: dest for converting from ascii	R3: flag for a user entering a '-'
;R4: holds value being built		R5: contains dividand for divison
;R6: holds remainder for divison	R7: 
;R8: holds address for end of DecStr	R9: holds address for RevStr
;R10: holds address for TwosComp	R11:holds address for DecStr
;R12:					R13:
;-------------------------------------------------------------------------
;			Begin Main Routine
;-------------------------------------------------------------------------
Main

Startover
	LDR R10,=TwosComp	;Store pointers into registers
	LDR R11,=DecStr
	LDR R9, =RevStr
	LDR R8, =DecStr


	MOV R1, #0		;Zero out registers
	MOV R2, #0
	MOV R4, #0
	MOV R5, #0
	MOV R6, #0
	
;******************************************************************************
	
	LDR R0, =InMsg		;Message for user instruction
	SWI 2
UserIn

	MOV R0, #0
	CMP R1, #8		;Check counter value
	BEQ UserInDone		;If counter=8 end loop
	SWI 4			;take keyboard input  
	CMP R0, #Enter		;check to see if return was the value entered
	BEQ UserInDone		;if so end loop
		
	CMP R0, #NULL		;
	BLT ERROR		;if <0 it is invalid
	
	CMP R0, #'A'		;
	BGE ConvertLetter	;if it is >='A' then it has to either be a letter or invalid

	CMP R0, #'9'		;if this is reached then its known we are only dealing with numerical
	BGT ERROR		;	values so if >'9'	
	SUB R2,R0,#'0'		;sub the ascii to the ascii for 0 for num value

FinishBuild

	ADD R4, R2, R4, LSL #4	;build number into R4
	ADD R1, R1,#1		;increment counter
	B UserIn		;loop

;******************************************************************************

ConvertLetter
	
	CMP R0, #'F'		  ;
	BGT ToUpCase		  ;if >'F' it has to either be lower case or invalid
	SUB R2, R0, #ConvertChar  ;subtract the ConvertChar value to get the hex value of the uppercase ascii symbol
	B FinishBuild		  ;return after R2 contains the hex value of the input

;******************************************************************************

ToUpCase

	CMP R0, #'f'		;
	BGT ERROR		;if >'f' it is invalid 
	CMP R0, #'a'		;
	BLT ERROR		;if <'a' it is invalid since all other cases have been checked
	SUB R0, R0, #32		;subtract 32 from the lower case ascii value to get the uppercase
	B ConvertLetter		;branch to the function that deals with uppercase letters

;******************************************************************************

UserInDone
	CMP R4, #MaxNegValue	;
	BEQ ERROR		;error if special case is entered
	CMP R4, #0		;check for negitive number 
	BLT Negitive
	STR R4,[R10]		;store the hex value into TwosComp
	B Convert

Negitive
	MOV R3, #Minus		;set flag for neg value
	STR R4,[R10]		;store the hex value into TwosComp
	STRB R3,[R9], #1	;put the negitive sign at beginning of RevStr

Convert
	BL ToDec		;subroutine


;---------------------------------------------------------------------------	
;			Branch To Subroutine
;---------------------------------------------------------------------------

FillRev
	
	LDRB R4, [R11], #-1	;load byte from DecStr and move index back by 1
	STRB R4, [R9], #1	;store into RevStr and move index up by 1
	CMP R11, R8		;compare the start and end pointer's address of DecStr
	BLT DisplayResult	;if the end pointer address becomes less than the start then all bytes have been moved
	B FillRev		;loop until pointers cross
	
		


DisplayResult
	LDR R0,=OutMsg		;a message for the user to proceed the program's result
	SWI 2

	MOV R4, #NULL		;move 0 into R4 for RevStr's null terminator
	STRB R4,[R9]		;store it to the end of the string
	LDR R0, =RevStr 	;load RevStr into R0 for display
	SWI 2			;display the converted signed number


	SWI 0x11		;terminate program

;---------------------------------------------------------------------------
;			Begin Subroutine
;---------------------------------------------------------------------------

ToDec
	CMP R3, #Minus		;Check if neg flag is set
	MVNEQ R4, R4		;if so turn neg 2sComp to pos for conversion
	ADDEQ R4,R4,#1		;

;******************************************************************************
	 
Loop
	CMP R4, #Divisor	;
	BLT addRemainder	;if dividand is less than divisor div is done
	SUB R4, R4, #Divisor	;division through repitive subraction
	ADD R5, R5, #1		;incremented for every full subtraction of the divisor
	B Loop

;******************************************************************************

addRemainder

	CMP R4, #'A'		;account for letter values
	BGE LetterRem		;if >='A' then the remainder is a letter
	ADD R4, R4, #'0'	;build ASCII number from remainder
	STRB R4, [R11],#1	;put ASCII code into DecStr
	CMP R5,#Divisor		;
	BLT Done		;if the remaining quotent is smaller than the divisor
	MOV R4, R5		;the quotent becomes the new dividand
	MOV R5, #NULL		;clear R5 for next round
	B Loop

LetterRem

	ADD R4, R4, #'A'	;build ASCII number from remainder
	STRB R4, [R11],#1	;put ASCII code into DecStr
	CMP R5,#Divisor		;
	BLT Done		;if the remaining quotent is smaller than the divisor
	MOV R4, R5		;the quotent becomes the new dividand
	MOV R5, #NULL		;clear R5 for next round
	B Loop
;******************************************************************************

Done 
	ADD R4, R5, #'0'	;the last itteration the final remainder is the quotent that is too small to subtract
	STRB R4, [R11]		;store into memory without increasing the index so that R11 points to end of string

	
	MOV PC, LR		;return
	
;-------------------------------------------------------------------------------
;				Error Handling
;-------------------------------------------------------------------------------

ERROR
	LDR R0, =ErrorMsg	;displays a message saying that the number was invalid
	SWI 2			;
	B Startover		;start from the beginning of the main routine

;-------------------------------------------------------------------------------
;				End Of Code Area
;-------------------------------------------------------------------------------

	AREA	Data, DATA

TwosComp DCD	0 
DecStr		% 12
RevStr 	 	% 12
ErrorMsg DCB	Enter ,"Invalid input. Please enter entire number again.",Enter,0
InMsg 	 DCB	"Enter a signed Hex value: ",0
OutMsg 	 DCB	Enter,"Decimal Value: ",0


	END



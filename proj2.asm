; ==========================================================
:
;     LED.1 : RED : P2.4            SW.1 : P2.0 
;     LED.2 : YEL : P0.5            SW.2 : P0.1
;     LED.3 : GRN : P2.7            SW.3 : P2.3
;     LED.4 : AMB : P0.6            SW.4 : P0.2
;     LED.5 : BLU : P1.6            SW.5 : P1.4
;     LED.6 : RED : P0.4            SW.6 : P0.0
;     LED.7 : YEL : P2.5            SW.7 : P2.1
;     LED.8 : GRN : P0.7            SW.8 : P0.3
;     LED.9 : AMB : P2.6            SW.9 : P2.2
;
;     Theirs:     r3.r4 = 65536 - 3686400/(F)
;     Correct:    r3.r4 = 65536 - 3686400/(2F)
;     Kory's timings: 32,c8,c8
; ==========================================================
#include <reg932.inc>

  CSEG at 0x0000
init:
  MOV P0M1,#0				              ; Set ports to bi-directional
	MOV P1M1,#0
	MOV P2M1,#0
	MOV TMOD,#0x01		              ; Set TIMER 0 into mode 1
  MOV R7,#0

  CSEG AT 0x000B		            	; Interrupt Vector Address for TIMER 0
	CPL P1.7				              	; compliments P1.4 to produce sound from speaker
	CLR C
	MOV A, R5				              	; Reads upper byte of 16-bit timer re-load value
	MOV TH0, A			              	; into A and puts it into the upper byte of TIMER 0
	MOV A, R6				              	; Reads lower byte of 16-bit timer re-load value
	MOV TL0, A			              	; into A and puts it into the lower byte of TIMER 0
	RETI						              	; Returns from the interrupt

main:
	JNB P2.0,cuntr                  ; Stay in loop until button is pressed
	JMP main

cuntr:
  MOV R0,#255
  MOV R1,#255
  MOV R2,#255

cntrDelay:
  JNB P2.0,pressedButton
  DJNZ R2,cntrDelay
  DJNZ R1,cntrDelay
  DJNZ R0,cntrDelay
  ACALL MATHS
  ACALL THROB

pressedButton:
  CLR P1.6
  JNB P2.0,pressedButton
  ACALL DEBOUNCE
  INC R7
  SETB P1.6
  SJUMP cuntr
	
; ==========================================================
;	Subroutines Go Below This Line. Also CAPS for all Subs.
; ==========================================================	

MATHS:
  MOV A,R7                        ; Num of Presses into Accum
  MOV B,#16                       ; Divide by 16
  DIV AB                          ; 
  MOV 1DH,R7                      ; store total button pushes
  MOV R3,A                        ; Store quotient for beeps
  MOV R4,B                        ; Store remainder for binary output of leds
  RET

THROB:                            ; makes the speaker 'drop a mad beat'
  JZ noThrob
  throb:
    MOV TMOD,#0x01                ; R0: length of beep
    MOV TH0,#0                    ; R1: 
    MOV TL0,#0                    ; R2: 
    MOV R5,#0xF7                  ; R3: number of beeps 
    MOV R6,#0xD1                  ; R4: remainder for leds
    SETB ET0                      ; R5: upperbit of timer for A6 note
    SETB EA                       ; R6: lowerbit of timer A6 note
    SETB TR0                      ; R7: Number of presses

    MOV R0,#32
    acall DELAY
    CLR TRO
    MOV R0,#16
    MOV R5,#0x00
    MOV R6,#0x00
    acall DELAY
    DJNZ R3, throb
  noThrob:
    nop

  RET

DEBOUNCE:                         ; Used for debouncing switches
  debounceLoop:
    MOV R1,#50
  debounceLoop_1:
    MOV R2,#200

    DJNZ R2,debounceLoop_1
    DJNZ R1,debounceLoop
  RET

DELAY:                            ; R0 is set before call to lengthen loop
  delayLoop:
    MOV R1,#85
  delayLoop_1:
    MOV R2,#255
  delayLoop_2:
    DJNZ R2,delayLoop_2
    DJNZ R1,delayLoop_1
    DJNZ R0,delayLoop
    RET

  END

;* PRU1 Firmware for BeagleLogic
;*
;* Copyright (C) 2014 Kumar Abhishek <abhishek@theembeddedkitchen.net>
;*
;* This file is a part of the BeagleLogic project
;*
;* This program is free software; you can redistribute it and/or modify
;* it under the terms of the GNU General Public License version 2 as
;* published by the Free Software Foundation.

	.include "beaglelogic-pru-defs.inc"

NOP	.macro
	 ADD R0.b0, R0.b0, R0.b0
	.endm

; Generic delay loop macro
; Also includes a post-finish op
DELAY	.macro Rx, op
	SUB	R0, Rx, 2
	QBEQ	$E?, R0, 0
$M?:	SUB	R0, R0, 1
	QBNE	$M?, R0, 0
$E?:	op
	.endm

	.sect ".text:main"
	.global asm_main
asm_main:
	; Set C28 in this PRU's bank =0x24000
	LDI32  R0, CTPPR_0+0x2000               ; Add 0x2000
	LDI    R1, 0x00000240                   ; C28 = 00_0240_00h = PRU1 CFG Registers
	SBBO   &R1, R0, 0, 4

	; Configure R2 = 0x0000 - ptr to PRU1 RAM
	LDI    R2, 0

	; Enable the cycle counter
	LBCO   &R0, C28, 0, 4
	SET    R0, R0, 3
	SBCO   &R0, C28, 0, 4

	; Load Cycle count reading to registers [LBCO=4 cycles, SBCO=2 cycles]
	LBCO   &R0, C28, 0x0C, 4
	SBCO   &R0, C24, 0, 4

	; Load magic bytes into R2
	LDI32  R0, 0xBEA61E10

	; Wait for PRU0 to load configuration into R14[samplerate] and R15[unit]
	; This will occur from an downcall issued to us by PRU0
	HALT

	; Jump to the appropriate sample loop
	; TODO

	LDI    R31, PRU0_ARM_INTERRUPT_B + 16   ; Signal SYSEV_PRU0_TO_ARM_B to kernel driver
	HALT

	; Sample starts here
	; Maintain global bytes transferred counter (8 byte bursts)
	LDI    R29, 0
	QBEQ   sampleincnumberstest, R14, 0
	QBNE   samplexm, R14, 1
sample100m:
	QBEQ   sample100m8, R15, 1
	QBEQ   tdmArraySamplingInit, R15, 3
sample100m16:
	MOV    R21.w0, R31.w0
	NOP
	MOV    R21.w2, R31.w0
	NOP
$sample100m16$2:
	MOV    R22.w0, R31.w0
	NOP
	MOV    R22.w2, R31.w0
	NOP
	MOV    R23.w0, R31.w0
	NOP
	MOV    R23.w2, R31.w0
	NOP
	MOV    R24.w0, R31.w0
	NOP
	MOV    R24.w2, R31.w0
	NOP
	MOV    R25.w0, R31.w0
	NOP
	MOV    R25.w2, R31.w0
	NOP
	MOV    R26.w0, R31.w0
	NOP
	MOV    R26.w2, R31.w0
	NOP
	MOV    R27.w0, R31.w0
	NOP
	MOV    R27.w2, R31.w0
	NOP
	MOV    R28.w0, R31.w0
	ADD    R29, R29, 32                     ; Maintain global byte counter
	MOV    R28.w2, R31.w0
	XOUT   10, &R21, 36                     ; Move data across the broadside
	MOV    R21.w0, R31.w0
	LDI    R31, PRU1_PRU0_INTERRUPT + 16    ; Jab PRU0
	MOV    R21.w2, R31.w0
	JMP    $sample100m16$2

sample100m8:
	MOV    R21.b0, R31.b0
	NOP
	MOV    R21.b1, R31.b0
	NOP
$sample100m8$2:
	MOV    R21.b2, R31.b0
	NOP
	MOV    R21.b3, R31.b0
	NOP
	MOV    R22.b0, R31.b0
	NOP
	MOV    R22.b1, R31.b0
	NOP
	MOV    R22.b2, R31.b0
	NOP
	MOV    R22.b3, R31.b0
	NOP
	MOV    R23.b0, R31.b0
	NOP
	MOV    R23.b1, R31.b0
	NOP
	MOV    R23.b2, R31.b0
	NOP
	MOV    R23.b3, R31.b0
	NOP
	MOV    R24.b0, R31.b0
	NOP
	MOV    R24.b1, R31.b0
	NOP
	MOV    R24.b2, R31.b0
	NOP
	MOV    R24.b3, R31.b0
	NOP
	MOV    R25.b0, R31.b0
	NOP
	MOV    R25.b1, R31.b0
	NOP
	MOV    R25.b2, R31.b0
	NOP
	MOV    R25.b3, R31.b0
	NOP
	MOV    R26.b0, R31.b0
	NOP
	MOV    R26.b1, R31.b0
	NOP
	MOV    R26.b2, R31.b0
	NOP
	MOV    R26.b3, R31.b0
	NOP
	MOV    R27.b0, R31.b0
	NOP
	MOV    R27.b1, R31.b0
	NOP
	MOV    R27.b2, R31.b0
	NOP
	MOV    R27.b3, R31.b0
	NOP
	MOV    R28.b0, R31.b0
	NOP
	MOV    R28.b1, R31.b0
	NOP
	MOV    R28.b2, R31.b0
	ADD    R29, R29, 32
	MOV    R28.b3, R31.b0
	XOUT   10, &R21, 36                     ; Move data across the broadside
	MOV    R21.b0, R31.b0
	LDI    R31, PRU1_PRU0_INTERRUPT + 16    ; Jab PRU0
	MOV    R21.b1, R31.b0
	JMP    $sample100m8$2

tdmArraySamplingInit:
	;; R21 to R28 used for eight samples. But only the first 24 bits (32)
	;; R21 first used for 262144 initiating SCKs
	;; R18 counts 0, 1 (reset) to keep track of 4 or 8 recorded samples
	;; R19 sample timing. Increments every new WS
	
	;; R20.b0 used for simultaneous sampling of 4 TDM bits
	;; R20.b1 used for WS and SCK for first bit per sample
	;; R20.b2 used for WS counting down interation var
	;; R20.b3 used for counting down blanks interation var
	
	;; todo: start sequence with 262144 (r21) SCK at 25 MHz
	;; yeah, each 8 clock cycle
	LDI R21, 262144
	LDI R22, 0
	LDI R23, 0
	LDI R24, 0
	LDI R29, 0		;zero recorded bytes
	LDI R30.w0, 0x00	; Set both SCK as well as both WS to 0
	LDI R18, 0
	LDI R19, 0
	LDI R20.b2, 15		;WS only once every 16th iteration
	LDI R20.b1, 0x33	;WS first round

tdmArraySamplingInitLoop:
	LDI R30.b0, 0x03		;Set both SCK to 1
	NOP
	NOP
	NOP

	LDI R30.b0, 0x00		;Set both SCK to 0
	SUB R21, R21, 1
	NOP
	QBNE tdmArraySamplingInitLoop, R21, 0
	
tdmArraySamplingCycleStart:
	;; bit 23 (MSB)
	LDI R30.b0,  R20.b1	; SCK and WS (WS for first mics on loops)
	MOV  R20.b0,  R31.b0	; Sample all four mics simultaneously
	MOV   R21.t23, R21.t24	; mic from loop 1
	MOV   R22.t23, R21.t25	; mic from loop 2

	LDI R30.b0,  0x0000	; !WS and !SCK
	MOV   R23.t23, R21.t26	; mic from loop 3
	MOV   R24.t23, R21.t27	; mic from loop 4
	NOP

	
	LDI R30.b0,  0x03	; SCK
	MOV  R20.b0,  R31.b0	; Sample all four first mics simultaneously
	MOV   R21.t22, R21.t24	; 
	MOV   R22.t22, R21.t25	; 

	LDI R30.b0,  0x00	; !SCK
	MOV   R23.t22, R21.t26	; 
	MOV   R24.t22, R21.t27	; 
	NOP

	
	;; todo: bits 20 all the way to bits 1
	;; Do not forget!!!!!!!!!!!!!!!!!!!

	LDI R30.b0, 0x03	; SCK
	MOV  R20.b0, R31.b0	; Sample all four first mics simultaneously
	MOV   R21.t0, R21.t24	;
	MOV   R22.t0, R21.t25	;

	LDI R30.b0, 0x00	; !SCK
	MOV   R23.t0, R21.t26	;
	MOV   R24.t0, R21.t27	;
	;XOUT 10, &R21, 16	; Move data accross to the other PRU
	ADD R18, R18, 1
	
	;; todo: create SCKs for the next 8 empty bits
tdmArraySamplingBlanks:
	LDI R30.b0, 0x03	;Set both SCK to 1
	LDI   R20.b3, 7		;Set iteration variable for blanks 
	SUB   R20.b2, R20.b2, 1	;WS only every 16th
	;LDI R31, PRU1_PRU0_INTERRUPT + 16    ; Jab PRU0
	NOP 			; JAB PRU0 after XOUT

	LDI R30.b0, 0x00	;Set both SCK to 0
	QBEQ  upcommingWS, R20.b2, 0
	LDI   R20.b1, 0x03	;WS is set not set for next sample
	QBA   $tdmArraySamplingBlanks$2	;keep timing

upcommingWS:
	LDI   R20.b1, 0x33	;WS is set for next sample
	LDI   R20.b2, 16	;Set iteration variable for WS only every 16th

	;; todo: use regs r25-r28 instead. xout first time, xin to
	;; 	r21-r24 before xout of all. Send sampTime in MSBs of R21-r24.
	
tdmArraySamplingBlanks2:
	LDI R30.b0, 0x03	;Set both SCK to 1
	ADD   R29, R29, 16	;increment recorded bytes
	NOP
	NOP

	LDI R30.b0, 0x00	;Set both SCK to 0
	SUB   R20.b3, R20.b3, 1
	QBNE  tdmArraySamplingBlanks3, R20.b3, 0 ;keep timing, once more blanks
	QBA   tdmArraySamplingCycleStart

tdmArraySamplingBlanks3:
	QBA   tdmArraySamplingBlanks2	;keep timing, once more blanks
	
	













	
samplexm:
	QBEQ   samplexm8, R15, 1
samplexm16:
	MOV    R21.w0, R31.w0
	DELAY  R14, NOP
	MOV    R21.w2, R31.w0
	DELAY  R14, NOP
$samplexm16$2:
	MOV    R22.w0, R31.w0
	DELAY  R14, NOP
	MOV    R22.w2, R31.w0
	DELAY  R14, NOP
	MOV    R23.w0, R31.w0
	DELAY  R14, NOP
	MOV    R23.w2, R31.w0
	DELAY  R14, NOP
	MOV    R24.w0, R31.w0
	DELAY  R14, NOP
	MOV    R24.w2, R31.w0
	DELAY  R14, NOP
	MOV    R25.w0, R31.w0
	DELAY  R14, NOP
	MOV    R25.w2, R31.w0
	DELAY  R14, NOP
	MOV    R26.w0, R31.w0
	DELAY  R14, NOP
	MOV    R26.w2, R31.w0
	DELAY  R14, NOP
	MOV    R27.w0, R31.w0
	DELAY  R14, NOP
	MOV    R27.w2, R31.w0
	DELAY  R14, NOP
	MOV    R28.w0, R31.w0
	DELAY  R14, "ADD    R29, R29, 32"                     ; Maintain global byte counter
	MOV    R28.w2, R31.w0
	DELAY  R14, "XOUT   10, &R21, 36"                     ; Move data across the broadside
	MOV    R21.w0, R31.w0
	DELAY  R14, "LDI    R31, PRU1_PRU0_INTERRUPT + 16"    ; Jab PRU0
	MOV    R21.w2, R31.w0
	DELAY  R14, "JMP    $samplexm16$2"

samplexm8:
	MOV    R21.b0, R31.b0
	DELAY  R14, NOP
	MOV    R21.b1, R31.b0
	DELAY  R14, NOP
$samplexm8$2:
	MOV    R21.b2, R31.b0
	DELAY  R14, NOP
	MOV    R21.b3, R31.b0
	DELAY  R14, NOP
	MOV    R22.b0, R31.b0
	DELAY  R14, NOP
	MOV    R22.b1, R31.b0
	DELAY  R14, NOP
	MOV    R22.b2, R31.b0
	DELAY  R14, NOP
	MOV    R22.b3, R31.b0
	DELAY  R14, NOP
	MOV    R23.b0, R31.b0
	DELAY  R14, NOP
	MOV    R23.b1, R31.b0
	DELAY  R14, NOP
	MOV    R23.b2, R31.b0
	DELAY  R14, NOP
	MOV    R23.b3, R31.b0
	DELAY  R14, NOP
	MOV    R24.b0, R31.b0
	DELAY  R14, NOP
	MOV    R24.b1, R31.b0
	DELAY  R14, NOP
	MOV    R24.b2, R31.b0
	DELAY  R14, NOP
	MOV    R24.b3, R31.b0
	DELAY  R14, NOP
	MOV    R25.b0, R31.b0
	DELAY  R14, NOP
	MOV    R25.b1, R31.b0
	DELAY  R14, NOP
	MOV    R25.b2, R31.b0
	DELAY  R14, NOP
	MOV    R25.b3, R31.b0
	DELAY  R14, NOP
	MOV    R26.b0, R31.b0
	DELAY  R14, NOP
	MOV    R26.b1, R31.b0
	DELAY  R14, NOP
	MOV    R26.b2, R31.b0
	DELAY  R14, NOP
	MOV    R26.b3, R31.b0
	DELAY  R14, NOP
	MOV    R27.b0, R31.b0
	DELAY  R14, NOP
	MOV    R27.b1, R31.b0
	DELAY  R14, NOP
	MOV    R27.b2, R31.b0
	DELAY  R14, NOP
	MOV    R27.b3, R31.b0
	DELAY  R14, NOP
	MOV    R28.b0, R31.b0
	DELAY  R14, NOP
	MOV    R28.b1, R31.b0
	DELAY  R14, NOP
	MOV    R28.b2, R31.b0
	DELAY  R14, "ADD    R29, R29, 32"
	MOV    R28.b3, R31.b0
	DELAY  R14, "XOUT   10, &R21, 36"
	MOV    R21.b0, R31.b0
	DELAY  R14, "LDI    R31, PRU1_PRU0_INTERRUPT + 16"
	MOV    R21.b1, R31.b0
	DELAY  R14, "JMP    $samplexm8$2"

; Unit test to check for dropped frames
; Runs at 100 MHz
sampleincnumberstest:
	LDI    R21, 0
	NOP
	NOP
	NOP
$S1:	ADD    R22, R21, 1
	NOP
	NOP
	NOP
	ADD    R23, R22, 1
	NOP
	NOP
	NOP
	ADD    R24, R23, 1
	NOP
	NOP
	NOP
	ADD    R25, R24, 1
	NOP
	NOP
	NOP
	ADD    R26, R25, 1
	NOP
	NOP
	NOP
	ADD    R27, R26, 1
	NOP
	NOP
	NOP
	ADD    R28, R27, 1
	XOUT   10, &R21, 36
	LDI    R31, PRU1_PRU0_INTERRUPT + 16
	NOP
	ADD    R21, R28, 1
	NOP
	NOP
	JMP    $S1

; End-of-firmware
	HALT

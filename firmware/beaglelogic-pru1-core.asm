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
	;; Taking samples from ICS-52000 in for daisy chains.
	;; Must send SCK evenly at 25 MHz.
	;; Each sample is 24 bits.
	;; Each daisy chain consists of 16 mics.
	;; WS is sent first iteration and then every 16th mic, i.e. the first mic.
	
	;; R21 to R28 used for eight samples. But only the first 24 bits (of 32)
	;; R21 first used for 262144 initiating SCKs
	;; R18 counts 0, 1 (reset) to keep track of 4 or 8 recorded samples
	;; R19 sample timing. Increments every new WS
	
	;; R20.b0 used for simultaneous sampling of 4 TDM bits
	;; R20.b1 used for WS and SCK for first bit per sample
	;; R20.b2 used for WS counting down interation var
	;; R20.b3 used for counting down blanks interation var
	
	ZERO R18, 48		;clear R18 to R29
	LDI R20.b1, 0x33	;SCK and WS first round
	LDI R20.b2, 16		;WS only once every 16th iteration
	LDI R21, 262144		;var for start sequence with 262144 SCK at 25 MHz
	LDI R30.w0, 0x00	; Set both SCK as well as both WS to 0

tdmArraySamplingInitLoop:
	LDI R30.b0, 0x03	;Set both SCK to 1
	NOP
	NOP
	NOP

	LDI R30.b0, 0x00	;Set both SCK to 0
	SUB R21, R21, 1		;Decrease from initial 262144
	NOP
	QBNE tdmArraySamplingInitLoop, R21, 0

	;; Done! Now valid samples after first WS
	
tdmArraySamplingCycleStart:
	;; SCK for bit 23 (MSB)
	MOV R30.b0,  R20.b1	; SCK and WS (WS for first mics on loops)
	NOP
	NOP
	NOP
	
	LDI R30.b0,  0x00	; !WS and !SCK
	MOV  R20.b0,  R31.b0	; Sample all four mics simultaneously
	MOV   R25.t23, R20.t0	; mic from loop 1
	MOV   R26.t23, R20.t1	; mic from loop 2

	;; SCK for bit 22
	LDI R30.b0,  0x03	; SCK
	MOV   R27.t23, R20.t2	; mic from loop 3
	MOV   R28.t23, R20.t3	; mic from loop 4
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t22, R20.t0	; 
	MOV   R26.t22, R20.t1	; 

	;; SCK for bit 21
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t22, R20.t2	; 
	MOV   R28.t22, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t21, R20.t0	; 
	MOV   R26.t21, R20.t1	; 

	;; SCK for bit 20
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t21, R20.t2	; 
	MOV   R28.t21, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t20, R20.t0	; 
	MOV   R26.t20, R20.t1	; 

	;; SCK for bit 19
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t20, R20.t2	; 
	MOV   R28.t20, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t19, R20.t0	; 
	MOV   R26.t19, R20.t1	; 

	;; SCK for bit 18
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t19, R20.t2	; 
	MOV   R28.t19, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t18, R20.t0	; 
	MOV   R26.t18, R20.t1	; 

	;; SCK for bit 17
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t18, R20.t2	; 
	MOV   R28.t18, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t17, R20.t0	; 
	MOV   R26.t17, R20.t1	; 

	;; SCK for bit 16
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t17, R20.t2	; 
	MOV   R28.t17, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t16, R20.t0	; 
	MOV   R26.t16, R20.t1	; 

	;; SCK for bit 15
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t16, R20.t2	; 
	MOV   R28.t16, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t15, R20.t0	; 
	MOV   R26.t15, R20.t1	; 

	;; SCK for bit 14
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t15, R20.t2	; 
	MOV   R28.t15, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t14, R20.t0	; 
	MOV   R26.t14, R20.t1	; 

	;; SCK for bit 13
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t14, R20.t2	; 
	MOV   R28.t14, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t13, R20.t0	; 
	MOV   R26.t13, R20.t1	; 

	;; SCK for bit 12
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t13, R20.t2	; 
	MOV   R28.t13, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t12, R20.t0	; 
	MOV   R26.t12, R20.t1	; 

	;; SCK for bit 11
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t12, R20.t2	; 
	MOV   R28.t12, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t11, R20.t0	; 
	MOV   R26.t11, R20.t1	; 

	;; SCK for bit 10
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t11, R20.t2	; 
	MOV   R28.t11, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t10, R20.t0	; 
	MOV   R26.t10, R20.t1	; 

	;; SCK for bit 9
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t10, R20.t2	; 
	MOV   R28.t10, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t9, R20.t0	; 
	MOV   R26.t9, R20.t1	; 

	;; SCK for bit 8
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t9, R20.t2	; 
	MOV   R28.t9, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t8, R20.t0	; 
	MOV   R26.t8, R20.t1	; 

	;; SCK for bit 7
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t8, R20.t2	; 
	MOV   R28.t8, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t7, R20.t0	; 
	MOV   R26.t7, R20.t1	; 

	;; SCK for bit 6
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t7, R20.t2	; 
	MOV   R28.t7, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t6, R20.t0	; 
	MOV   R26.t6, R20.t1	; 

	;; SCK for bit 5
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t6, R20.t2	; 
	MOV   R28.t6, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t5, R20.t0	; 
	MOV   R26.t5, R20.t1	; 

	;; SCK for bit 4
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t5, R20.t2	; 
	MOV   R28.t5, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t4, R20.t0	; 
	MOV   R26.t4, R20.t1	; 

	;; SCK for bit 3
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t4, R20.t2	; 
	MOV   R28.t4, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t3, R20.t0	; 
	MOV   R26.t3, R20.t1	; 

	;; SCK for bit 2
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t3, R20.t2	; 
	MOV   R28.t3, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t2, R20.t0	; 
	MOV   R26.t2, R20.t1	; 

	;; SCK for bit 1
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t2, R20.t2	; 
	MOV   R28.t2, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t1, R20.t0	; 
	MOV   R26.t1, R20.t1	; 

	;; SCK for bit 0
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t1, R20.t2	; 
	MOV   R28.t1, R20.t3	; 
	NOP

	LDI R30.b0,  0x00	; !SCK
	MOV  R20.b0,  R31.b0	;
	MOV   R25.t0, R20.t0	; 
	MOV   R26.t0, R20.t1	; 

	;; SCK for empty bit 0 [0-7]
	LDI R30.b0, 0x03	; SCK
	MOV   R27.t0, R20.t2	; 
	MOV   R28.t0, R20.t3	; 
	NOP

	LDI R30.b0, 0x00	; !SCK
	NOP
	NOP
	QBEQ moveFirstFour, R18, 0 ; Move samples to lower regs

sendEightSamples:	
	;; While giving SCK to empty bit 1
	;; Giving data to other PRU
	LDI R30.b0, 0x03	; SCK
	ADD R29, R29, 32	;byte counter
	XOUT  10, &R21, 36     ; Move data across the broadside
	LDI   R31, PRU1_PRU0_INTERRUPT + 16    ; Jab PRU0

	LDI R30.b0, 0x00	; !SCK
	LDI   R18, 0
	NOP
	QBA tdmArraySamplingBlanks
	
moveFirstFour:
	;; While giving SCK to empty bit 1
	;; We will send 8 samples (registers) at a time
	LDI R30.b0, 0x03	; SCK
	MOV R21, R25
	MOV R22, R26
	MOV R23, R27

	LDI R30.b0, 0x00	; !SCK
	MOV R24, R28
	LDI R18, 1
	NOP
	

tdmArraySamplingBlanks:
	;; giving SCK to empty bit 1 (and 2)
	LDI R30.b0, 0x03	;Set both SCK to 1
	LDI   R20.b3, 4		;Set iteration variable for blanks 
	SUB   R20.b2, R20.b2, 1	;WS only every 16th
	NOP

	LDI R30.b0, 0x00	;Set both SCK to 0
	QBEQ  upcommingWS, R20.b2, 0

	LDI   R20.b1, 0x03	;WS is set not set for next sample
	NOP

	;; SCK for empty bit 2
	LDI R30.b0, 0x03		;Set both SCK to 1
	NOP
	NOP
	NOP

	LDI R30.b0, 0x00		;Set both SCK to 0
	NOP
	NOP
	QBA   tdmArraySamplingBlanks2	;keep timing

upcommingWS:
	LDI   R20.b1, 0x33	;WS is set for next sample
	LDI   R20.b2, 16	;Set iteration variable for WS only every 16th

	;; alternative for empty bit 2
	LDI R30.b0, 0x03		;Set both SCK to 1
	ADD R19, R19, 1
	LDI R25.b3, R19.b3
	LDI R26.b3, R19.b2

	LDI R30.b0, 0x00		;Set both SCK to 0
	LDI R27.b3, R19.b1
	LDI R28.b3, R19.b0
	NOP
	

tdmArraySamplingBlanks2:
	;; SCK for empty bits 3-7
	LDI R30.b0, 0x03	;Set both SCK to 1
	NOP
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

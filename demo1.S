CUSTOM	equ	$dff000

DMACON  equ	$096
DMACONR	equ	$002

INTENA 	equ	$09a
INTENAR	equ	$01c

INTREQ	equ	$09c
INTREQR	equ	$01e

ADKCON	equ	$09e
ADKCONR	equ	$010

COP1LCH	equ	$080
COPJMP1	equ	$088
VPOSR	equ	$004

BLTCON0	equ	$040
BLTCON1 equ	$042
BLTAFWM	equ	$044
BLTALWM	equ	$046
BLTCPTH equ	$048
BLTAPTH	equ	$050
BLTDPTH	equ	$054
BLTSIZE	equ	$058
BLTCON0L equ	$05A	; Blitter control 0, lower 8 bits (minterms)
BLTCMOD equ	$060
BLTBMOD equ	$062
BLTAMOD equ	$064
BLTDMOD equ	$066
BLTBDAT equ	$072
BLTADAT	equ 	$074


start:
	move.l	$80.w,-(a7)
	move.l	#program,$80.w
	trap	#0
	move.l	(a7)+,$80.w
	rts

program:
	lea	CUSTOM,a1
	move.w	DMACONR(a1),-(a7)		; save enabled dma channels
	move.w	INTENAR(a1),-(a7)		; save enabled interrupts
	;move.w	#%0111111111111111,INTENA(a7)	; disable all interupts
	move.w	INTREQR(a1),-(a7)		; store current interrupt request bits
	move.w	ADKCONR(a1),-(a7)		; store current disk and sound control

	bsr	main_init
	bsr	scroller_init

.vblk:	move.l	VPOSR(a1),d0			; wait for verticl blank
	and.l	#$0001ff00,d0
	cmp.l	#$00000000,d0
	bne.b	.vblk

	move.l	#copperlist,COP1LCH(a1)
	move.w	#%0111111111111111,DMACON(a1)	; turn off all dma 
	move.w	#%1000001111000000,DMACON(a1)	; enable bitplane + copper + blitter dma

loop:
	move.l	VPOSR(a1),d0			; wait for line $40
	and.l	#$0001ff00,d0
	cmp.l	#$00004000,d0
	bne.b	loop

	move.w	#$0f0,$dff180			; bg red on mainloop start

	bsr	scroller_frame
	bsr	main_frame

	lea	CUSTOM,a1

	move.w	#$000,$dff180			; bg black on mainloop finish

	btst	#6,$bfe001
	bne.b	loop

	lea	CUSTOM,a1

	move.l	$4,a6
	move.l	156(a6),a6
	move.l	38(a6),COP1LCH(a1)		; restore system copper list

	move.w	#$8000,d1			; enable bit

	move.w	(a7)+,d0			; restore disk and sound control
	or.w	d1,d0
	move.w	d0,ADKCON(a1)

	move.w	(a7)+,d0			; restore interrupt request bits
	or.w	d1,d0
	move.w	d0,INTREQ(a1)

	move.w	(a7)+,d0			; restore enabled interrupts
	or.w	d1,d0
	move.w	d0,INTENA(a1)

	move.w	(a7)+,d0			; restore enabled dma channels
	or.w	d1,d0
	move.w	d0,DMACON(a1)

	rte

main_init:
	move.l	mainscreenp,d0
	lea	mainbitp,a0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	rts

main_frame:
	lea	CUSTOM,a6
	move.l	mainscreenp,a0
	move.w	#20,d4
	move.w	#150,d5
	bsr	clearmem

	move.w	#40,d4

	move.l	#46,d0
	move.l	#52,d1
	move.l	#0,d2
	move.l	#52,d3
	bsr	draw_line

	move.l	#48,d0
	move.l	#52,d1
	move.l	#0,d2
	move.l	#80,d3
	bsr	draw_line

	move.l	#50,d0
	move.l	#52,d1
	move.l	#0,d2
	move.l	#147,d3
	bsr	draw_line

	move.l	#52,d0
	move.l	#52,d1
	move.l	#50,d2
	move.l	#147,d3
	bsr	draw_line

	move.l	#54,d0
	move.l	#52,d1
	move.l	#60,d2
	move.l	#147,d3
	bsr	draw_line

	move.l	#56,d0
	move.l	#52,d1
	move.l	#319,d2
	move.l	#147,d3
	bsr	draw_line

	move.l	#56,d0
	move.l	#52,d1
	move.l	#319,d2
	move.l	#52,d3
	bsr	draw_line

	; upwards
	move.l	#48,d0
	move.l	#48,d1
	move.l	#1,d2
	move.l	#2,d3
	bsr	draw_line

	move.l	#50,d0
	move.l	#49,d1
	move.l	#30,d2
	move.l	#2,d3
	bsr	draw_line


	move.l	#52,d0
	move.l	#48,d1
	move.l	#52,d2
	move.l	#2,d3
	bsr	draw_line

	move.l	#54,d0
	move.l	#48,d1
	move.l	#80,d2
	move.l	#2,d3
	bsr	draw_line

	move.l	#56,d0
	move.l	#48,d1
	move.l	#319,d2
	move.l	#2,d3
	bsr	draw_line


	move.l	mainscreenp,d0			; Flip and update copperlist
	move.l	mainscreenp+4,d1
	move.l	d1,mainscreenp
	move.l	d0,mainscreenp+4
	lea	mainbitp,a0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)

	add.w	#1,XCLIP0
	cmp.w	#320,XCLIP0
	bne	.l
	move.w	#0,XCLIP0

.l	move.w	XCLIP0,XCLIP1
	add.w	#40,XCLIP1
	rts

clearmem:
	; a0 - screen address
	; d4 - screen width in words
	; d5 - screen height
	; a6 - custom base

	; destroyed regs: d0,d1

.wait:	btst	#14,DMACONR(a6)		; wait for blitter ready
	bne.b	.wait

	move.l	a0,BLTDPTH(a6)
	moveq.l	#0,d0
	move.w	d0,BLTDMOD(a6)
	move.w	#%100000000,d0
	swap d0
	move.l	d0,BLTCON0(a6)

	move.w	d5,d0
	lsl.w	#6,d0
	or.w	d4,d0
	move.w	d0,BLTSIZE(a6)
	rts



XCLIP0	dc.w 20
XCLIP1	dc.w 200

draw_line:
	; a0 - screen adddress
	; d4 - screen width
	; a6 - custom base
	; d0/d1 - pos 0
	; d2/d3 - pos 1

	; order points left-right
	cmp.w	d0,d2
	bgt	.rgt
	exg	d0,d2 
	exg	d1,d3
.rgt:

	; Clip against x min and max
	cmp.w	XCLIP0,d2
	ble	.done		; xmax < XCLIP0 -> done
	cmp.w	XCLIP1,d0	
	bge	.done		; XCLIP1 < xmin -> done

	cmp.w	XCLIP0,d0	; XCLIP0 <= xmin 
	bge	.noxc0

	; clip against left side
	move	XCLIP0,d5
	sub	d0,d5

	move	d3,d6
	sub	d1,d6
	muls.w	d5,d6

	move	d2,d5
	sub	d0,d5
	divs.w	d5,d6

	add.w	d6,d1
	move.w	XCLIP0,d0
.noxc0:
	cmp.w	XCLIP1,d2	; xmax < XCLIP1 -> no clipping with XCLIP1
	ble	.noxc1

	; clip against right side
	move	XCLIP1,d5
	sub	d2,d5

	move	d1,d6
	sub	d3,d6
	muls.w	d5,d6

	move	d0,d5
	sub	d2,d5
	divs.w	d5,d6

	add.w	d6,d3
	move.w	XCLIP1,d2
.noxc1:

	cmp.w	d1,d3			; 4(1/0) Always draw line from top down
	bgt.b	.dwnw			; (halves number of octants and fixes
	;beq	.done			; skip horizontal lines when filling
	exg	d0,d2 
	exg	d1,d3
.dwnw:

	sub.w	d1,d3
	moveq.l	#0,d5
	sub.w	d0,d2
	bpl.b	.dxpos
	neg.w	d2
	addq.w	#2,d5
.dxpos:

	cmp.w	d3,d2       ; make sure d2 is greater than d3
	bge.b	.dxge       ; add bit1 if |dy| > |dx|
	exg	d2,d3       ; 
	addq.l	#4,d5       ; |dx| < |dy| -> set bit 2 of d5
.dxge:

	; d0: BLTCON0 & BLTCON1 - step 1: shift value and word index
	ext.l	d0		; clear upper word (assumes x0 is positive)
	ror.l	#4,d0		; 8+2*4=16(1/0) lsb in upper part of upper word

	; a2: BLTCPT & BLTDPT - word of first pixel of the line
	mulu	d4,d1		; d1 = 40*y0  less than 1600 lines -> 16 bits
	add.w	d0,d1		; word offset
	add.w	d0,d1		; word offset x 2
	lea	(a0,d1.w),a2    ; a2 = a0 + 40*d1 + 2*d0 -> word addr of line start

	; d6: BLTSIZE
	move.w	d2,d6		; d6 = dx
	addq.w	#1,d6		; d6 = dx+1
	lsl.w	#6,d6
	addq.w	#2,d6		; d6 = BLTSIZE value

	; d7: BLTCMOD & BLTBMOD - hi: width in bytes, lo: 4*dy
	move.w  d4,d7
	swap    d7
	asl.w   #2,d3		; d3 = 4*dy
	move.w  d3,d7		; d7-hi: width in bytes, d7-lo: 4*dy

	; d3 BTLAMOD & BLTDMOD - hi: 4(dy-dx), lo: 4dy
	add.w	d2,d2		; d2 = 2*dx
	sub.w	d2,d3		; d3 = 4dy - 2dx
	bpl	.nsgn
	addq.w	#8,d5		; 4dy-2dx < 0 -> set bit 3 of d5
.nsgn:
	; a1 BLTAPT - 4dy-2dx
	movea.w	d3,a1		; sign-extend 4dy-2dx into a1

	; d3: BLTAMOD & BLTDMOD - hi: 4*dy - 4*dx, lo: width in bytes
	sub.w	d2,d3		; d3 = 4dy - 4dx
	swap	d3
	move	d4,d3		; store width in low

	; d0: BLTCON0 & BLTCON1 - step 2: set bits and octant
	or.l	#$BFA0000,d0	; set BLTCON0 flag bits
	move.w	oct(pc,d5),d0	; set BLTCON1 octant and flag bits

	move.w	#$f00,$180(a6)
.wait:	btst	#14,DMACONR(a6)
	bne.b	.wait
	move.w	#$0f0,$180(a6)

	move.l	d3,BLTAMOD(a6)	; set BLTAMOD ($064) and BLTDMOD ($066)
	move.l	a1,BLTAPTH(a6)
	move.l	a2,BLTCPTH(a6)
	move.l	a2,BLTDPTH(a6)
	move.l	d0,BLTCON0(a6)	; set BLTCON0 ($040) and BLTCON1 ($042)
	move.l	d7,BLTCMOD(a6)	; set BLTCMOD ($060) and BLTBMOD ($062)

	move.w	#$8000,BLTADAT(a6)
	moveq.l	#-1,d0
	move.w	d0,BLTBDAT(a6)	; line pattern
	move.l	d0,BLTAFWM(a6)	; $ffff in BLTAFWM and BLTALWM

	move.w	d6,BLTSIZE(a6)

.done	rts
oct:	dc.w	(4<<2)|%00000001	; 4dy-2dx >= 0 :: |dx| >= |dy| :: dx pos => oct 4(7)
	dc.w	(5<<2)|%00000001 	; 4dy-2dx >= 0 :: |dx| >= |dy| :: dx neg => oct 5(4)
	dc.w	(0<<2)|%00000001	; 4dy-2dx >= 0 :: |dx| <  |dy| :: dx pos => oct 0(6)
	dc.w	(2<<2)|%00000001	; 4dy-2dx >= 0 :: |dx| <  |dy| :: dx neg => oct 2(5)
	dc.w	(4<<2)|%01000001	; 4dy-2dx <  0 :: |dx| >= |dy| :: dx pos => oct 4(7)
	dc.w	(5<<2)|%01000001	; 4dy-2dx <  0 :: |dx| >= |dy| :: dx neg => oct 5(4)
	dc.w	(0<<2)|%01000001	; 4dy-2dx <  0 :: |dx| <  |dy| :: dx pos => oct 0(6)
	dc.w	(2<<2)|%01000001	; 4dy-2dx <  0 :: |dx| <  |dy| :: dx neg => oct 2(5)


	include "inc_miniscroller.S"

mainscreenp:	dc.l	mainscreen1, mainscreen2

		section ChipRAM,Data_c

copperlist:	dc.l	$01800000
		dc.l	$01820fff
		dc.l	$00920038,$009400d0		; DDFSTRT and DDFSTOP

		dc.l	$01080004,$010a0000		; BPL1MOD BPL2MOD
scrollbitp:	dc.l	$00e00000,$00e20000
		dc.l	$3021fffe			; wait line $30
		dc.l	$01800002,$01001200		; BPU0 on

		dc.l	$3521fffe			; line $35
		dc.l	$0180000f,$0180000c,$01000200	; BPU0 off
		dc.l	$3621fffe
		dc.l	$0180008f,$01080000,$010a0000		; BPL1MOD BPL2MOD
mainbitp:	dc.l	$00e00000,$00e20000
		dc.l	$3721fffe,$01800002,$01001200	; BPU0 on
		dc.l	$01800000

		dc.l	$cc21fffe,$0108ff88
		dc.l	$cd21fffe
		dc.l	$01800004
		dc.l	$0182004f

		dc.l	$ffe1fffe

		dc.l	$1721fffe,$0180008f
		dc.l	$01000200

		dc.l	$1821fffe,$0180000f
		dc.l	$1921fffe,$01800000

		dc.l	$fffffffe

scrollscreen:	blk.b	44*5+2,0

mainscreen1:	blk.b	40*1,$81
		blk.b	40*49,$00
		blk.b	40*1,$aa
		blk.b	40*98,$00
		blk.b	40*1,$81
mainscreen2:	blk.b	40*1,$81
		blk.b	40*49,$00
		blk.b	40*1,$aa
		blk.b	40*98,$00
		blk.b	40*1,$81
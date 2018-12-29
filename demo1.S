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

	move.l	#0,d0
	move.l	#-10,d1
	move.l	#330,d2
	move.l	#160,d3
	bsr	draw_line

	move.l	#-10,d0
	move.l	#0,d1
	move.l	#330,d2
	move.l	#160,d3
	bsr	draw_line

	move.l	#330,d0
	move.l	#-10,d1
	move.l	#-10,d2
	move.l	#160,d3
	bsr	draw_line



	move.l	mainscreenp,d0			; Flip and update copperlist
	move.l	mainscreenp+4,d1
	move.l	d1,mainscreenp
	move.l	d0,mainscreenp+4
	lea	mainbitp,a0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)

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



XCLIP	equ 319
YCLIP	equ 159

	include	"inc_line_solid_clipped.S"
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
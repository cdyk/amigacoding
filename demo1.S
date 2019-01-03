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
COP2LCH equ	$084
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

Exec_Forbid		equ	-132
Exec_Permit		equ	-138
Exec_OpenLibrary	equ	-552
Exec_CloseLibrary	equ	-414
Exec_FindTask		equ	-294
Exec_SetTaskPri		equ	-300

Gfx_LoadView		equ	-222
Gfx_WaitTOF		equ	-270
Gfx_Field_ActiView	equ	34
Gfx_Field_copinit	equ	38
Gfx_Field_LOFlist	equ	50


start:
	move.l	$4,a6

	sub.l	a1,a1				; zero - find current task
	jsr	Exec_FindTask(a6)
	move.l	d0,a1				; set current task to high pri
	moveq	#127,d0
	jsr	Exec_SetTaskPri(a6)

	lea	gfxname,a1
	moveq	#0,d0
	jsr	Exec_OpenLibrary(a6)
	tst.l	d0
	beq	.error
	move.l	d0,gfxbase

	move.l	d0,a6
	move.l	Gfx_Field_ActiView(a6),-(a7)	;	 store active view

	sub.l	a1,a1					; load zero view so we get default zero state 
	jsr	Gfx_LoadView(a6)
	jsr	Gfx_WaitTOF(a6)				; Wait for both long and short frame to finish
	jsr	Gfx_WaitTOF(a6)

	move.l	$4,a6
	jsr	Exec_Forbid(a6)

	bsr	program

	move.l	$4,a6
	jsr	Exec_Permit(a6)

	move.l	gfxbase,a6
	move.l	(a7)+,a1				; load stored active view
	jsr	Gfx_LoadView(a6)
	jsr	Gfx_WaitTOF(a6)
	jsr	Gfx_WaitTOF(a6)

	move.l	$4,a6
	move.l	gfxbase,a1
	jsr	Exec_CloseLibrary(a6)

	moveq	#0,d0
	rts

.error:	moveq	#-1,d0
	rts

gfxname:	dc.b	'graphics.library',0
		even
gfxbase:	dc.l	0


program:

	lea	CUSTOM,a1
	move.w	DMACONR(a1),-(a7)		; save enabled dma channels
	move.w	INTENAR(a1),-(a7)		; save enabled interrupts
	;move.w	#%0111111111111111,INTENA(a7)	; disable all interupts
	move.w	INTREQR(a1),-(a7)		; store current interrupt request bits
	move.w	ADKCONR(a1),-(a7)		; store current disk and sound control

	bsr	main_init
	bsr	scroller_init

	lea	CUSTOM,a1
.vb1	move.l	VPOSR(a1),d0				; wait for vertical blank
	and.l	#$0001ff00,d0
	cmp.l	#$00012700,d0
	bne.b	.vb1
	move.l	#copperlist,COP1LCH(a1)

	move.w	#%0111111111111111,DMACON(a1)	; turn off all dma 
	move.w	#%1000011111000000,DMACON(a1)	; enable bitplane + copper + blitter dma

loop:
	move.l	VPOSR(a1),d0			; wait for line $40
	and.l	#$0001ff00,d0
	cmp.l	#$00004000,d0
	bne.b	loop

	move.w	#$030,$dff180			; bg red on mainloop start

	bsr	scroller_frame
	bsr	main_frame
	lea	CUSTOM,a1

	move.w	#$000,$dff180			; bg black on mainloop finish

	btst	#6,$bfe001
	bne.b	loop

	lea	CUSTOM,a1

.vb2	move.l	VPOSR(a1),d0				; wait for vertical blank
	and.l	#$0001ff00,d0
	cmp.l	#$00012700,d0
	bne.b	.vb2

	move.l	gfxbase,a6
	move.l	Gfx_Field_copinit(a6),COP1LCH(a1)	; restore system copper list
	move.l	Gfx_Field_LOFlist(a6),COP2LCH(a1)

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

	rts

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
	move.w	#150*2,d5
	bsr	clearmem
	bsr	setup_matrix
	bsr	transform_vertices
	bsr	draw_faces

	lea	CUSTOM,a6
	move.l	mainscreenp,a0
	move.w	#20,d4
	move.w	#150*2,d5
	bsr	fillmem

	move.l	mainscreenp,d0			; Flip and update copperlist
	move.l	mainscreenp+4,d1
	move.l	d1,mainscreenp
	move.l	d0,mainscreenp+4
	lea	mainbitp,a0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	add.w	#40*150,d0
	move.w	d0,8+6(a0)
	swap	d0
	move.w	d0,8+2(a0)


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

fillmem:
	; a0 - screen address
	; d4 - screen width in words
	; d5 - screen height
	; a6 - custom base

.wait:	btst	#14,DMACONR(a6)
	bne.b	.wait

	move.w	d5,d0
	muls.w	d4,d0
	add.w	d0,d0
	lea	-2(a0,d0),a2

	move.l	a2,BLTAPTH(a6)
	sub.l	#20,a2
	move.l	a2,BLTDPTH(a6)
	move.l	#-1,BLTAFWM(a6)
	move.w	#20,BLTAMOD(a6)
	move.w	#20,BLTDMOD(a6)
	move.l	#$09f00012,BLTCON0(a6)		; A shift, USEA&D, LF4..7

	move.w	d5,d0
	lsl.w	#6,d0
	lsr.w	#1,d4
	or.w	d4,d0
	move.w	d0,BLTSIZE(a6)
	rts


draw_faces:
	move.l	mainscreenp,a0
	lea	vertices_transformed,a3
	lea	faces,a4
	lea	CUSTOM,a6

	bsr	draw_line_setup

	move.w	#face_N,-(a7)	; push face count

.l0:	move.w	(a4)+,-(a7)	; push edge count
	move.w	(a4)+,d7	; color in d7

	; -- backface culling --

	; fetch first three vertices
	move.w	(a4)+,d1	; index 0
	lsl	#2,d1
	move.w	(a3,d1),d0	; x0
	move.w	2(a3,d1),d1	; y0

	move.w	(a4),d3		; index 1
	lsl	#2,d3
	move.w	(a3,d3),d2	; x1
	move.w	2(a3,d3),d3	; y1

	move.w	2(a4),d5	; index 2
	lsl	#2,d5
	move.w	(a3,d5),d4	; x2
	move.w	2(a3,d5),d5	; y2

	; calculate sign of 2d cross product
	move.w	d2,d6		; d6 = x1
	sub.w	d0,d6		; d6 = (x1-x0)
	sub.w	d1,d5		; d5 = (y2-y0)
	muls.w	d6,d5		; d5 = (x1-x0)(y2-y0)
	move.w	d3,d6		; d6 = y1
	sub.w	d1,d6		; d6 = (y1-y0)
	sub.w	d0,d4		; d4 = (x2-x0)
	muls.w	d6,d4		; d4 = (y1-y0)(x2-x0)
	sub.l	d5,d4
	bpl	.first		; visible, we already have populated d0..d3, draw first line

	; face is backwards facing, adjust pointers and skip
	move.w	(a7)+,d0	; edge count
	lsl.w	#1,d0
	adda.w	d0,a4		; skip indices
	bra	.skip

	; edge draw loop
.l1	move.w	(a4)+,d1	; index 0
	lsl	#2,d1
	move.w	(a3,d1),d0	; x0
	move.w	2(a3,d1),d1	; y0

	move.w	(a4),d3		; index B
	lsl	#2,d3
	move.w	(a3,d3),d2	; x1
	move.w	2(a3,d3),d3	; y1

.first:	bsr	draw_line

	subq.w	#1,(a7)		; edge loop
	bgt	.l1
	addq	#2,a7		; pop edge counter

	addq.w	#2,a4		; move past last index

.skip	subq.w	#1,(a7)		; face loop
	bgt	.l0
	addq	#2,a7		; pop face counter

	rts


pos:	dc.w	0
xrot:	dc.w	0
yrot:	dc.w	0
zrot:	dc.w	0

matrix:
	dc.w	256,0,0,0
	dc.w	0,256,0,0
	dc.w	0,0,256,-500

XCLIP	equ	319
YCLIP	equ	149

	include	"inc_vertex_transform.S"
	include	"inc_solid_line_clipped.S"
	include "inc_miniscroller.S"
	include	"inc_cube.S"
	include "inc_cos_table.S"

vertices_transformed:
	blk.w	2*vertex_N,0

mainscreenp:	dc.l	mainscreen1, mainscreen2

		section ChipRAM,Data_c

copperlist:	dc.l	$01800000
		dc.l	$01820fff
		dc.l	$008e2c81,$00902cc1		; DIWSTRT and DIWSTOP
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
		dc.l	$00e40000,$00e60000
		dc.l	$3721fffe,$01800002,$01002200	; BPU0 on
		dc.l	$01800000
		dc.l	$01820f44
		dc.l	$018404f4
		dc.l	$0186044f

		dc.l	$cc21fffe,$0108ff88,$010aff88
		dc.l	$cd21fffe
		dc.l	$01800004

		dc.l	$0182082a
		dc.l	$0184028a
		dc.l	$0186022f


		dc.l	$ffe1fffe

		dc.l	$1721fffe,$0180008f
		dc.l	$01000200

		dc.l	$1821fffe,$0180000f
		dc.l	$1921fffe,$01800000

		dc.l	$fffffffe

scrollscreen:	blk.b	44*5+2,0

mainscreen1:	blk.b	40*150*2,$00
mainscreen2:	blk.b	40*150*2,$00

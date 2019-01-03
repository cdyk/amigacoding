setup_matrix:
	; animation
	add.w	#7,xrot
	and.w	#1023,xrot
	add.w	#3,yrot
	and.w	#1023,yrot
	add.w	#1,zrot
	and.w	#1023,zrot

	add.w	#5,pos
	and.w	#1023,pos

	; fetch sin and cos values
	lea	cos_table,a0
	move.w	xrot,d0
	add.w	d0,d0
	move.w	d0,d1
	move.w	(a0,d0.w),d0	; cx
	add.w	#512,d1
	and.w	#2047,d1
	move.w	(a0,d1.w),d1	; sx

	move.w	yrot,d2
	add.w	d2,d2
	move.w	d2,d3
	move.w	(a0,d2.w),d2	; cy
	add.w	#512,d3
	and.w	#2047,d3
	move.w	(a0,d3.w),d3	; sy

	move.w	zrot,d4
	add.w	d4,d4
	move.w	d4,d5
	move.w	(a0,d4.w),d4	; cz
	add.w	#512,d5
	and.w	#2047,d5
	move.w	(a0,d5.w),d5	; sz

	; calculate matrix entries
	lea	matrix,a2
.a00:	move.w	d2,d6
	muls.w	d4,d6
	asr.l	#8,d6
	move.w	d6,0(a2)	; a00 = cy cz
.a01:	move.w	d2,d6
	muls.w	d5,d6
	asr.l	#8,d6
	neg.w	d6
	move.w	d6,2(a2)	; a01 = -cy sz
.a02:	move.w	d3,4(a2)	; a02 = sy
.a10:	move.w	d4,d6
	muls.w	d1,d6
	asr.l	#8,d6
	muls.w	d3,d6
	move.w	d0,d7
	muls.w	d5,d7
	add.l	d7,d6
	asr.l	#8,d6
	move.w	d6,8(a2)	; a10 = cz sx sy + cx sz
.a11:	move.w	d0,d6
	muls.w	d4,d6
	move.w	d1,d7
	muls.w	d3,d7
	asr.l	#8,d7
	muls.w	d5,d7
	sub.l	d7,d6
	asr.l	#8,d6
	move.w	d6,10(a2)	;a11 = cx cz - sx sy sz
.a12:	move.w	d2,d6
	muls.w	d1,d6
	asr.l	#8,d6
	neg.w	d6
	move.w	d6,12(a2)	; a12 = -cy sx
.a20:	move.w	d1,d6
	muls.w	d5,d6
	move.w	d0,d7
	muls.w	d4,d7
	asr.l	#8,d7
	muls.w	d3,d7
	sub.l	d7,d6
	asr.l	#8,d6
	move.w	d6,16(a2)	; a20 = sx sz - cx cz sy
.a21:	move.w	d4,d6
	muls.w	d1,d6
	move.w	d0,d7
	muls.w	d3,d7
	asr.l	#8,d7
	muls.w	d5,d7
	add.l	d7,d6
	asr.l	#8,d6
	move.w	d6,18(a2)	; a21 = cz sx + cx sy sz
.a22:	move.w	d0,d6
	muls.w	d2,d6
	asr.l	#8,d6
	move.w	d6,20(a2)	; a22 = cx cy

	; update position

	move.w	pos,d0
	add.w	d0,d0
	move.w	d0,d1
	move.w	(a0,d0.w),d0
	moveq	#0,d0
	move.w	d0,6(a2)

	add.w	#512,d1
	and.w	#2047,d1
	move.w	(a0,d1.w),d1	; sx
	moveq	#0,d1
	sub.w	#1000,d1
	move.w	d1,22(a2)


	rts

transform_vertices:

	move.w	#vertex_N-1,d7
	lea	vertices,a0
	lea	vertices_transformed,a1

.l	move.w	(a0)+,d0
	move.w	(a0)+,d1
	move.w	(a0)+,d2

	move.w	d0,d4
	muls.w	16(a2),d4
	move.w	d1,d5
	muls.w	18(a2),d5
	add.l	d5,d4
	move.w	d2,d5
	muls.w	20(a2),d5
	add.l	d5,d4
	asr.l	#8,d4
	add.w	22(a2),d4

	move.w	d0,d3
	muls.w	0(a2),d3
	move.w	d1,d5
	muls.w	2(a2),d5
	add.l	d5,d3
	move.w	d2,d5
	muls.w	4(a2),d5
	add.l	d5,d3
	; omit asr - implicit zoom by 256
	move.w	6(a2),d5
	ext.l	d5
	asl.l	#8,d5
	add.l	d5,d3
	divs.w	d4,d3
	add.w	#(11*XCLIP)/12,d3
	move.w	d3,(a1)+

	move.w	d0,d3
	muls.w	8(a2),d3
	move.w	d1,d5
	muls.w	10(a2),d5
	add.l	d5,d3
	move.w	d2,d5
	muls.w	12(a2),d5
	add.l	d5,d3
	; omit asr - implicit zoom by 256
	move.w	14(a2),d5
	ext.l	d5
	asl.l	#8,d5
	add.l	d5,d3
	divs.w	d4,d3
	add.w	#YCLIP/2,d3
	move.w	d3,(a1)+

	dbra	d7,.l
	rts

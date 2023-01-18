.memorymap
	defaultslot 0

	slotsize $10000
	slot 0 $0000
.endme

.banksize $10000
.rombanks 1

.asciitable
.enda

.base $00

.bank $000 slot 0

.org $808
	jmp PreHook

.org $810
	jmp PostHook

.org $900

GB_SNES_DATA_OFFS = $1530
GB_TILEMAP_BUFFER = $a94c
IN_SNEK_GAMEPLAY = $7f2000
wPendingGBScreensBG3Update = $201
wCurrPtrGBTileDataBuffer = $284

.macro acc16
	rep #$20
	.accu 16
.endm

.macro idx16
	rep #$10
	.index 16
.endm

.macro accidx16
	rep #$30
	.accu 16
	.index 16
.endm

.macro acc8
	sep #$20
	.accu 8
.endm

.macro idx8
	sep #$10
	.index 8
.endm

.macro accidx8
	sep #$30
	.accu 8
	.index 8
.endm

.redef TILE_MAP_DEST = $00 ; l
.redef TILE_DATA_SRC = $03 ; l
PreHook:
; get ctrl byte from gb's tile data
	acc16
	lda wCurrPtrGBTileDataBuffer
	clc
	adc #GB_SNES_DATA_OFFS
	sta TILE_DATA_SRC
	acc8
	lda #$7e
	sta TILE_DATA_SRC+2
	lda [TILE_DATA_SRC]

	cmp #$5a
	bne @unset
; if flag is 1, keep setting to 1
	lda IN_SNEK_GAMEPLAY
	cmp #$01
	beq @set
; flag is 0, set tilemap
	lda #$7e
	sta TILE_MAP_DEST+2
	accidx16
; hide info tile
	lda #$213f
	sta $7ead72
; set 16x16 tilemap
	lda #GB_TILEMAP_BUFFER
	sta TILE_MAP_DEST
	ldx #$10
	@nextTileRow:
		phx
		ldy #$00
		ldx #$10
		@nextTileCol:
			lda [TILE_MAP_DEST], Y
			and #$e3ff
			ora #$1400
			sta [TILE_MAP_DEST], Y
			iny
			iny
			dex
			bne @nextTileCol
		lda TILE_MAP_DEST
		clc
		adc #$40
		sta TILE_MAP_DEST
		plx
		dex
		bne @nextTileRow
	accidx8
; update BG3, set flag to 1 (init done)
	lda #$01
	sta wPendingGBScreensBG3Update
	bra @set
@unset:
	lda #$00
@set:
	sta IN_SNEK_GAMEPLAY
	rts

.orga $a00

.redef TILE_DATA_SRC = $00 ; l
.redef DOUBLE_SNAKE_X = $03 ; w
.redef TILE_MAP_DEST = $05 ; l
.redef ORA_ATTR = $08 ; w
; palettes in p: vhopppcc cccccccc
PostHook:
	lda IN_SNEK_GAMEPLAY
	bne +
	rts
+	acc16
	lda wCurrPtrGBTileDataBuffer
	clc
	adc #GB_SNES_DATA_OFFS+1
	sta TILE_DATA_SRC
	acc8
	lda #$7e
	sta TILE_DATA_SRC+2
; bank of dest
	sta TILE_MAP_DEST+2
; high of snake X
	lda #$00
	sta DOUBLE_SNAKE_X+1
; low of nametable attr
	sta ORA_ATTR
	ldy #$00
; 0 read straight away? dont update BG3
	lda [TILE_DATA_SRC], Y
	bne @nextCtrl
	rts
@nextCtrl:
	lda [TILE_DATA_SRC], Y
	bne +
	lda #$01
	sta wPendingGBScreensBG3Update
	rts
+	bpl @addPart
; subPart
	and #$7f
	tax
	iny
	lda #$14
	sta ORA_ATTR+1

	@nextNode:
		jsr GetSnakePosAndOffs
		.accu 16
		lda [TILE_MAP_DEST]
		and #$e3ff
		ora ORA_ATTR
		sta [TILE_MAP_DEST]
		acc8
		dex
		bne @nextNode
	bra @nextCtrl

@addPart:
	tax
	iny
	lda #$04
	sta ORA_ATTR+1
	bra @nextNode


; Sets accu to 16
GetSnakePosAndOffs:
	phx
; put snake X in X
	lda [TILE_DATA_SRC], Y
	iny
	asl
	sta DOUBLE_SNAKE_X
; add on snake Y
	lda [TILE_DATA_SRC], Y
	iny
	acc16
	and #$00ff.w
.rept 6
	asl
.endr
	clc
	adc DOUBLE_SNAKE_X
	adc #GB_TILEMAP_BUFFER
	sta TILE_MAP_DEST
	plx
	rts

INCLUDE "inc/hardware.inc"
INCLUDE "inc/macros.inc"
INCLUDE "inc/constants.inc"

SECTION "crash", ROM0[$38]
Crash:
	ld b, b ; todo : crash handler
	jr @

SECTION "ivblank", ROM0[$40]
iVBlank:
	push af
	push bc
	push de
	push hl
	jp VBlank ; hope this doesnt end badly

SECTION "istat", ROM0[$48]
iStat:
	reti ; only used to break out of HALT

SECTION "itimer", ROM0[$50]
iTimer:
	rst $38 ; shouldnt be called

SECTION "iserial", ROM0[$58]
iSerial:
	rst $38 ; shouldnt be called

SECTION "ijoypad", ROM0[$60]
iJoypad:
	rst $38 ; shouldnt be called

SECTION "entry", ROM0[$100]	; execution starts at $100
EntryPoint:
	di ; nintendo recommends a nop, everyone else a di
	jp Intro
	ds $150-@ ; pad for the required GB header
	INCLUDE "inc/header.inc" ; my extended header, can be safely removed



SECTION "main", ROM0
MainLoop:: ; quickly setup title screen
	; SGB palette
	ld hl, wSPalTitle
	call Packet
	; DMG palette
	ld a, $e4
	ldh [rBGP], a
	; LCDC
	ld a, MENU_LCDC ; since everything is already
	ldh [rLCDC], a ; loaded this all works just fine
.loop
	halt
	call Joy
	ldh a, [hP1]
	ld b, a
	ldh a, [hP1.x]
	and b
	ld b, a
	and PADF_START
	jr nz, .start
	ld a, b
	and PADF_SELECT
	jr z, .skipDebugPalEn
	ld a, DEBUGF_PALETTE
	ldh [hDebug], a
	.skipDebugPalEn
	call rand
	jr .loop
.start
	; init
	call GameInit
	; SGB palette
	ld hl, wSPalGame
	call Packet
	; LCDC
	ld a, GAME_LCDC
	ldh [rLCDC], a
.gameLoop
	halt ; since im only using VBlank int, a halt is fine
	; cpu ussage meter
	ld a, [hDebug]
	and DEBUGF_PALETTE
	jr z, .skipDebugPal
		:ldh a, [rLY]
		cp 1
		jr nz, :-
		ld a, DEBUG_PALETTE
		ldh [rBGP], a
	.skipDebugPal
	call Joy ; poll (read) joypad(s)
	call JoyCheck
	call Snake ; basically all the game code in one routine
	call JoyCurrent ; display the snake direction
	call Score ; tally score
	call Time ; inc timer
	call StatusbarUpdate
	ldh a, [hFood] ; check food
		cp $ff
		call z, FoodReroll
	; funny palette
		ld a, $e4
		ldh [rBGP], a
	ld a, [hP1]
	ld b, a
	ld a, [hP1.x]
	and b
	and PADF_START
	jp nz, .pause
	jr .gameLoop
.pause
	ld hl, wPauses
	ld a, [hl]
	inc a
	ld [hl], a
	cp 10
	jr c, .skip
	xor a
	ld [hl+], a
	ld a, [hl]
	inc a
	ld [hl], a
	cp 10
	jr c, .skip
	ld a, 9
	ld [hl-], a
	ld [hl], a
	.skip
	ld hl, PauseTilemap
	ld de, _SCRN0+$10
	ld bc, 4
	call SafeCpy
	call StatusbarUpdate
.pauseLoop
	halt
	call Joy
	call JoyCheck
	call JoyCurrent
	ld a, [hP1]
	ld b, a
	ld a, [hP1.x]
	and b
	and PADF_START
	jr nz, .unpause
	jr .pauseLoop
.unpause
	ld hl, wGameTilemap+$10
	ld de, _SCRN0+$10
	ld bc, 4
	call SafeCpy
	jp .gameLoop

SECTION "joycurrent", ROM0
JoyCurrent:
	ldh a, [hFacing]
	and a
	ret z ; exit if no input
	ld hl, wGameTilemap.statusbar+SCRN_X_B-1+(SCRN_VX_B*1)
	ld b, BASE_ARROW-1
	.loop
	inc b
	rla
	jr nc, .loop
	; push to statusbar
	ld [hl], b
	ret

SECTION "joycheck", ROM0
JoyCheck::	; check if input changed
	ldh a, [hP1]
	ld b, a
	ldh a, [hFacing.forbid] ; discard 180s
	cpl
	and b
	and $f0
	ret z ; check if any key pressed
	ld b, a
	ld a, [hFacing]
	and b ; bitmask new and last input
	ret nz ; check if current key not pressed
	; convert to new Facing and movement vectors
	ld a, b
	ld de, 0
	rla ; down
	jr nc, :+
	inc d
	ld a, PADF_DOWN
	jr .done
:	rla ; up
	jr nc, :+
	dec d
	ld a, PADF_UP
	jr .done
:	rla ; left
	jr nc, :+
	dec e
	ld a, PADF_LEFT
	jr .done
:	rla ; right
	jr nc, :+
	inc e
	ld a, PADF_RIGHT
	jr .done
:	xor a
.done ; store to RAM
	ldh [hFacing], a
	ld a, d
	ldh [hVel.y], a
	ld a, e
	ldh [hVel.x], a
	ret

SECTION "statusbarupdate", ROM0
StatusbarUpdate:
	ld c, BASE_DECIMAL
	; score
	ld hl, wGameTilemap.statusbar+0
	ld a, BASE_STATUSBAR+0
	ld [hl+], a
	inc a
	ld [hl+], a
	ld de, wScore.end
	ld b, wScore.end - wScore
	.scoreLoop
	dec de
	ld a, [de]
	add c
	ld [hl+], a
	dec b
	jr nz, .scoreLoop
	; length
	ld hl, wGameTilemap.statusbar+14
	ld a, BASE_STATUSBAR+2
	ld [hl+], a
	inc a
	ld [hl+], a
	ld de, wLength.end
	ld b, wLength.end - wLength
	.lengthLoop
	dec de
	ld a, [de]
	add c
	ld [hl+], a
	dec b
	jr nz, .lengthLoop
if def(CUSTOM_ATTRS)
; tile to be hidden by snes with custom data
	ld a, $36
	ld [hl+], a
endc
	; time
	ld hl, wGameTilemap.statusbar+$20
	ld a, BASE_STATUSBAR+4
	ld [hl+], a
	inc a
	ld [hl+], a
	ld de, wTime.end
	ld b, BASE_TIME
	.timeLoop
	rept 2
		dec de
		ld a, [de]
		add c
		ld [hl+], a
	endr
	ld [hl], b
	inc hl
	inc b
	ld a, b
	cp BASE_TIME+4
	jr nz, .timeLoop
	; pauses
	ld hl, wGameTilemap.statusbar+$20+14
	ld a, BASE_STATUSBAR+6
	ld [hl+], a
	inc a
	ld [hl+], a
	ld de, wPauses.end
	.pauseLoop
	rept 2
		dec de
		ld a, [de]
		add c
		ld [hl+], a
	endr
	ret

SECTION "score", ROM0
Score:
	; check if grading enabled
	ldh a, [hGrading]
	and a
	ret nz
	; check if any score
	ldh a, [hBonus+0]
	ld c, a
	ldh a, [hBonus+1]
	ld b, a
	or c
	ret z
	; decrement bonus
	dec bc
	ld a, c
	ldh [hBonus+0], a
	ld a, b
	ldh [hBonus+1], a
	; increment score
	ld hl, wScore
	ld b, wScore.end - wScore
	.loop
	ld a, [hl]
	inc a
	ld [hl], a
	cp 10
	ret c
	xor a
	ld [hl+], a
	dec b
	jr nz, .loop
	; if caps out, set to max and disable grading
	ld b, 8
	dec hl
	ld a, 9
	.max
	ld [hl-], a
	dec b
	jr nz, .max
	ld a, 1
	ldh [hGrading], a
	ret

AddBonus::
	ldh a, [hBonus+0]
	ld l, a
	ldh a, [hBonus+1]
	ld h, a
	add hl, bc
	jr nc, .noOverflow
	ld hl, -1
	.noOverflow
	ld a, l
	ldh [hBonus+0], a
	ld a, h
	ldh [hBonus+1], a
	ret

SECTION "time", ROM0
Time: ; uses hl as an argument
	; check if grading enabled
	ldh a, [hGrading]
	and a
	ret nz
	; increment timer
	ld hl, wTime
	ld de, TimeLUT
	ld b, wTime.end - wTime
	.loop
	ld a, [de]
	inc e
	ld c, [hl]
	inc c
	ld [hl], c
	cp c
	ret nc
	xor a
	ld [hl+], a
	dec b
	jr nz, .loop
	; if caps out, set to max and disable grading
	ld b, 8
	dec hl
	.max
	dec e
	ld a, [de]
	ld [hl-], a
	dec b
	jr nz, .max
	ld a, 1
	ldh [hGrading], a
	ret

SECTION "timelut", ROM0, ALIGN[3]
TimeLUT:
db 9, 5, 9, 5, 9, 5, 9, 9

SECTION "length", ROM0
Length:
	; check if grading enabled
	ldh a, [hGrading]
	and a
	ret nz
	; increment length
	ld hl, wLength
	ld b, wLength.end - wLength
	.loop
	ld a, [hl]
	inc a
	ld [hl], a
	cp 10
	ret c
	xor a
	ld [hl+], a
	dec b
	jr nz, .loop
	; if caps out, set to max and disable grading
	ld b, 8
	dec hl
	ld a, 9
	.max
	ld [hl-], a
	dec b
	jr nz, .max
	ld a, 1
	ldh [hGrading], a
	ret

SECTION "snake", ROM0
Snake:	
if def(CUSTOM_ATTRS)
; 0 out pending tilemap updates
	ld de, wSnesSnakeData+1
:	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	xor a
	ld [de], a
endc

	; make sure next part only runs when needed
	; check if A or B is held
		; do these comments make sense?
	ldh a, [hP1]
	and PADF_A | PADF_B ; clears carry?
	ld b, a
	rra
		ASSERT PADF_A | PADF_B == $03
	or b
	and $01 ; also clears carry?
	rra
	; advance delay counter
	ldh a, [hDelay]
	sbc 1
	ldh [hDelay], a
	ret nc
	; if enough frames pass, reset the counter and run snake logic
	ld a, SNAKE_DELAY - 1
	ldh [hDelay], a
	; do not mind these comments
		; uhhhh do stuff? todo: stuff
		; (sorry i was happy with having input and decided thats enogu hfor me)
		; seriously zlago, write this thing already
		; hello past me, thanks for the funny comment
	
	; but before that we must talk about our sponsor
	; the funny anti-180 logic!
	ldh a, [hFacing]
	ld b, -1
	or a ; clear carry
:	rla ; convert to shifts
	inc b
	jr nc, :-
	rla ; ld a, $01
	xor b ; swap bit 0
	ld b, a
	xor a
	scf
	inc b
	:rra ; convert back to rP1 format
	dec b
	jr nz, :-
	ldh [hFacing.forbid], a
	; AHEM start by fetching the current position
	ld hl, wSnakeBuffer.head
	ld a, [hl] ; advance snake head
	inc a
	ld [hl], a
	ld l, a
	dec l
	ld h, HIGH(wSnakeBuffer.y) ; advance snake
	ld a, [hVel.y]
	ld b, [hl]
	add b ; then apply velocity
	cp 16 ; kill if OOB
	call nc, GameOver
	inc l
	ld [hl], a
	dec l
	; repeat for X
	inc h
		ASSERT FAIL, wSnakeBuffer.x - wSnakeBuffer.y == 256
		ASSERT FAIL, wSnakeBuffer & $ff == 0
	ld a, [hVel.x]
	ld b, [hl]
	add b ; then apply velocity
	cp 16 ; kill if OOB
	call nc, GameOver
	inc l
	ld [hl], a
if def(CUSTOM_ATTRS)
; copy 'bytes to add'
	ld de, wSnesSnakeData+1
:	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, $01
	ld [de], a
	inc de
; copy snake x
:	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, [hl]
	ld [de], a
	inc de
; copy snake y
	dec h
:	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, [hl]
	ld [de], a
	inc de
	inc h
; zero out 'removed part'
:	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	xor a
	ld [de], a
endc
	; check if colliding with food
	ld c, [hl]
	ld a, [hFood.x]
	cp c
	jr nz, .skipFood
	dec h
	ld c, [hl]
	ld a, [hFood.y]
	cp c
	jr nz, .skipFood
	ld a, [wSnakeBuffer.length]
	cp 255
	adc 0 ; dont go past 255 length
	ld [wSnakeBuffer.length], a
	call FoodEaten
if def(CUSTOM_ATTRS)
	jr .afterFood
.skipFood
; copy over tail marker
	ld de, wSnesSnakeData+4
:	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, $81
	ld [de], a
	inc de
; copy over tail x
	ld a, [wSnakeBuffer.length]
	ld b, a
	ld a, [wSnakeBuffer.head]
	sub b
	ld l, a
	ld h, HIGH(wSnakeBuffer.y)
	ld b, [hl]
	inc h
:	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, [hl]
	ld [de], a
	inc de
; copy over tail y
:	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, b
	ld [de], a
	inc de
; zero out end
:	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	xor a
	ld [de], a
.afterFood
else
.skipFood
endc
	; check if colliding with self
	ld a, [wSnakeBuffer.length]
	cp 1
	jr c, .skipSnake
	ld b, a ; b = length
	ld a, [wSnakeBuffer.head]
	ld h, HIGH(wSnakeBuffer.x)
	ld l, a
	ld e, [hl] ; d = Y, e = X
	dec h
	ld d, [hl]
	dec l
	dec b
	call SnakeCollision
	and a ; check if zero
	call nz, GameOver
	.skipSnake
	; display everything but head
	call SnakeDisplay
	; display head
	ld a, [wSnakeBuffer.head]
	call SnakePosDir ; get position and direction
	add a, BASE_SNAKE_HEAD ; add offset
	call Pos2SCRN
	; fin, done, no more, goto(hell), abort, i dont care now, bye-bye
	ret

SnakeDisplay::
	; undisplay tail
	ld a, [wSnakeBuffer.length]
	ld b, a
	ld a, [wSnakeBuffer.head]
	sub b
	push af ; save for later
	call SnakePosDir
	ld a, b
	xor a, c ; check if current pos is even/odd
	and a, BASE_EMPTY | %1 ; discard upper bits
	call Pos2SCRN
	; display body
	ld a, [wSnakeBuffer.head]
	call SnakePosDir ; get position and direction
	push af ; save for later
	ld a, [wSnakeBuffer.head]
	dec a
	call SnakePosDir ; get more positions and directions
	; do epic maths
	pop de
	or a ; clear carry
	rla ; multiply by 2
	rla
	or d
	add a, BASE_SNAKE_BODY ; add offset
	call Pos2SCRN
	; display tail
	pop af ; reuse value used by untail
	inc a
	push af
	inc a
	call SnakePosDir ; get direction
	pop de
	push af
	ld a, d
	call SnakePosDir ; get position
	pop af
	add a, BASE_SNAKE_TAIL ; add offset
	call Pos2SCRN
	ret

SnakeCollision:: ; returns 0 if no collision, $ff if collided
	.loop	; enter with h = buffer.y, l = snake head, b = length, de = YX to check
	ld a, [hl]
	cp d ; check y
	jr nz, .skip
	inc h
	ld a, [hl]
	dec h
	cp e
	jr nz, .skip
	ld a, $ff
	ret
	.skip
	dec l
	dec b
	jr nz, .loop
	xor a
	ret

SnakePosDir:: ; bc = position of snake cell [a]
	; a = direction of snake cell [a], clobbers hl, de
	ld l, a
	ld h, HIGH(wSnakeBuffer.y)
	ld b, [hl] ; current Y pos
	dec l
	ld d, [hl] ; last Y pos
	inc h
		ASSERT FAIL, wSnakeBuffer.x - wSnakeBuffer.y == 256
		ASSERT FAIL, wSnakeBuffer & $ff == 0
	ld e, [hl] ; last X pos
	inc l
	ld c, [hl] ; current X pos
	; convert to offset
	ld a, b
	sub d
	ld d, a
	ld a, c
	sub e
	ld e, a
	; prep for LUT
	xor a
	; Y
	rr d
	rra
	rr d
	rra
	; X
	rr e
	rra
	rr e
	rra
	; fix
	swap a
	; fetch dir
	ld d, HIGH(OffDirLUT)
	ld e, a
	ld a, [de]
	; done
	ret

FoodEaten::
	ld bc, BONUS_FOOD
	call AddBonus
	call Length
	jp FoodReset ; tail call

FoodReset::
	ld a, $ff
	ldh [hFood.y], a
	ldh [hFood.x], a
	ret

FoodReroll::
	; get random position
	call rand
	ld b, a
	and $0f
	ld e, a
	ld a, b
	swap a
	and $0f
	ld d, a
	; check if valid
	ld a, [wSnakeBuffer.length]
	ld b, a ; b = length
	ld a, [wSnakeBuffer.head]
	ld h, HIGH(wSnakeBuffer.y)
	ld l, a
	call SnakeCollision
	and a ; check if zero
	jr nz, .failed
	xor a
	ld [hFood.fail], a
	; store
	ld a, d
	ldh [hFood.y], a
	ld a, e
	ldh [hFood.x], a
	; display
	ldh a, [hFood.y]
	ld b, a
	ldh a, [hFood.x]
	ld c, a
	ld a, $04
	call Pos2SCRN
	ret
.failed
	ld a, [hFood.fail]
	inc a
	ret z
	ld [hFood.fail], a
	ret

Pos2SCRN: ; hl = bc as SCRN position, a = a
	push af
	ld h, 0
	ld l, b
	REPT 5 ; turn into a SCRN position
		add hl, hl
	ENDR
	ld a, c
	and (SCRN_VX_B - 1) << 0
	or l
	ld l, a
	ld a, h
	and (SCRN_VY_B - 1) >> 3
	or HIGH(_SCRN0)
	ld h, a
	pop af
	jp VBufferPush ; tail calling

SECTION "snake tiledata", VRAM[$8360]
	wSnesSnakeData::

SECTION "gameover", ROM0
GameOver:
	ld a, $e4
	ldh [rBGP], a
	call SnakeDisplay
	ld sp, wStack.origin
		; load game over graphic
		ld hl, GameOverTilemap
		ld de, _SCRN0+$10+(0*SCRN_VX_B)
		ld bc, 4
		call SafeCpy
	ld a, 30 ; stall
	.delay
	halt
	dec a
	jr nz, .delay
	; load rest
		ld de, _SCRN0+$10+(1*SCRN_VX_B)
		ld bc, 4
		call SafeCpy
		ld de, _SCRN0+$10+(2*SCRN_VX_B)
		ld bc, 4
		call SafeCpy
	.loop
	halt
	call Joy
	ld a, [hP1]
	ld b, a
	ld a, [hP1.x]
	and b
	and PADF_A | PADF_B
	jr z, .loop
	and PADF_A
	jp nz, MainLoop.start
	jp MainLoop

SECTION "offdirlut", ROM0, ALIGN[8]
OffDirLUT:
;     Y =  0,+1,Er,-1
	db 1, 0, 0, 1 ; X =  0
	db 3, 3, 3, 1 ; X = +1
	db 0, 0, 0, 1 ; X = Er
	db 2, 2, 2, 1 ; X = -1

SECTION "snakebuffer", WRAM0, ALIGN[8]
wSnakeBuffer::
	.y::		ds 256	; ring buffer, y
	.x::		ds 256	; x
	.head::		ds 1	; snake head, as buffer position
	.length::	ds 1	; snake length
	.end::

SECTION "gamedata", WRAM0
wGameData::
wScore:: ; total score
	ds 8
	.end::
wTime:: ; in game time
	ds 8
	.end::
wLength:: ; food eaten
	ds 3
	.end::
wPauses:: ; # of pauses
	ds 2
	.end::
wGameDataEnd::

SECTION "other", HRAM
	hOther::
	hFacing::	ds 1 ; current direction, as input
	.forbid::	ds 1 ; last direction
	hDelay::	ds 1 ; frames before next move
	hVel:: ; current direction, as a vector
		.y::	ds 1 
		.x::	ds 1
	hFood: ; fruit position
		.y	ds 1
		.x	ds 1
		.fail	ds 1 ; fruit spawn attempts
	hBonus::	ds 2 ; score to be added
	hGrading::	ds 1 ; nonzero disables grading
	hDebug::	ds 1 ; funny performance viewer
	hOtherEnd::
	hConsole::	ds 1 ; console version

SECTION "tilemapbuffers", WRAM0, align[1]
wGameTilemap::
	ds SCRN_VX_B*(SCRN_Y_B-2)
	.statusbar::
	ds SCRN_VX_B*2
	.end::
wTitleTilemap::
	ds SCRN_VX_B*SCRN_Y_B
	.end::

SECTION "graphics", ROM0, align[1]
Base2bpp::
	INCBIN "gfx/bin/base.2bpp"
	.end::
Statusbar1bpp::
	INCBIN "gfx/bin/statusbar.1bpp"
	.end::
Arrow2bpp::
	INCBIN "gfx/bin/arrows.2bpp"
	.end::
Title1bpp::
	INCBIN "gfx/bin/title.1bpp"
	.end::
GameOver1bpp::
	INCBIN "gfx/bin/gamestop.1bpp"
	.end::

SECTION "tilemaps", ROM0
GameTilemap::
	INCBIN "gfx/bin/game.tilemap"
	.end::
TitleTilemap::
	INCBIN "gfx/bin/title.tilemap"
	.end::
GameOverTilemap::
	INCBIN "gfx/bin/gamestop.tilemap", 4, 12
	.end::
PauseTilemap::
	INCBIN "gfx/bin/gamestop.tilemap", 0, 4
	.end::

SECTION "sgbdata", ROM0, align[1]
BorderTiles::
	INCBIN "gfx/bin/border.4bpp"
	.end::
BorderTilemap::
	INCBIN "gfx/bin/border.pct"
	.end::
BorderPalette::
	INCBIN "gfx/bin/border.pal"
	.end::

SAttr::
SAttrTitle::
	ds 90,	%00_00_00_00
.end::
SAttrGame::
	rept 16
	ds 4,	%01_01_01_01
	db	%00_00_00_00
	endr
	ds 10,	%00_00_00_00
	.end::
SAttrEnd::

SPal::
BaseSPal::
	INCBIN "gfx/bin/base.spal"
	.end::
SnakeSPal::
	INCBIN "gfx/bin/snake.spal"
	.end::
SPalEnd::

BaseCPal:: ; cpals are broken, this should be changed once theyre fixed
	INCBIN "gfx/bin/base.spal"
	.end::
SnakeCPal::
	INCBIN "gfx/bin/snake.spal"
	.end::

SECTION "snaketiles", ROM0, align[1]
Snake2bpp::
	INCBIN "gfx/bin/snake.2bpp"
	.end::

SECTION "devmessage", ROMX
db "would you look at that, someone checked this in a hex editor! well, hi there! im zlago, and this ", \
"is a little hidden easter egg that may or may not become viewable in-game, 'nyways, heres a list of ", \
"cool people, some of them even directly helped! : Eeivui/Evie, PinoBatch/Pin8, ISSO/ISSOtm ", \
"calc84maniac, rangi, bbbbbr, aaaaaa123456789/ax6, yumaikas, piellow/lordpillows, nezuo, kaselord, ", \
"falcon nova, hail, delivery cat, zeta0134, kasumi, bella marie, leina, genericheroguy "
db "<NEWLINE> this was quite fun to make, reaching the end of v1.0 felt quite special, and.. ", \
"ok i dont have much else to say, thanks for finding this data, cya! *ceases to exist*"
; SGB packets
DEF   PAL01    EQU $00<<3 ; Set SGB Palette 0 & 1
DEF PAL23    EQU $01<<3 ; Set SGB Palette 2 & 3
DEF PAL03    EQU $02<<3 ; Set SGB Palette 0 & 3
DEF PAL12    EQU $03<<3 ; Set SGB Palette 1 & 2
DEF ATTR_BLK EQU $04<<3 ; �Block� Area Designation Mode
DEF ATTR_LIN EQU $05<<3 ; �Line� Area Designation Mode
DEF ATTR_DIV EQU $06<<3 ; �Divide� Area Designation Mode
DEF ATTR_CHR EQU $07<<3 ; �1CHR� Area Designation Mode
DEF SOUND    EQU $08<<3 ; Sound On/Off
DEF SOU_TRN  EQU $09<<3 ; Transfer Sound PRG/DATA
DEF PAL_SET  EQU $0a<<3 ; Set SGB Palette Indirect
DEF PAL_TRN  EQU $0b<<3 ; Set System Color Palette Data
DEF ATRC_EN  EQU $0c<<3 ; Enable/disable Attraction Mode
DEF TEST_EN  EQU $0d<<3 ; Speed Function
DEF ICON_EN  EQU $0e<<3 ; SGB Function
DEF DATA_SND EQU $0f<<3 ; SUPER NES WRAM Transfer 1
DEF DATA_TRN EQU $10<<3 ; SUPER NES WRAM Transfer 2
DEF MLT_REQ  EQU $11<<3 ; Multiple Controllers Request
DEF JUMP     EQU $12<<3 ; Set SNES Program Counter
DEF CHR_TRN  EQU $13<<3 ; Transfer Character Font Data
DEF PCT_TRN  EQU $14<<3 ; Set Screen Data Color Data
DEF ATTR_TRN EQU $15<<3 ; Set Attribute from ATF
DEF ATTR_SET EQU $16<<3 ; Set Data to ATF
DEF MASK_EN  EQU $17<<3 ; Game Boy Window Mask
DEF OBJ_TRN  EQU $18<<3 ; Super NES OBJ Mode
; menu & debug
def	MENU_LCDC	equ	LCDCF_ON|LCDCF_BG8800|LCDCF_BG9C00|LCDCF_OBJOFF|LCDCF_BGON
def	GAME_LCDC	equ	LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_OBJOFF|LCDCF_BGON
def	DEBUG_PALETTE	equ	$5a
def	DEBUGF_PALETTE	equ	%00000001
; tilemap
def	BASE_EMPTY	equ $00
def	BASE_SOLID	equ $03
def	BASE_SNAKE_TAIL	equ $08
def	BASE_SNAKE_HEAD	equ $0c
def	BASE_SNAKE_BODY	equ $10
def	BASE_DECIMAL	equ $20
def	BASE_STATUSBAR	equ $2a
def	BASE_TIME	equ $32
def	BASE_ARROW	equ $38
; score
def	BONUS_FOOD	equ 10
; gameplay
def	SNAKE_LENGTH	equ 3
def	SNAKE_Y		equ 7
def	SNAKE_X		equ 7
def	SNAKE_DELAY	equ 30
; console
def CONSOLEB_CGB equ 0
def CONSOLEB_SGB equ 1
def CONSOLEB_MOD equ 2
def CONSOLEF_CGB equ 1 << CONSOLEB_CGB
def CONSOLEF_SGB equ 1 << CONSOLEB_SGB
def CONSOLEF_MOD equ 1 << CONSOLEB_MOD
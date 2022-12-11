MACRO lb ; "load bytes", ld for two n8 to one r16
	assert -128 <= (\2) && (\2) <= 255, "Second argument to `lb` must be 8-bit!"
	assert -128 <= (\3) && (\3) <= 255, "Third argument to `lb` must be 8-bit!"
	ld \1, (((\2) << 8) & $FF00) | ((\3) & $FF)
ENDM

def CONSOLEB_CGB equ 0
def CONSOLEB_SGB equ 1
def CONSOLEB_MOD equ 2

def CONSOLEF_CGB equ 1 << CONSOLEB_CGB
def CONSOLEF_SGB equ 1 << CONSOLEB_SGB
def CONSOLEF_MOD equ 1 << CONSOLEB_MOD
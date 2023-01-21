# rgbasm defs
DEFINES=

ASM_REQS = $(shell find code/ -name '*.asm' | sed "s/code/obj/" | sed "s/\.asm/.o/" | sed "s/\.s/.z80/")
GFX_REQS = gfx/bin/arrows.2bpp gfx/bin/bad.1bpp gfx/bin/base.2bpp gfx/bin/base.spal \
	gfx/bin/base.cpal gfx/bin/border.pal gfx/bin/border.4bpp gfx/bin/border.pct \
	gfx/bin/game.tilemap gfx/bin/gamestop.tilemap gfx/bin/gamestop.1bpp \
	gfx/bin/snake.2bpp gfx/bin/snake.spal gfx/bin/snake.cpal gfx/bin/statusbar.1bpp \
	gfx/bin/title.1bpp gfx/bin/title.tilemap

all: bin/pong.gb


gfx/bin/arrows.2bpp: gfx/png/arrows.png
	rgbgfx -v -o $@ $<

gfx/bin/bad.1bpp: gfx/png/bad.png
	rgbgfx -v -d 1 -o $@ $<

gfx/bin/base.2bpp gfx/bin/base.spal: gfx/png/base.png
	rgbgfx -v -o gfx/bin/base.2bpp -p gfx/bin/base.spal $<

gfx/bin/base.cpal: gfx/png/base.png
	rgbgfx -v -C -p $@ $<

gfx/bin/border.pal gfx/bin/border.4bpp gfx/bin/border.pct: gfx/png/border.png
	superfamiconv -v -i $< -p gfx/bin/border.pal -t gfx/bin/border.4bpp -P 4 -m gfx/bin/border.pct -M snes --color-zero 0000ff -B 4

gfx/bin/game.tilemap: gfx/png/game.png gfx/bin/base.2bpp gfx/bin/base.dpal
	superfamiconv map -v -M gb -i gfx/png/game.png -p gfx/bin/base.dpal -t gfx/bin/base.2bpp -d $@ -B 2

gfx/bin/gamestop.tilemap gfx/bin/gamestop.1bpp: gfx/png/gamestop.png
	rgbgfx -v -t gfx/bin/gamestop.tilemap -o gfx/bin/gamestop.1bpp $< -b 128 -d 1

gfx/bin/snake.2bpp gfx/bin/snake.spal: gfx/png/snake2.png
	rgbgfx -v -o gfx/bin/snake.2bpp -p gfx/bin/snake.spal $<

gfx/bin/snake.cpal: gfx/png/snake2.png
	rgbgfx -v -C -p $@ $<

gfx/bin/statusbar.1bpp: gfx/png/statusbar.png
	rgbgfx -v -d 1 -o $@ $<

gfx/bin/title.1bpp gfx/bin/title.tilemap: gfx/png/title.png
	rgbgfx -v -d 1 -o gfx/bin/title.1bpp $< -t gfx/bin/title.tilemap -u

obj/%.o: code/%.asm
	rgbasm ${DEFINES} -h -Wall -i inc -o $@ $<

obj/%.o: code/%.z80
	rgbasm ${DEFINES} -h -Wall -i inc -o $@ $<


bin/pong.gb: $(ASM_REQS) $(GFX_REQS)
	rgblink -p 0xFF -m bin/pong.map -n bin/pong.sym -o $@ obj/main.o obj/init.o obj/sub.o obj/vblank.o obj/rand.o
	rgbfix -l 0x33 -j -c -s -v -p 0xFF -t "PONG TEST" $@

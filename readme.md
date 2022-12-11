### snek-gbc

**Snek!** or **snek-gbc** is an open source snake clone for the game boy,
super game boy and game boy color consoles, written in assembly using rgbds

### compiling

to compile this, you will need:
- [RGBDS](https://github.com/gbdev/rgbds), v6.0.0 should work
- [SuperFamiconv](https://github.com/Optiroc/SuperFamiconv),
must be compiled from source (relies on a new feature for the SGB border)
- optionally, [romusage](https://github.com/bbbbbr/romusage), v1.2.4 should work

all of the above must be located in your PATH

(this uses batch files, sorry!) to build the game:
1. run `gfx/_ALL.bat` to convert the assets
2. run `build.bat` to assemble, link and fix the rom
3. open `pong.gb` in your favourite emulator
4. ask no questions about the rom filename

the resulting object files and ROM image should end up in `obj/` and `bin/` respectively

### misc

- a license should be added at some point
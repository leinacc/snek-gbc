@ ECHO OFF
rgbasm -h -Wall -i inc -o obj\main.o code\main.asm
rgbasm -h -Wall -i inc -o obj\init.o code\init.asm
rgbasm -h -Wall -i inc -o obj\sub.o code\sub.asm
rgbasm -h -Wall -i inc -o obj\vblank.o code\vblank.asm
rgbasm -h -Wall -i inc -o obj\rand.o code\rand.z80
rgblink -p 0xFF -m pong.map -n pong.sym -o pong.gb obj\main.o obj\init.o obj\sub.o obj\vblank.o obj\rand.o
rgbfix -l 0x33 -j -c -s -v -p 0xFF -t "PONG TEST" pong.gb
romusage pong.map -g
pause
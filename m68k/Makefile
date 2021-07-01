
CC=m68k-atari-mint-gcc
OBJCOPY=m68k-atari-mint-objcopy
OBJDUMP=m68k-atari-mint-objdump

SRCS=simple_asm.S \
     puts.c

CFLAGS=-Wall -Os -fomit-frame-pointer -nostdlib -ffreestanding -nostartfiles
LDFLAGS=-Wl,-T simple.lk

all: simple_asm.o puts.o
	$(CC) $(LDFLAGS) $(CFLAGS) -Osrec -o simple.srec $^
	$(OBJCOPY) -Obinary simple.srec simple.bin

.PHONY: clean
clean:
	- rm -f *.o simple.out simple.elf
    
dump:
	$(OBJDUMP) -bbinary --architecture=m68k:68020 -D simple.bin

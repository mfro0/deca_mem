
CC=m68k-elf-gcc
OBJCOPY=m68k-elf-objcopy
OBJDUMP=m68k-elf-objdump

SRCS=simple_asm.S \
     puts.c

CFLAGS=-Wall -Os -fomit-frame-pointer -nostdlib -ffreestanding -nostartfiles
LDFLAGS=-Wl,-T simple.lk

all: simple_asm.o puts.o
	$(CC) $(LDFLAGS) $(CFLAGS) -o simple.elf $^
	$(OBJCOPY) -Obinary simple.elf simple.bin

.PHONY: clean
clean:
	- rm -f *.o simple.out simple.elf
    
dump:
	$(OBJDUMP) -bbinary --architecture=m68k:68020 -D simple.bin

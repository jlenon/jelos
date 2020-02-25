CFLAGS:=$(CFLAGS) -std=gnu99 -ffreestanding -O2 -Wall -Wextra -I "/mnt/c/dev/Toy OS/JELOS/src/libc/include"
LDLAGS:=$(LFLAGS) -T linker.ld -ffreestanding -O2 -nostdlib -lgcc
CC=~/opt/cross/bin/i686-elf-gcc
LD=~/opt/cross/bin/i686-elf-gcc
CSRC = $(shell find src -type f -name '*.c')
COBJ = $(patsubst src/%.c, obj/%.o, $(CSRC))
ASMSRC = $(shell find src -type f -name '*.asm')
ASMOBJ = $(patsubst src/%.asm, obj/%_s.o, $(ASMSRC))

all: jelos.bin

jelos.bin: $(COBJ) $(ASMOBJ)
	 $(LD) $(LDLAGS) -o jelos.bin $(ASMOBJ) $(COBJ)

obj/%.o: src/%.c
	 $(CC) $(CFLAGS) -o $@ -c $<
     
obj/%_s.o: src/%.asm
	 nasm -felf32 -o $@ $<

clean:
	find . -name '*.o' -delete
	-rm *.bin
#!/bin/bash
~/opt/cross/bin/i686-elf-gcc -T linker.ld -o jelos.bin -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc

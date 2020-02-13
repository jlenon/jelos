#!/bin/bash

cp jelos.bin isodir/boot/jelos.bin
cp grub.cfg isodir/boot/grub/grub.cfg
grub-mkrescue -o jelos.img isodir

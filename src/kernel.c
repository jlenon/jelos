#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "drivers/terminal.h"
 
/* Check if the compiler thinks you are targeting the wrong operating system. */
#if defined(__linux__)
#warning "You are not using a cross-compiler, you will most certainly run into trouble"
#endif
 
/* This tutorial will only work for the 32-bit ix86 targets. */
#if !defined(__i386__)
#warning "This tutorial needs to be compiled with a ix86-elf compiler"
#endif
 

struct kernel_memory_t
{
	uint32_t virtual_start;
	uint32_t virtual_end;
	uint32_t physical_start;
	uint32_t physical_end;
	uint32_t page_directory_physical;
};


void kernel_main(struct kernel_memory_t kernel_memory, uint32_t ebx) 
{
	/* Initialize terminal interface */
	terminal_initialize();
 
	/* Newline support is left as an exercise. */
	terminal_writestring("Welcome to JELOS - v1!\n");

	terminal_writestring("Kernel Virtual Start = ");
	terminal_writehex(kernel_memory.virtual_start);
	terminal_writestring("\n");
	terminal_writestring("Kernel Virtual End = ");
	terminal_writehex(kernel_memory.virtual_end);
	terminal_writestring("\n");
	terminal_writestring("Kernel Physical Start = ");
	terminal_writehex(kernel_memory.physical_start);
	terminal_writestring("\n");
	terminal_writestring("Kernel Physical End = ");
	terminal_writehex(kernel_memory.physical_end);
	terminal_writestring("\n");
	terminal_writestring("Page Dir Phyisical = ");
	terminal_writehex(kernel_memory.page_directory_physical);
	terminal_writestring("\n");
}
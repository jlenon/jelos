#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "drivers/terminal.h"
#include "system/gdt.h"
#include "system/idt.h"
#include "system/isr.h"
#include "common/common.h"
 
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

void page_fault(registers_t regs)
{
    // A page fault has occurred.
    // The faulting address is stored in the CR2 register.
    uint32_t faulting_address;
    asm volatile("mov %%cr2, %0" : "=r" (faulting_address));
    
    // The error code gives us details of what happened.
    int present   = !(regs.err_code & 0x1); // Page not present
    int rw = regs.err_code & 0x2;           // Write operation?
    int us = regs.err_code & 0x4;           // Processor was in user-mode?
    int reserved = regs.err_code & 0x8;     // Overwritten CPU-reserved bits of page entry?
    //int id = regs.err_code & 0x10;          // Caused by an instruction fetch?

    // Output an error message.
    terminal_writestring("Page fault! ( ");
    if (present) {terminal_writestring("present ");}
    if (rw) {terminal_writestring("read-only ");}
    if (us) {terminal_writestring("user-mode ");}
    if (reserved) {terminal_writestring("reserved ");}
    terminal_writestring(") at 0x");
    terminal_writehex(faulting_address);
    terminal_writestring("\n");
    PANIC("Page fault");
}

void kernel_main(struct kernel_memory_t kernel_memory, uint32_t ebx) 
{
	/* Initialize terminal interface */
	terminal_initialize();
 
	terminal_writestring("Welcome to JELOS - v3!\n");
	terminal_writestring("\n");
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
	terminal_writestring("\n\n");

	/* Initialize Global Descriptior Tables */
	gdt_initialize();
	terminal_writestring("Global Descriptior Table initialised\n\n");

	/* Initialize Global Descriptior Tables */
	idt_initialize();
	terminal_writestring("Interrupt Descriptior Table initialised\n\n");

	/* Setup interrup handler */
    register_interrupt_handler(14, page_fault);
	terminal_writestring("Page fault hander enabled\n\n");

	uint32_t *ptr1 = (uint32_t*)0xc0100005;
    uint32_t do_page_fault1 = *ptr1;    
    
    terminal_writestring("Got 1st memory address\n");

    uint32_t *ptr2 = (uint32_t*)0xA0000000;
    uint32_t do_page_fault2 = *ptr2;

	terminal_writestring("Got 2nd memory address\n");

}
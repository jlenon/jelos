#include "common.h"
#include "../drivers/terminal.h"

extern void panic(const char *message, const char *file, uint32_t line)
{
    // We encountered a massive problem and have to stop.
    asm volatile("cli"); // Disable interrupts.

    terminal_writestring("PANIC(");
    terminal_writestring(message);
    terminal_writestring(") at ");
    terminal_writestring(file);
    terminal_writestring(":");
    terminal_writedec(line);
    terminal_writestring("\n");
    // Halt by going into an infinite loop.
    for(;;);
}

extern void panic_assert(const char *file, uint32_t line, const char *desc)
{
    // An assertion failed, and we have to panic.
    asm volatile("cli"); // Disable interrupts.

    terminal_writestring("ASSERTION-FAILED(");
    terminal_writestring(desc);
    terminal_writestring(") at ");
    terminal_writestring(file);
    terminal_writestring(":");
    terminal_writedec(line);
    terminal_writestring("\n");
    // Halt by going into an infinite loop.
    for(;;);
}

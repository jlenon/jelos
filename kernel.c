#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
 
/* Check if the compiler thinks you are targeting the wrong operating system. */
#if defined(__linux__)
#warning "You are not using a cross-compiler, you will most certainly run into trouble"
#endif
 
/* This tutorial will only work for the 32-bit ix86 targets. */
#if !defined(__i386__)
#warning "This tutorial needs to be compiled with a ix86-elf compiler"
#endif
 
/* Hardware text mode color constants. */
enum vga_color {
	VGA_COLOR_BLACK = 0,
	VGA_COLOR_BLUE = 1,
	VGA_COLOR_GREEN = 2,
	VGA_COLOR_CYAN = 3,
	VGA_COLOR_RED = 4,
	VGA_COLOR_MAGENTA = 5,
	VGA_COLOR_BROWN = 6,
	VGA_COLOR_LIGHT_GREY = 7,
	VGA_COLOR_DARK_GREY = 8,
	VGA_COLOR_LIGHT_BLUE = 9,
	VGA_COLOR_LIGHT_GREEN = 10,
	VGA_COLOR_LIGHT_CYAN = 11,
	VGA_COLOR_LIGHT_RED = 12,
	VGA_COLOR_LIGHT_MAGENTA = 13,
	VGA_COLOR_LIGHT_BROWN = 14,
	VGA_COLOR_WHITE = 15,
};
 
static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) 
{
	return fg | bg << 4;
}
 
static inline uint16_t vga_entry(unsigned char uc, uint8_t color) 
{
	return (uint16_t) uc | (uint16_t) color << 8;
}
 
size_t strlen(const char* str) 
{
	size_t len = 0;
	while (str[len])
		len++;
	return len;
}
 
static const size_t VGA_WIDTH = 80;
static const size_t VGA_HEIGHT = 25;
 
size_t terminal_row;
size_t terminal_column;
uint8_t terminal_color;
uint16_t* terminal_buffer;
 
void terminal_initialize(void) 
{
	terminal_row = 0;
	terminal_column = 0;
	terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
	terminal_buffer = (uint16_t*) 0xC00b8000; //0xB8000;
	for (size_t y = 0; y < VGA_HEIGHT; y++) {
		for (size_t x = 0; x < VGA_WIDTH; x++) {
			const size_t index = y * VGA_WIDTH + x;
			terminal_buffer[index] = vga_entry(' ', terminal_color);
		}
	}
}
 
void terminal_setcolor(uint8_t color) 
{
	terminal_color = color;
}
 
void terminal_putentryat(char c, uint8_t color, size_t x, size_t y) 
{
	const size_t index = y * VGA_WIDTH + x;
	terminal_buffer[index] = vga_entry(c, color);
}
 
void terminal_putchar(char c) 
{
	if (c == '\n')
	{
		terminal_row++;
		terminal_column = 0;
	}
	else
	{
		terminal_putentryat(c, terminal_color, terminal_column, terminal_row);
	}

	if (++terminal_column == VGA_WIDTH) {
		terminal_column = 0;
			if (++terminal_row == VGA_HEIGHT)
				terminal_row = 0;
		}
}
 
void terminal_write(const char* data, size_t size) 
{
	for (size_t i = 0; i < size; i++)
		terminal_putchar(data[i]);
}
 
void terminal_writestring(const char* data) 
{
	terminal_write(data, strlen(data));
}
 
void terminal_writehex(uint32_t n)
{
    int32_t tmp;

    terminal_writestring("0x");

    char noZeroes = 1;

    int i;
    for (i = 28; i > 0; i -= 4)
    {
        tmp = (n >> i) & 0xF;
        if (tmp == 0 && noZeroes != 0)
        {
            continue;
        }
    
        if (tmp >= 0xA)
        {
            noZeroes = 0;
            terminal_putchar (tmp-0xA+'a' );
        }
        else
        {
            noZeroes = 0;
            terminal_putchar( tmp+'0' );
        }
    }
  
    tmp = n & 0xF;
    if (tmp >= 0xA)
    {
        terminal_putchar (tmp-0xA+'a');
    }
    else
    {
        terminal_putchar (tmp+'0');
    }

}

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
	terminal_writestring("Welcome to JELOS!\n");

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
/* The bootloader will look at this image and start execution at the symbol
   designated as the entry point. */
ENTRY(_start)
 
/* Tell where the various sections of the object files will be put in the final
   kernel image. */
SECTIONS
{
	/* Begin putting sections at 1 MiB, a conventional place for kernels to be
	   loaded at by the bootloader. */
	. = 0xC0100000;  /* the code should be linked as though it were loaded at 3GB + 1MB. In actuality, it will be loaded at physical address 1MB, then we will map virtual addresses above 3GB to physical address starting at 0 */

	kernel_virtual_start = .;
    kernel_physical_start = . - 0xC0000000;
 
	/* First put the multiboot header, as it is required to be put very early
	   early in the image or the bootloader won't recognize the file format.
	   Next we'll put the .text section. */
	.text ALIGN(0x1000) :   AT(ADDR(.text)-0xC0000000)
	{
		*(.multiboot)
		*(.text)
	}
 
	/* Read-only data. */
	.rodata  ALIGN(0x1000) :   AT(ADDR(.rodata)-0xC0000000)
	{
		*(.rodata)
	}
 
	/* Read-write data (initialized) */
	.data  ALIGN(0x1000) :   AT(ADDR(.data)-0xC0000000)
	{
		*(.data)
	}
 
	/* Read-write data (uninitialized) and stack */
	.bss  ALIGN(0x1000) :   AT(ADDR(.bss)-0xC0000000)
	{
		*(COMMON)
		*(.bss)
	}
 
	/* The compiler may produce other sections, by default it will put them in
	   a segment with the same name. Simply add stuff here as needed. */

    kernel_virtual_end = .;
    kernel_physical_end = . - 0xC0000000;

}
;global loader                   ; the entry symbol for ELF
                                ; 'global' is a directive that includes this
                                ; symbol in the symbol table. Directives appear
                                ; at the start of the file. 'global' exports and
                                ; 'extern' imports.

extern kmain                    ; the starting point in our C code

extern kernel_virtual_start
extern kernel_virtual_end
extern kernel_physical_start
extern kernel_physical_end


; Declare constants for the multiboot header.
MBALIGN  equ  1 << 0            ; align loaded modules on page boundaries
MEMINFO  equ  1 << 1            ; provide memory map
FLAGS    equ  MBALIGN | MEMINFO ; this is the Multiboot 'flag' field
MAGIC    equ  0x1BADB002        ; 'magic number' lets bootloader find the header
CHECKSUM equ -(MAGIC + FLAGS)   ; checksum of above, to prove we are multiboot

KERNEL_VIRTUAL_BASE equ 0xC0000000
KERNEL_PAGE_NUMBER equ (KERNEL_VIRTUAL_BASE >> 22) ; Index in the page directory -  Page directory index of kernel's 4MB PTE - This will 768 = 0x300
 
KERNEL_STACK_SIZE equ 4096      ; size of stack in bytes (4 kilobyte)

; Declare a multiboot header that marks the program as a kernel. These are magic
; values that are documented in the multiboot standard. The bootloader will
; search for this signature in the first 8 KiB of the kernel file, aligned at a
; 32-bit boundary. The signature is in its own section so the header can be
; forced to be within the first 8 KiB of the kernel file.
section .multiboot
align 4
	dd MAGIC
	dd FLAGS
	dd CHECKSUM
 

;https://medium.com/@connorstack/how-does-a-higher-half-kernel-work-107194e46a64
section .data
align 0x1000 ; align to 4KB, the size of a page
global page_directory_virtual_address
page_directory_virtual_address:
    ; the first entry identity maps the first 4MB of memory
    ; All bits are clear except the following:
    ; bit 7: PS The kernel page is 4MB.
    ; bit 1: RW The kernel page is read/write.
    ; bit 0: P  The kernel page is present.
    ;dd 0x00000083 ; in binary this is 10000011    ; entries for unmapped virtual addresses
    
	; Pages before kernel space.
	;times (KERNEL_PAGE_NUMBER - 1) dd 0     
	
	; entry for the kernel's virtual address
    ;dd 0x00000083    
	
	; entries for unmapped addresses above the kernel
    ;times (1024 - KERNEL_PAGE_NUMBER - 1) dd 0

	times (1024) dd 0	;4KB page

global page_table1_virtual_address
page_table1_virtual_address:

	times (1024) dd 0	;4KB page
 
; The linker script specifies _start as the entry point to the kernel and the
; bootloader will jump to this position once the kernel has been loaded. It
; doesn't make sense to return from this function as the bootloader is gone.
; Declare _start as a function symbol with the given symbol size.
section .text
;global _start:function (_start.end - _start)
;_start:
global _start
_start:
start equ (_start - KERNEL_VIRTUAL_BASE)
	; The bootloader has loaded us into 32-bit protected mode on a x86
	; machine. Interrupts are disabled. Paging is disabled. The processor
	; state is as defined in the multiboot standard. The kernel has full
	; control of the CPU. The kernel can only make use of hardware features
	; and any code it provides as part of itself. There's no printf
	; function, unless the kernel provides its own <stdio.h> header and a
	; printf implementation. There are no security restrictions, no
	; safeguards, no debugging mechanisms, only what the kernel provides
	; itself. It has absolute and complete power over the
	; machine.
 
	global page_directory_physical_address
	page_directory_physical_address equ (page_directory_virtual_address - KERNEL_VIRTUAL_BASE) ; 0x104000

	;set up 4KB paging
	mov edi, (page_table1_virtual_address - KERNEL_VIRTUAL_BASE)

	mov esi, 0x00
	; Map 1023 pages. The 1024th will be the VGA text buffer.
	mov ecx ,1023d
.1:
	; Only map the kernel.
	cmp esi, (kernel_virtual_start - KERNEL_VIRTUAL_BASE)
	jl .2
	cmp esi, (kernel_virtual_end - KERNEL_VIRTUAL_BASE)
	jge .3

	;Map physical address as "present, writable". Note that this maps
	;.text and .rodata as writable. Mind security and map them as non-writable.
	; bit 1: RW The kernel page is read/write.
    ; bit 0: P  The kernel page is present.
	mov edx, esi
	or edx, 0x003
	mov [edi], edx

.2:
	;Size of page is 4096 bytes.
	add esi, 0x1000
	;Size of entries in boot_page_table1 is 4 bytes.
	add edi, 4
	;Loop to the next entry if we haven't finished.
	loop .1

.3:
	;Map VGA video memory to 0xC03FF000 as "present, writable".
	mov dword [page_table1_virtual_address - KERNEL_VIRTUAL_BASE + 1023 * 4], (0x000B8000 | 0x003)

	;The page table is used at both page directory entry 0 (virtually from 0x0
	;to 0x3FFFFF) (thus identity mapping the kernel) and page directory entry
	;768 (virtually from 0xC0000000 to 0xC03FFFFF) (thus mapping it in the
	;higher half). The kernel is identity mapped because enabling paging does
	;not change the next instruction, which continues to be physical. The CPU
	; would instead page fault if there was no identity mapping.

	;Map the page table to both virtual addresses 0x00000000 and 0xC0000000.
	mov dword [page_directory_virtual_address - KERNEL_VIRTUAL_BASE + 0], (page_table1_virtual_address - KERNEL_VIRTUAL_BASE + 0x003)
	mov dword [page_directory_virtual_address - KERNEL_VIRTUAL_BASE + 768 * 4], (page_table1_virtual_address - KERNEL_VIRTUAL_BASE + 0x003)

	;Set cr3 to the address of the boot_page_directory.
	mov ecx, page_directory_physical_address
	mov cr3, ecx

	;Enable paging and the write-protect bit.
	mov ecx, cr0
	or ecx, 0x80010000
	mov cr0, ecx

	;Jump to higher half with an absolute jump. 
	lea ecx, [StartInHigherHalf]
	jmp ecx

StartInHigherHalf:

	; zero-out the first entry in the page directory
	mov dword [page_directory_virtual_address], 0; tell the CPU the first entry has changed
	invlpg [0]

	; To set up a stack, we set the esp register to point to the top of our
	; stack (as it grows downwards on x86 systems). This is necessarily done
	; in assembly as languages such as C cannot function without a stack.
	;mov esp, stack_top


	mov esp, kernel_stack_lowest_address + KERNEL_STACK_SIZE   ; point esp to the start of the
                                                ; stack (end of memory area)
    add ebx, KERNEL_VIRTUAL_BASE ; make the address virtual
    push ebx ; GRUB stores a pointer to a struct in the register ebx that,
             ; among other things, describes at which addresses the modules are loaded.
             ; Push ebx on the stack before calling kmain to make it an argument for kmain.

	push page_directory_physical_address
    push kernel_physical_end
    push kernel_physical_start
    push kernel_virtual_end
    push kernel_virtual_start
	
	; This is a good place to initialize crucial processor state before the
	; high-level kernel is entered. It's best to minimize the early
	; environment where crucial features are offline. Note that the
	; processor is not fully initialized yet: Features such as floating
	; point instructions and instruction set extensions are not initialized
	; yet. The GDT should be loaded here. Paging should be enabled here.
	; C++ features such as global constructors and exceptions will require
	; runtime support to work as well.
 
	; Enter the high-level kernel. The ABI requires the stack is 16-byte
	; aligned at the time of the call instruction (which afterwards pushes
	; the return pointer of size 4 bytes). The stack was originally 16-byte
	; aligned above and we've since pushed a multiple of 16 bytes to the
	; stack since (pushed 0 bytes so far) and the alignment is thus
	; preserved and the call is well defined.
        ; note, that if you are building on Windows, C functions may have "_" prefix in assembly: _kernel_main
	extern kernel_main
	call kernel_main
 
	; If the system has nothing more to do, put the computer into an
	; infinite loop. To do that:
	; 1) Disable interrupts with cli (clear interrupt enable in eflags).
	;    They are already disabled by the bootloader, so this is not needed.
	;    Mind that you might later enable interrupts and return from
	;    kernel_main (which is sort of nonsensical to do).
	; 2) Wait for the next interrupt to arrive with hlt (halt instruction).
	;    Since they are disabled, this will lock up the computer.
	; 3) Jump to the hlt instruction if it ever wakes up due to a
	;    non-maskable interrupt occurring or due to system management mode.
	cli
.hang:	hlt
	jmp .hang
.end:


; The multiboot standard does not define the value of the stack pointer register
; (esp) and it is up to the kernel to provide a stack. This allocates room for a
; small stack by creating a symbol at the bottom of it, then allocating 16384
; bytes for it, and finally creating a symbol at the top. The stack grows
; downwards on x86. The stack is in its own section so it can be marked nobits,
; which means the kernel file is smaller because it does not contain an
; uninitialized stack. The stack on x86 must be 16-byte aligned according to the
; System V ABI standard and de-facto extensions. The compiler will assume the
; stack is properly aligned and failure to align the stack will result in
; undefined behavior.
global kernel_stack_lowest_address
section .bss                        ; Use the 'bss' section for the stack
    align 4                         ; align at 4 bytes for performance reasons
    kernel_stack_lowest_address:    ; label points to beginning of memory
        resb KERNEL_STACK_SIZE      ; reserve stack for the kernel
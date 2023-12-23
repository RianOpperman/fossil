# Declare constants for the MULTIBOOT header
.set ALIGN, 1 << 0 # Align loaded modules on page boundaries
.set MEMINFO, 1 << 1 # Provide memory map
.set FLAGS, ALIGN | MEMINFO # This is the Multiboot 'flag' field
.set MAGIC, 0x1BADB002 # 'Magic number' let's bootloader find the header
# Checksum of above, to prove we are multiboot
.set CHECKSUM, -(MAGIC + FLAGS)

/*
    Declare multiboot header that marks the program as a kernel. These values
    are documented in the multiboot standard. Bootloader will search for this
    in the first 8 KiB of the kernel file, aligned at a 32-bit boundary,
    Signature is in it's own section so header can be forced to be within the
    first 8 KiB of the kernel file
*/
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

/*
    Multiboot standard doesn't define the value of the stack pointer register
    (`esp`) and it is up to the kernel to provide the stack. This allocates
    room for a small stack by creating a symbol at the bottom of it, then
    allocating 16384 B for it, and creating a symbol at the top. The stack
    grows downward. Stack is in its own section so it can be marked nobits,
    which means the kernel file is smaller because it doesn't contain an
    uninitialized stack. The stack on x86 must be 16-byte aligned. The
    compiler will assume the stack is properly aligned and failure to align
    the stack will result in UB
*/
.section .bss
.align 16
stack_bottom:
.skip 16384 # 16 KiB
stack_top:

/*
    Linker script specifies _start as the entry point and bootloader will
    jump to this position once the kernel has been loaded. Don't return
    here as the bootloader will be gone
*/
.section .text
.global _start
.type _start, @function
_start:
    /*
        Bootloader has loaded us into 32-bit protected mode. Interrupts &
        paging are disabled. Processor state is as defined in the multiboot
        standard. Kernel has full control of the CPU. Kernel can only make
        use of hardware features and any code it provides as part of itself.
        There is no `printf`, unless we include our own <stdio.h> header and
        printf implementation. No security restrictions, no safeguards, no
        debugging, only what the kernel provides itself.
    */

    /*
        To set up a stack, we set the esp register to point to the top of
        the stack. Needs to be done since C can't function without a stack.
    */
    mov $stack_top, %esp

    /*
        This is a good place to initialize the crucial processor state
        before the kernel is entered. Best to minimize the early
        environment where crucial features are offline. CPU not fully
        initialized yet; no FP instructions or instruction set
        extensions.
        GDT should be loaded here & paging should be enabled.
    */

    /*
        Enter the kernel. ABI requires the stack as 16-byte aligned at the
        time of the call (which pushes the return pointer of size 4 B).
        Stack was originally 16 B aligned above and we've pushed a multiple
        of 16 B onto the stack since then, so alignment has been preserved
        and call is well defined
    */
    call kernel_main

    /*
        If the system has nothing more to do, put the computer into an
        infinite loop:
        1.  Disable interrupts with cli. They are already disabled by the
            bootloader so not needed. We might need to enable interrupts
            later and return from kernel_main (although its kinda nonsense)
        2.  Wait for the next interrupt to arrive with hlt
            (halt instruction). Since they are disabled locks up PC
        3.  Jump to hlt if it ever wakes up from a non-maskable interrupt
            or from system management mode
    */
    cli
1:  hlt
    jmp 1b

/*
    Set the size of the _start symbol to the current location '.' minus its
    start. Tis is useful when debugging or when you implement call tracing.
*/
.size _start, . - _start

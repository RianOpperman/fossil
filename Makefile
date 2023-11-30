kernel := fossil.bin
isoFile := fossil.iso
linkFiles := kernel.o boot.o
compileOptions := -ffreestanding -O2 -Wall -Wextra
linkOptions := -ffreestanding -O2 -nostdlib

all: assemble compile link

assemble: boot.s
	i686-elf-as boot.s -o boot.o

compile: kernel.c
	i686-elf-gcc -c kernel.c -o kernel.o $(compileOptions)

link:
	i686-elf-gcc -T linker.ld -o fossil.bin $(linkOptions) $(linkFiles) -lgcc

verify: $(kernel)
	grub-file --is-x86-multiboot $(kernel)

iso: $(kernel) grub.cfg
	cp $(kernel) iso/boot
	cp grub.cfg iso/boot/grub
	grub-mkrescue -o $(isoFile) iso

run:
	qemu-system-i386 -cdrom $(isoFile)

runk runK:
	qemu-system-i386 -kernel $(kernel)

clean:
	rm -f *.o
	rm -rf iso
	rm -f $(kernel)
	rm -f $(isoFile)
	mkdir -p iso/boot/grub

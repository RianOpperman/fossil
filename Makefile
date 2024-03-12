# Flags & various variables
CC := clang

WARNINGS := -Wall -Wextra -pedantic -Wshadow -Wpointer-arith -Wcast-align \
            -Wmissing-prototypes -Wredundant-decls -Wnested-externs -Winline \
			-Wno-long-long -Wconversion -Wstrict-prototypes

COMMON_CFLAGS := -ffreestanding \
				 -mno-red-zone \
				 -O2 \
				 $(WARNINGS)

QEMU_FLAGS := -L OVMF \
			  -pflash OVMF/OVMF.fd \
			  -drive file=fossil.iso,format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on \
			  -device ahci,id=ahci0 \
			  -device ide-cd,bus=ahci0.0,drive=drive-cd1,id=cd1,bootindex=1

BOOT_DIR := src/boot
BOOT_SRC_FILES := $(shell find src/boot -type f \( -name "*main.c" -o -name "*data.c" \))
BOOT_CFLAGS := -target x86_64-unknown-windows \
		  -fshort-wchar \
		  $(COMMON_CFLAGS) \
		  -I$(BOOT_DIR)/inc -I$(BOOT_DIR)/inc/x86_64 -I$(BOOT_DIR)/inc/protocol
BOOT_LDFLAGS := -target x86_64-unknown-windows \
		   -nostdlib \
			 -O2 \
		   -Wl,-entry:efi_main \
		   -Wl,-subsystem:efi_application \
		   -fuse-ld=lld-link
BOOT_OBJ_FILES := $(patsubst %.c,%.o,$(BOOT_SRC_FILES))


KERNEL_DIR := src/kernel
KERNEL_SRC_FILES := $(shell find $(KERNEL_DIR) -type f -name "*.c")
KERNEL_HDR_FILES := $(shell find $(KERNEL_DIR) -type f -name "*.h")
KERNEL_CFLAGS := -target x86_64-unknown-linux-gnu \
								 $(COMMON_CFLAGS)
KERNEL_LFLAGS := -target x86_64-unknown-linux-gnu \
								 -nostdlib \
								 -O2 \
								 -Wl,-ekmain

KERNEL_OBJ_FILES := $(patsubst %.c,%.o,$(KERNEL_SRC_FILES))

OBJ_FILES := $(KERNEL_OBJ_FILES) $(BOOT_OBJ_FILES)

KERNEL := fossil.bin
BOOTLOADER := BOOTX64.EFI
ISO := fossil.iso
EMULATOR := qemu-system-x86_64
BOOT_FILE := BOOTX64.EFI
FAT_IMG := fat.img

.PHONY: all clean run runk runK iso kernel bootloader

all: $(BOOTLOADER) $(BOOT_OBJ_FILES) $(KERNEL) $(KERNEL_OBJ_FILES)

kernel: $(KERNEL) $(KERNEL_OBJ_FILES)

bootloader: $(BOOTLOADER) $(BOOT_OBJ_FILES)

# Source files & Compilation
src/kernel/%.o: src/kernel/%.c
	@echo "Compiling kernel object files..."
	@$(CC) $(KERNEL_CFLAGS) -c $< -o $@

$(KERNEL): $(KERNEL_OBJ_FILES)
	@echo "Creating kernel ELF binary..."
	@$(CC) $(KERNEL_LFLAGS) -o $(KERNEL) $(KERNEL_OBJ_FILES) -lgcc

$(BOOT_DIR)/%.o: $(BOOT_DIR)/%.c
	@echo "Compiling bootloader object files..."
	@$(CC) $(BOOT_CFLAGS) -c $< -o $@

$(BOOTLOADER): $(BOOT_OBJ_FILES)
	@echo "Creating EFI binary..."
	@$(CC) $(BOOT_LDFLAGS) -o $(BOOT_FILE) $(BOOT_OBJ_FILES)

# Run commands
# Creates an ISO with the bootloader in /EFI/BOOT and the kernel in /boot
iso: $(KERNEL) $(BOOTLOADER)
	@echo "Creating $(ISO)..."
	@dd if=/dev/zero of=$(FAT_IMG) bs=1k count=1440
	@mformat -i $(FAT_IMG) -f 1440 ::
	@mmd -i $(FAT_IMG) ::/EFI
	@mmd -i $(FAT_IMG) ::/EFI/BOOT
	@mmd -i $(FAT_IMG) ::/boot
	@mcopy -i $(FAT_IMG) $(BOOT_FILE) ::/EFI/BOOT
	@mcopy -i $(FAT_IMG) $(KERNEL) ::/boot
	@cp $(FAT_IMG) iso
	@xorriso -as mkisofs -R -f -e $(FAT_IMG) -no-emul-boot -o $(ISO) iso
	@echo "Created $(ISO)!"

# Run from the bootloader (Recommended)
run:
	@qemu-system-x86_64 $(QEMU_FLAGS)

# Run from the kernel
runk runK:
	@$(EMULATOR) -kernel $(KERNEL)

clean:
	@rm -f $(OBJ_FILES)
	@rm -rf iso
	@rm -f $(KERNEL) $(BOOTLOADER) $(FAT_IMG) $(ISO)
	@mkdir -p iso

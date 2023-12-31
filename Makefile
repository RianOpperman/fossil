# Flags & various variables
CC := i686-elf-gcc
AS := i686-elf-as
PROJ_DIRS := src
BOOT_FILE := $(shell find $(PROJ_DIRS) -type f -name "boot.s")
SRC_FILES := $(shell find $(PROJ_DIRS) -type f -name "*.c")
HDR_FILES := $(shell find $(PROJ_DIRS) -type f -name "*.h")

BOOT_OBJ_FILES := $(patsubst %.s, %.o, $(BOOT_FILE))
C_OBJ_FILES := $(patsubst %.c,%.o,$(SRC_FILES))
OBJ_FILES := $(C_OBJ_FILES) $(BOOT_OBJ_FILES)

DEP_FILES := $(patsubst %.c,%.d,$(SRC_FILES))
LINKER_FILES := $(shell find $(PROJ_DIRS) -type f -name "*.ld")
CFG_FILES := $(shell find $(PROJ_DIRS) -type f -name "*.cfg")

WARNINGS := -Wall -Wextra -pedantic -Wshadow -Wpointer-arith -Wcast-align \
            -Wmissing-prototypes -Wredundant-decls -Wnested-externs -Winline \
			-Wno-long-long -Wconversion -Wstrict-prototypes
CFLAGS := -ffreestanding -O2 $(WARNINGS)
LFLAGS := -ffreestanding -O2 -nostdlib

KERNEL := fossil.bin
ISO := fossil.iso
EMULATOR := qemu-system-i386

.PHONY: all clean run runk runK iso verify

all: $(BOOT_OBJ_FILES) $(OBJ_FILES) fossil.bin

# Source files & Compilation
$(BOOT_OBJ_FILES): $(BOOT_FILE)
	@$(AS) $(BOOT_FILE) -o $(BOOT_OBJ_FILES)

%.o: %.c
	@$(CC) $(CFLAGS) -c $< -o $@

$(KERNEL): $(OBJ_FILES)
	@$(CC) $(LFLAGS) -T $(LINKER_FILES) -o $(KERNEL) $(OBJ_FILES) -lgcc

# Run commands
verify: $(KERNEL)
	grub-file --is-x86-multiboot $(KERNEL)

iso: $(KERNEL) $(CFG_FILES)
	@cp $(KERNEL) iso/boot
	@cp $(CFG_FILES) iso/boot/grub
	@grub-mkrescue -o $(ISO) iso

run:
	@$(EMULATOR) -cdrom $(ISO)

runk runK:
	@$(EMULATOR) -kernel $(KERNEL)

clean:
	@rm -f $(OBJ_FILES)
	@rm -rf iso
	@rm -f $(KERNEL)
	@rm -f $(ISO)
	@mkdir -p iso/boot/grub

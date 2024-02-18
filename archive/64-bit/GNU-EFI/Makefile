CC := clang
CFLAGS := -target x86_64-unknown-windows \
		  -ffreestanding \
		  -fshort-wchar \
		  -mno-red-zone \
		  -Iinc -Iinc/x86_64 -Iinc/protocol
LDFLAGS := -target x86_64-unknown-windows \
		   -nostdlib \
		   -Wl,-entry:efi_main \
		   -Wl,-subsystem:efi_application \
		   -fuse-ld=lld-link

QEMU_FLAGS := -L ../../OVMF \
			  -pflash ../../OVMF/OVMF.fd \
			  -drive file=fossil.iso,format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on \
			  -device ahci,id=ahci0 \
			  -device ide-cd,bus=ahci0.0,drive=drive-cd1,id=cd1,bootindex=1

PROJ_DIRS := src
SRC_FILES := $(shell find $(PROJ_DIRS) -type f -name "*.c")
OBJ_FILES := $(patsubst %.c,%.o,$(SRC_FILES))

BOOT_FILE := BOOTX64.EFI
ISO := kernel.ISO
FAT_IMG := fat.img

.PHONY: all clean run

all: $(OBJ_FILES) $(BOOT_FILE) $(ISO)

%.o: %.c
	@$(CC) $(CFLAGS) -c $< -o $@

$(BOOT_FILE): $(OBJ_FILES)
	@$(CC) $(LDFLAGS) -o $(BOOT_FILE) $(OBJ_FILES)

$(ISO): $(BOOT_FILE)
	@echo "Creating $(ISO)..."
	@dd if=/dev/zero of=$(FAT_IMG) bs=1k count=1440
	@mformat -i $(FAT_IMG) -f 1440 ::
	@mmd -i $(FAT_IMG) ::/EFI
	@mmd -i $(FAT_IMG) ::/EFI/BOOT
	@mcopy -i $(FAT_IMG) $(BOOT_FILE) ::/EFI/BOOT
	@cp $(FAT_IMG) iso
	@xorriso -as mkisofs -R -f -e $(FAT_IMG) -no-emul-boot -o $(ISO) iso
	@echo "Created $(ISO)!"

clean:
	@rm $(OBJ_FILES) $(BOOT_FILE) iso/$(FAT_IMG)

run:
	qemu-system-x86_64 $(QEMU_FLAGS)

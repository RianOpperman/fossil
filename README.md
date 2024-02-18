# Fossil
Custom UNIX like 64-bit OS written in C using a Rust written library

## Requirements

- `clang`
- `lld-link`
- `xorriso`
- `qemu-system-x86_64`

## Information
The OS is UEFI compatible & uses a custom made UEFI-based bootloader called `uitgrawe` (pronounced "uh-ate-gra-ve"), which is written in C. 

`clang` is used as the compiler due to its ability to support both UEFI applications (Windows PE format) and ELF files (Linux format).

### Uitgrawe
"Uitgrawe" means "excavate" in English, which is why it's the bootloader to set up everything for the `fossil` OS.

The GNU-EFI library is used under the hood to enable the bootloader to talk to the UEFI firmware. It is included in the repo for your convenience.
Additionally, the OVMF firmware binaries are used with `qemu` to boot into a UEFI environment for the bootloader to take action. It has also been included for your convenience.
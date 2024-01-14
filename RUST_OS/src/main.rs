#![no_std]
#![no_main] // Disable usual entry points

use core::panic::PanicInfo;

// On panics this is used
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

// Entry point to the kernel
#[no_mangle]
pub extern "C" fn _start() -> ! {
    loop {}
}
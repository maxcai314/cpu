#include "riscv_io.h"

#define MMIO32(ADDR) ((volatile u32 *)(ADDR))
#define MMIO8(ADDR) ((volatile u8 *)(ADDR))

#define SIO_BASE (0x01000fff)
#define SIO_LED_OUTPUT MMIO8(SIO_BASE + 0x00)

void set_led_output(u8 value) {
    *SIO_LED_OUTPUT = value;
}

// does roughly 20 cycles of stalling
static inline void stall_loop(u32 num_iter) {
    asm volatile (
        "1:\n\t"
        "beq %0, zero, 2f\n\t"
        "addi %0, %0, -1\n\t"
        "nop\n\t" "nop\n\t" "nop\n\t" "nop\n\t"
        "nop\n\t" "nop\n\t" "nop\n\t" "nop\n\t"
        "nop\n\t" "nop\n\t" "nop\n\t" "nop\n\t"
        "nop\n\t" "nop\n\t" "nop\n\t" "nop\n\t"
        "j 1b\n\t"
        "2:\n\t"
        : "+r"(num_iter)
        :
        : "memory"
    );
}

#define LOOPS_PER_MS 746 // Adjust this value based on your system's clock speed

void delay_ms(u32 ms) {
    for (u32 i = 0; i < ms; i++) {
        stall_loop(LOOPS_PER_MS); // Adjust the loop count for your clock speed
    }
}
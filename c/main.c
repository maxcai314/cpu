#include "types.h"
#include "riscv_io.h"

int main(void) __attribute__ ((section ("entry")));
void setup(void);
void loop(void);

int main() {
    setup();
    while (1) loop();
}

int a;

void setup() {
    // Set the LED output to 0 initially
    set_led_output(0);
    a = 5;
}

void loop() {
    // Turn on the LED
    set_led_output(1);
    delay_ms(1000); // Delay for 1 second

    // Turn off the LED
    set_led_output(0);
    delay_ms(1000); // Delay for 1 second
    a *= a;
}
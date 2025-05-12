#include "types.h"
#include "riscv_io.h"

int main(void);
void setup(void);
void loop(void);

int main() {
    setup();
    while (1) loop();
}

/// user code

void flash_digit(int digit) {
    set_led_output(0);
    delay_ms(1);
    // Flash the LED with the given digit
    for (int i = 0; i < digit; i++) {
        set_led_output(1);
        delay_ms(1);
        set_led_output(0);
        delay_ms(1);
    }
    set_led_output(0);
    delay_ms(1);
}

// flash each digit of a four-digit number from left to right
// i.e. an input of "123" will flash 0, 1, 2, 3
void flash_four_digits(int four_digits) {
    u8 digits[4];
    for (int i=0; i<4; i++) {
        digits[i] = four_digits % 10;
        four_digits /= 10;
    }
    // flash the digits in reverse order
    for (int i=3; i>=0; i--) {
        flash_digit(digits[i]);
        if (i != 0) delay_ms(3); // delay between digits
    }
}

void setup() {
    // Set the LED output to 0 initially
    set_led_output(0);
    delay_ms(2);
    
    // calculate and display digits of pi
    // https://crypto.stanford.edu/pbc/notes/pi/code.html
    s16 r[280 + 1];
    int i, k;
    int b, d;
    int c = 0;

    for (i = 0; i < 280; i++) {
	    r[i] = 2000;
    }
    r[i] = 0;

    for (k = 280; k > 0; k -= 14) {
        d = 0;

        i = k;
        for (;;) {
            d += r[i] * 10000;
            b = 2 * i - 1;

            r[i] = d % b;
            d /= b;
            i--;
            if (i == 0) break;
            d *= i;
        }
        
        int four_digits = c + d / 10000;
        flash_four_digits(four_digits);

        c = d % 10000;
    }
}

void loop() {
    set_led_output(0);
    delay_ms(100);

    // Turn on the LED
    set_led_output(1);
    delay_ms(1);

    // Turn off the LED
    set_led_output(0);
    delay_ms(1);
}
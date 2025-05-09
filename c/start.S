.section .entry
.global _start
_start:
    la sp, _sp         # Load stack pointer
    call main          # Call C main
1:  j 1b               # If main returns, halt

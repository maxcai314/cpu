PREFIX = riscv32-unknown-elf

CC = $(PREFIX)-gcc
LD = $(PREFIX)-ld
STRIP = $(PREFIX)-strip
OBJCOPY = $(PREFIX)-objcopy
CFLAGS = -march=rv32id -ffreestanding -nostdlib -lgcc -O2
LDFLAGS = -melf32lriscv -T link_riscv.ld

LGCC = $(shell $(CC) -print-libgcc-file-name)

SRC_C = main.c riscv_io.c
SRC_S = start.S
OBJ = $(SRC_C:.c=.o) $(SRC_S:.S=.o)

all: main.mem

.PHONY: all clean
.PRECIOUS: %.bin %.o

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

main.bin: $(OBJ)
	$(LD) $(LDFLAGS) $^ $(LGCC) -o $@

main.raw: main.bin
	$(STRIP) $<
	$(OBJCOPY) -O binary $< $@

main.mem: main.raw
	od -An -vtx1 -w1 $< | cut -c2- > $@

clean:
	rm -f *.o *.bin *.raw *.mem

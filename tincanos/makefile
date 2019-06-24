ASFLAGS = --32
CFLAGS = -m32 -Wall -std=c99 -O0 -fno-builtin -nostdlib
LDFLAGS := -Tlinker.ld

EXEC := $(shell basename $(PWD))
EXEC_IMG := $(EXEC).img

.PHONY: all
all: $(EXEC_IMG)

$(EXEC_IMG): $(EXEC).bin
	mkdosfs -n TINCANOS -C $@ -S 512 1440
	dd if=loader.com of=$@ bs=1 seek=62
	dd if=$< of=$@ bs=512 seek=1
	dd if=/dev/zero of=$@ bs=512 seek=2879 count=1

.INTERMEDIATE: $(EXEC).bin
$(EXEC).bin: $(EXEC) loader.com
	objcopy -Obinary $< $@

.INTERMEDIATE: $(EXEC)
$(EXEC): init.o system.o
	$(LD) $(LDFLAGS) -o $@ $^

.INTERMEDIATE: loader.com
loader.com: loader.asm
	nasm -f bin -o $@ $^

.INTERMEDIATE: init.o
init.o: init.s

.INTERMEDIATE: system.o
system.o: system.c

.PHONY: clean
clean:
	rm -f *.o *.bin *.img


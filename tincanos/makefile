CFLAGS = -Wall -std=c99 -O0 -fno-builtin -nostdlib
LDFLAGS := -Tlinker.ld

EXEC := $(shell basename $(PWD))
EXEC_IMG := $(EXEC).img
BOOT_IMG := boot.img

$(BOOT_IMG): EXEC_IMG_SIZE = $(shell ls -l $(EXEC_IMG) | awk '{print $$5}')
$(BOOT_IMG): $(EXEC_IMG)
	dd if=/dev/zero of=$@ bs=1 seek=$(EXEC_IMG_SIZE) count=1474560
	truncate -s 1474560 $(BOOT_IMG)
$(EXEC_IMG): $(EXEC).bin
	mkdosfs -n TINCANOS -C $@ -S 512 1440
	dd if=loader.com of=$@ bs=1 seek=61
	dd if=$(EXEC).bin of=$@ bs=512 seek=1
$(EXEC).bin: $(EXEC) loader.com
	objcopy -Obinary $< $@
$(EXEC): init.o system.o
	$(LD) $(LDFLAGS) -o $@ $^
loader.com: loader.asm
	nasm -f bin -o $@ $^
init.o: init.s
system.o: system.c

.PHONY: clean
clean:
	rm -f *.o *.bin *.com *.img $(EXEC)


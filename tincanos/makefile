CFLAGS = -Wall -std=c99 -O0 -fno-builtin -nostdlib
LDFLAGS := -Tlinker.ld
EXEC := $(shell basename $(PWD))

$(EXEC).img: $(EXEC)
	objcopy -Obinary $^ $@
$(EXEC): init.o system.o
	$(LD) $(LDFLAGS) -o $@ $^
init.o: init.s
system.o: system.c

.PHONY: clean
clean:
	rm -f *.o *.img $(EXEC)

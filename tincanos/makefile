LDFLAGS := -Tlinker.ld
EXEC := $(shell basename $(PWD))

$(EXEC).bin: hello
	objcopy -Obinary $^ $@
$(EXEC): isr.o hello.o
	$(LD) $(LDFLAGS) -o $@ $^
hello.o: hello.s
isr.o: isr.s

.PHONY: clean
clean:
	rm -f *.o *.bin $(EXEC)

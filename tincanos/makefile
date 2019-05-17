LDFLAGS := -Tlinker.ld
EXEC := $(shell basename $(PWD))

$(EXEC).img: $(EXEC)
	objcopy -Obinary $^ $@
$(EXEC): init.o
	$(LD) $(LDFLAGS) -o $@ $^
init.o: init.s

.PHONY: clean
clean:
	rm -f *.o *.img $(EXEC)

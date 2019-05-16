CFLAGS=-Wall -marm -std=c99 -O0 -fno-builtin -fomit-frame-pointer
CPPFLAGS=-I .
EXECNAME=primos

# linker command 

$(EXECNAME): loader.o console.o init.o
	$(LD) $^ $(LDFLAGS) -o $@

init.o: init.c
loader.o: loader.s
console.o: console.s

.PHONY: clean
clean:
	rm -f *.o $(EXECNAME)


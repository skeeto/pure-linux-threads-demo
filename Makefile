NASM      ?= nasm
NASMFLAGS  =  -Fdwarf -g

all : threads.x86_64 threads.i386

threads.x86_64 : threads-x86_64.o
	$(LD) -melf_x86_64 $(LDFLAGS) -o $@ $^ $(LDLIBS)

threads.i386 : threads-i386.o
	$(LD) -melf_i386 $(LDFLAGS) -o $@ $^ $(LDLIBS)

threads-x86_64.o : threads-x86_64.s
	$(NASM) -felf64 $(NASMFLAGS) -o $@ $^

threads-i386.o : threads-i386.s
	$(NASM) -felf32 $(NASMFLAGS) -o $@ $^

clean :
	$(RM) *.o threads.x86_64 threads.i386

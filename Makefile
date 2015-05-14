NASM      ?= nasm
NASMFLAGS  = -g

plain-threads : threads.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LDLIBS)

threads.o : threads.s

clean :
	$(RM) threads.o plain-threads

%.o : %.s
	$(NASM) -felf64 $(NASMFLAGS) -o $@ $^

.PHONY : clean

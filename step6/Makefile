build:
	nasm -f elf64 hello.asm
	ld hello.o -T link.lds -o hello.out
	strip hello.out
.PHONY: build

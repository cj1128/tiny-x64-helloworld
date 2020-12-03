# Tiny x64 Hello World

A step by step adventure to find out how small a x64 binary can be which prints "hello, world".

- OS: CentOS 7, Linux 3.10.0-862.el7.x86_64
- GCC: gcc (Homebrew GCC 5.5.0_7) 5.5.0

## Overview

- `make build`: build all steps
- `make list`: list binary size of all steps
- `final/hello.out` is our final result, and it's 170 bytes 🎉

```
$ make build && make list
-rwxr-xr-x 1 root root 16712 Dec  4 00:08 step0/hello.out
-rwxr-xr-x 1 root root 14512 Dec  4 00:08 step1/hello.out
-rwxr-xr-x 1 root root 14512 Dec  4 00:08 step2/hello.out
-rwxr-xr-x 1 root root 13664 Dec  4 00:08 step3/hello.out
-rwxr-xr-x 1 root root 12912 Dec  4 00:08 step4/hello.out
-rwxr-xr-x 1 root root   584 Dec  4 00:08 step5/hello.out
-rwxr-xr-x 1 root root   440 Dec  4 00:08 step6/hello.out
-rwxr-xr-x 1 root root   170 Dec  4 00:08 step7/hello.out
-rwxr-xr-x 1 root root   170 Dec  4 00:08 final/hello.out
```

## step0

This is our first try, the good old program to print "hello, world".

```c
#include <stdio.h>

int
main()
{
  printf("hello, world\n");
  return 0;
}
```

`cd step0 && make build` and we get our first `hello.out` binary.

Unfortunately, it's too big, 16712 bytes!

## step1: strip symbols

Let's take an easy move to strip all the symbols.

Let `gcc -c` do the work and now we get out new binary, it's 14512 bytes.

Still big, but hey, we certainly make a progress, do hurry 😉.

## step2: optimization

Modern compilers can do a lot of "magic" to optimize our program, let's give it a try.

`gcc -O3` enable the maximum optimization level and we will find oud that our binary size keeps the same 😢, 14512 bytes.

It actually makes sense though. Our program is too simple, there isn't any room left to optimize.

## step3: remove startup files

Our C program always starts with `main`, but Do you ever wonder who calls `main`?

It turns out the `main` function is being called by something called `crt`, the C runtime library which is implemented by the compiler.

If we remove it, our binary must be smaller, right?

We need to change our program a little bit.

- Let's change our entry function name to `nomain` to make the fact more obviously that we don't use crt
- Since we don't use crt, we need to explicitly use system call to exit

```c
#include <stdio.h>
#include <unistd.h>

int
nomain()
{
  printf("hello, world\n");
  _exit(0);
}
```

You must wonder why we are using `_exit` rather than `exit`? Good old StackOverflow always helps, check [What is the difference between using \_exit() & exit() in a conventional Linux fork-exec?
](https://stackoverflow.com/questions/5422831/what-is-the-difference-between-using-exit-exit-in-a-conventional-linux-fo).

Use `gcc -e nomain -notartfiles` to compiler our program and now our binary is 13664 bytes.

We are making a progress again!

## step4: remove standard library

We can go more wilder. We don't need the crt to do the startup, why do we need to use `printf` to print? We can certainly do it on our own!

To print something to the terminal, we need to use the `write` system call. [Here](https://github.com/torvalds/linux/blob/v3.13/arch/x86/syscalls/syscall_64.tbl) is the full x64 system call table.

To directly invoke system call in C, we need to use [inline assembly](https://www.ibiblio.org/gferg/ldp/GCC-Inline-Assembly-HOWTO.html).

```c
char *str = "hello, world\n";

void
myprint()
{
  asm("movq $1, %%rax \n"
      "movq $1, %%rdi \n"
      "movq %0, %%rsi \n"
      "movq $13, %%rdx \n"
      "syscall \n"
      : // not output
      : "r"(str)
      : "rax", "rdi", "rsi", "rdx");
}

void
myexit()
{
  asm("movq $60, %rax \n"
      "xor %rdi, %rdi \n"
      "syscall \n");
}

int
nomain()
{
  myprint();
  myexit();
}
```

Looks kind of messy, but it's actually very simple code.

`gcc -nostdlib` to tell GCC we don't want the standard library since we are cool enough to do all the tings by ourselves.

And we get 12912 bytes.

Our program doesn't depend on anyting now, but it's still very big, why????

## step5: custom linker script

Let's examine sctions of our binary.

```
$ readelf -S -W step4/hello.out
Section Headers:
  [Nr] Name              Type            Address          Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            0000000000000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        0000000000401000 001000 00006e 00  AX  0   0 16
  [ 2] .rodata           PROGBITS        0000000000402000 002000 00000e 01 AMS  0   0  1
  [ 3] .eh_frame_hdr     PROGBITS        0000000000402010 002010 000024 00   A  0   0  4
  [ 4] .eh_frame         PROGBITS        0000000000402038 002038 000054 00   A  0   0  8
  [ 5] .data             PROGBITS        0000000000404000 003000 000008 00  WA  0   0  8
  [ 6] .comment          PROGBITS        0000000000000000 003008 000022 01  MS  0   0  1
  [ 7] .shstrtab         STRTAB          0000000000000000 00302a 000040 00      0   0  1
```

`Off` is kind of strange, some sections start with very big offset.

Maybe linker does some alignment? Check `ld --verbose` and yes it does!

So our binary is so big because of alignment, if we use `xxd` to see the binary content we can see that there are a lot of zeroes.

Time to write our own linker script `link.lds`.

```
ENTRY(nomain)

SECTIONS
{
  . = 0x8048000 + SIZEOF_HEADERS;

  tiny : { *(.text) *(.data) *(.rodata*) }

  /DISCARD/ : { *(*) }
}
```

`gcc -T link.lds` and we get 584 bytes, a huge step 🔥.

## step6: assembly

Can we do better? There is nothing we can do inside the C world, it's time to move to the lower level.

Handmade assembly seems terrfying, just give it a try, you will find it's actually very interesting.

You are like the God, you can control everyting!

```nasm
section .data
message: db "hello, world", 0xa

section .text

global nomain
nomain:
  mov rax, 1
  mov rdi, 1
  mov rsi, message
  mov rdx, 13
  syscall
  mov rax, 60
  xor rdi, rdi
  syscall
```

Use `nasm` to assemble our code and we get 440 bytes.

## step7: handmade binary

Can we do better?

## Final Binary Anatomy

```
00: 7f 45 4c 46 02 01 01 00
08: 00 00 00 00 00 00 00 00
0:   b8 01 00 00 00          mov    $0x1,%eax
 5:   bf 01 00 00 00          mov    $0x1,%edi
 a:   48 be 9d 00 40 00 00    movabs $0x40009d,%rsi
11:   00 00 00
14:   ba 0d 00 00 00          mov    $0xd,%edx
19:   0f 05                   syscall
1b:   b8 3c 00 00 00          mov    $0x3c,%eax
20:   48 31 ff                xor    %rdi,%rdi
23:   0f 05                   syscall
25:   68 65 6c 6c 6f          pushq  $0x6f6c6c65
2a:   2c 20                   sub    $0x20,%al
2c:   77 6f                   ja     0x9d
2e:   72 6c                   jb     0x9c
30:   64                      fs
31:   0a                      .byte 0xa
```

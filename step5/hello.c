char *str = "hello, world\n";

void
myprint()
{
  asm("movq $1, %%rax \n"
      "movq $1, %%rdi \n"
      "movq %0, %%rsi \n"
      "movq $13, %%rdx \n"
      "syscall \n"
      : // no output
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

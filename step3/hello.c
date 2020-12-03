#include <stdio.h>
#include <unistd.h>

int
nomain()
{
  printf("hello, world\n");
  _exit(0);
}

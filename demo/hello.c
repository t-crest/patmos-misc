#include <stdio.h>

int main(int argc, char** argv)
{
  int i = 20;

  if (argc > 0) {
    i = i / argc;
  }

  printf("Hello World: %d\n", i);

  return 0;
}


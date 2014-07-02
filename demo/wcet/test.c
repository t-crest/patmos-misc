#include <stdio.h>

int measure(int i) __attribute__((noinline,used));
int measure(int a) {
  int b = a;
  for (int i = 0; i < 10; i++) {
    b = b * i + b / 2;
  }
  return b;
}

int main(int argc, char** argv) {

  int c = measure(argc + 5);

  printf("Result: %d!\n", c);

  return 0;
}

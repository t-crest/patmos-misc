
volatile int a = 1;
volatile int b = 2;
volatile int c = 3;
volatile int d = 4;

int v[256] = {1,2,3,4,5};
volatile int* volatile p1 = &v[0];
volatile int* volatile p2 = &v[0];


int main(int argc, char** argv) {

  int r = b;
  int s = d;

  for  (int i = 0; i < 256; i++) {
    // = ?
    // = a
    r = s + *p1 + a * 2;

    // = ?
    // = c
    s = r + *p2 + c * 3;
  }

  return r > s;
}

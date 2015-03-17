// A hello world program

#include <stdio.h>

#ifdef BARE_MODE
extern void printstr(const char*);
#endif

int main() {
#ifdef BARE_MODE
  printstr("Hello World!\n");   /* printf is not available in bare-metal mode */
#else
  printf("Hello World!\n");
#endif
}


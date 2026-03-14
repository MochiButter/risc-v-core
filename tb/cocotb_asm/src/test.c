#include <stddef.h>
#define PRINT_ADDR ((volatile char *) 0x10000000)

void handle_exception(){
  void *mepc;
  asm("csrr %0, mepc" : "=r"(mepc));
  mepc += 4;
  asm("add ra, x0, %0" : "=r"(mepc));
  return;
}

int main(){
  void *f = handle_exception;
  asm("csrw mtvec, %0" : "=r"(f));

  char *sample_text = "hellowld";
  while (*sample_text != '\0') {
    *PRINT_ADDR = *sample_text;
    sample_text ++;
  }

  char test;
  test = 'a';
  *(&test) = 'b';
  char *some_location = (char *) 0x200;
  *some_location = 0x42;
  int *word = (int*) 0x1ff;
  *word = 0xdeadbeef;
  int num = 2 + 2;
  return 0;
}

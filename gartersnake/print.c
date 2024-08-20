#include <stdint.h>
#include "print.h"

#define HEX_TO_STRING(hex, buffer) (sprintf(buffer, "0x%llx", (unsigned long long)(hex)), buffer)
#define DEC_TO_STRING(dec, buffer) (sprintf(buffer, "%lld", (long long)(dec)), buffer)

void print_heap(int64_t* heap_start, int64_t* heap_end) {
  char buffer[20];
  
  printf("HEAP_START------------------------------------\n");
  while (heap_start < heap_end) {
    printf("----------------------------------------------\n");
    printf("%p | GC - %ld\n", heap_start, *heap_start);
    int64_t size = *(++heap_start);
    printf("%p | Size - %ld\n", heap_start, size);
    heap_start++;
    printf("%p | Name - %s\n", heap_start, *((char **)heap_start));
    heap_start++;
    for (int64_t i = 0; i < size; i++, heap_start++) {
      int64_t representation = *heap_start;
      char *val;
      if      (representation == 0)       val = "null";
      else if (representation == 2)       val = "false";
      else if (representation == 6)       val = "true";
      else if ((representation & 7) == 0) val = HEX_TO_STRING(representation, buffer);
      else                                val = DEC_TO_STRING(representation >> 1, buffer);
      printf("%p | [%ld] - %s\n", heap_start, i, val);
    }
  }
  printf("HEAP_END--------------------------------------\n");
}

void print_stack(int64_t* stack_top, int64_t* stack_bottom) {
  printf("(print_stack) Not yet implemented.\n");
}

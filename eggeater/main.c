#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define TRUE         0x0000000000000006L
#define FALSE        0x0000000000000002L
// #define NULL      0x0000000000000000L
#define POINTER_MASK 0x0000000000000007L

#define BOA_MIN (- (1L << 62))
#define BOA_MAX ((1L << 62) - 1)

extern int64_t our_code_starts_here(int64_t* the_heap, int64_t input_val) asm("our_code_starts_here");
extern int64_t print(int64_t input_val) asm("print");
extern void error(int64_t val) asm("error");

// Replaces newlines with spaces.
void print_array_element(int64_t val) {
  if (val & 1) printf("%ld ", val >> 1);
  else if (val == TRUE) printf("true ");
  else if (val == FALSE) printf("false ");
  else if (val == (int64_t) NULL) printf("null ");
  else if ((val & POINTER_MASK) == 0)
  {
    int64_t *array_pointer = (int64_t*)val;
    int64_t length = array_pointer[0];
    printf("[");
    for (size_t i = 1; i <= length; i++)
      print_array_element(array_pointer[i]);
    printf("] ");
  }
  else fprintf(stderr, "\nGot unrepresentable value: %ld\n", val);
}

int64_t print(int64_t val) {
  if (val & 1) printf("%ld\n", val >> 1);
  else if (val == TRUE) printf("true\n");
  else if (val == FALSE) printf("false\n");
  else if (val == (int64_t) NULL) printf("null\n");
  else if ((val & POINTER_MASK) == 0)
  {
    int64_t *array_pointer = (int64_t*)val;
    int64_t length = array_pointer[0];
    printf("[ ");
    for (size_t i = 1; i <= length; i++)
      print_array_element(array_pointer[i]);
    printf("]\n");
  }
  else fprintf(stderr, "Got unrepresentable value: %ld\n", val);
  return val;
}

void error(int64_t error_code) {
  switch (error_code)
  {
  case 1:
    fprintf(stderr, "Error: overflow\n");
    break;
  case 2:
    fprintf(stderr, "Error: out of bounds array access\n");
    break;
  case 3:
    fprintf(stderr, "Error: negative array size\n");
    break;
  case 4:
    fprintf(stderr, "Error: tried to index into something that's not an array.\n");
    break;
  default:
    fprintf(stderr, "Error: unknown error\n");
    break;
  }
  exit(1);
}

int64_t parse_input(char *input) {
  char *endptr;
  int64_t parsed_input = strtol(input, &endptr, 10);
  if (*endptr != '\0') {
    fprintf(stderr, "Error: input must be a number: %s\n", input);
    exit(1);
  }
  if (parsed_input > BOA_MAX || parsed_input < BOA_MIN) {
    fprintf(stderr, "Error: input is not a representable number: %s\n", input);
    exit(1);
  }

  return (parsed_input << 1) | 1;
}

int main(int argc, char** argv) {
  if (argc != 2) {
    printf("Usage: eggeater <int>\n");
    exit(1);
  }

  int64_t input_val = parse_input(argv[1]);
  int64_t* the_heap = calloc(10000, sizeof(int64_t));
  int64_t result = our_code_starts_here(the_heap, input_val);
  print(result);
  return 0;
}

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define TRUE 0x0000000000000002L
#define FALSE 0x0000000000000000L

#define BOA_MIN (- (1L << 62))
#define BOA_MAX ((1L << 62) - 1)

extern int64_t our_code_starts_here(int64_t input_val) asm("our_code_starts_here");
extern void error(int64_t val) asm("error");

int64_t print(int64_t val) {
  if (val & 1) printf("%ld\n", val >> 1);
  else if (val == TRUE) printf("true\n");
  else if (val == FALSE) printf("false\n");
  else fprintf(stderr, "Got unrepresentable value: %ld\n", val);
}

void error(int64_t error_code) {
  switch (error_code)
  {
  case 1:
    fprintf(stderr, "Error: expected a number\n");
    break;
  case 2:
    fprintf(stderr, "Error: expected a boolean\n");
    break;
  case 3:
    fprintf(stderr, "Error: overflow\n");
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
    fprintf(stderr, "Error: input must be a boolean or a number: %s\n", input);
    exit(1);
  }
  if (parsed_input > BOA_MAX || parsed_input < BOA_MIN) {
    fprintf(stderr, "Error: input is not a representable number: %s\n", input);
    exit(1);
  }

  return (parsed_input << 1) | 1;
}
    

int main(int argc, char** argv) {
  if (argc > 2) {
    printf("Usage: boa [input]\n");
    exit(1);
  } 
  
  int64_t input_val =
          argc == 1
          ? FALSE
          : strcmp("true", argv[1]) == 0
          ? TRUE
          : parse_input(argv[1]);

  int64_t result = our_code_starts_here(input_val);
  print(result);
  return 0;
}

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define TRUE         0x0000000000000006L
#define FALSE        0x0000000000000002L
// #define NULL      0x0000000000000000L
#define POINTER_MASK 0x0000000000000007L
#define VISITED      0x0000000000000004L

#define BOA_MIN (- (1L << 62))
#define BOA_MAX ((1L << 62) - 1)

extern int64_t our_code_starts_here(int64_t* the_heap, int64_t input_val) asm("our_code_starts_here");
extern int64_t print(int64_t input_val) asm("print");
extern int64_t struct_eq(int64_t a, int64_t b) asm("struct_eq");
extern void error(int64_t val) asm("error");

typedef struct Node {
  int64_t *array;
  struct Node *next;
} Node;

Node *visited_head = NULL;
Node *visited_tail = NULL;

Node* create_node(int64_t *array) {
    Node *new_node = (Node *) malloc(sizeof(Node));
    if (new_node == NULL) {
        printf("Memory allocation failed\n");
        exit(1);
    }
    new_node->array = array;
    new_node->next = NULL;
    return new_node;
}

Node* add_node(int64_t *array) {
    Node *new_node = create_node(array);
    if (visited_head == NULL)
      visited_head = visited_tail = new_node;
    else {
      visited_tail->next = new_node;
      visited_tail = new_node;
    }
}

void clean_up() {
  while (visited_head != NULL) {
    *visited_head->array &= ~VISITED;
    Node *temp = visited_head;
    visited_head = visited_head->next;
    free(temp);
  }
}

int64_t rec_eq(int64_t *ap, int64_t *bp) {
  int64_t a = *ap, b = *bp;
  if (a == b) return TRUE;
  int64_t a_tag = a & POINTER_MASK, b_tag = b & POINTER_MASK;
  // Incompatible types, or TRUE / FALSE, or visited/unvisited
  if (a_tag != b_tag) return FALSE;
  if (a_tag & 1) return FALSE;
  // Cycle detected
  if (a_tag == VISITED) {
    fprintf(stderr, "Error: tried ~= on cyclic structure\n");
    exit(1);
  }
  if ((void *)a == NULL || (void *)b == NULL) return FALSE;
  // Must be unvisited pointers
  add_node(ap);
  add_node(bp);
  int64_t *new_ap = (int64_t*)a, *new_bp = (int64_t*)b;
  *ap = a | VISITED;
  *bp = b | VISITED;
  int64_t length = new_ap[0];
  if (length != new_bp[0]) return FALSE;
  
  int64_t are_eq = TRUE;
  for (size_t i = 1; i <= length; i++)
    are_eq &= rec_eq(&(new_ap[i]), &(new_bp[i]));
  
  return are_eq;
}

int64_t struct_eq(int64_t a, int64_t b) {
  // Same num, same bool, same address
  if (a == b) return TRUE;

  int64_t a_tag = a & POINTER_MASK, b_tag = b & POINTER_MASK;
  // Incompatible types, or TRUE / FALSE
  if (a_tag != b_tag) return FALSE;

  // Nums which are not the same
  if (a_tag & 1) return FALSE;

  // Must be pointers
  int64_t *ap = (int64_t*)a, *bp = (int64_t*)b;
  // One's null, the other isn't
  if (ap == NULL) return FALSE;
  // Get length
  int64_t length = ap[0];
  if (length != bp[0]) return FALSE;
  
  // Iterate through all elements
  int64_t are_eq = TRUE;
  for (size_t i = 1; i <= length; i++) {
    are_eq &= rec_eq(&(ap[i]), &(bp[i]));
  }
  
  // Clean up
  clean_up();
  return are_eq;
}

// Replaces newlines with spaces.
void print_array_element(int64_t *val_pointer) {
  int64_t val = *val_pointer;
  if (val & 1) printf("%ld ", val >> 1);
  else if (val == TRUE) printf("true ");
  else if (val == FALSE) printf("false ");
  else if (val == (int64_t) NULL) printf("null ");
  else if ((val & POINTER_MASK) == 0)
  {
    add_node(val_pointer);        // Store this address (it's the address of one array element)
    int64_t *array_pointer = (int64_t*)val;
    *val_pointer = val | VISITED; // Tag the contents of the array's element
    int64_t length = array_pointer[0];
    printf("[ ");
    for (size_t i = 1; i <= length; i++)
      print_array_element(&(array_pointer[i]));
    printf("] ");
  }
  else if ((val & POINTER_MASK) == VISITED) printf("(cyclic reference) "); // Stop the recursion for this array
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
      print_array_element(&(array_pointer[i]));
    printf("]\n");
    clean_up();
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

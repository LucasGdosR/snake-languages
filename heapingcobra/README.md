# PA6: Heap extensions
Heapingcobra implements both reference and structural equality and cycle detection for printing arrays. There are two example input files that showcase how they work, `print_cycle.boa` and `valid_eq.boa`.

I added a new operation to the definitions in `expr.ml`, parsed it in `parser.ml`, and included code generation in `compile.ml` to call a C function for structural equality. The meat and potatoes of the extensions is in `main.c`.

When arrays are printed or are compared structurally, the runtime environment tags all the pointers that are encountered. If an array holds a pointer to a second array, the pointer inside the first array gets tagged. Here's how the tagging works:
- Integers have their LSB set to 1
- Booleans have their 2 LSB set to 10 (either 110 or 010)
- Unvisited pointers have their 3 LSB set to 000
- Visited pointers have their 3 LSB set to 100

Those tags must be removed after the operation is done. For that, the runtime stores a pointer to every tagged pointer inside a linked list, and untags every node of the linked list when it's done printing / comparing.

This approach would not work well for multithreaded programs, since another thread could visit the modified pointer and it would need to always clear the tag before dereferencing the pointer.

Snippets for printing:
```
// Printing
int64_t print(int64_t val) {
  ...
  else if ((val & POINTER_MASK) == 0)
  {
    int64_t *array_pointer = (int64_t*)val;
    int64_t length = array_pointer[0];
    printf("[ ");
    for (size_t i = 1; i <= length; i++)
      print_array_element(&(array_pointer[i]));
    printf("]\n");
    clean_up(); // untag all pointers and free the linked list
  }
  ...
}

void print_array_element(int64_t *val_pointer) {
  int64_t val = *val_pointer;
  ...
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
  ...
}
```

Snippets for equality:
```
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
```

Snippets for linked list:
```
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
```

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "print.h"
#include "gc.h"

#define DEBUG 0

#define DEBUG_PRINT(...) \
     do { if (DEBUG) fprintf(stdout, __VA_ARGS__); } while (0)

#define IS_NON_NULL_POINTER(var) (((var & 7) == 0) && var)
#define NEXT_ADDR(size) (next += size + 3)

typedef struct {
  Data *gc_metadata;
  int64_t size;
  char* name;
  int64_t elements[];
} Data;

Data* mark_heap(Data *p);
extern int64_t *HEAP_END;

static int64_t *next;
static int64_t *HEAP_MIDDLE = 0;

int64_t* gc(int64_t* stack_bottom,
            int64_t* first_frame,
            int64_t* stack_top,
            int64_t* heap_start,
            int64_t* heap_end,
            int64_t* alloc_ptr) {
     DEBUG_PRINT("starting GC...\n");
     DEBUG_PRINT("\tstack top    = 0x%p\n\tstack_bottom = 0x%p\n\tfirst_frame  = 0x%p\n\theap start   = 0x%p\n\theap_end     = 0x%p\n",
                 stack_top,
                 stack_bottom,
                 first_frame,
                 heap_start,
                 heap_end);

     // Init the middle of the heap for cycling
     if (!HEAP_MIDDLE) HEAP_MIDDLE = HEAP_END;

     // Init next_addr pointer
     // and cycle halves of the heap
     bool which_cycle = HEAP_END > HEAP_MIDDLE;
     HEAP_END = HEAP_MIDDLE + (which_cycle ? 0 : ((int64_t) HEAP_MIDDLE - (int64_t) heap_start));
     next = which_cycle ? heap_start : HEAP_MIDDLE;

     // Scan the stack for the root set:
     int64_t *top_buf = stack_top, *rsp = first_frame - 1;
     while (top_buf < stack_bottom) {
          for (; top_buf < rsp; top_buf++) {
               int64_t var = *top_buf;
               if (IS_NON_NULL_POINTER(var))
                    *top_buf = (int64_t) mark_heap((Data*)var);
          }
          // Skip rsp and return address
          top_buf += 2;
          // Don't dereference rbx's value
          if (rsp != stack_bottom - 1)
               // Go to the next frame
               rsp = (int64_t*)((*rsp) - 1);
     }

     return next;
}

Data* mark_heap(Data *p) {
     Data* md = p->gc_metadata;
     if (md) return md;

     md = (Data*)next;
     p->gc_metadata = md;

     int64_t size = p->size;
     NEXT_ADDR(size);
     md->size = size;
     md->name = p->name;
     int64_t *elements = p->elements;
     for (int64_t i = 0; i < size; i++) {
          int64_t var = elements[i];
          if (IS_NON_NULL_POINTER(var))
               var = mark_heap((Data*)var);
          md->elements[i] = var;
     }
     
     return md;
}

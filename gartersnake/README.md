# PA7: Garbage collection
Garter Snake is the implementation of garbage collection. All of the implementation is in the gc.c file. I chose to implement semispace swapping. The other option was mark and compact. I am confident I could implement it too if I had to.

Every object allocated in the heap has a 24 B header, with 8 bytes for garbage collection metadata, 8 bytes for a pointer to the name of the object type, and 8 pointers for the object's size. Then comes the contents of the object.

The stack holds the return address at the bottom, then the previous rsp on top of it, then the arguments to the current function, then the local variables.

When garbage collection is triggered, we traverse the stack looking for pointers. We go through every frame, skipping old values of rsp and return addresses. Whenever a pointer is found, we follow it to the stack, mark it as visited and remember to where it will be moved to, move it, and go through whatever references it has to the heap. Finally, its new address is returned to the stack and updated. If a reference is ever visited twice, it returns its new address:
```
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
(...)

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
```

The garbage collector cycles between using the higher and lower halves of the heap addresses:
```
     // Init the middle of the heap for cycling
     if (!HEAP_MIDDLE) HEAP_MIDDLE = HEAP_END;

     // Init next_addr pointer
     // and cycle halves of the heap
     bool which_cycle = HEAP_END > HEAP_MIDDLE;
     HEAP_END = HEAP_MIDDLE + (which_cycle ? 0 : ((int64_t) HEAP_MIDDLE - (int64_t) heap_start));
     next = which_cycle ? heap_start : HEAP_MIDDLE;
```

And that's it! This was a pretty easy and small capstone project, compared to the rest. Still, it demystifies garbage collection.

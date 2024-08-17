# pa5
Writeup here:
https://ucsd-cse131-f19.github.io/pa5/pa5-open.pdf

The concrete grammar of your language, pointing out and describing the new concrete syntax beyond Diamondback. Graded on clarity and completeness (it’s clear what’s new, everything new is there) and if it’s accurately reflected by your parse implementation.

> I added arrays and operations on them. "set" is overloaded, taking 2 arguments to set variables, and 3 arguments to set elements of arrays.
>```
> e := ...
>   | (array e)
>   | (index e e)
>   | (set e e e)
>   | (null typ)
>
> op1 := ...
>   | isNull
>
> d := ...
>   | (type Alias typ)
>
> typ := ...
>   | Array
>   | Alias
>```
> As for types, there's a possibility of defining your own types. It is not possible to define a struct with this syntax, only an alias.
>
> The idiomatic way to create structs (on the heap, not the stack) starts with defining an alias of an Array. Then, define multiple functions for abstraction:
>- Constructor that takes the arguments and returns an array with each argument in the positionally correct field;
>
>- Getters and setters for each field that interact with the correct index;
>
> Here's a concrete example of a tree:
> ```
>(type Node Array)
>
>(def make_node (val : Num) : Node
>    (let ((node (array 3)))
>        (set node 0 val)
>        (set node 1 (null Node))
>        (set node 2 (null Node))
>        node))
>
>(def val (node : Node) : Num
>    (index node 0))
>(def left (node : Node) : Node
>    (index node 1))
>(def right (node : Node) : Node
>    (index node 2))
>
>(def set_left(parent : Node child : Node) : Node
>    (set parent 1 child))
>...
>```

The definition of your language’s AST, highlighting new expressions and definitions beyond Diamondback. Graded on clarity and completeness, and if the abstract syntax is an accurate representation of the concrete syntax.

```
type prim1 =
  ...
  | IsNull (* binary ends with 100 *)

type typ =
  ...
  | TArray
  | TName of string

type expr =
  ...
  | EArray of expr
  | EIndex of expr * expr
  | ESetIndex of expr * expr * expr
  | ENull of typ

type def =
  ...
  | DType of string * typ
```

A diagram of how heap-allocated values are arranged on the heap, including any extra words like the size of an allocated value or other metadata. Graded on clarity and completeness, and if it matches the implementation of heap allocation in the compiler.

> The first 8 bytes hold the size in binary, with no tag bits. Each 8 bytes thereafter hold the value of one element of the array.
```
| n | val 0 | ... | val n - 1 |
```

The required tests:
> The programs error1-3 showcase error reporting around heap operations. There are more interesting files regarding geometric points and vector addition, binary search trees, and linked lists.

- For each of the files error1-3, show the error message and explain in which phase your compiler and/or runtime catches the error.

- For the others, include the actual output of the generated binary (in terms of stdout/stderr), the output you’d like them to have (if there’s any difference) and any notes on interesting features of that output.
> I'm not cluttering this with the test files. They're all in the input directory, and the outputs are all as expected.

A description of the thing you think is most interesting or exciting about your design and implementation in 2-3 sentences.
> Arrays can hold elements of any type, so indexing into an array does not have a known type at compile time. Some type errors are caught at compile time, but as soon as indexing into arrays enters the picture, a joker "TUnknown" starts propagating and type errors must be caught at runtime.

A description of a feature you’d like to add to your language next, with an outline of how you’d add it in 2-3 sentences.
> I'd like to add structs that can be stored directly on the stack. I would add type declarations that can take multiple types, and make let expressions lookup in an environment the required size of the type that's being instantiated.

Pick two other programming languages you know that support heap-allocated data, and describe why your language’s design is more like one than the other.
> My language supports different types in a single array, making it more like Python than Java. At the same time, using negative indexes results in an OOB exception, which makes it more like Java than Python. Both have arrays/lists stored contiguously in memory, with no pointers like linked lists, as does my implementation. I don't know how they deal with metadata, but all I store is the array's length.

A list of the resources you used to complete the assignment, including message board posts, online resources (including resources outside the course readings like Stack Overflow or blog posts with design ideas), and students or course staff discussions you had in-person. Please do collaborate and give credit to your collaborators.

> I did this one on my own. I didn't even use AI assistants for this iteration.

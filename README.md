# snake-languages
These are my implementations of the projects for UCSD's [CSE131](https://github.com/ucsd-cse131-f19/ucsd-cse131-f19.github.io/tree/master) class for the fall of 2019. You can run them by going to the respective directory, typing `make`, then `make ./output/filename.run`, and finally `./output/filename.run`. You may program files by including them in the `input/` directory with the appropriate extension. I've included sample files you can simply run.

###### PA0: Neonate
This is the simplest compiler. It takes a number and makes a binary file that puts that number in RAX, returns it to a C function, and then prints it.

##### PA1: Anaconda
This compiler implements some arithmetic integer operations and variable declarations.

#### PA2: Boa
This version has both integer and boolean types, which have an internal representation that differs on the least significant bit. It has runtime errors for wrong types and overflow, conditionals, command-line inputs, and some more operations that yield booleans (<, >, ==, isBool, isNum).

### PA3: Copperhead
Copperhead implements static type checking, loops, and variable assignment. Up to now, variables could be declared, but they were immutable.

***Highlight:*** I implemented two optional, advanced features related to type checking, which are only a part of Copperhead:
- For isNum and isBool operations, there's no runtime computation. Since the types are known at compile time, those operations are compiled to moving either true or false to RAX;
- The user inputs a command-line argument which may be a number or a boolean, and that is unknown at compile time. To use the input in the code, it must be wrapped by isNum or isBool operations. When used inside an if-conditional, the input's type if refined for each branch. This maintains the soundness of the type checker. For example,
```
; Input is a command-line argument
(if (isBool input)
  ; In this branch it is a bool, so the output might be 10 or 5, which are both numbers
  (if input 10 5)
  ; In this branch it is a number, so it is summed with 10, and the output is a number
  (+ input 10))
```

### PA4: Diamondback
Diamondback implements function declarations and the `print` operation. This leads to interesting engineering choices, such as defining a calling convention. You can read about the calling convention I adopted inside Diamondback's `readme`.

***Highlight:*** I implemented the optional challenge of not requiring type anotations on function declaration returns, instead calculating them based on the known input types. I also started the optional challenge of tail call optimizations, propagating a tail call boolean to identify tail calls. I found it tricky to update stack variables when one is needed to update the other, and eventually moved on without finishing this optimization.

### PA5: Eggeater
This was a more open-ended project. Eggeater allowed me to make a 1 dollar mistake: introducing `null` to the language. I also included type aliasing, like `typedef`. The most significant and powerful change was the addition of heap allocated memory. Eggeater allows the creation, access, and modification of arrays. This powerful feature is demonstrated by the available executable files, which include data-structures that hold points, a linked list implementation, and binary search trees. Eggeater has the optional challenge of dealing with structural equality (different arrays with identical content) and cyclic data structures, which I'm tackling on as part of PA6.

### PA6
PA6 has two options: either extend PA5 with structural equality and cycle detection for both printing and equality, or extend PA4 with optimizations. I chose both!

#### PA6.H: Heapingcobra
Heapingcobra is strictly an upgrade to Eggeater. It deals with structural equality (different arrays with the same content), including the case of cyclic data structures, which it detects and rejects. Unlike the rest of the compilers, which were mostly implemented in OCaml and were focused on compile time, these features were implemented C functions, which are called in runtime.

***Highlight:*** Heapingcobra does not eagerly throw errors. It detects cycles during printing and stops printing the cycle, but prints the rest of the structure. It can also check for structural equality in some cyclic structures, but not all.

#### PA6.O: Optimalsnake
Optimalsnake implements:
- Constant propagation: substitute constant variables for their contents (if x is always 1, replace all x's with 1, and don't read from memory)
- Constant folding: make constant operations in compile time (replace 3 + 6 with 9, or 3 > 2 with true, etc)
- Dead code elimination: don't generate code that will never be run (eliminate conditional branches and while loops that will never be taken)

***Highlight***: none of this material was covered in the recorded lectures, so I was on my own for this implementation. I built it from the ground up. Optimalsnake implements a fixed-point algorithm that keeps trying new optimization passes as long as some optimization was successful. Folding operations expose variables as constants, allowing them to propagate, and maybe eliminating some branches once their value is known. This assignment taught me a lot about what efficient code can look like for a compiled language (but not for interpreted languages).

A really cool feature is that variables can be shadowed by variables with the same name, and both are treated as constants. As long as the variable isn't set, all the work is done at compiletime.

### PA7: Garter Snake
I implemented garbage collection using semispace swapping (allocating half of the memory, copying everything that's "live" to the other half), and a debugging function that prints the contents of the heap in a friendly human readable way.

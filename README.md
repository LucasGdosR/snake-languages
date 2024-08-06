# snake-languages
These are my implementations of the projects for UCSD's [CSE131](https://github.com/ucsd-cse131-f19/ucsd-cse131-f19.github.io/tree/master) class for the fall of 2019. You can run them by going to the respective directory, typing `make`, then `make ./output/filename.run`, and finally `./output/filename.run`. You may program files by including them in the `input/` directory with the appropriate extension. I've included sample files you can simply run.

###### PA0: Neonate
This is the simplest compiler. It takes a number and makes a binary file that puts that number in RAX, returns it to a C function, and then prints it.

##### PA1: Anaconda
This compiler implements some arithmetic integer operations and variable declarations.

#### PA2: Boa
This version has both integer and boolean types, which have an internal representation that differs on the least significant bit. It has runtime errors, conditionals, command-line inputs, and some more operations that yield booleans (<, >, ==, isBool, isNum).

#### PA3: Copperhead
Copperhead implements static type checking, loops, and variable assignment. Up to now, variable could be declared, but they were immutable. ***Highlight:*** I implemented an optional optimization: for isNum and isBool operations, there's no runtime computation. Since the types are known at compile time, those operations are compiled to moving either true or false to RAX. This feature is only a part of Copperhead.

#### PA4: Diamondback
Diamondback implements function declarations and the `print` operation. This leads to interesting engineering choices, such as defining a calling convention. You can read about the calling convention I adopted inside Diamondback's `readme`. ***Highlight***: I implemented the optional challenge of not requiring type anotations on function declaration returns, instead calculating them based on the known input types.

#### PA5: Eggeater
This was a more open-ended project. Eggeater allowed me to make a 1 dollar mistake: introducing `null` to the language. I also included type aliasing, like `typedef`. The most significant and powerful change was the addition of heap allocated memory. Eggeater allows the creation, access, and modification of arrays. This powerful feature is demonstrated by the available executable files, which include data-structures that hold points, a linked list implementation, and binary search trees. Eggeater has the optional challenge of dealing with structural equality (different arrays with identical content), which I'm tackling on as part of PA6.

Also, Diamondback had an issue with stack alignment depending on the number of arguments on a function or the number of variables declared in a let-expression. Eggeater fully fixes this bug, maintaining stack alignment no matter what.

#### TODO: PA6: Heapingcobra and Optimalsnake
PA6 gives two options: implement more heap features (cycle detection in data-structures and printing them accordingly without infinite loops, and structural equality), or implementing optimizations. I'm doing both.

#### TODO: PA7: Garter Snake
Implement data definitions and garbage collection!

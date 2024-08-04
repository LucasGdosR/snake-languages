%.run: %.o
	gcc -m32 -o $@ main.c $<

%.o: %.s
	nasm -f elf32 -o $@ $<

%.s: %.int
	ocaml compiler.ml $< > $@
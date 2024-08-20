UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
  FORMAT=elf64
  NOPIE=-no-pie
  MAIN=./compilers/main
else
ifeq ($(UNAME), Darwin)
  FORMAT=macho64
  NOPIE=-Wl,-no_pie
  MAIN=./compilers/main-osx
endif
endif

PKGS=oUnit,extlib,unix,sexplib,str

BUILD=ocamlbuild -r -use-ocamlfind -pkg $(PKGS) $(OCAMLOPT)

test: runner.ml test.ml
	mkdir -p output
	$(BUILD) test.native
	mv test.native test

output/%.run: output/%.o main.c gc.c print.c
	gcc $(NOPIE) -fsanitize=address -g -mstackrealign -o $@ main.c gc.c print.c $<

output/%.o: output/%.s
	nasm -f $(FORMAT) -o $@ $<

output/%.s: input/%.boa
	mkdir -p output
	$(MAIN) $< > $@

clean:
	rm -rf output/*.o output/*.s output/*.dSYM output/*.run *.log
	rm -rf _build/

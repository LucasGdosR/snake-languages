open Printf

(* A very sophisticated compiler - insert the given integer into the mov
instruction at the correct place *)
let compile (program : int) : string =
  sprintf "
section .text
global our_code_starts_here
our_code_starts_here:
  mov eax, %d
  ret\n" program;;

(* Some OCaml boilerplate for reading files and command-line arguments *)
let () =
  let input_file = (open_in (Sys.argv.(1))) in
  let input_program = int_of_string (input_line input_file) in
  let program = (compile input_program) in
  printf "%s\n" program;;
# pa4

Writeup here:
https://github.com/ucsd-cse131-f19/ucsd-cse131-f19.github.io/blob/master/pa4/pa4.pdf

> The following example programs are included in the `input` and `output` directories: deepstack, fibonacci, isprime, remainder.
>
> You can make new binary executables by creating a file in the input directory and typing `make output/<filename>.run` to the command-line while inside the diamondback directory. You can make assembly files with the `.s` file extension instead of `.run`. You can execute by typing `output/<filename>.run <input>`. Input must be an integer.

1. A description of your calling convention in general terms:

(a) What does the caller do before and after the call?
> In compile.ml, in the compile_expr function, there's a case for a function call, which is EApp. First, the caller checks if it needs to add padding to the stack to remain 16 byte aligned. Then, it stores all arguments to the function in the stack. The first argument is stored at the bottom of the stack, and the last is at the top. When all the arguments are on the stack, RSP is modified (sub) to point to the last argument, the top of the stack. The function is called, which pushes the return address on top of the last argument. When the function returns and the return address is popped, RSP is adjusted (add) to just below the arguments, effectively freeing the stack. A similar approach is taken for `print`.

(b) What is the callee responsible for?
> All the callee has to do is access its arguments correctly from the stack. It should be aware of its environment, which is done at compile time.

(c) Are there improvements you can imagine making in the future?
> Using registers instead of relying solely on the stack. Using more push and pop instructions instead of adding and subbing RSP directly as often.

Use snippets of OCaml code from your compiler to illustrate key features.
```
(* Getting bodies to accept multiple expressions that aren't lists wrapped in parentheses: *)
and parse_body (body : Sexp.t list) =
  match body with
  | [] -> []
  | [e] -> [parse e]
  | e :: rest -> (parse e)::(parse_body rest)

and parse_def sexp =
  match sexp with
  | List(Atom("def") :: Atom(f) :: List(args) :: Atom(":") :: Atom(return_typ) :: body) ->
    begin match validate_id_opt f, parse_typ return_typ, body with
      | None, _, _ -> failwith ("Invalid function name " ^ f)
      | _, _, [] -> failwith "Invalid: Empty body"
      | _, parsed_t, _ -> DFun(f, parse_arg args, parsed_t, parse_body body)
    end
  | List(Atom("def") :: Atom(f) :: List(args) :: body) ->
    begin match validate_id_opt f, body with
      | None, _ -> failwith ("Invalid function name " ^ f)
      | _, [] -> failwith "Invalid: Empty body"
      | _, _ -> DFunNoRet(f, parse_arg args, parse_body body)
    end
  | _ -> failwith "Invalid definition."

(* The EApp case I mentioned in compile_expr: *)
| EApp(f, args) -> 
    let rec store_args_in_stack args si = 
      match args with
      | [] -> []
      | arg :: rest -> (compile_expr arg si env def_env) @ [IMov(stackloc si, Reg(RAX))] @ store_args_in_stack rest (si + 1)
    in 
    let num_args = List.length args in
    let rsp_offset = si + num_args - 1 in
    let align_adjust = if (rsp_offset + 1) mod 2 = 0 then 0 else 1 in
    let args_instructions = store_args_in_stack args (si + align_adjust) in
    let rsp_adjust = [ISub(Reg(RSP), Const(8 * (rsp_offset + align_adjust)))] in
    let restore_rsp = [IAdd(Reg(RSP), Const(8 * (rsp_offset + align_adjust)))] in
    args_instructions @ rsp_adjust
    @ [ICall(f ^ "_func")] @ restore_rsp

(* Building the argument environment in for the definition during compile time: *)
compile_def def def_env =
  let name, args, body = match def with
    | DFun(f_name, args, _, body) -> f_name, args, body
    | DFunNoRet(f_name, args, body) -> f_name, args, body in
  let rec build_args_env args si = match args with
    | [] -> []
    | (arg, _) :: rest -> (arg, si) :: build_args_env rest (si + 1)
  in
  let args_length = List.length args in
  let env = build_args_env args (-args_length) in
  let compiled_body = compile_body body 1 env def_env in
  [ILabel(name ^ "_func")] @ compiled_body @ [IRet]
```

2. Pick three example programs that use functions and are interesting in different ways (you can use the required tests if you like), and use them to describe your calling convention:

(a) Show their source, generated assembly, and output (you can summarize the generated code if it’s quite long)
> Available in the "input" and "output" directories, respectively.

(b) Highlight the parts of the generated assembly that make the example interesting, distinct, and/or especially challenging to compile
> Having a let expression inside a function initially messed with my stack. Using push or pop instructions for let expressions would mess with the function's environment, which holds an offset from the stack pointer to the arguments.

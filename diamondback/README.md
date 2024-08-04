# pa4
Starter code for pa4

Writeup here:
https://ucsd-cse131-f19.github.io/pa4/

## Describing Your Calling Convention
As you implement Diamondback, you will need to make a number of decisions, not least of which is the calling convention you choose, and decisions you make around compiling application expressions and definitions. Along with your code, you will write a desgin document as a separate PDF describing how your calling convention works.

There are no restrictions on the calling convention you choose. You could implement the x86-64 convention for your functions, the version we discussed in class generalized to arbitrary lists of values, or something of your own design. Different choices will require different implementation strategies, different stack management requirements, and produce code that is “interesting” to debug in various ways.

In your design document, you should make sure to cover (in whatever order makes sense) the items below. This report will be worth 30% of your assignment grade.
1. A description of your calling convention in general terms:

(a) What does the caller do before and after the call?
> In compile.ml, in the compile_expr function, there's a case for a function call, which is EApp. First, the caller stores all arguments to the function in the stack. The first argument is stored at the bottom of the stack, and the last is at the top. When all the arguments are on the stack, RSP is modified (sub) to point to the last argument, the top of the stack. The function is called, which pushes the return address on top of the last argument. When the function returns and the return address is popped, RSP is adjusted (add) to just below the arguments, effectively freeing the stack.

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
  | _ -> failwith "Invalid definition."

(* The EApp case I mentioned in compile_expr: *)
| EApp(f, args) -> 
    let rec store_args_in_stack args si = 
      match args with
      | [] -> []
      | arg :: rest -> (compile_expr arg si env def_env) @ [IMov(stackloc si, Reg(RAX))] @ store_args_in_stack rest (si + 1)
    in 
    let rsp_offset = si + List.length args - 1 in
    let args_instructions = store_args_in_stack args si in
    let rsp_adjust = [ISub(Reg(RSP), Const(8 * (rsp_offset)))] in
    let restore_rsp = [IAdd(Reg(RSP), Const(8 * (rsp_offset)))] in
    args_instructions @ rsp_adjust
    @ [ICall(f ^ "_func")] @ restore_rsp

(* Building the argument environment in for the definition during compile time: *)
compile_def (DFun(name, args, _, body)) def_env =
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

Still write this even if you don’t have everything working! In that case, in part 2, pick at least one example that doesn’t work, and note both its expected output and its actual behavior with your compiler.

Submit this part of the assignment as a PDF to pa4-written.

Advice on writing: Whenever you write, be thoughtful about your expected audience, and most importantly choose at least one specific audience you are writing for.5 For this assignment, imagine that Diamondback is a custom language that your team maintains. You are writing this design document to help with the onboarding process for people joining your team. They are programmers who know generally how compilers work and how x86-64 works, but not how Diamondback has made its choices internally. They will be curious how things work, why decisions were made the way they were, and what upcoming work on the compiler might look like.
open Printf
open Expr
open Asm

let rec find ls x =
  match ls with
  | [] -> None
  | (y,v)::rest ->
    if y = x then Some(v) else find rest x

let stackloc si = RegOffset(-8 * si, RSP)

let rec compile_expr (e : expr) (si : int) (env : (string * int) list) : instruction list =
  match e with
  | EPrim1(op, e) -> compile_prim1 op e si env
  | EPrim2(op, e1, e2) -> compile_prim2 op e1 e2 si env
  | ENumber(i) -> [IMov(Reg(RAX), Const(i))]
  | EId(name) -> 
      (match find env name with
      | None -> failwith "Unbound variable identifier"
      | Some(i) -> [IMov(Reg(RAX), stackloc i)]
      )
  | ELet(bindings, body) ->
    let rec compile_bindings binds si env =
      match binds with
      | [] -> ([], env, si)
      | (name, expr)::rest ->
          let compiled_expr = compile_expr expr si env in
          let env' = (name, si)::env in
          let si' = si + 1 in
          let (rest_instructions, final_env, final_si) = compile_bindings rest si' env' in
          (compiled_expr @ [IMov(stackloc si, Reg(RAX))] @ rest_instructions, final_env, final_si)
      in
      let (bindings_instructions, extended_env, new_si) = compile_bindings bindings si env in
      let body_instructions = compile_expr body new_si extended_env in
      bindings_instructions @ body_instructions

and compile_prim1 op e si env =
  let compiled_e = compile_expr e si env in
  match op with
  | Add1 -> compiled_e @ [IAdd(Reg(RAX), Const(1))]
  | Sub1 -> compiled_e @ [ISub(Reg(RAX), Const(1))]
  
and compile_prim2 op e1 e2 si env =
  let e1is = compile_expr e1 si env in
  let e2is = compile_expr e2 (si + 1) env in
  let op_is = match op with
  | Plus -> [IAdd(Reg(RAX), stackloc (si + 1))]
  | Minus -> [ISub(Reg(RAX), stackloc (si + 1))]
  | Times -> [IMul(Reg(RAX), stackloc (si + 1))]
  in e1is @ [IMov(stackloc si, Reg(RAX))] @ e2is
  @ [IMov(stackloc (si + 1), Reg(RAX))]
  @ [IMov(Reg(RAX), stackloc si)] @ op_is

let compile_to_string prog =
  let prelude =
    "section .text\n" ^
    "global our_code_starts_here\n" ^
    "our_code_starts_here:" in
  let compiled = (compile_expr prog 1 []) in
  let as_assembly_string = (to_asm (compiled @ [IRet])) in
  sprintf "%s%s\n" prelude as_assembly_string


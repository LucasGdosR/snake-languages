(* Can I replace most IMov(stacklock si, Reg(RAX)) with IPush(Reg(RAX))? *)

open Printf
open Expr
open Asm

let non_number_err = "internal_error_non_number"
let non_boolean_err = "internal_error_non_boolean"
let overflow_err = "internal_error_overflow"
let assert_rax_is_num = [IMov(Reg(RBX), Const(1)); IAnd(Reg(RBX), Reg(RAX)); ICmp(Reg(RBX), Const(0)); IJe(non_number_err)]

let rec find ls x =
  match ls with
  | [] -> None
  | (y,v)::rest ->
    if y = x then Some(v) else find rest x

let stackloc si = RegOffset(-8 * si, RSP)

let true_const  = HexConst(0x0000000000000002L)
let false_const = HexConst(0x0000000000000000L)
       
let rec well_formed_e (e : expr) (env : (string * int) list) : string list =
  match e with
  | ENumber(_)
  | EBool(_) -> []
  | EIf(e1, e2, e3) -> (well_formed_e e1 env) @ (well_formed_e e2 env) @ (well_formed_e e3 env)
  | EPrim1(_, e) -> well_formed_e e env
  | EPrim2(_, e1, e2) -> (well_formed_e e1 env) @ (well_formed_e e2 env)
  | EId(id) -> 
    (match find env id with
    | Some(_) -> []
    | None -> ["Variable identifier " ^ id ^ " unbound"]
    )
  | ELet(bindings, body) -> 
    let rec check_bindings bs seen_ids  =
      (match bs with
      | [] ->
        let new_env = List.fold_left (fun acc (name, _) -> (name, 0) :: acc) env bindings in
        well_formed_e body new_env
      | (id, e)::rest ->
        if List.mem id seen_ids then
          ["Multiple bindings for variable identifier " ^ id]
          @ well_formed_e e env
          @ check_bindings rest seen_ids
        else
          well_formed_e e env
          @ check_bindings rest (id::seen_ids)
      ) in
    check_bindings bindings []

let check (e : expr) : string list =
  match well_formed_e e [("input", -1)] with
  | [] -> []
  | errs -> failwith (String.concat "\n" errs)

let rec compile_expr (e : expr) (si : int) (env : (string * int) list) : instruction list =
  match e with
  | EPrim1(op, e) -> compile_prim1 op e si env
  | EPrim2(op, e1, e2) -> compile_prim2 op e1 e2 si env
  | ENumber(i) -> [IMov(Reg(RAX), Const64(Int64.add (Int64.mul (Int64.of_int i) (Int64.of_int 2)) Int64.one))]
  | EBool(b) -> [IMov(Reg(RAX), if b then true_const else false_const)]
  | EId(name) -> 
    (match find env name with
    | None -> failwith "Unbound variable identifier"
    | Some(i) -> [IMov(Reg(RAX), stackloc i)]
    )
  | EIf(predicate, consequent, alternative) ->
      let then_branch = gen_temp "then" in
      let else_branch = gen_temp "else" in
      let end_branch = gen_temp "end" in
      (* Branch to true, or false, or call error *)
      (compile_expr predicate si env)
      @ [ICmp(Reg(RAX), true_const); IJe(then_branch);
      ICmp(Reg(RAX), false_const); IJe(else_branch);
      ICall(non_boolean_err);
      (* True branch *)
      ILabel(then_branch)] @ (compile_expr consequent si env) @ [IJmp(end_branch);
      (* False branch *)
      ILabel(else_branch)] @ (compile_expr alternative si env)
      (* Finally *)
      @ [ILabel(end_branch)]
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
    (* Assert it's a number. Add/sub 2, because the first bit is a type flag. *)
    | Add1 -> compiled_e @ assert_rax_is_num @ [IAdd(Reg(RAX), Const(2))]
    | Sub1 -> compiled_e @ assert_rax_is_num @ [ISub(Reg(RAX), Const(2))]
    (* The first bit is a number flag. When it is zero, the second bit is a true/false flag. *)
    | IsNum -> compiled_e @ [IAnd(Reg(RAX), Const(1)); IShl(Reg(RAX), Const(1))]
    | IsBool -> compiled_e @ [IXor(Reg(RAX), Const(1)); IAnd(Reg(RAX), Const(1)); IShl(Reg(RAX), Const(1))]

  (* Type errors: (x and y) (cmp) (je): only works if x and y are numbers *)
and compile_prim2 op e1 e2 si env =
  let e1is = compile_expr e1 si env in
  let e2is = compile_expr e2 (si + 1) env in

  (* Eval expressions, assert they're numbers, store them, convert them to numbers for op. *)
  let set_up = match op with
    | Equal -> e1is @ [IMov(stackloc si, Reg(RAX))]
        @ e2is @ [IMov(stackloc (si + 1), Reg(RAX));
        IMov(Reg(RAX), stackloc si); IMov(Reg(RBX), stackloc (si + 1))]
    | o -> e1is @ assert_rax_is_num @ [IMov(stackloc si, Reg(RAX))]
        @ e2is @ assert_rax_is_num @ [IMov(stackloc (si + 1), Reg(RAX));
        IMov(Reg(RAX), stackloc si); IMov(Reg(RBX), stackloc (si + 1))]
        @ (match o with
          | Less
          | Greater -> []
          | _ -> [ISar(Reg(RAX), Const(1)); ISar(Reg(RBX), Const(1))]
          )
    in

  (* Operate, check for overflow, shift left, check for overflow, restore tag *)
  let assert_no_overflow_and_binary_to_boa =
    [IJo(overflow_err); IShl(Reg(RAX), Const(1)); IJo(overflow_err); IAdd(Reg(RAX), Const(1))] in
  let op_is = match op with
    | Plus -> [IAdd(Reg(RAX), Reg(RBX))] @ assert_no_overflow_and_binary_to_boa
    | Minus -> [ISub(Reg(RAX), Reg(RBX))] @ assert_no_overflow_and_binary_to_boa
    | Times -> [IMul(Reg(RAX), Reg(RBX))] @ assert_no_overflow_and_binary_to_boa
    | _ -> (
      let true_label = gen_temp ("true") in
      let end_label = gen_temp ("end") in
      let compare = [ICmp(Reg(RAX), Reg(RBX))] in
      let set_bool_const =
      [IMov(Reg(RAX), false_const); IJmp(end_label);
      ILabel(true_label); IMov(Reg(RAX), true_const); ILabel(end_label)] in 
      match op with
      | Less -> compare @ [IJl(true_label)] @ set_bool_const
      | Greater -> compare @ [IJg(true_label)] @ set_bool_const
      | Equal -> compare @ [IJe(true_label)] @ set_bool_const
      | _ -> failwith "Impossible error."
      )
  in set_up @ op_is

let compile_to_string prog =
  let _ = check prog in
  let prelude = "  section .text\n" ^
                "  extern error\n" ^
                "  global our_code_starts_here\n" ^
                "our_code_starts_here:\n" ^
                "  mov [rsp - 8], rdi\n" in
  let postlude = [IRet] in
  let error_labels = [
    (* Op error label *)
    ILabel(non_number_err);
    (* Set up RDI with error code *)
    IMov(Reg(RDI), Const(1));
    (* Align stack *)
    IPush(Const(0));
    (* Call error *)
    ICall("error");
    
    ILabel(non_boolean_err);
    IMov(Reg(RDI), Const(2));
    IPush(Const(0));
    ICall("error");
    
    ILabel(overflow_err);
    IMov(Reg(RDI), Const(3));
    IPush(Const(0));
    ICall("error")
  ] in
  let compiled = (compile_expr prog 2 [("input", 1)]) in
  let as_assembly_string = (to_asm (compiled @ postlude @ error_labels)) in
  sprintf "%s%s\n" prelude as_assembly_string

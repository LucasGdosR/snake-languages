open Printf
open Expr
open Asm
open Typecheck
open Optimize

let overflow_err = "internal_error_overflow"

let rec find_def p x =
  match p with
  | [] -> None
  | (DFun(name, _, _, _) as d)::rest ->
    if name = x then Some(d) else find_def rest x
  
let stackloc si = RegOffset(-8 * si, RSP)

let true_const  = HexConst(0x0000000000000002L)
let false_const = HexConst(0x0000000000000000L)

(* I decided that the environment here does not care about the variable's address, only if it is present. *)
let rec well_formed_e (e : expr) (env : string list) : string list =
  match e with
  | ENumber(_)
  | EBool(_) -> []
  | EIf(e1, e2, e3) -> (well_formed_e e1 env) @ (well_formed_e e2 env) @ (well_formed_e e3 env)
  | EPrim1(_, e) -> well_formed_e e env
  | EPrim2(_, e1, e2) -> (well_formed_e e1 env) @ (well_formed_e e2 env)
  | EId(id) -> if List.mem id env  then [] else ["Variable identifier " ^ id ^ " unbound"]
  | ESet(id, e) -> if List.mem id env then well_formed_e e env else ["Variable identifier " ^ id ^ " unbound"] @ well_formed_e e env
  | ELet(bindings, body) -> 
    let rec check_bindings bs seen_ids =
      (match bs with
      | [] ->
        let new_env = List.fold_left (fun acc (name, _) -> name :: acc) env bindings in
        check_body body new_env
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
  | EWhile(cond, body) -> well_formed_e cond env @ check_body body env
  | EApp(_, args) -> List.fold_left (fun acc arg -> acc @ well_formed_e arg env) [] args

and check_body (body : expr list) (env : string list) : string list =
  match body with
  | []-> []
  | e::rest -> (well_formed_e e env) @ (check_body rest env)

and well_formed_def (DFun(f_name, args, _, body)) =
  let rec unique_arguments checked to_check =
    match to_check with
    | [] -> check_body body checked
    | (arg_name, _) :: rest -> if List.mem arg_name checked
      then ["Multiple bindings in function " ^ f_name] @ unique_arguments checked rest
      else unique_arguments (arg_name :: checked) rest in
  unique_arguments [] args

let well_formed_prog (defs, main) =
  let rec check_multiple_functions (to_check : def list) (checked : string list) = match to_check with
  | [] -> []
  | DFun(name, _, _, _) :: rest ->
    if List.mem name checked then ["Multiple functions named " ^ name] @ check_multiple_functions rest checked
      else check_multiple_functions rest (name :: checked)
  in
  (check_multiple_functions defs []) @ (List.concat (List.map well_formed_def defs)) @ (well_formed_e main ["input"])

let check p : string list =
  match well_formed_prog p with
  | [] -> []
  | errs -> failwith (String.concat "\n" errs)

let rec compile_expr (e : expr) (si : int) (env : (string * int) list) def_env
  : instruction list =
  match e with
  | EPrim1(op, e) -> compile_prim1 op e si env def_env
  | EPrim2(op, e1, e2) -> compile_prim2 op e1 e2 si env def_env
  | ENumber(i) -> [IMov(Reg(RAX), Const64(Int64.add (Int64.mul (Int64.of_int i) (Int64.of_int 2)) Int64.one))]
  | EBool(b) -> [IMov(Reg(RAX), if b then true_const else false_const)]
  | EId(name) -> begin match find env name with
      | None -> failwith "Unbound variable identifier"
      | Some(i) -> [IMov(Reg(RAX), stackloc i)]
    end
  | EIf(predicate, consequent, alternative) ->
      let else_branch = gen_temp "else" in
      let end_branch = gen_temp "end" in
      (compile_expr predicate si env def_env) @ [ICmp(Reg(RAX), false_const); IJe(else_branch)]
      @ (compile_expr consequent si env def_env) @ [IJmp(end_branch);
      ILabel(else_branch)] @ (compile_expr alternative si env def_env)
      @ [ILabel(end_branch)]
  | ELet(bindings, body) -> 
      let rec compile_bindings binds si env def_env =
        match binds with
        | [] -> ([], env, si)
        | (name, expr)::rest ->
            let compiled_expr = compile_expr expr si env def_env in
            let env' = (name, si)::env in
            let si' = si + 1 in
            let (rest_instructions, final_env, final_si) = compile_bindings rest si' env' def_env in
            (compiled_expr @ [IMov(stackloc si, Reg(RAX))] @ rest_instructions, final_env, final_si)
      in
      let (bindings_instructions, extended_env, new_si) = compile_bindings bindings si env def_env in
      let body_instructions = compile_body body new_si extended_env def_env in
      bindings_instructions @ body_instructions
  | ESet(id, e) -> let stack_offset = find env id in
      begin match stack_offset with
        | Some(i) -> compile_expr e si env def_env @ [IMov(stackloc i, Reg(RAX))]
        | None -> failwith "Unbound variable"
      end
  | EWhile(cond, body) ->
    let while_label = gen_temp "while_test" in
    let end_label = gen_temp "end" in
    [ILabel(while_label)] @ compile_expr cond si env def_env @ [ICmp(Reg(RAX), true_const); IJne(end_label)]
    @ compile_body body si env def_env @ [IJmp(while_label); ILabel(end_label)]
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
    
and compile_prim1 op e si env def_env =
  let compiled_e = compile_expr e si env def_env in
  match op with
    | Add1 -> compiled_e @ [IAdd(Reg(RAX), Const(2)); IJo(overflow_err)]
    | Sub1 -> compiled_e @ [ISub(Reg(RAX), Const(2)); IJo(overflow_err)]
    | IsNum -> compiled_e @ [IAnd(Reg(RAX), Const(1)); IShl(Reg(RAX), Const(1))]
    | IsBool -> compiled_e @ [IXor(Reg(RAX), Const(1)); IAnd(Reg(RAX), Const(1)); IShl(Reg(RAX), Const(1))]
    | Print -> 
      let stack_adjust = Const(if (si + 1) mod 2 = 0 then 8 * (si + 1) else 8 * (si + 2)) in
      compiled_e @ [IMov(Reg(RDI), Reg(RAX)); ISub(Reg(RSP), stack_adjust); ICall("print"); IAdd(Reg(RSP), stack_adjust)]
    

and compile_prim2 op e1 e2 si env def_env =
  let e1is = compile_expr e1 si env def_env in
  let e2is = compile_expr e2 (si + 1) env def_env in
  let boa_to_binary = [ISar(Reg(RAX), Const(1)); ISar(Reg(RBX), Const(1))] in
  let assert_no_overflow_and_binary_to_boa =
    [IJo(overflow_err); IShl(Reg(RAX), Const(1)); IJo(overflow_err); IAdd(Reg(RAX), Const(1))]
  in
  (* Eval expressions, store them, convert numbers to binary. *)
  e1is @ [IMov(stackloc si, Reg(RAX))]
  @ e2is @ [IMov(stackloc (si + 1), Reg(RAX));
  IMov(Reg(RAX), stackloc si); IMov(Reg(RBX), stackloc (si + 1))]
  @ match op with
    | Plus -> boa_to_binary @ [IAdd(Reg(RAX), Reg(RBX))] @ assert_no_overflow_and_binary_to_boa
    | Minus -> boa_to_binary @ [ISub(Reg(RAX), Reg(RBX))] @ assert_no_overflow_and_binary_to_boa
    | Times -> boa_to_binary @ [IMul(Reg(RAX), Reg(RBX))] @ assert_no_overflow_and_binary_to_boa
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

and compile_body body si env def_env =
  match body with
  | e::rest -> (compile_expr e si env def_env) @ (compile_body rest si env def_env)
  | [] -> []

and compile_def (DFun(name, args, _, body)) def_env =
  let rec build_args_env args si = match args with
    | [] -> []
    | (arg, _) :: rest -> (arg, si) :: build_args_env rest (si + 1)
  in
  let args_length = List.length args in
  let env = build_args_env args (-args_length) in
  let compiled_body = compile_body body 1 env def_env in
  [ILabel(name ^ "_func")] @ compiled_body @ [IRet]

let compile_to_string ((defs, _) as prog : Expr.prog) =
  let _ = check prog in
  let def_env = build_def_env defs in
  let _ = tc_p prog def_env in
  let (defs, main) = optimize_prog prog in
  let compiled_defs = List.concat (List.map (fun d -> compile_def d defs) defs) in
  let compiled_main = compile_expr main 2 [("input", 1)] defs in
  let prelude = "  section .text\n" ^
                "  extern error\n" ^
                "  extern print\n" ^
                "  global our_code_starts_here\n" in
  let kickoff = "our_code_starts_here:\n" ^
                "push rbx\n" ^
                "  mov [rsp - 8], rdi\n" ^ 
                to_asm compiled_main ^
                "\n  pop rbx\nret\n" in
  let postlude = [ILabel(overflow_err); IMov(Reg(RDI), Const(1)); IPush(Const(0)); ICall("error")] in
  let as_assembly_string = (to_asm (compiled_defs @ postlude)) in
  sprintf "%s%s\n%s\n" prelude as_assembly_string kickoff

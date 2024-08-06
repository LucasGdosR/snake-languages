open Printf
open Expr
open Asm

let overflow_err = "internal_error_overflow"

let rec find ls x =
  match ls with
  | [] -> None
  | (y,v)::rest ->
    if y = x then Some(v) else find rest x

let stackloc si = RegOffset(-8 * si, RSP)

let true_const  = HexConst(0x0000000000000002L)
let false_const = HexConst(0x0000000000000000L)

type typ =
  | TNumber
  | TBoolean
  | TNumOrBool

let rec tc_e (e : expr) (env : (string * typ) list) : typ =
  match e with
  | ENumber(_) -> TNumber
  | EBool(_) -> TBoolean
  | EId(x) -> begin match find env x with
      | Some(typ) -> typ
      | None -> failwith "Unbound id" (* Never reached *)
    end
  | EIf(EPrim1(IsBool, EId(x)), cons, alt) -> 
      let cons_typ = tc_e cons ((x, TBoolean) :: env) in
      let alt_typ = tc_e alt ((x, TNumber) :: env) in
      if cons_typ = alt_typ
        then cons_typ
      else failwith "Type mismatch"
  | EIf(EPrim1(IsNum , EId(x)), cons, alt) -> 
      let cons_typ = tc_e cons ((x, TNumber) :: env) in
      let alt_typ = tc_e alt ((x, TBoolean) :: env) in
      if cons_typ = alt_typ
        then cons_typ
      else failwith "Type mismatch"
  | EIf(cond, cons, alt) -> begin match (tc_e cond env, tc_e cons env, tc_e alt env) with
      | TBoolean, cons_typ, alt_typ when cons_typ = alt_typ -> cons_typ
      | _ -> failwith "Type mismatch"
    end
  | ESet(var, value) ->
    let set_typ = tc_e value env in
    begin match find env var with
      | Some(typ) when typ = set_typ -> typ
      | Some(_) -> failwith "Type mismatch"
      | None -> failwith "Unbound id" (* Never reached *)
    end
  | EPrim1(op, e) -> begin match op with
      | Add1 | Sub1 -> begin match tc_e e env with
          | TNumber -> TNumber
          | _ -> failwith "Type mismatch"
        end
      | IsNum | IsBool -> TBoolean
    end
  | EPrim2(op, e1, e2) -> begin match op, tc_e e1 env, tc_e e2 env with
      | Equal, _, _ -> TBoolean
      | _, (TBoolean | TNumOrBool), _ | _, _, (TBoolean | TNumOrBool) -> failwith "Type mismatch"
      | Plus, _, _ | Minus, _, _ | Times, _, _ -> TNumber
      | Greater, _, _ | Less, _, _ -> TBoolean
    end
  | ELet(bindings, body) ->
    let rec tc_body (body : expr list) (env : (string * typ) list) =
      match body with
        | e::rest when rest = [] -> tc_e e env
        | e::rest -> let _ = tc_e e env in
          tc_body rest env
        | [] -> failwith "Empty body has no type." (* Never reached *)
    in
  
    let rec tc_bindings (binding : (string * expr) list) (body : expr list) (env : (string * typ) list) = begin match binding with
        | [] -> tc_body body env
        | (x, value)::rest -> let x_typ = tc_e value env in
          tc_bindings rest body ((x, x_typ)::env)
      end in
    tc_bindings bindings body env
  | EWhile(cond, body) ->
    let rec tc_body (body : expr list) (env : (string * typ) list) =
      match body with
        | e::rest -> let _ = tc_e e env in
          tc_body rest env
        | [] -> TBoolean
    in
  
    match tc_e cond env with
      | TBoolean -> tc_body body env
      | _ -> failwith "Type mismatch"

let rec well_formed_e (e : expr) (env : (string * int) list) : string list =
  match e with
  | ENumber(_)
  | EBool(_) -> []
  | EIf(e1, e2, e3) -> (well_formed_e e1 env) @ (well_formed_e e2 env) @ (well_formed_e e3 env)
  | EPrim1(_, e) -> well_formed_e e env
  | EPrim2(_, e1, e2) -> (well_formed_e e1 env) @ (well_formed_e e2 env)
  | EId(id) -> begin match find env id with
      | Some(_) -> []
      | None -> ["Variable identifier " ^ id ^ " unbound"]
    end
  | ESet(id, e) -> begin match find env id with
      | Some(_) -> well_formed_e e env
      | None -> ["Variable identifier " ^ id ^ " unbound"] @ well_formed_e e env
    end
  | ELet(bindings, body) -> 
    let rec check_bindings bs seen_ids  =
      (match bs with
      | [] ->
        let new_env = List.fold_left (fun acc (name, _) -> (name, 0) :: acc) env bindings in
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

and check_body (body : expr list) (env : (string * int) list) : string list =
  match body with
  | []-> []
  | e::rest -> (well_formed_e e env) @ (check_body rest env)
  

let check (e : expr) : string list =
  match well_formed_e e [("input", -1)] with
  | [] -> []
  | errs -> failwith (String.concat "\n" errs)

let rec compile_expr (e : expr) (si : int) (tc_env : (string * typ) list) (env : (string * int) list) : instruction list =
  match e with
  | EPrim1(op, e) -> compile_prim1 op e si tc_env env
  | EPrim2(op, e1, e2) -> compile_prim2 op e1 e2 si tc_env env
  | ENumber(i) -> [IMov(Reg(RAX), Const64(Int64.add (Int64.mul (Int64.of_int i) (Int64.of_int 2)) Int64.one))]
  | EBool(b) -> [IMov(Reg(RAX), if b then true_const else false_const)]
  | EId(name) -> begin match find env name with
      | None -> failwith "Unbound variable identifier"
      | Some(i) -> [IMov(Reg(RAX), stackloc i)]
    end
  | EIf(predicate, consequent, alternative) ->
      let else_branch = gen_temp "else" in
      let end_branch = gen_temp "end" in
      (compile_expr predicate si tc_env env) @ [ICmp(Reg(RAX), false_const); IJe(else_branch)]
      @ (compile_expr consequent si tc_env env) @ [IJmp(end_branch);
      ILabel(else_branch)] @ (compile_expr alternative si tc_env env)
      @ [ILabel(end_branch)]
  | ELet(bindings, body) -> 
      let rec compile_bindings binds si tc_env env =
        match binds with
        | [] -> ([], tc_env, env, si)
        | (name, expr)::rest ->
            let compiled_expr = compile_expr expr si tc_env env in
            let typ = tc_e expr tc_env in
            let env' = (name, si)::env in
            let tc_env' = (name, typ)::tc_env in
            let si' = si + 1 in
            let (rest_instructions, final_tc_env, final_env, final_si) = compile_bindings rest si' tc_env' env' in
            (compiled_expr @ [IMov(stackloc si, Reg(RAX))] @ rest_instructions, final_tc_env, final_env, final_si)
      in
      let (bindings_instructions, extended_tc_env, extended_env, new_si) = compile_bindings bindings si tc_env env in
      let body_instructions = compile_body body new_si extended_tc_env extended_env in
      bindings_instructions @ body_instructions
  | ESet(id, e) -> let stack_offset = find env id in
      begin match stack_offset with
        | Some(i) -> compile_expr e si tc_env env @ [IMov(stackloc i, Reg(RAX))]
        | None -> failwith "Unbound variable"
      end
  | EWhile(cond, body) ->
    let while_label = gen_temp "while_test" in
    let end_label = gen_temp "end" in
    [ILabel(while_label)] @ compile_expr cond si tc_env env @ [ICmp(Reg(RAX), true_const); IJne(end_label)]
    @ compile_body body si tc_env env @ [IJmp(while_label); ILabel(end_label)]

and compile_prim1 op e si tc_env env =
  let compiled_e = compile_expr e si tc_env env in
  match op with
  | IsNum -> let cond_typ = tc_e e tc_env in
    if cond_typ = TNumOrBool
      then compiled_e @ [IAnd(Reg(RAX), Const(1)); IShl(Reg(RAX), Const(1))]
    else
    [IMov(Reg(RAX), if tc_e e tc_env = TNumber then true_const else false_const)]
  | IsBool -> let cond_typ = tc_e e tc_env in
    if cond_typ = TNumOrBool
      then compiled_e @ [IXor(Reg(RAX), Const(1)); IAnd(Reg(RAX), Const(1)); IShl(Reg(RAX), Const(1))]
    else
    [IMov(Reg(RAX), if tc_e e tc_env = TBoolean then true_const else false_const)]
  | Add1 -> compiled_e @ [IAdd(Reg(RAX), Const(2)); IJo(overflow_err)]
  | Sub1 -> compiled_e @ [ISub(Reg(RAX), Const(2)); IJo(overflow_err)]

and compile_prim2 op e1 e2 si tc_env env =
  let e1is = compile_expr e1 si tc_env env in
  let e2is = compile_expr e2 (si + 1) tc_env env in
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

and compile_body body si tc_env env =
  match body with
  | e::rest -> (compile_expr e si tc_env env) @ (compile_body rest si tc_env env)
  | [] -> []

let compile_to_string prog =
  let _ = check prog in
  let _ = tc_e prog [("input", TNumOrBool)] in
  let prelude = "  section .text\n" ^
                "  extern error\n" ^
                "  global our_code_starts_here\n" ^
                "our_code_starts_here:\n" ^
                "  mov [rsp - 8], rdi\n" in
  let postlude = [IRet]
    @ [ILabel(overflow_err); IMov(Reg(RDI), Const(1)); IPush(Const(0)); ICall("error")] in
  let compiled = (compile_expr prog 2 [("input", TNumOrBool)] [("input", 1)]) in
  let as_assembly_string = (to_asm (compiled @ postlude)) in
  sprintf "%s%s\n" prelude as_assembly_string

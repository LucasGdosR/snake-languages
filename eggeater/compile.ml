open Printf
open Expr
open Asm
open Typecheck

let overflow_err = "internal_error_overflow"
let bounds_err = "internal_error_out_of_bounds"
let negative_arr_err = "internal_error_negative_array"
let not_a_pointer_err = "internal_error_not_a_pointer"

let rec find ls x =
  match ls with
  | [] -> None
  | (y,v)::rest ->
    if y = x then Some(v) else find rest x

let rec find_def p x =
  match p with
  | [] -> None
  | (DFun(name, _, _, _) as d)::rest ->
    if name = x then Some(d) else find_def rest x
  | (DType(name, _) as t)::rest ->
    if name = x then Some(t) else find_def rest x

let stackloc si = RegOffset(-8 * si, RSP)
let heaploc si = RegOffset(8 * si, R15) (* In the kickoff, we store the start of the heap in R15 *)

(* Suggested values for `true` and `false` to distinguish them from pointers *)
let true_const  = HexConst(0x0000000000000006L)
let null_const = HexConst(0x0000000000000000L)
let false_const = HexConst(0x0000000000000002L)

let rec well_formed_e (e : expr) (env : string list) : string list =
  let well_formed_e e = well_formed_e e env in
  match e with
  | ENumber _ | ENull _ | EBool _ -> []
  | EPrim1(_, e) | EArray e -> well_formed_e e
  | EIndex(e1, e2) | EPrim2(_, e1, e2) -> well_formed_e e1 @ well_formed_e e2
  | EIf(e1, e2, e3) | ESetIndex(e1, e2, e3) -> List.concat_map well_formed_e [e1; e2; e3]
  | EId id -> if List.mem id env  then [] else ["Variable identifier " ^ id ^ " unbound"]
  | ESet(id, e) -> if List.mem id env then well_formed_e e else ["Variable identifier " ^ id ^ " unbound"] @ well_formed_e e
  (* Changed implementation, check if it broke *)
  | EApp(_, args) -> List.concat_map well_formed_e args
  | EWhile(cond, body) -> well_formed_e cond @ check_body body env
  | ELet(bindings, body) -> 
    let rec check_bindings bs seen_ids  = begin match bs with
      | [] -> check_body body (seen_ids @ env)
      | (id, e)::rest -> if List.mem id seen_ids then
          ["Multiple bindings for variable identifier " ^ id]
          @ well_formed_e e @ check_bindings rest seen_ids
        else well_formed_e e @ check_bindings rest (id::seen_ids)
      end in
    check_bindings bindings []
  
  and check_body (body : expr list) (env : string list) : string list =
    match body with
    | []-> []
    | e::rest -> (well_formed_e e env) @ (check_body rest env)

let well_formed_def (def) =
  match def with
  | DType(_) -> []
  | DFun(name, args, _, body) ->
    let rec unique_arguments checked to_check =
      match to_check with
      | [] -> check_body body checked
      | (arg_name, _) :: rest -> if List.mem arg_name checked
        then ["Multiple bindings in function " ^ name] @ unique_arguments checked rest
        else unique_arguments (arg_name :: checked) rest in
    unique_arguments [] args

let well_formed_prog (defs, main) =
  let rec check_multiple_defs (to_check : def list) (checked : string list) = match to_check with
  | [] -> []
  | DType(name, _) :: rest | DFun(name, _, _, _) :: rest ->
    if List.mem name checked then ["Multiple defs named " ^ name] @ check_multiple_defs rest checked
      else check_multiple_defs rest (name :: checked)
  in
  (check_multiple_defs defs []) @ 
  (List.concat (List.map well_formed_def defs)) @ (well_formed_e main ["input"])

let check p : string list =
  match well_formed_prog p with
  | [] -> []
  | errs -> failwith (String.concat "\n" errs)

let rec compile_expr (e : expr) (si : int) (env : (string * int) list) def_env
  : instruction list =
  let compile_expr e si env = compile_expr e si env def_env in
  match e with
  | EArray(len) -> 
    let len = compile_expr len si env in
    (* Convert length to binary *)
    len @ [ISar(Reg(RAX), Const(1));
    (* Check for a negative number *)
    ICmp(Reg(RAX), Const(0)); IJl(negative_arr_err);
    (* Length at RBX *)
    IMov(Reg(RBX), Reg(RAX));
    (* Heap pointer at RAX *)
    IMov(Reg(RAX), Reg(R15));
    (* Array's length in its base address *)
    IMov(heaploc 0, Reg(RBX));
    (* Convert length to byte offset including the space for the length and add it to the pointer *)
    IShl(Reg(RBX), Const(3)); IAdd(Reg(R15), Reg(RBX)); IAdd(Reg(R15), Const(8))]
  | EIndex(arr, i) ->
    let arr = compile_expr arr si env in
    let i = compile_expr i (si + 1) env in
    arr @ [IMov(stackloc si, Reg(RAX));
    IAnd(Reg(RAX), Const(7)); ICmp(Reg(RAX), Const(0)); IJne(not_a_pointer_err)] @
    i @
    (* Convert index to binary, check bounds *)
    [ISar(Reg(RAX), Const(1));
    ICmp(Reg(RAX), Const(0)); IJl(bounds_err);
    IMov(Reg(RBX), stackloc si); (* Array base at RBX *)
    ICmp(Reg(RAX), RegOffset(0, RBX)); IJge(bounds_err);
    (* Lookup *)
    IAdd(Reg(RAX), Const(1));
    IMov(Reg(RAX), BaseOffset(RBX, RAX))]
  | ESetIndex(arr, i, value) -> 
    let arr = compile_expr arr si env in
    let i = compile_expr i (si + 1) env in
    let value = compile_expr value (si + 1) env in
    arr @ [IMov(stackloc si, Reg(RAX));
    IAnd(Reg(RAX), Const(7)); ICmp(Reg(RAX), Const(0)); IJne(not_a_pointer_err)]
    @ i @
    (* Convert index to binary, check bounds *)
    [ISar(Reg(RAX), Const(1));
    ICmp(Reg(RAX), Const(0)); IJl(bounds_err);
    IMov(Reg(RBX), stackloc si); (* Array base at RBX *)
    ICmp(Reg(RAX), RegOffset(0, RBX)); IJge(bounds_err);
    (* Get the element's address at RAX *)
    IAdd(Reg(RAX), Const(1)); IShl(Reg(RAX), Const(3)); IAdd(Reg(RAX), Reg(RBX));
    (* Free stack, store only the element's address *)
    IMov(stackloc si, Reg(RAX))] @
    (* Store the new value at the address *)
    value @ [IMov(Reg(RBX), stackloc si); IMov(RegOffset(0, RBX), Reg(RAX))]
  | ENumber i -> [IMov(Reg(RAX), Const64(Int64.add (Int64.mul (Int64.of_int i) (Int64.of_int 2)) Int64.one))]
  | EBool b -> [IMov(Reg(RAX), if b then true_const else false_const)]
  | ENull _ -> [IMov(Reg(RAX), null_const)]
  | ELet(bindings, body) -> 
    let rec compile_bindings binds si env def_env =
      match binds with
      | [] -> ([], env, si)
      | (name, expr)::rest ->
          let compiled_expr = compile_expr expr si env in
          let env' = (name, si)::env in
          let si' = si + 1 in
          let (rest_instructions, final_env, final_si) = compile_bindings rest si' env' def_env in
          (compiled_expr @ [IMov(stackloc si, Reg(RAX))] @ rest_instructions, final_env, final_si)
    in
    let (bindings_instructions, extended_env, new_si) = compile_bindings bindings si env def_env in
    let body_instructions = compile_body body new_si extended_env def_env in
    bindings_instructions @ body_instructions
  | EWhile(cond, body) ->
    let while_label = gen_temp "while_test" in
    let end_label = gen_temp "end" in
    [ILabel(while_label)] @ compile_expr cond si env @ [ICmp(Reg(RAX), true_const); IJne(end_label)]
    @ compile_body body si env def_env @ [IJmp(while_label); ILabel(end_label)]
  | ESet(id, e) -> let stack_offset = find env id in
    begin match stack_offset with
      | Some(i) -> compile_expr e si env @ [IMov(stackloc i, Reg(RAX))]
      | None -> failwith "Unbound variable" (* I'm pretty sure this would be caught in well formed *)
    end
  | EIf(predicate, consequent, alternative) ->
    let else_branch = gen_temp "else" in
    let end_branch = gen_temp "end" in
    (compile_expr predicate si env) @ [ICmp(Reg(RAX), false_const); IJe(else_branch)]
    @ (compile_expr consequent si env) @ [IJmp(end_branch);
    ILabel(else_branch)] @ (compile_expr alternative si env)
    @ [ILabel(end_branch)]
  | EId(name) -> begin match find env name with
      | None -> failwith "Unbound variable identifier" (* Caught in well formed *)
      | Some(i) -> [IMov(Reg(RAX), stackloc i)]
    end
  | EPrim1(op, e) -> compile_prim1 op e si env def_env
  | EPrim2(op, e1, e2) -> compile_prim2 op e1 e2 si env def_env
  | EApp(f, args) -> 
    let rec store_args_in_stack args si = 
      match args with
      | [] -> []
      | arg :: rest -> (compile_expr arg si env) @ [IMov(stackloc si, Reg(RAX))] @ store_args_in_stack rest (si + 1)
    in 
    let rsp_offset = si + List.length args - 1 in
    let args_instructions = store_args_in_stack args si in
    let rsp_adjust = [ISub(Reg(RSP), Const(8 * (rsp_offset)))] in
    let restore_rsp = [IAdd(Reg(RSP), Const(8 * (rsp_offset)))] in
    args_instructions @ rsp_adjust
    @ [ICall(f ^ "_func")] @ restore_rsp

and compile_prim1 op e si env def_env =
  let compiled_e = compile_expr e si env def_env in
  match op with
    | Add1 -> compiled_e @ [IAdd(Reg(RAX), Const(2)); IJo(overflow_err)]
    | Sub1 -> compiled_e @ [ISub(Reg(RAX), Const(2)); IJo(overflow_err)]
    | IsNum -> compiled_e @ [IAnd(Reg(RAX), Const(1)); IShl(Reg(RAX), Const(2)); IAdd(Reg(RAX), Const(2))]
    | IsBool -> let not_bool = gen_temp "false" in
      compiled_e @ [IMov(Reg(RBX), false_const);
      (* Bools end in 10; get 2 lsb, compare with 10 *)
      IAnd(Reg(RAX), Const(3)); ICmp(Reg(RAX), Const(2));
      (* If it's a bool, add 4, turning false -> true *)
      IJne(not_bool); IAdd(Reg(RBX), Const(4));
      ILabel(not_bool); IMov(Reg(RAX), Reg(RBX))]
    | Print -> compiled_e @ [IMov(Reg(RDI), Reg(RAX)); ISub(Reg(RSP), Const(8 * (si + 1))); ICall("print"); IAdd(Reg(RSP), Const(8 * (si + 1)))]
    | IsNull -> let not_null = gen_temp "false" in
      compiled_e @ [IMov(Reg(RBX), false_const); ICmp(Reg(RAX), null_const);
      IJne(not_null); IAdd(Reg(RBX), Const(4));
      ILabel(not_null); IMov(Reg(RAX), Reg(RBX))]

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

and compile_def def def_env =
  match def with
  | DType(_) -> []
  | DFun(name, args, _, body) -> 
    let rec build_args_env args si = match args with
      | [] -> []
      | (arg, _) :: rest -> (arg, si) :: build_args_env rest (si + 1)
    in
    let args_length = List.length args in
    let env = build_args_env args (-args_length) in
    let compiled_body = compile_body body 1 env def_env in
    [ILabel(name ^ "_func")] @ compiled_body @ [IRet]

and compile_body body si env def_env =
  match body with
  | e::rest -> (compile_expr e si env def_env) @ (compile_body rest si env def_env)
  | [] -> []

let compile_to_string ((defs, main) as prog : Expr.prog) =
  let _ = check prog in
  let def_env, typ_env = build_def_env defs in
  let _ = tc_p prog def_env typ_env in
  let compiled_defs = List.concat (List.map (fun d -> compile_def d defs) defs) in
  let compiled_main = compile_expr main 2 [("input", 1)] defs in
  let prelude = "  section .text\n" ^
                "  extern error\n" ^
                "  extern print\n" ^
                "  global our_code_starts_here\n" in
  let kickoff = "our_code_starts_here:\n" ^
                "push rbx\n" ^
                "  mov r15, rdi\n" ^       (* rdi and r15 contain a pointer to the start of the heap *)
                "  mov [rsp - 8], rsi\n" ^ (* rsi and [rsp-8] contain the input value *)
                to_asm compiled_main ^
                "\n  pop rbx\nret\n" in
  let postlude = [
    ILabel(overflow_err); IMov(Reg(RDI), Const(1)); IPush(Const(0)); ICall("error");
    ILabel(bounds_err); IMov(Reg(RDI), Const(2)); IPush(Const(0)); ICall("error");
    ILabel(negative_arr_err); IMov(Reg(RDI), Const(3)); IPush(Const(0)); ICall("error");
    ILabel(not_a_pointer_err); IMov(Reg(RDI), Const(4)); IPush(Const(0)); ICall("error");
  ] in
  let as_assembly_string = (to_asm (compiled_defs @ postlude)) in
  sprintf "%s%s\n%s\n" prelude as_assembly_string kickoff

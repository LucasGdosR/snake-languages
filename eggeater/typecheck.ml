open Expr
open Printf

let rec find ls x =
  match ls with
  | [] -> None
  | (y,v)::rest ->
    if y = x then Some(v) else find rest x

type def_env = (string * (typ list * typ)) list
type typ_env = (string * typ) list

let rec convert_alias_typ typ typ_env = match typ with
    | TName(s) -> begin match find typ_env s with
        | Some(t) -> convert_alias_typ t typ_env
        | None -> failwith ("Undeclared type: " ^ s)
      end
    | _ -> typ

let build_def_env (defs : def list) =
  let append_env (def_env, typ_env) def = match def with
    | DFun(name, args, ret_typ, _) -> ((name, (List.map snd args, ret_typ)) :: def_env, typ_env)
    | DType(name, actual_typ) -> (def_env, (name, actual_typ) :: typ_env)
  in
  let turn_def_primitive (name, (typ_list, typ)) typ_env =
    (name,
    (List.map (fun t -> convert_alias_typ t typ_env) typ_list,
    convert_alias_typ typ typ_env))
  in
  let def_env, typ_env = List.fold_left append_env ([], []) defs in
  let primitive_def_env = List.map (fun def -> turn_def_primitive def typ_env) def_env in
  primitive_def_env, typ_env

let rec tc_e (e : expr) (env : (string * typ) list) (def_env : def_env) (typ_env : typ_env) : typ =
  let tc_e e env = tc_e e env def_env typ_env in
  match e with
  | ENumber(_) -> TNum
  | EBool(_) -> TBool
  | EId(x) -> begin match find env x with
      | Some(typ) -> typ
      | None -> failwith "Unbound id" (* Never reached *)
    end
  | EIf(cond, cons, alt) -> begin match (tc_e cond env, tc_e cons env, tc_e alt env) with
      | (TBool | TUnknown), cons_typ, alt_typ when cons_typ = alt_typ -> cons_typ
      | (TBool | TUnknown), TUnknown, alt_typ -> alt_typ
      | (TBool | TUnknown), cons_typ, TUnknown -> cons_typ
      | _ -> failwith "Type mismatch 1"
    end
  | ESet(var, value) -> begin match find env var with
      | Some(typ) when List.mem (tc_e value env) [typ; TUnknown] -> typ
      | Some(_) -> failwith "Type mismatch 2"
      | None -> failwith "Unbound id" (* Never reached *)
    end
  | EPrim1(op, e) -> begin match op with
      | Add1 | Sub1 -> begin match tc_e e env with
          | (TNum | TUnknown) -> TNum
          | _ -> failwith "Type mismatch 3"
        end
      | IsNum | IsBool | IsNull -> TBool
      | Print -> tc_e e env
    end
  | EPrim2(op, e1, e2) -> begin match op, tc_e e1 env, tc_e e2 env with
      | Equal, _, _ -> TBool
      | (Plus | Minus | Times), (TNum | TUnknown), (TNum | TUnknown) -> TNum
      | (Greater | Less), (TNum | TUnknown), (TNum | TUnknown) -> TBool
      | _ -> failwith "Type mismatch 4"
    end
  | ELet(bindings, body) ->
    let rec tc_body (body : expr list) (env : (string * typ) list) =
      match body with
        | e::rest when rest = [] -> tc_e e env
        | e::rest -> let _ = tc_e e env in
          tc_body rest env
        | [] -> failwith "Empty body has no type." (* Never reached *)
    in
    let rec tc_bindings (binding : (string * expr) list) (env : (string * typ) list) = begin match binding with
        | [] -> tc_body body env
        | (x, value)::rest -> tc_bindings rest ((x, tc_e value env)::env)
      end in
    tc_bindings bindings env
  | EWhile(cond, body) ->
    let rec tc_body (body : expr list) (env : (string * typ) list) =
      match body with
        | e::rest -> let _ = tc_e e env in
          tc_body rest env
        | [] -> TBool
    in
    begin match tc_e cond env with
      | (TBool | TUnknown) -> tc_body body env
      | _ -> failwith "Type mismatch 5"
    end
  | EApp(f, provided) -> begin match find def_env f with
      | None -> failwith ("Unbound function." ^ f)
      | Some(expected, ret_typ)
        when List.for_all2 (
          fun provided_elem expected_elem ->
            List.mem (tc_e provided_elem env) [expected_elem; TUnknown]
          ) provided expected -> ret_typ
      | _ -> failwith ("Argument type does not match in function " ^ f)
    end
  | EArray(e) ->
    if tc_e e env = TNum
      then TArray
    else failwith "Type mismatch 6"
  | ENull(t) -> t
  | ESetIndex(arr, i, value) -> 
    let arr = tc_e arr env in
    let i = tc_e i env in
    let value = tc_e value env in
    if arr = TArray && i = TNum then value else failwith "Type mismatch 7"
    (* I should store the type of the i-th element of arr in env, but how is that knowable? *)
  | EIndex(_) -> TUnknown (* Lookup in env, fail if not set. Let's start with arrays of num only. *)
    
let tc_def def_env def typ_env =
  match def with
  | DType(_) -> []
  | DFun(_, args, ret_typ, body) -> 
    let rec tc_body (body : expr list) (env : (string * typ) list) =
      match body with
        | e::rest when rest = [] -> tc_e e env def_env typ_env
        | e::rest -> let _ = tc_e e env def_env typ_env in
          tc_body rest env
        | [] -> failwith "Empty function body (caught in parsing)."
  in
  let turn_arg_primitive (name, typ) = (name, convert_alias_typ typ typ_env) in
  let primitive_args = List.map turn_arg_primitive args in
  let ret_typ = convert_alias_typ ret_typ typ_env in
  let def_typ = tc_body body primitive_args in
  let debug_typs typ = begin match typ with
      | TArray -> "Array"
      | TBool -> "Bool"
      | TNum -> "Num"
      | TName(s) -> s
      | TUnknown -> "Unknown"
    end
  in
  if List.mem def_typ [ret_typ; TUnknown] then [] else failwith (
    "Definition does not evaluate to return type.\nExpected: "
    ^ (debug_typs ret_typ) ^ "\nReceived: " ^ (debug_typs def_typ))
  (*if def_typ = ret_typ then [] else failwith "Definition does not evaluate to return type."*)
  
let tc_p (defs, main) def_env typ_env: typ =
  begin ignore (List.map (fun def -> tc_def def_env def typ_env) defs); tc_e main [("input", TNum)] def_env typ_env end

open Expr
open Printf

let rec find ls x =
  match ls with
  | [] -> None
  | (y,v)::rest ->
    if y = x then Some(v) else find rest x

type def_env = (string * (typ list * typ)) list

let rec tc_e (e : expr) (env : (string * typ) list) (def_env : def_env) : typ =
  let tc_e e env = tc_e e env def_env in
  match e with
  | ENumber(_) -> TNum
  | EBool(_) -> TBool
  | EId(x) -> begin match find env x with
      | Some(typ) -> typ
      | None -> failwith "Unbound id" (* Never reached *)
    end
  | EIf(cond, cons, alt) -> begin match (tc_e cond env, tc_e cons env, tc_e alt env) with
      | TBool, cons_typ, alt_typ when cons_typ = alt_typ -> cons_typ
      | _ -> failwith "Type mismatch"
    end
  | ESet(var, value) -> begin match find env var with
      | Some(typ) when typ = tc_e value env -> typ
      | Some(_) -> failwith "Type mismatch"
      | None -> failwith "Unbound id" (* Never reached *)
    end
  | EPrim1(op, e) -> begin match op with
      | Add1 | Sub1 -> begin match tc_e e env with
          | TNum -> TNum
          | TBool -> failwith "Type mismatch"
        end
      | IsNum | IsBool -> TBool
      | Print -> tc_e e env
    end
  | EPrim2(op, e1, e2) -> begin match op, tc_e e1 env, tc_e e2 env with
      | Equal, _, _ -> TBool
      | _, TBool, _ | _, _, TBool -> failwith "Type mismatch"
      | Plus, _, _ | Minus, _, _ | Times, _, _ -> TNum
      | Greater, _, _ | Less, _, _ -> TBool
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
        | (x, value)::rest -> tc_bindings rest body ((x, tc_e value env)::env)
      end in
    tc_bindings bindings body env
  | EWhile(cond, body) ->
    let rec tc_body (body : expr list) (env : (string * typ) list) =
      match body with
        | e::rest -> let _ = tc_e e env in
          tc_body rest env
        | [] -> TBool
    in
  
    begin match tc_e cond env with
      | TBool -> tc_body body env
      | TNum -> failwith "Type mismatch"
    end
  | EApp(f, provided) -> begin match find def_env f with
      | None -> failwith "Unbound function."
      | Some(expected, ret_typ) when List.map (fun provided -> tc_e provided env) provided = expected -> ret_typ
      | _ -> failwith "Argument type does not match"
    end

let build_def_env (defs : def list) : def_env =
  let get_typ (DFun(name, args, ret_typ, _)) = (name, ((List.map snd args), ret_typ)) in

  let rec tc_body (body : expr list) (env : (string * typ) list) =
    match body with
      | e::rest when rest = [] -> tc_e e env []
      | e::rest -> let _ = tc_e e env [] in
        tc_body rest env
      | [] -> failwith "Empty body has no type." (* Never reached *)
  in

  let calc_typ (DFunNoRet(name, args, body)) = (name, ((List.map snd args), tc_body body args)) in

  let map_def_typ (def : def) = match def with
  | DFun(_) -> get_typ def
  | DFunNoRet(_) -> calc_typ def
  in
  
  List.map map_def_typ defs

let tc_def def_env (def : def) =
  match def with
  | DFunNoRet(_) -> []
  | DFun(_, args, ret_typ, body) -> 
    let rec tc_body (body : expr list) (env : (string * typ) list) =
      match body with
        | e::rest when rest = [] -> tc_e e env
        | e::rest -> let _ = tc_e e env def_env in
          tc_body rest env
        | [] -> failwith "Empty function body (caught in parsing)."
    in
    let def_typ = tc_body body args def_env in
    if def_typ = ret_typ then [] else failwith "Definition does not evaluate to return type."

let tc_p (defs, main) def_env : typ =
  begin ignore (List.map (tc_def def_env) defs); tc_e main [("input", TNum)] def_env end

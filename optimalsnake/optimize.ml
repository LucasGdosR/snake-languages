open Expr
open Parser

let rec find ls x =
  match ls with
  | [] -> None
  | (y,v)::rest ->
    if y = x then Some(v) else find rest x

type value = | Int of int | Bool of bool

let rec propagate_consts (e: expr) (st: (string * value) list) : expr * bool * (string * value) list =
  (* (let ((x 1) ...) ...) *)
  (* Replace all x's with 1 until a (set x _) is found,
     or there's a shadowing (let ((x ...) ...) ...),
     in which case update the value of x and keep propagating *)
  match e with
  | EId id ->
    begin match find st id with
      | Some(v) -> begin match v with
          | Int i -> ENumber i, true, st
          | Bool b -> EBool b, true, st
        end
      | None -> EId id, false, st
    end
  | ESet(name, e) ->
      let e, p, st = propagate_consts e st in
      let st = List.filter (fun (var, _) -> var <> name) st in
      ESet(name, e), p, st
  | ELet(bindings, body) ->
      (* begin propagate_through_bindings *)
      let propagate_through_bindings (bindings: (string * expr) list) (st: (string * value) list)
      (* bindings              previous st filtered by sets   constant bindings st    propagated *)
      : (string * expr) list * (string * value) list *        (string * value) list * bool = 
      
        let rev_acc_bindings, acc_b, acc_st_filtered, acc_st_from_bindings =
          List.fold_left (fun (rev_acc_bindings, acc_b, acc_st_filtered, acc_st_from_bindings) (name, e) ->
            match e with
            (* If a binding takes a constant, put it into an accumulated symbol table that will be merged later *)
            | ENumber n -> (name, e) :: rev_acc_bindings, acc_b, acc_st_filtered, (name, Int n) :: acc_st_from_bindings
            | EBool b -> (name, e) :: rev_acc_bindings, acc_b, acc_st_filtered, (name, Bool b) :: acc_st_from_bindings
            | EId id -> begin match find acc_st_filtered id with
                | Some v -> begin match v with
                    | Int i -> (name, ENumber i) :: rev_acc_bindings, true, acc_st_filtered, (name, Int i) :: acc_st_from_bindings
                    | Bool b -> (name, EBool b) :: rev_acc_bindings, true, acc_st_filtered, (name, Bool b) :: acc_st_from_bindings
                  end
                | None -> (name, e) :: rev_acc_bindings, acc_b, acc_st_filtered, acc_st_from_bindings
              end
            (* Propagate constants normally.
            If there's a set expression inside a binding,
            filter the set variable from the symbol table
            before passing it to the next binding *)
            | _ -> let e, p, st = propagate_consts e acc_st_filtered in
                (name, e) :: rev_acc_bindings, p || acc_b, st, acc_st_from_bindings
            ) ([], false, st, []) bindings in
        (List.rev rev_acc_bindings, acc_st_filtered, acc_st_from_bindings, acc_b)
      in
      (* end propagate_through_bindings *)

      let bindings, st_filtered, st_from_bindings, p_bindings = propagate_through_bindings bindings st in
      (* Allow shadowing by maintaining a single value for each variable name *)
      let merged_st = List.fold_left (fun (st) (k, v) -> if List.mem_assoc k st then st else (k, v) :: st) st_from_bindings st_filtered in

      let body, p_body, st = propagate_through_body body merged_st in

      (* The parent should receive the original st
         minus the variables that were set in the bindings (st_filtered)
         minus the variables that were set in the body (this filter) *)
      let parent's_st = List.filter (fun (k, _) -> List.mem_assoc k st) st_filtered in 
      ELet(bindings, body), p_bindings || p_body, parent's_st
    
  | EIf(cond, cons, alt) ->
      let cond, p1, st = propagate_consts cond st in
      (* Branches are independent, so they receive the same st *)
      let cons, p2, st_cons = propagate_consts cons st in
      let alt, p3, st_alt = propagate_consts alt st in
      (* The returned st must remove variables set by either branch *)
      let merged_st = List.filter (fun (e) -> List.mem e st_cons) st_alt in
      EIf(cond, cons, alt), p1 || p2 || p3, merged_st
  | EWhile(cond, body) ->
      (* If a variable is set in the body, it can't be propagated to the condition *)
      let rec get_set_vars (set_vars: string list) (e: expr): string list =
        match e with
          | ESet(name, _) -> name :: set_vars
          | ELet(bindings, body) ->
              let set_vars = List.concat_map (get_set_vars set_vars) body in
              List.concat_map (get_set_vars set_vars) (List.map snd bindings)
          | EWhile(cond, body) ->
              let set_vars = get_set_vars set_vars cond in
              List.concat_map (get_set_vars set_vars) body
          | EApp(_, args) -> List.concat_map (get_set_vars set_vars) args
          | EIf(cond, cons, alt) ->
              let set_vars = get_set_vars set_vars cond in
              let set_vars = get_set_vars set_vars cons in
              get_set_vars set_vars alt
          | EPrim2(_, e1, e2) ->
              let set_vars = get_set_vars set_vars e1 in
              get_set_vars set_vars e2
          | EPrim1(_, e) -> get_set_vars set_vars e
          | EId _ | ENumber _ | EBool _ -> set_vars
      in
      let set_vars = List.concat_map (get_set_vars []) body in
      let st = List.filter (fun (name, _) -> not (List.mem name set_vars)) st in
      let cond, p1, st = propagate_consts cond st in
      let body, p2, st = propagate_through_body body st in
      EWhile(cond, body), p1 || p2, st
  | EApp(f, args) ->
      let args, p, st = propagate_through_body args st in
      EApp(f, args), p, st
  | EPrim2(op, e1, e2) ->
      let e1, p1, st = propagate_consts e1 st in
      let e2, p2, st = propagate_consts e2 st in
      EPrim2(op, e1, e2), p1 || p2, st
  | EPrim1(op, e) ->
      let e, p, st = propagate_consts e st in
      EPrim1(op, e), p, st
  | EBool bool -> EBool bool, false, st
  | ENumber num -> ENumber num, false, st
(* Expressions must be evaluated sequentially in the body to update the st correctly *)
and propagate_through_body (body: expr list) (st: (string * value) list)
: expr list * bool * (string * value) list =
  let rev_acc_e, acc_b, acc_st =
    List.fold_left (fun (rev_acc_e, acc_b, acc_st) e ->
      let e', b, st' = propagate_consts e acc_st in
      (e' :: rev_acc_e, acc_b || b, st')
    ) ([], false, st) body in
  (List.rev rev_acc_e, acc_b, acc_st)

let opt_list opt_fun expr_list =
  List.fold_right (fun e (acc_e, acc_b) ->
    let e', b = opt_fun e in
    (e' :: acc_e, acc_b || b)
  ) expr_list ([], false)  

let rec fold_consts (e: expr) : expr * bool =
  (* at least arithmetic *)
  (* x = 3 + 6 => x = 9 *)
  match e with
  | EPrim2(Equal, ENumber n1, ENumber n2) -> EBool(n1 = n2), true
  | EPrim2(Equal, EBool b1, EBool b2) -> EBool(b1 = b2), true
  | EPrim2(Equal, (ENumber _ | EBool _), (ENumber _ | EBool _)) -> EBool(false), true
  | EPrim2((Plus | Minus | Times | Less | Greater) as op, ENumber n1, ENumber n2) ->
      let n1_64 = Int64.of_int n1 in
      let n2_64 = Int64.of_int n2 in
      begin match op with
        | Less -> EBool(n1 < n2), true
        | Greater -> EBool(n1 > n2), true
        | Plus when (Int64.add n1_64 n2_64) > Int64.of_int boa_max-> failwith ("Overflow: " ^ string_of_int n1 ^ " + " ^ string_of_int n2)
        | Plus -> ENumber(n1 + n2), true
        | Minus when (Int64.sub n1_64 n2_64) < Int64.of_int boa_min -> failwith ("Overflow: " ^ string_of_int n1 ^ " - " ^ string_of_int n2)
        | Minus -> ENumber(n1 - n2), true
        | Times when (n1 != 0 && n2 != 0 && n1 > boa_max / n2) -> failwith ("Overflow: " ^ string_of_int n1 ^ " * " ^ string_of_int n2)
        | Times -> ENumber(n1 * n2), true
        | Equal -> failwith "Impossible"
      end
  | EPrim2(op, e1, e2) ->
      let e1, f1 = fold_consts e1 in
      let e2, f2 = fold_consts e2 in
      EPrim2(op, e1, e2), f1 || f2
  | EPrim1((Add1 | Sub1) as op, ENumber e) ->
      ENumber(match op with
        | Add1 when e = boa_max -> failwith ("Overflow adding 1 to " ^ string_of_int e)
        | Add1 -> e + 1
        | Sub1 when e = boa_min -> failwith ("Overflow subbing 1 from " ^ string_of_int e)
        | _ -> e - 1), true
  | EPrim1((IsNum | IsBool) as op, ((ENumber _ | EBool _) as e)) ->
      EBool(match op, e with
        | IsNum, ENumber _ | IsBool, EBool _ -> true
        | _ -> false), true
  | EPrim1(op, e) ->
      let e, fold = fold_consts e in
      EPrim1(op, e), fold
  | EWhile(cond, body) -> 
      let cond, f1 = fold_consts cond in
      let body, f2 = opt_list fold_consts body in
      EWhile(cond, body), f1 || f2
  | EIf(cond, cons, alt) ->
      let cond, f1 = fold_consts cond in
      let cons, f2 = fold_consts cons in
      let alt, f3 = fold_consts alt in
      EIf(cond, cons, alt), f1 || f2 || f3
  | EApp(f, args) ->
      let args, fold = opt_list fold_consts args in
      EApp(f, args), fold
  | ELet(bindings, body) ->
      let bindings, f1 =
        List.fold_right (fun (name, e) (acc_bindings, acc_bool) ->
          let e', b = fold_consts e in
          ((name, e') :: acc_bindings, acc_bool || b)
        ) bindings ([], false) in
      let body, f2 = opt_list fold_consts body in
      ELet(bindings, body), f1 || f2
  | ESet(id, e) ->
      let e, fold = fold_consts e in
      ESet(id, e), fold
  | EBool bool -> EBool bool, false
  | EId id -> EId id, false
  | ENumber num -> ENumber num, false

let rec elim_dead (e: expr) : expr * bool =
  (* at least if expressions and while loops *)
  (* (if true <cons> <alt>) => <cons> *)
  match e with
  | EIf(EBool(bool), cons, alt) -> 
      let expr _ = elim_dead (if bool then cons else alt) in
      expr true
  | EIf(cond, cons, alt) ->
      let cond, e1 = elim_dead cond in 
      let cons, e2 = elim_dead cons in 
      let alt, e3 = elim_dead alt in
      EIf(cond, cons, alt), e1 || e2 || e3
  | EWhile(EBool(bool), _) ->
      (if bool then failwith "Infinite loop detected during optimization" else EBool(false)), true
  | EWhile(cond, body) ->
      let cond, e1 = elim_dead cond in
      let body, e2 = opt_list elim_dead body in
      EWhile(cond, body), e1 || e2
  | EApp(f, args) ->
      let args, e = opt_list elim_dead args in
      EApp(f, args), e
  | ELet(bindings, body) ->
      let bindings, e1 =
        List.fold_right (fun (name, e) (acc_bindings, acc_bool) ->
          let e', b = elim_dead e in
          ((name, e') :: acc_bindings, acc_bool || b)
        ) bindings ([], false) in
      let body, e2 = opt_list elim_dead body in
      ELet(bindings, body), e1 || e2
  | EPrim2(op, ex1, ex2) ->
      let ex1, e1 = elim_dead ex1 in
      let ex2, e2 = elim_dead ex2 in
      EPrim2(op, ex1, ex2), e1 || e2
  | EPrim1(op, e) -> 
      let e, elim = elim_dead e in
      EPrim1(op, e), elim
  | ESet(id, e) ->
      let e, elim = elim_dead e in
      ESet(id, e), elim
  | EBool bool -> EBool bool, false
  | EId id -> EId id, false
  | ENumber num -> ENumber num, false

(* Fixpoint optimization:
Perform optimizations until there're no changes *)
let rec opt_e (e : expr) =
  let prop_e, p, _ = propagate_consts e [] in
  let fold_e, f = fold_consts prop_e in
  let elim_e, e = elim_dead fold_e in
  if p || f || e then opt_e elim_e else elim_e

let opt_def (DFun(name, args, ret, body): def) =
  DFun(name, args, ret, List.map opt_e body)

let optimize_defs (defs : def list) =
  List.map opt_def defs

let optimize_prog ((defs, main) : prog) : prog =
  let defs = optimize_defs defs in
  let main = opt_e main in
  (defs, main)
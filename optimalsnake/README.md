# PA6: Optimizations
Optimalsnake implements constant propagation, constant folding, and dead code elimination. Since these particular optimizations never undo each other, it is safe to implement them using a fixed-point algorithm, and it will always terminate. This was my approach.

Unlike the rest of the course, there's no material for optimizations, so I was on my own. First, I had to decide where to apply the optimizations. My working version of Diamondback already had well formedness and type checking right after the parser. I could either apply optimizations to the IR in the AST form I had at that point, or in the linear instruction list form after the "compile" function. I decided to do it with the AST, right after the program was checked. I included a call to the optimizing function here:
```
let compile_to_string ((defs, _) as prog : Expr.prog) =
  let _ = check prog in
  let def_env = build_def_env defs in
  let _ = tc_p prog def_env in
  let (defs, main) = optimize_prog prog in  (* OPTIMIZATION CALL *)
  let compiled_defs = List.concat (List.map (fun d -> compile_def d defs) defs) in
  let compiled_main = compile_expr main 2 [("input", 1)] defs in
  ...
```
The optimization functions are in `optimize.ml`. Here's how the fixed-point optimization works:
```
let rec opt_e (e : expr) =
  let prop_e, p, _ = propagate_consts e [] in
  let fold_e, f = fold_consts prop_e in
  let elim_e, e = elim_dead fold_e in
  if p || f || e then opt_e elim_e else elim_e
```
It makes tail recursive calls to itself if any optimization was successfull in this pass. Once none are successfull, the algorithm has reached a fixed-point, and it will always return the same thing.

Each of the three optimizations care more about different language constructs. Dead code elimination is all about branching, so "if"s and "while"s are the most relevant nodes. If their conditionals are known boolean values, some part of the code can be eliminated. The terminal expressions indicate there's no change to be made, and the rest recurse to check if there's an "if" or "while" as one of their children:
```
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
  ...
```

Constant folding is about operations on constants, so it cares about "+", "-", "*", "<", ">", "==", "inc", "dec", "isNum", "isBool". If the operands are known, the whole expression can be replaced by its result. It is important to check for overflow when folding constants, since overflows were treated as runtime errors previously:
```
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
  ...
```

Constant propagation is about finding variables which have a known value at a time, and replacing them for that value. That means variable names are important, as are "let declarations", and "set expressions". There are other tricky details, such as when different "set"s appear on conditional branches, and not propagating to a "while"'s condition something that is set in its body. I believe a different IR with static single-assignment (SSA) would be a nice fit for this case, and it might even allow to propagate constants after "set expressions":
```
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
  ...
```
Here's some explanation of how I went about it: I passed a symbol table around with the name of the declared variables and their values. "Let expressions" add to the symbol table, while "set expressions" filter out the set variable. When a variable name is found, if it's in the symbol table, it is replaced by the value.

I reasoned about sequencing the updates to the symbol table, and caring about it made this implementation the longest of the three. In "let expressions", we must first filter any variable from the symbol table that is set in one of the variable declarations. Meanwhile, we must build up a symbol table with the declarations and their values. Then, we must merge them together, preferring new values over old ones for declared variables, effectively shadowing them. The symbol table that passes to the let's body is the merged symbol table. Then, the symbol table that is returned to the let's parent is the one that the parent passed minus whatever was filtered, be it inside the declarations, or inside the let's body. This implementation resulted in correct constant propagation even when variables are shadowed, which I found pretty cool.

For "if"s, if a variable is set in one either branch, it is filtered out. For "while"s, any vars set in the body are filtered from the symbol table before passing it to the conditional, and then any variable set in the conditional is filtered before passing it to the body too.

There are four input files exemplifying the optimizations that Optimalsnake implements. I've included assembly files for them with some annotations to make it clear what's happening.

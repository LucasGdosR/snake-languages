open Sexplib.Sexp
open Expr

(* Defines rules for what ids are valid -- ids must match the regex and not
 * be a reserved word *)
let reserved_words = ["let"; "add1"; "sub1"]

(* Converts a string to Some int or None if not convertable *)
let int_of_string_opt s =
  try Some(int_of_string s) with
  | _ -> None

let rec parse sexp =
  match sexp with
  | Atom(s) -> 
    (match int_of_string_opt s with
    | Some(i) -> ENumber(i)
    | None -> 
      (match s with
      | s when List.mem s reserved_words -> failwith "Invalid syntax"
      | _ -> EId(s)
      )
    )
  | List(sexps) ->
    match sexps with
    | [Atom("add1"); arg] -> EPrim1(Add1, parse arg)
    | [Atom("sub1"); arg] -> EPrim1(Sub1, parse arg)
    | [Atom("+"); arg1; arg2] -> EPrim2(Plus, parse arg1, parse arg2)
    | [Atom("-"); arg1; arg2] -> EPrim2(Minus, parse arg1, parse arg2)
    | [Atom("*"); arg1; arg2] -> EPrim2(Times, parse arg1, parse arg2)
    | [Atom("let"); List(bindings); body] -> ELet(parse_binding bindings, parse body)
    | _ -> failwith "Invalid syntax"

and parse_binding binding =
  match binding with
  | [] -> []
  | List([Atom(var); expr]) :: rest -> (var, parse expr) :: parse_binding rest
  | _ -> failwith "Invalid syntax"

open Sexplib.Sexp
module Sexp = Sexplib.Sexp
open Expr

let boa_max = int_of_float(2.**62.) - 1;;
let boa_min = -int_of_float(2.**62.);;
let valid_id_regex = Str.regexp "[a-zA-Z][a-zA-Z0-9]*"
let number_regex = Str.regexp "^[+-]?[0-9]+"
let reserved_words = ["let"; "add1"; "sub1"; "isNum"; "isBool"; "if"; "set"; "while"]
let reserved_constants = ["true"; "false"; ]
let int_of_string_opt s =
  try Some(int_of_string s) with
  | _ -> None

let validate_id_opt s =
  match s with
  | _ when List.mem s reserved_words -> failwith "Invalid syntax: keywords can't be variables"
  | _ when Str.string_match number_regex s 0 -> failwith "Invalid syntax: cannot assign to constant number"
  | _ when List.mem s reserved_constants -> None
  | _ when Str.string_match valid_id_regex s 0 -> Some(s)
  | _ -> failwith "Invalid syntax: invalid variable name"

let rec parse (sexp : Sexp.t) =
  match sexp with
  | Atom(x) -> begin match int_of_string_opt x with
      | Some(i) -> ENumber(i)
      | None -> begin match x with
          | _ when Str.string_match number_regex x 0 -> failwith "Non-representable number"
          | _ -> begin match validate_id_opt x with
              | Some(id) -> EId(id)
              | None when x = "true"-> EBool(true)
              | None when x = "false" -> EBool(false)
              | None -> failwith "Invalid syntax: identifier"
            end
        end
    end
  | List([Atom("if"); p; c; a]) -> EIf(parse p, parse c, parse a)
  | List([Atom(op); arg]) -> EPrim1(
    begin match op with
      | "add1" -> Add1
      | "sub1" -> Sub1
      | "isBool" -> IsBool
      | "isNum" -> IsNum
      | _ -> failwith "Invalid syntax: unknown unary operator"
    end, parse arg)
  | List([Atom("set"); Atom(var); arg]) -> ESet(var, parse arg)
  | List(Atom("let") :: List(bindings) :: body) -> ELet(parse_binding bindings, parse_body body)
  | List(Atom("while") :: cond :: body) -> EWhile(parse cond, parse_body body)
  | List([Atom(op); arg1; arg2]) -> EPrim2(
    begin match op with
      | "+" -> Plus
      | "-" -> Minus
      | "*" -> Times
      | "<" -> Less
      | ">" -> Greater
      | "==" -> Equal
      | _ -> failwith "Invalid syntax: unknown binary operator"
    end, parse arg1, parse arg2)
  | _ -> failwith "Invalid syntax: invalid expression"
    
and parse_binding binding =
  match binding with
  | [] -> []
  | List([Atom(x); value])::rest -> begin match validate_id_opt x with
      | Some(_) -> (x, parse value)::parse_binding rest
      | None -> failwith "Invalid syntax: cannot assign to constant words"
    end
  | _ -> failwith "Invalid syntax: bindings must contain 2 elements"

and parse_body body =
  match body with
  | [] -> []
  | [e] -> [parse e]
  | e::rest -> (parse e)::(parse_body rest)

  (* let rec parse_program sexps =
  match sexps with
  | [] -> failwith "Invalid: Empty program"
  | [e] -> ([], parse e)
  | e::es ->
     let parse_e = (parse_def e) in
     let defs, main = parse_program es in
     parse_e::defs, main *)
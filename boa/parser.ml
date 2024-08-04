open Sexplib.Sexp
module Sexp = Sexplib.Sexp
open Expr

let boa_max = int_of_float(2.**62.) - 1;;
let boa_min = -int_of_float(2.**62.);;
let valid_id_regex = Str.regexp "[a-zA-Z][a-zA-Z0-9]*"
let number_regex = Str.regexp "^[-]?[0-9]+"
let reserved_words = ["let"; "add1"; "sub1"; "isNum"; "isBool"; "if"]
let reserved_constants = ["true"; "false"; ]
let int_of_string_opt s =
  try Some(int_of_string s) with
  | _ -> None

let validate_number i =
  if i <= boa_max && i >= boa_min then ENumber(i) else failwith "Non-representable number"
    
let rec parse (sexp : Sexp.t) =
  match sexp with
  | Atom(x) -> 
      (match int_of_string_opt x with
      | Some(i) -> validate_number i
      | None ->
          (match x with
          | _ when List.mem x reserved_words -> failwith "Invalid syntax: lone keyword"
          | _ when List.mem x reserved_constants ->
              (match x with
              | "true" -> EBool(true)
              | "false" -> EBool(false)
              | _ -> failwith "Unexpected error"
              )
          | _ when Str.string_match valid_id_regex x 0 -> EId(x)
          | _ when Str.string_match number_regex x 0 -> failwith "Non-representable number"
          | _ -> failwith "Invalid syntax: identifier"
          )
      )
  | List([Atom("let"); List(bindings); body]) -> ELet(parse_binding bindings, parse body)
  | List([Atom("if"); p; c; a]) -> EIf(parse p, parse c, parse a)
  | List([Atom(op); arg]) -> EPrim1(
      (match op with
      | "add1" -> Add1
      | "sub1" -> Sub1
      | "isBool" -> IsBool
      | "isNum" -> IsNum
      | _ -> failwith "Invalid syntax: unknown unary operator"), parse arg)
  | List([Atom(op); arg1; arg2]) -> EPrim2(
      (match op with
      | "+" -> Plus
      | "-" -> Minus
      | "*" -> Times
      | "<" -> Less
      | ">" -> Greater
      | "==" -> Equal
      | _ -> failwith "Invalid syntax: unknown binary operator"), parse arg1, parse arg2)
  | _ -> failwith "Invalid syntax: invalid expression"

and parse_binding binding =
  match binding with
  | [] -> []
  | List([Atom(x); value])::rest
    when Str.string_match valid_id_regex x 0
    -> (x, parse value)::parse_binding rest
  | _ -> failwith "Invalid syntax" 

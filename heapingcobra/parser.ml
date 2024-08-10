open Sexplib.Sexp
module Sexp = Sexplib.Sexp
open Expr

let boa_max = int_of_float(2.**62.) - 1;;
let boa_min = -int_of_float(2.**62.);;
let valid_id_regex = Str.regexp "[a-z][a-zA-Z0-9]*"
let valid_new_type_regex = Str.regexp "[A-Z][a-zA-Z0-9]*"
let number_regex = Str.regexp "^[+-]?[0-9]+"
let reserved_words = ["let"; "add1"; "sub1"; "isNum"; "isBool"; "isNull"; "if"; "set"; "while"; "def"; "print"; "index"; "array"; "null"; "type"]
let reserved_constants = ["true"; "false"]
let int_of_string_opt s =
  try Some(int_of_string s) with
  | _ -> None

let validate_id_opt s =
  match s with
  | _ when List.mem s reserved_words -> failwith "Invalid syntax: keywords can't be variables"
  | _ when Str.string_match number_regex s 0 -> failwith "Invalid syntax: cannot assign to constant number"
  | _ when List.mem s reserved_constants -> None
  | _ when Str.string_match valid_id_regex s 0 -> Some s
    | _ -> failwith "Invalid syntax: invalid variable name"

let parse_typ t = 
  match t with
  | Atom "Num" -> TNum
  | Atom "Bool" -> TBool
  | Atom "Array" -> TArray
  | Atom name when Str.string_match valid_new_type_regex name 0 -> TName(name)
  | _ -> failwith "Invalid type."

let parse_prim1 op =
  match op with
  | "add1" -> Some Add1
  | "sub1" -> Some Sub1
  | "isBool" -> Some IsBool
  | "isNum" -> Some IsNum
  | "isNull" -> Some IsNull
  | "print" -> Some Print
  (* One argument function *)
  | _ -> None

let parse_prim2 op =
  match op with
  | "+" -> Some Plus
  | "-" -> Some Minus
  | "*" -> Some Times
  | "<" -> Some Less
  | ">" -> Some Greater
  | "==" -> Some Equal
  | "~=" -> Some StructEqual
  (* Two argument function *)
  | _ -> None

let rec parse (sexp : Sexp.t) =
  match sexp with
  (* Atom *)
  | Atom x -> begin match int_of_string_opt x with
      | Some i -> ENumber i
      | None -> begin match x with
          | _ when Str.string_match number_regex x 0 -> failwith "Non-representable number"
          | _ -> begin match validate_id_opt x with
              | Some id -> EId id
              | None when x = "true"-> EBool true
              | None when x = "false" -> EBool false
              | None -> failwith "Invalid syntax: identifier"
            end
        end
    end
  (* List with 2 elements *)
  | List [Atom "null"; t] -> ENull(parse_typ t)
  | List [Atom "array"; len] -> EArray(parse len)
  | List [Atom op; arg] -> begin match parse_prim1 op with 
      | None -> EApp(op, [parse arg])
      | Some prim -> EPrim1(prim, parse arg)
    end
  (* List with 3 elements *)
  | List [Atom "set"; Atom(var); arg] -> ESet(var, parse arg)
  | List((Atom "let") :: List bindings :: body) -> ELet(parse_binding bindings, parse_body body)
  | List(Atom "while" :: cond :: body) -> EWhile(parse cond, parse_body body)
  | List [Atom "index"; arr; i] -> EIndex(parse arr, parse i)
  | List [Atom op; arg1; arg2] -> begin match parse_prim2 op with
      | None -> EApp(op, [parse arg1; parse arg2])
      | Some prim -> EPrim2(prim, parse arg1, parse arg2)
    end
  (* List with 4 elements *)
  | List [Atom "if"; p; c; a] -> EIf(parse p, parse c, parse a)
  | List [Atom "set"; arr; i; value] -> ESetIndex(parse arr, parse i, parse value)
  (* List with n elements *)
  | List(Atom f :: args) -> begin match validate_id_opt f with
      | None -> failwith "Invalid function name."
      | _ -> EApp(f, List.map parse args)
    end
  | _ -> failwith "Invalid syntax: invalid expression"

and parse_binding binding =
  match binding with
  | [] -> []
  | List [Atom(x); value] ::rest -> begin match validate_id_opt x with
      | Some _ -> (x, parse value)::parse_binding rest
      | None -> failwith "Invalid syntax: cannot assign to constant words"
    end
  | _ -> failwith "Invalid syntax: bindings must contain 2 elements"

and parse_body (body : Sexp.t list) =
  match body with
  | [] -> []
  | [e] -> [parse e]
  | e :: rest -> (parse e)::(parse_body rest)

and parse_def sexp =
  match sexp with
  | List (Atom "def" :: Atom f :: List args :: Atom ":" :: return_typ :: body) ->
    begin match validate_id_opt f, parse_typ return_typ, body with
      | None, _, _ -> failwith ("Invalid function name " ^ f)
      | _, _, [] -> failwith "Invalid: Empty body"
      | _, parsed_t, _ -> DFun(f, parse_arg args, parsed_t, parse_body body)
    end
  | List([Atom "type"; Atom alias; actual_typ]) ->
    if Str.string_match valid_new_type_regex alias 0
      then DType(alias, parse_typ actual_typ)
    else failwith ("Invalid type name " ^ alias)
  | _ -> failwith "Invalid definition."

and parse_arg arg =
  match arg with
  | [] -> []
  | Atom(x) :: Atom(":") :: t :: rest -> begin match validate_id_opt x, parse_typ t with
      | Some(_), parsed_t -> (x, parsed_t)::parse_arg rest
      | _ -> failwith "Invalid argument name."
    end
  | _ -> failwith "Invalid argument syntax."

let rec parse_program sexps =
  match sexps with
  | [] -> failwith "Invalid: Empty program"
  | [e] -> ([], parse e)
  | e::es ->
     let parse_e = (parse_def e) in
     let defs, main = parse_program es in
     parse_e::defs, main

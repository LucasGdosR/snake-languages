type prim1 =
  | Add1
  | Sub1
  | IsNum  (* binary ends with 1 *)
  | IsBool (* binary ends with 10 *)
  | IsNull (* binary ends with 100 *)
  | Print

type prim2 =
  | Plus
  | Minus
  | Times
  | Less
  | Greater
  | Equal
  | StructEqual

(* typ syntax: "Num", "Bool", "(Array typ)"*)
(* (def get_index_3 (arr : (Array Num)) : Num (index arr 3)) *)
(* (def get_index_3 (arr : (Array (Array Num))) : Num (index arr 3)) *)
type typ =
  | TNum
  | TBool
  | TArray (*of typ - the PA specifies it should take different types *)
  | TName of string (* this is just an alias for an existing type *)
  | TUnknown

type expr =
  | ELet of (string * expr) list * expr list
  | EWhile of expr * expr list
  | ESet of string * expr
  | EIf of expr * expr * expr
  | EId of string
  | ENumber of int
  | EBool of bool
  | EPrim1 of prim1 * expr
  | EPrim2 of prim2 * expr * expr
  | EApp of string * expr list
  (* (array Num (+ 1 2)) 
     (array Bool id)
     Nevermind, spec says arrays should accept different types *)
  | EArray of expr
  | EIndex of expr * expr
  (* (set arr i val) *)
  | ESetIndex of expr * expr * expr
  (* (null Num) *)
  | ENull of typ

type def =
  | DFun of string * (string * typ) list * typ * expr list
  (* typ list for many fields, maybe? *)
  | DType of string * typ (* list *)

type prog = def list * expr

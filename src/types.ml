type action =
  | Left
  | Right

type transition = {
  read : char;
  to_state : string;
  write : char;
  action : action;
}

type machine = {
  name : string;
  alphabet : char list;
  blank : char;
  states : string list;
  initial : string;
  finals : string list;
  transitions : (string * transition list) list;
}

(* Symbols to the left of the head are stored in reverse order. *)
type tape = {
  left : char list;
  current : char;
  right : char list;
}

type step_res =
  | Halted of tape
  | Blocked of string * tape
  | Continue of string * tape * transition

(* Trace output is either plain text or ANSI-colored text. *)
type style =
  | Plain
  | Color

(* The trace can be written to stdout or to a file. *)
type sink =
  | Stdout
  | File of string

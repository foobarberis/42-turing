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

(* Tape representation *)
type tape = {
	left : char list;			(* Symbols to the left of the head, in reverse order *)
	current : char;				(* Symbol under the head *)
	right : char list;		(* Symbols to the right of the head *)
}

(* Execution result variant types *)
type step_res =
  | Halted of tape
  | Blocked of string * tape
  | Continue of string * tape * transition
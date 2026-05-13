open Execute
open Types

(* Example machine definition *)
let machine : machine = {
	name = "mcn";
	alphabet = ['0'; '1'];
	blank = '_';
	initial = "q0";
	states = ["q0"; "q1"];
	finals = ["q1"];
	transitions = [
		( "q0", [
			{read = '0'; to_state = "q0"; write = '0'; action = Right};
			{read = '1'; to_state = "q1"; write = '1'; action = Right};
			{read = '_'; to_state = "q1"; write = '_'; action = Right}
		]);
		( "q1", [
			{read = '0'; to_state = "q1"; write = '0'; action = Right};
			{read = '1'; to_state = "q1"; write = '1'; action = Right};
			{read = '_'; to_state = "q1"; write = '_'; action = Right}
		])
	]
}

(* Initial tape value *)
let tape_value : tape = {
	left = [];
	current = '0';
	right = ['0'; '1'; '0'];
}

(* Run the machine *)
let test () =
 		let result = execute machine tape_value machine.initial in
		match result with
		| Halted _ -> true
		| Blocked _ -> false
		| Continue _ -> false

let () =
  if test () then
    print_endline "OK"
  else
    print_endline "FAIL"


(*********************************************************************************
[<1>11-11=.............] (scanright, 1) -> (scanright, 1, RIGHT)
[1<1>1-11=.............] (scanright, 1) -> (scanright, 1, RIGHT)
[11<1>-11=.............] (scanright, 1) -> (scanright, 1, RIGHT)
[111<->11=.............] (scanright, -) -> (scanright, -, RIGHT)
[111-<1>1=.............] (scanright, 1) -> (scanright, 1, RIGHT)
[111-1<1>=.............] (scanright, 1) -> (scanright, 1, RIGHT)
[111-11<=>.............] (scanright, =) -> (eraseone, ., LEFT)
[111-1<1>..............] (eraseone, 1) -> (subone, =, LEFT)
[111-<1>=..............] (subone, 1) -> (subone, 1, LEFT)
[111<->1=..............] (subone, -) -> (skip, -, LEFT)
[11<1>-1=..............] (skip, 1) -> (scanright, ., RIGHT)
[11.<->1=..............] (scanright, -) -> (scanright, -, RIGHT)
[11.-<1>=..............] (scanright, 1) -> (scanright, 1, RIGHT)
[11.-1<=>..............] (scanright, =) -> (eraseone, ., LEFT)
[11.-<1>...............] (eraseone, 1) -> (subone, =, LEFT)
[11.<->=...............] (subone, -) -> (skip, -, LEFT)
[11<.>-=...............] (skip, .) -> (skip, ., LEFT)
[1<1>.-=...............] (skip, 1) -> (scanright, ., RIGHT)
[1.<.>-=...............] (scanright, .) -> (scanright, ., RIGHT)
[1..<->=...............] (scanright, -) -> (scanright, -, RIGHT)
[1..-<=>...............] (scanright, =) -> (eraseone, ., LEFT)
[1..<->................] (eraseone, -) -> (HALT, ., LEFT)*)
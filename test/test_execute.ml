open Execute
open Types

(* Example machine definition *)
let machine_1 : machine = {
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
let tape_value_1 : tape = {
	left = [];
	current = '0';
	right = ['0'; '1'; '0'];
}

(* "name" : "unary_sub",
"alphabet": [ "1", ".", "-", "=" ],
"blank" : ".",
"states" : [ "scanright", "eraseone", "subone", "skip", "HALT" ],
"initial" : "scanright",
"finals" : [ "HALT" ],
"transitions" : {
"scanright": [
{ "read" : ".", "to_state": "scanright", "write": ".", "action": "RIGHT"},
{ "read" : "1", "to_state": "scanright", "write": "1", "action": "RIGHT"},
{ "read" : "-", "to_state": "scanright", "write": "-", "action": "RIGHT"},
{ "read" : "=", "to_state": "eraseone" , "write": ".", "action": "LEFT" }
],
"eraseone": [
{ "read" : "1", "to_state": "subone", "write": "=", "action": "LEFT"},
{ "read" : "-", "to_state": "HALT" , "write": ".", "action": "LEFT"}
],
"subone": [
{ "read" : "1", "to_state": "subone", "write": "1", "action": "LEFT"},
{ "read" : "-", "to_state": "skip" , "write": "-", "action": "LEFT"}
],
"skip": [
{ "read" : ".", "to_state": "skip" , "write": ".", "action": "LEFT"},
{ "read" : "1", "to_state": "scanright", "write": ".", "action": "RIGHT"} *)
let machine_2 : machine = {
	name = "unary_sub";
	alphabet = ['1'; '.'; '-'; '='];
	blank = '.';
	initial = "scanright";
	states = ["scanright"; "eraseone"; "subone"; "skip"; "HALT"];
	finals = ["HALT"];
	transitions = [
		( "scanright", [
			{ read = '.'; to_state = "scanright"; write = '.'; action = Right };
			{ read = '1'; to_state = "scanright"; write = '1'; action = Right };
			{ read = '-'; to_state = "scanright"; write = '-'; action = Right };
			{ read = '='; to_state = "eraseone"; write = '.'; action = Left }
		]);
		( "eraseone", [
			{ read = '1'; to_state = "subone"; write = '='; action = Left };
			{ read = '-'; to_state = "HALT"; write = '.'; action = Left }
		]);
		( "subone", [
			{ read = '1'; to_state = "subone"; write = '1'; action = Left };
			{ read = '-'; to_state = "skip"; write = '-'; action = Left }
		]);
		( "skip", [
			{ read = '.'; to_state = "skip"; write = '.'; action = Left };
			{ read = '1'; to_state = "scanright"; write = '.'; action = Right }
		])
	]
}

(* 111-11 *)
(* Initial tape value *)
let tape_value_2 : tape = {
	left = [];
	current = '1';
	right = ['1'; '1'; '-'; '1'; '1'; '='];
}

(* Run the machine *)
let test () =
 		(*let result = execute machine_1 tape_value_1 machine_1.initial in*)
		let result = execute machine_2 tape_value_2 machine_2.initial in
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
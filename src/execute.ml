open Types

(* Writes a symbol to the tape at the current head position
*)
let write  _symbol _tape =
	let new_tape = { _tape with current = _symbol } in
	new_tape

(* ========================= TAPE MOVEMENT HELPERS =====================
*)
let move_left _tape =
	let new_tape = match _tape with
	| { left = []; current; right } ->
		{ left = []; current =  '0'(*TODO change to blank symbol*); right = current :: right }
	| { left = x :: xs; current; right } ->
		{ left = xs; current = x; right = current :: right } in
		new_tape

let move_right _tape = 
	let new_tape = match _tape with
	| { left; current; right = [] } ->
		{ left = current :: left; current =  '0' (*TODO change to blank symbol*); right = [] }
	| { left; current; right = x :: xs } ->
		{ left = current :: left; current = x; right = xs } in
		new_tape

(* Moves the tape head one position in the given direction
*)
let move _direction _tape =
	let new_tape = match _direction with
		| Left -> move_left _tape
		| Right -> move_right _tape
	in new_tape

(* ========== TRANSITION LOOKUP ==========
 *)

(* Finds the transition rule for the given state and symbol
*)
let find_transition _state _symbol _machine =
	let transition = match _machine.transitions with
		| (from_state, transitions) :: _ when from_state = _state ->
			List.find_opt (fun t -> t.read = _symbol) transitions
		| _ :: rest -> None 
		| [] -> None
		in transition

let execute_transition _transition _tape =
	let tape_after_write = write _transition.write _tape 
	in let new_tape = move _transition.action tape_after_write 
	in new_tape

(* ========== PRINTING FUNCTIONS ==========
*)
let string_of_char lst =
	String.concat "" (List.map (String.make 1) lst)

let string_of_transition _transition = 
	"(" 
	^ String.make 1 _transition.read 
	^ " -> " 
	^ _transition.to_state 
	^ ", " 
	^ String.make 1 _transition.write ^ ", " 
	^ (match _transition.action with Left -> "LEFT" | Right -> "RIGHT") ^ ")"

let tape_to_string _tape = 
	"[" 
	^ string_of_char  _tape.left 
	^ "<" 
	^ String.make 1 _tape.current 
	^ ">" 
	^ string_of_char  _tape.right 
	^ "]"

let print_step _state _tape _transition =
	Printf.printf "%s %s\n"(string_of_transition _transition) (tape_to_string _tape)

(* ========== SINGLE EXECUTION STEP ==========
   Performs one complete step of machine execution:
   1. Read current symbol from tape
   2. Look up transition rule for (state, symbol)
   3. If found: write new symbol, move head, transition to new state
   4. If not found: machine is blocked (no matching transition)
========== *)

(* Executes a single step of the Turing machine
*)
let step _machine _state _tape =
	let current_symbol = _tape.current in
	match find_transition _state current_symbol _machine with
	| Some _transition ->
		let new_tape = execute_transition _transition _tape in
		Continue(_transition.to_state, new_tape, _transition)
	| None -> Blocked(_state, _tape)

(* ========== MAIN EXECUTION LOOP ==========
   Runs the machine until it reaches a final state or gets blocked
   Recursively executes steps until a halt condition is met
========== *)

(* Runs the machine from the current state and tape until halting
*)
let rec execute _machine _tape _state =
	if List.mem _state _machine.finals then
		Halted(_tape)
	else
		match step _machine _state _tape with
		| Continue(new_state, new_tape, _transition) -> 
			print_step _state _tape _transition;
			execute _machine new_tape new_state
		| Blocked(_state, _tape) -> Blocked(_state, _tape)

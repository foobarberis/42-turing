open Types

(* Writes a symbol to the tape at the current head position
*)
let write (symbol: char) (tape: tape) : tape =
	let new_tape = { tape with current = symbol } in
	new_tape

(* ========================= TAPE MOVEMENT HELPERS =====================
*)
let move_left (tape: tape) (machine : machine)=
	match tape with
	| { left = []; current; right } ->
		{ left = []; current =  machine.blank; right = current :: right }
	| { left = x :: xs; current; right } ->
		{ left = xs; current = x; right = current :: right }

let move_right (tape: tape) (machine: machine) : tape = 
	match tape with
	| { left; current; right = [] } ->
		{ left = current :: left; current =  machine.blank ; right = [] }
	| { left; current; right = x :: xs } ->
		{ left = current :: left; current = x; right = xs }

(* Moves the tape head one position in the given direction
*)
let move (action: action) (tape: tape) (machine: machine): tape =
	 match action with
		| Left -> move_left tape machine
		| Right -> move_right tape machine

(* ========== TRANSITION LOOKUP ==========
 *)

(* Finds the transition rule for the given state and symbol
*)
let find_transition (state: string) (symbol: char) (machine: machine)  : transition option =
	match List.assoc_opt state machine.transitions with
	| None -> None
	| Some transitions ->
		match List.find_opt (fun t -> t.read = symbol) transitions with
		| Some transition -> Some transition
		| None -> None

let execute_transition (transition: transition) (tape: tape) (machine: machine): tape =
	let new_tap = write transition.write tape in move transition.action new_tap machine

(* ========== PRINTING FUNCTIONS ==========
*)
let string_of_char lst =
	String.concat "" (List.map (String.make 1) lst)

let string_of_transition (state: string) (transition: transition): string = 
	"(" 
	^ state
	^ ", "
	^ String.make 1 transition.read 
	^ ") -> (" 
	^ transition.to_state 
	^ ", " 
	^ String.make 1 transition.write ^ ", " 
	^ (match transition.action with Left -> "LEFT" | Right -> "RIGHT") ^ ")"

let tape_to_string (tape: tape) (machine: machine) : string = 
	"[" 
	^  string_of_char (List.rev tape.left) 
	^ "<" 
	^ String.make 1 tape.current 
	^ ">" 
	^ match string_of_char  tape.right with
	| s when String.length s + (List.length tape.left)  + 1 > 20 -> s
	| s -> s ^ String.make (20 - String.length s - (List.length tape.left) - 1) machine.blank
	^ "]"

let print_step (state: string) (tape: tape) (transition: transition) (machine: machine) =
	Printf.printf "%s %s\n"(tape_to_string tape machine) (string_of_transition state transition) 

(* ========== SINGLE EXECUTION STEP ==========
   Performs one complete step of machine execution:
   1. Read current symbol from tape
   2. Look up transition rule for (state, symbol)
   3. If found: write new symbol, move head, transition to new state
   4. If not found: machine is blocked (no matching transition)
========== *)

(* Executes a single step of the Turing machine
*)
let step (machine: machine) (state: string) (tape: tape) =
	let current_symbol = tape.current in
	match find_transition state current_symbol machine with
	| Some transition ->
		let new_tape = execute_transition transition tape machine in
		Continue(transition.to_state, new_tape, transition)
	| None ->
		if List.mem state machine.finals then
			Halted(tape)
		else
			 Blocked(state, tape)

(* ========== MAIN EXECUTION LOOP ==========
   Runs the machine until it reaches a final state or gets blocked
   Recursively executes steps until a halt condition is met
========== *)

(* Runs the machine from the current state and tape until halting
*)
let rec execute (machine: machine) (tape: tape) (state: string)  =
	if List.mem state machine.finals then
		Halted(tape)
	else
		match step machine state tape with
		| Continue(new_state, new_tape, transition) -> 
			print_step state tape transition machine; (*TODO change to log*)
			execute machine new_tape new_state
		| Blocked(state, tape) -> Blocked(state, tape)
		| Halted(tape) -> Halted(tape)

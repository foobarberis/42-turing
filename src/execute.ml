open Types

(*Writes a symbol to the tape at the current head position
	@param symbol the symbol to write
	@param tape the current tape*)
let write (symbol: char) (tape: tape) : tape =
	{ tape with current = symbol }

(*Moves the tape head one position in the given direction
	@param action the direction to move
	@param m current machine
	@param tape current tape*)
let move (action: action) (m: machine) (tape: tape): tape =
	match action, tape with
		| Left, {left = []; current; right} ->
			{left = []; current =  m.blank; right = current :: right}
		| Left, { left = x :: xs; current; right} ->
			{left = xs; current = x; right = current :: right}
		| Right, { left; current; right = []} ->
			{left = current :: left; current =  m.blank ; right = []}
		| Right,  { left; current; right = x :: xs} ->
			{left = current :: left; current = x; right = xs}

(*Finds the transition rule for the given state and symbol
	@param state actual state of the machine
	@param symbol current symbol under the tape head
	@param m current machine*)
let find_transition (state: string) (symbol: char) (m: machine)  : transition option =
	match List.assoc_opt state m.transitions with
	| Some transitions -> List.find_opt (fun t -> t.read = symbol) transitions
	| None -> None

(*Execute a transition on the tape, Writing the new symbol and moving the head
	@param transition transition to execute
	@param tape current tape
	@param m current machine*)
let execute_transition (transition: transition) (tape: tape) (m: machine): tape =
	tape
	|> write transition.write 
	|> move transition.action m

(* Executes a single step of the Turing machine
	@param state actual state of the machine
	@param tape current tape
	@param m current machine*)
let step (state: string) (tape: tape) (m: machine): step_res =
	let current_symbol = tape.current in
	match find_transition state current_symbol m with
	| Some transition ->
		let new_tape = execute_transition transition tape m in
		Continue(transition.to_state, new_tape, transition)
	| None ->
		if List.mem state m.finals then
			Halted(tape)
		else
			 Blocked(state, tape)

(* Runs the machine from the current state and tape until halting
	@param m current machine
	@param tape current tape
	@param state actual state of the machine
	@param out file descriptor for logging*)
let rec execute (m: machine) (tape: tape) (state: string) (out: out_channel): step_res  =
	match step state tape m with
	| Continue(new_state, new_tape, transition) -> Trace.step_info (Continue(state, tape, transition)) m out;
		execute m new_tape new_state out
	| Blocked(new_state, new_tape) -> Blocked(new_state, new_tape)
	| Halted(new_tape) -> Halted(new_tape)

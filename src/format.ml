open Types

(*transforme list of char to one string
	@param lst current list*)
let string_of_char_list (lst: char list): string =
	String.concat "" (List.map (String.make 1) lst)

(*make a header for machine log
	@param m_name machine name*)	
let string_of_header (m_name: string) : string =
	String.make 80 '*' ^ "\n"
	^ "*" ^ String.make 78 ' ' ^ "*\n"
	^ "*" ^ String.make (39 - String.length m_name/2) ' ' ^ m_name ^ String.make (39 - String.length m_name/2 - 1) ' ' ^ "*\n"
	^ "*" ^ String.make 78 ' ' ^ "*\n"
	^ String.make 80 '*' 

(*transform machine info to one string
	@param m current machine*)
let string_of_machine_header (m: machine) : string =
	"Alphabet: " ^ "[" ^ String.concat "; " (List.map (String.make 1) m.alphabet) ^ "]\n"
	^ "Blank: " ^ String.make 1 m.blank ^ "\n"
	^ "States: " ^ "[" ^ String.concat "; " m.states ^ "]\n"
	^ "Initial: " ^ m.initial ^ "\n"
	^ "Finals: "  ^ "[" ^ String.concat "; " m.finals ^ "]"

(*transform one transition to one string 
	@param state actual state of the machine
	@param t actual transition of the machine*)
let string_of_transition (state: string) (t: transition): string = 
	"(" 
	^ state
	^ ", "
	^ String.make 1 t.read 
	^ ") -> (" 
	^ t.to_state 
	^ ", " 
	^ String.make 1 t.write ^ ", " 
	^ (match t.action with Left -> "LEFT" | Right -> "RIGHT") 
  ^ ")"

(*transform all transitions rules of the machine to one string
	@param states list of all states of the current machine
	@param ts transititons of the current machine*)
let string_of_machine_transitions (states: string list) (ts: (string * transition list) list ) : string = 
	(List.concat_map  (fun state ->
		 match List.assoc_opt state ts with
			| None -> []
			| Some ltr ->
				List.map (string_of_transition state) ltr) states
		|> String.concat "\n")
	^ "\n" ^ String.make 80 '*'

(*transform tape info to one string
	@param tape current tape
	@param m current machine*)
let string_of_tape (tape: tape) (m: machine) : string = 
	"[" 
	^  string_of_char_list  (List.rev tape.left) 
	^ "<" 
	^ String.make 1 tape.current 
	^ ">" 
	^ match string_of_char_list   tape.right with
		| s when String.length s + (List.length tape.left)  + 1 > 20 -> s ^ "]"
		| s -> s ^ String.make (20 - String.length s - (List.length tape.left) - 1) m.blank
	^ "]"

(*transform machine info to one string
	@param m current machine*)
let string_of_machine(m: machine) : string = 
	string_of_machine_header m
	^ "\n"
	^ string_of_machine_transitions m.states m.transitions

(*transform machine info to one string
	@param Continue info of the current step
	@param m current machine*)
let string_of_step (res: step_res) (m: machine) : string =
	match res with
		| Continue(state, tape, transition) -> string_of_tape tape m ^ " " ^ string_of_transition state transition
		| Halted(tape) -> string_of_tape tape m
		| Blocked(state, tape) -> string_of_tape tape m ^ "Blocked at this state " ^ state

(*Transform String to tape
	@Param str string convert*)
let tape_of_string ?(blank = ' ') (str: string): tape = 
	match List.of_seq(String.to_seq str) with
		| x :: xs -> {left = [];  current = x; right = xs}
		| [] -> {left = [];  current = blank; right = []}

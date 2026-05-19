open Types

(* Write a symbol at the current head position. *)
let write (symbol : char) (tape : tape) : tape =
  { tape with current = symbol }

(* Move the tape head one cell left or right. *)
let move (action : action) (m : machine) (tape : tape) : tape =
  match action, tape with
  | Left, { left = []; current; right } ->
      { left = []; current = m.blank; right = current :: right }
  | Left, { left = x :: xs; current; right } ->
      { left = xs; current = x; right = current :: right }
  | Right, { left; current; right = [] } ->
      { left = current :: left; current = m.blank; right = [] }
  | Right, { left; current; right = x :: xs } ->
      { left = current :: left; current = x; right = xs }

(* Find the transition for the current state and symbol. *)
let find_transition (state : string) (symbol : char) (m : machine) : transition option =
  match List.assoc_opt state m.transitions with
  | Some transitions -> List.find_opt (fun t -> t.read = symbol) transitions
  | None -> None

(* Apply one transition to the tape. *)
let execute_transition (transition : transition) (tape : tape) (m : machine) : tape =
  tape
  |> write transition.write
  |> move transition.action m

(* Execute one machine step. *)
let step (state : string) (tape : tape) (m : machine) : step_res =
  let current_symbol = tape.current in
  match find_transition state current_symbol m with
  | Some transition ->
      let new_tape = execute_transition transition tape m in
      Continue (transition.to_state, new_tape, transition)
  | None ->
      if List.mem state m.finals then
        Halted tape
      else
        Blocked (state, tape)

(* Run the machine until it halts or blocks. *)
let rec execute (m : machine) (tape : tape) (state : string) (style : style) (out : out_channel) : step_res =
  if List.mem state m.finals then
    Halted tape
  else
    match step state tape m with
    | Continue (new_state, new_tape, transition) ->
        Trace.step_info (Continue (state, tape, transition)) m style out;
        execute m new_tape new_state style out
    | Blocked (new_state, new_tape) -> Blocked (new_state, new_tape)
    | Halted new_tape -> Halted new_tape

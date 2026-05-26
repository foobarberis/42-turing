open Types

let color_prefix = "\027[1;38;2;183;58;52m"
let color_suffix = "\027[0m"

(* Convert a character list to a string. *)
let string_of_char_list (lst : char list) : string =
  String.concat "" (List.map (String.make 1) lst)

(* Build the machine header banner. *)
let string_of_header (m_name : string) : string =
  String.make 80 '*'
  ^ "\n"
  ^ "*"
  ^ String.make 78 ' '
  ^ "*\n"
  ^ "*"
  ^ String.make (39 - String.length m_name / 2) ' '
  ^ m_name
  ^ String.make (39 - String.length m_name / 2 - 1) ' '
  ^ "*\n"
  ^ "*"
  ^ String.make 78 ' '
  ^ "*\n"
  ^ String.make 80 '*'

(* Render the machine metadata. *)
let string_of_machine_header (m : machine) : string =
  "Alphabet: ["
  ^ String.concat "; " (List.map (String.make 1) m.alphabet)
  ^ "]\n"
  ^ "Blank: "
  ^ String.make 1 m.blank
  ^ "\n"
  ^ "States: ["
  ^ String.concat "; " m.states
  ^ "]\n"
  ^ "Initial: "
  ^ m.initial
  ^ "\n"
  ^ "Finals: ["
  ^ String.concat "; " m.finals
  ^ "]"

(* Render one transition. *)
let string_of_transition (state : string) (t : transition) : string =
  "("
  ^ state
  ^ ", "
  ^ String.make 1 t.read
  ^ ") -> ("
  ^ t.to_state
  ^ ", "
  ^ String.make 1 t.write
  ^ ", "
  ^ (match t.action with Left -> "LEFT" | Right -> "RIGHT")
  ^ ")"

(* Render all transitions in state order. *)
let string_of_machine_transitions (states : string list) (ts : (string * transition list) list) : string =
  let body =
    List.concat_map
      (fun state ->
        match List.assoc_opt state ts with
        | None -> []
        | Some transitions -> List.map (string_of_transition state) transitions)
      states
    |> String.concat "\n"
  in
  body ^ "\n" ^ String.make 80 '*'

(* Highlight the current tape cell. *)
let wrap_current (current : char) (style : style) : string =
  match style with
  | Color -> color_prefix ^ String.make 1 current ^ color_suffix
  | Plain -> "<" ^ String.make 1 current ^ ">"

(* Render the tape with the current head position. *)
let string_of_tape (tape : tape) (m : machine) (style : style) : string =
  let left = string_of_char_list (List.rev tape.left) in
  let right = string_of_char_list tape.right in
  let used = List.length tape.left + String.length right + 1 in
  let padded_right =
    if used > 20 then
      right
    else
      right ^ String.make (20 - used) m.blank
  in
  "[" ^ left ^ wrap_current tape.current style ^ padded_right ^ "]"

(* Render the machine description. *)
let string_of_machine (m : machine) : string =
  string_of_machine_header m ^ "\n" ^ string_of_machine_transitions m.states m.transitions

(* Render one execution step. *)
let string_of_step (res : step_res) (m : machine) (style : style) : string =
  match res with
  | Continue (state, tape, transition) ->
      string_of_tape tape m style ^ " " ^ string_of_transition state transition
  | Halted tape -> string_of_tape tape m style
  | Blocked (state, tape) -> string_of_tape tape m style ^ " Blocked at this state " ^ state

(* Convert an input string to a tape. *)
let tape_of_string ?(blank = ' ') (str : string) : tape =
  match List.of_seq (String.to_seq str) with
  | x :: xs -> { left = []; current = x; right = xs }
  | [] -> { left = []; current = blank; right = [] }

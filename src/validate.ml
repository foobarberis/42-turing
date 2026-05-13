open Types

exception Validation_error of string

let ensure condition message =
  if not condition then
    raise (Validation_error message)

let is_in x xs =
  List.mem x xs

let rec has_duplicates xs =
  match xs with
  | [] | [_] -> false
  | x :: rest -> is_in x rest || has_duplicates rest

let all_in xs allowed =
  List.for_all (fun x -> is_in x allowed) xs

let validate_alphabet alphabet =
  ensure (alphabet <> []) "alphabet must not be empty";
  ensure (not (has_duplicates alphabet)) "alphabet must not contain duplicates"

let validate_blank blank alphabet =
  ensure (is_in blank alphabet) "blank must be in alphabet"

let validate_states states =
  ensure (states <> []) "states must not be empty";
  ensure (not (has_duplicates states)) "states must not contain duplicates"

let validate_initial initial states =
  ensure (is_in initial states) "initial must be in states"

let validate_finals finals states =
  ensure (all_in finals states) "finals must be in states";
  ensure (not (has_duplicates finals)) "finals must not contain duplicates"

let validate_transition transition alphabet states =
  ensure (is_in transition.read alphabet) "transition read must be in alphabet";
  ensure (is_in transition.write alphabet) "transition write must be in alphabet";
  ensure (is_in transition.to_state states) "transition to_state must be in states"

let validate_state_transitions transitions alphabet states =
  let reads = List.map (fun transition -> transition.read) transitions in
  ensure (not (has_duplicates reads)) "transition reads must be unique within one source state";
  List.iter (fun transition -> validate_transition transition alphabet states) transitions

let validate_transitions transitions alphabet states =
  let source_states = List.map fst transitions in
  ensure (all_in source_states states) "transition source states must be in states";
  ensure (not (has_duplicates source_states)) "transition source states must be unique";
  List.iter (fun (_, state_transitions) ->
    validate_state_transitions state_transitions alphabet states) transitions

let validate_input input alphabet blank =
  let symbols = List.of_seq (String.to_seq input) in
  ensure (all_in symbols alphabet) "input symbols must be in alphabet";
  ensure (not (is_in blank symbols)) "input must not contain blank"

let validate_machine machine =
  validate_alphabet machine.alphabet;
  validate_blank machine.blank machine.alphabet;
  validate_states machine.states;
  validate_initial machine.initial machine.states;
  validate_finals machine.finals machine.states;
  validate_transitions machine.transitions machine.alphabet machine.states

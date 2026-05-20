open Types
open Format

let total = ref 0
let failed = ref 0

let fail name message =
  incr failed;
  Printf.eprintf "[unit] [%02d] FAIL %s\n  %s\n%!" !total name message

let run name f =
  incr total;
  try
    f ();
    Printf.printf "[unit] [%02d] OK %s\n%!" !total name
  with
  | Failure message -> fail name message
  | exn -> fail name (Printexc.to_string exn)

let expect condition message =
  if not condition then
    failwith message

let expect_equal expected actual message =
  expect (expected = actual) message

let border = String.make 80 '*'

let machine =
  {
    name = "fmt";
    alphabet = ['0'; '1'; '.'];
    blank = '.';
    states = ["q0"; "q1"; "HALT"];
    initial = "q0";
    finals = ["HALT"];
    transitions = [];
  }

let left_transition =
  {
    read = '0';
    to_state = "q1";
    write = '1';
    action = Left;
  }

let right_transition =
  {
    read = '1';
    to_state = "HALT";
    write = '0';
    action = Right;
  }

let machine_with_transitions =
  {
    machine with
    transitions =
      [
        ("q1", [right_transition]);
        ("HALT", []);
        ("q0", [left_transition]);
      ];
  }

let short_tape =
  {
    left = ['b'; 'a'];
    current = 'x';
    right = ['c'; 'd'];
  }

let long_tape =
  {
    left = [];
    current = 'x';
    right = List.init 25 (fun _ -> '0');
  }

let split_lines str =
  String.split_on_char '\n' str

let all_chars_are ch str =
  String.for_all (fun c -> c = ch) str

let () =
  Printf.printf "\nformat.ml\n%!";

  run "string_of_char_list concatenates characters" (fun () ->
    expect_equal "abc" (string_of_char_list ['a'; 'b'; 'c']) "unexpected string_of_char_list result");

  run "string_of_header uses 80-char borders and includes the name" (fun () ->
    let lines = split_lines (string_of_header machine.name) in
    expect_equal 5 (List.length lines) "unexpected header line count";
    expect_equal border (List.nth lines 0) "unexpected top border";
    expect_equal border (List.nth lines 4) "unexpected bottom border";
    expect (all_chars_are ' ' (String.sub (List.nth lines 1) 1 78)) "expected empty spacer line";
    expect (String.length (List.nth lines 2) = 80) "expected title line width 80";
    expect (String.contains (List.nth lines 2) 'f') "expected machine name in title line");

  run "string_of_transition renders LEFT" (fun () ->
    expect_equal
      "(q0, 0) -> (q1, 1, LEFT)"
      (string_of_transition "q0" left_transition)
      "unexpected LEFT transition rendering");

  run "string_of_transition renders RIGHT" (fun () ->
    expect_equal
      "(q1, 1) -> (HALT, 0, RIGHT)"
      (string_of_transition "q1" right_transition)
      "unexpected RIGHT transition rendering");

  run "string_of_machine renders header and transitions in state order" (fun () ->
    let expected =
      "Alphabet: [0; 1; .]\n"
      ^ "Blank: .\n"
      ^ "States: [q0; q1; HALT]\n"
      ^ "Initial: q0\n"
      ^ "Finals: [HALT]\n"
      ^ "(q0, 0) -> (q1, 1, LEFT)\n"
      ^ "(q1, 1) -> (HALT, 0, RIGHT)\n"
      ^ border
    in
    expect_equal expected (string_of_machine machine_with_transitions) "unexpected string_of_machine rendering");

  run "string_of_tape reverses left side and pads short tapes" (fun () ->
    expect_equal
      "[ab<x>cd...............]"
      (string_of_tape short_tape machine Plain)
      "unexpected short tape rendering");

  run "string_of_tape uses ANSI color in Color mode" (fun () ->
    expect_equal
      "[ab\027[1;38;2;183;58;52mx\027[0mcd...............]"
      (string_of_tape short_tape machine Color)
      "unexpected colored tape rendering");

  run "string_of_tape does not pad long tapes" (fun () ->
    expect_equal
      ("[<x>" ^ String.make 25 '0' ^ "]")
      (string_of_tape long_tape machine Plain)
      "unexpected long tape rendering");

  run "string_of_step renders Continue" (fun () ->
    expect_equal
      "[ab<x>cd...............] (q0, 0) -> (q1, 1, LEFT)"
      (string_of_step (Continue ("q0", short_tape, left_transition)) machine Plain)
      "unexpected Continue rendering");

  run "string_of_step renders Halted" (fun () ->
    expect_equal
      "[ab<x>cd...............]"
      (string_of_step (Halted short_tape) machine Plain)
      "unexpected Halted rendering");

  run "string_of_step renders Blocked" (fun () ->
    expect_equal
      "[ab<x>cd...............] Blocked at this state q0"
      (string_of_step (Blocked ("q0", short_tape)) machine Plain)
      "unexpected Blocked rendering");

  run "tape_of_string splits non-empty input" (fun () ->
    expect_equal
      { left = []; current = 'a'; right = ['b'; 'c'] }
      (tape_of_string "abc")
      "unexpected tape for non-empty input");

  run "tape_of_string uses the provided blank for empty input" (fun () ->
    expect_equal
      { left = []; current = '.'; right = [] }
      (tape_of_string ~blank:'.' "")
      "unexpected tape for empty input");

  let ok = !total - !failed in
  Printf.printf "SUMMARY: %d OK / %d FAIL\n%!" ok !failed;
  if !failed <> 0 then
    exit 1

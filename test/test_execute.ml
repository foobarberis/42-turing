open Types
open Execute

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

let expect_halted expected_tape result message =
  match result with
  | Halted tape -> expect_equal expected_tape tape message
  | Continue (state, _, _) ->
      failwith (message ^ ": expected Halted, got Continue(" ^ state ^ ")")
  | Blocked (state, _) ->
      failwith (message ^ ": expected Halted, got Blocked(" ^ state ^ ")")

let expect_blocked expected_state expected_tape result message =
  match result with
  | Blocked (state, tape) ->
      expect_equal expected_state state (message ^ ": unexpected blocked state");
      expect_equal expected_tape tape (message ^ ": unexpected blocked tape")
  | Continue (state, _, _) ->
      failwith (message ^ ": expected Blocked, got Continue(" ^ state ^ ")")
  | Halted _ ->
      failwith (message ^ ": expected Blocked, got Halted")

let expect_continue expected_state expected_tape expected_transition result message =
  match result with
  | Continue (state, tape, transition) ->
      expect_equal expected_state state (message ^ ": unexpected next state");
      expect_equal expected_tape tape (message ^ ": unexpected next tape");
      expect_equal expected_transition transition (message ^ ": unexpected transition")
  | Blocked (state, _) ->
      failwith (message ^ ": expected Continue, got Blocked(" ^ state ^ ")")
  | Halted _ ->
      failwith (message ^ ": expected Continue, got Halted")

let read_file path =
  let ic = open_in_bin path in
  try
    let len = in_channel_length ic in
    let content = really_input_string ic len in
    close_in ic;
    content
  with exn ->
    close_in_noerr ic;
    raise exn

let with_temp_out f =
  let path = Filename.temp_file "ft_turing_execute" ".log" in
  let out = open_out path in
  try
    let result = f out in
    close_out out;
    Sys.remove path;
    result
  with exn ->
    close_out_noerr out;
    (try Sys.remove path with Sys_error _ -> ());
    raise exn

let with_temp_log f =
  let path = Filename.temp_file "ft_turing_execute" ".log" in
  let out = open_out path in
  try
    let result = f out in
    close_out out;
    let content = read_file path in
    Sys.remove path;
    (result, content)
  with exn ->
    close_out_noerr out;
    (try Sys.remove path with Sys_error _ -> ());
    raise exn

let step_transition_0 =
  {
    read = '0';
    to_state = "q1";
    write = '1';
    action = Right;
  }

let step_transition_blank =
  {
    read = '.';
    to_state = "HALT";
    write = '.';
    action = Left;
  }

let step_machine =
  {
    name = "step";
    alphabet = ['0'; '1'; '.'];
    blank = '.';
    states = ["q0"; "q1"; "HALT"];
    initial = "q0";
    finals = ["HALT"];
    transitions =
      [
        ("q0", [step_transition_0]);
        ("q1", [step_transition_blank]);
        ("HALT", []);
      ];
  }

let blocked_machine =
  {
    name = "blocked";
    alphabet = ['0'; '.'];
    blank = '.';
    states = ["q0"; "HALT"];
    initial = "q0";
    finals = ["HALT"];
    transitions =
      [
        ("q0",
          [
            {
              read = '0';
              to_state = "HALT";
              write = '0';
              action = Right;
            };
          ]);
        ("HALT", []);
      ];
  }

let final_machine =
  {
    name = "final";
    alphabet = ['0'; '.'];
    blank = '.';
    states = ["HALT"];
    initial = "HALT";
    finals = ["HALT"];
    transitions = [("HALT", [])];
  }

let final_machine_with_transition =
  {
    name = "final_with_transition";
    alphabet = ['0'; '1'; '.'];
    blank = '.';
    states = ["HALT"];
    initial = "HALT";
    finals = ["HALT"];
    transitions =
      [
        ("HALT",
          [
            {
              read = '0';
              to_state = "HALT";
              write = '1';
              action = Right;
            };
          ]);
      ];
  }

let () =
  Printf.printf "\nexecute.ml\n%!";

  run "write updates current symbol" (fun () ->
    let tape = { left = ['0']; current = '1'; right = ['0'] } in
    let expected = { left = ['0']; current = 'x'; right = ['0'] } in
    expect_equal expected (write 'x' tape) "unexpected tape after write");

  run "move_left consumes left symbol" (fun () ->
    let tape = { left = ['1'; '0']; current = 'x'; right = ['y'] } in
    let expected = { left = ['0']; current = '1'; right = ['x'; 'y'] } in
    expect_equal expected (move Left step_machine tape) "unexpected tape after move_left");

  run "move_left extends blank on empty left" (fun () ->
    let tape = { left = []; current = 'x'; right = ['y'] } in
    let expected = { left = []; current = '.'; right = ['x'; 'y'] } in
    expect_equal expected (move Left step_machine tape) "unexpected tape after move_left at boundary");

  run "move_right consumes right symbol" (fun () ->
    let tape = { left = ['0']; current = 'x'; right = ['y'; 'z'] } in
    let expected = { left = ['x'; '0']; current = 'y'; right = ['z'] } in
    expect_equal expected (move Right step_machine tape) "unexpected tape after move_right");

  run "move_right extends blank on empty right" (fun () ->
    let tape = { left = ['0']; current = 'x'; right = [] } in
    let expected = { left = ['x'; '0']; current = '.'; right = [] } in
    expect_equal expected (move Right step_machine tape) "unexpected tape after move_right at boundary");

  run "find_transition returns matching rule" (fun () ->
    expect_equal
      (Some step_transition_0)
      (find_transition "q0" '0' step_machine)
      "expected to find transition");

  run "find_transition returns None for missing symbol" (fun () ->
    expect_equal None (find_transition "q0" '1' step_machine) "expected no transition");

  run "find_transition returns None for missing state" (fun () ->
    expect_equal None (find_transition "missing" '0' step_machine) "expected no transition");

  run "execute_transition writes before moving" (fun () ->
    let tape = { left = []; current = '0'; right = ['0'] } in
    let expected = { left = ['1']; current = '0'; right = [] } in
    expect_equal expected (execute_transition step_transition_0 tape step_machine) "unexpected tape after execute_transition");

  run "step returns Continue for matching rule" (fun () ->
    let tape = { left = []; current = '0'; right = [] } in
    let expected_tape = { left = ['1']; current = '.'; right = [] } in
    expect_continue "q1" expected_tape step_transition_0 (step "q0" tape step_machine) "unexpected step result");

  run "step returns Halted in final state without rule" (fun () ->
    let tape = { left = []; current = '0'; right = [] } in
    expect_halted tape (step "HALT" tape final_machine) "unexpected step result");

  run "step returns Blocked in non-final state without rule" (fun () ->
    let tape = { left = []; current = '.'; right = [] } in
    expect_blocked "q0" tape (step "q0" tape blocked_machine) "unexpected step result");

  run "execute halts immediately when initial is final" (fun () ->
    let tape = { left = []; current = '0'; right = [] } in
    let result = with_temp_out (fun out ->
      execute final_machine_with_transition tape final_machine_with_transition.initial Plain out)
    in
    expect_halted tape result "unexpected execute result");

  run "execute runs until Halted" (fun () ->
    let tape = { left = []; current = '0'; right = [] } in
    let expected_tape = { left = []; current = '1'; right = ['.'] } in
    let result = with_temp_out (fun out ->
      execute step_machine tape step_machine.initial Plain out)
    in
    expect_halted expected_tape result "unexpected execute result");

  run "execute logs each Continue step in order" (fun () ->
    let tape = { left = []; current = '0'; right = [] } in
    let expected_log =
      Format.string_of_step (Continue ("q0", tape, step_transition_0)) step_machine Plain
      ^ "\n"
      ^ Format.string_of_step
          (Continue ("q1", { left = ['1']; current = '.'; right = [] }, step_transition_blank))
          step_machine
          Plain
      ^ "\n"
    in
    let _, log = with_temp_log (fun out ->
      execute step_machine tape step_machine.initial Plain out)
    in
    expect_equal expected_log log "unexpected execute trace");

  run "execute returns Blocked when machine gets stuck" (fun () ->
    let tape = { left = []; current = '.'; right = [] } in
    let result = with_temp_out (fun out ->
      execute blocked_machine tape blocked_machine.initial Plain out)
    in
    expect_blocked "q0" tape result "unexpected execute result");

  let ok = !total - !failed in
  Printf.printf "SUMMARY: %d OK / %d FAIL\n%!" ok !failed;
  if !failed <> 0 then
    exit 1

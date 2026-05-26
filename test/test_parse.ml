open Types
open Parse

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

let expect_parse_error f =
  try
    let _ = f () in
    failwith "expected Parse_error"
  with
  | Parse_error _ -> ()

let transitions_for state machine =
  match List.assoc_opt state machine.transitions with
  | Some transitions -> transitions
  | None -> failwith ("missing state transitions: " ^ state)

let () =
  Printf.printf "parse.ml\n%!";
  run "parse_action LEFT" (fun () ->
    expect_equal Left (parse_action (`String "LEFT")) "expected Left");

  run "parse_action RIGHT" (fun () ->
    expect_equal Right (parse_action (`String "RIGHT")) "expected Right");

  run "parse_action rejects invalid value" (fun () ->
    expect_parse_error (fun () -> parse_action (`String "UP")));

  run "parse_action rejects non-string" (fun () ->
    expect_parse_error (fun () -> parse_action (`List [])));

  run "as_char parses one character" (fun () ->
    expect_equal '1' (as_char (`String "1")) "expected '1'");

  run "as_char rejects long strings" (fun () ->
    expect_parse_error (fun () -> as_char (`String "ab")));

  run "parse_transition parses one object" (fun () ->
    let json =
      `Assoc [
        ("read", `String "1");
        ("to_state", `String "q1");
        ("write", `String "0");
        ("action", `String "RIGHT");
      ]
    in
    let expected =
      {
        read = '1';
        to_state = "q1";
        write = '0';
        action = Right;
      }
    in
    expect_equal expected (parse_transition json) "unexpected transition");

  run "parse_transition rejects missing field" (fun () ->
    let json =
      `Assoc [
        ("read", `String "1");
        ("to_state", `String "q1");
        ("write", `String "0");
      ]
    in
    expect_parse_error (fun () -> parse_transition json));

  run "parse_transitions parses state transition lists" (fun () ->
    let json =
      `Assoc [
        ("transitions",
          `Assoc [
            ("q0",
              `List [
                `Assoc [
                  ("read", `String "0");
                  ("to_state", `String "q0");
                  ("write", `String "0");
                  ("action", `String "RIGHT");
                ];
                `Assoc [
                  ("read", `String ".");
                  ("to_state", `String "HALT");
                  ("write", `String ".");
                  ("action", `String "LEFT");
                ];
              ]);
            ("HALT", `List []);
          ]);
      ]
    in
    let expected =
      [
        ("q0",
          [
            {
              read = '0';
              to_state = "q0";
              write = '0';
              action = Right;
            };
            {
              read = '.';
              to_state = "HALT";
              write = '.';
              action = Left;
            };
          ]);
        ("HALT", []);
      ]
    in
    expect_equal expected (parse_transitions json) "unexpected transitions");

  run "load_json rejects missing file" (fun () ->
    expect_parse_error (fun () -> load_json "test/fixtures/parse/missing.json"));

  run "load_json rejects malformed syntax" (fun () ->
    expect_parse_error (fun () -> load_json "test/fixtures/parse/bad_syntax.json"));

  run "load_machine rejects invalid transitions shape" (fun () ->
    expect_parse_error (fun () ->
      load_machine "test/fixtures/parse/bad_transitions_type.json"));

  run "load_machine rejects missing top-level blank field" (fun () ->
    expect_parse_error (fun () ->
      load_machine "test/fixtures/parse/missing_blank.json"));

  run "load_machine rejects missing top-level states field" (fun () ->
    expect_parse_error (fun () ->
      load_machine "test/fixtures/parse/missing_states.json"));

  run "load_machine parses unary_add" (fun () ->
    let machine = load_machine "res/unary_add.json" in
    let validation_state = transitions_for "L" machine in
    let state_a = transitions_for "A" machine in
    expect_equal "unary_add" machine.name "unexpected machine name";
    expect_equal ['1'; '.'; '+'; '='] machine.alphabet "unexpected alphabet";
    expect_equal '.' machine.blank "unexpected blank symbol";
    expect_equal
      [
        "L";
        "R";
        "T";
        "W";
        "X";
        "A";
        "B";
        "C";
        "D";
        "E";
      ]
      machine.states
      "unexpected states";
    expect_equal "L" machine.initial "unexpected initial state";
    expect_equal ["E"] machine.finals "unexpected final states";
    expect_equal 4 (List.length validation_state) "unexpected validation transition count";
    expect_equal
      {
        read = '+';
        to_state = "R";
        write = '+';
        action = Right;
      }
      (List.nth validation_state 1)
      "unexpected validation transition";
    expect_equal 4 (List.length state_a) "unexpected A transition count";
    expect_equal
      {
        read = '=';
        to_state = "B";
        write = '.';
        action = Left;
      }
      (List.nth state_a 3)
      "unexpected A transition");

  let ok = !total - !failed in
  Printf.printf "SUMMARY: %d OK / %d FAIL\n%!" ok !failed;
  if !failed <> 0 then
    exit 1

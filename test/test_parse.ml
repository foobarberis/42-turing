open Types
open Parse

let total = ref 0
let failed = ref 0

let fail message =
  incr failed;
  Printf.eprintf "  FAIL: %s\n%!" message

let run name f =
  incr total;
  Printf.printf "[%02d] %s\n%!" !total name;
  try
    f ();
    Printf.printf "  OK\n%!"
  with
  | Failure message -> fail message
  | exn -> fail (Printexc.to_string exn)

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

  run "load_machine parses unary_sub" (fun () ->
    let machine = load_machine "res/unary_sub.json" in
    let scanright = transitions_for "scanright" machine in
    expect_equal "unary_sub" machine.name "unexpected machine name";
    expect_equal ['1'; '.'; '-'; '='] machine.alphabet "unexpected alphabet";
    expect_equal '.' machine.blank "unexpected blank symbol";
    expect_equal ["scanright"; "eraseone"; "subone"; "skip"; "HALT"]
      machine.states
      "unexpected states";
    expect_equal "scanright" machine.initial "unexpected initial state";
    expect_equal ["HALT"] machine.finals "unexpected final states";
    expect_equal 4 (List.length scanright) "unexpected scanright transition count";
    expect_equal
      {
        read = '=';
        to_state = "eraseone";
        write = '.';
        action = Left;
      }
      (List.nth scanright 3)
      "unexpected scanright transition");

  if !failed = 0 then
    Printf.printf "OK: %d tests\n" !total
  else begin
    Printf.eprintf "FAILED: %d/%d tests failed\n" !failed !total;
    exit 1
  end

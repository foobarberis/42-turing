open Types
open Validate

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

let expect_validation_error f =
  try
    let _ = f () in
    failwith "expected Validation_error"
  with
  | Validation_error _ -> ()

let valid_machine =
  {
    name = "ok";
    alphabet = ['0'; '1'; '.'];
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
              to_state = "q0";
              write = '1';
              action = Right;
            };
            {
              read = '1';
              to_state = "q0";
              write = '0';
              action = Right;
            };
            {
              read = '.';
              to_state = "HALT";
              write = '.';
              action = Right;
            };
          ]);
        ("HALT", []);
      ];
  }

let () =
  Printf.printf "\n== Validation tests ==\n\n%!";
  run "validate_machine accepts a valid machine" (fun () ->
    validate_machine valid_machine;
    expect true "expected valid machine");

  run "validate_machine rejects empty alphabet" (fun () ->
    expect_validation_error (fun () ->
      validate_machine { valid_machine with alphabet = [] }));

  run "validate_machine rejects duplicate alphabet symbols" (fun () ->
    expect_validation_error (fun () ->
      validate_machine { valid_machine with alphabet = ['0'; '1'; '0'; '.'] }));

  run "validate_machine rejects blank not in alphabet" (fun () ->
    expect_validation_error (fun () ->
      validate_machine { valid_machine with blank = 'x' }));

  run "validate_machine rejects empty states" (fun () ->
    expect_validation_error (fun () ->
      validate_machine { valid_machine with states = [] }));

  run "validate_machine rejects duplicate states" (fun () ->
    expect_validation_error (fun () ->
      validate_machine { valid_machine with states = ["q0"; "HALT"; "q0"] }));

  run "validate_machine rejects initial not in states" (fun () ->
    expect_validation_error (fun () ->
      validate_machine { valid_machine with initial = "missing" }));

  run "validate_machine rejects finals not in states" (fun () ->
    expect_validation_error (fun () ->
      validate_machine { valid_machine with finals = ["missing"] }));

  run "validate_machine rejects duplicate finals" (fun () ->
    expect_validation_error (fun () ->
      validate_machine { valid_machine with finals = ["HALT"; "HALT"] }));

  run "validate_machine rejects transition source states not in states" (fun () ->
    expect_validation_error (fun () ->
      validate_machine
        {
          valid_machine with
          transitions =
            [
              ("missing",
                [
                  {
                    read = '0';
                    to_state = "HALT";
                    write = '0';
                    action = Right;
                  };
                ]);
            ];
        }));

  run "validate_machine rejects duplicate transition source states" (fun () ->
    expect_validation_error (fun () ->
      validate_machine
        {
          valid_machine with
          transitions =
            [
              ("q0", []);
              ("q0", []);
            ];
        }));

  run "validate_machine rejects transition read not in alphabet" (fun () ->
    expect_validation_error (fun () ->
      validate_machine
        {
          valid_machine with
          transitions =
            [
              ("q0",
                [
                  {
                    read = 'x';
                    to_state = "HALT";
                    write = '0';
                    action = Right;
                  };
                ]);
            ];
        }));

  run "validate_machine rejects transition write not in alphabet" (fun () ->
    expect_validation_error (fun () ->
      validate_machine
        {
          valid_machine with
          transitions =
            [
              ("q0",
                [
                  {
                    read = '0';
                    to_state = "HALT";
                    write = 'x';
                    action = Right;
                  };
                ]);
            ];
        }));

  run "validate_machine rejects transition to_state not in states" (fun () ->
    expect_validation_error (fun () ->
      validate_machine
        {
          valid_machine with
          transitions =
            [
              ("q0",
                [
                  {
                    read = '0';
                    to_state = "missing";
                    write = '0';
                    action = Right;
                  };
                ]);
            ];
        }));

  run "validate_machine rejects duplicate reads within one source state" (fun () ->
    expect_validation_error (fun () ->
      validate_machine
        {
          valid_machine with
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
                  {
                    read = '0';
                    to_state = "q0";
                    write = '1';
                    action = Right;
                  };
                ]);
            ];
        }));

  run "validate_input accepts valid input" (fun () ->
    validate_input "0101" valid_machine.alphabet valid_machine.blank;
    expect true "expected valid input");

  run "validate_input rejects symbols not in alphabet" (fun () ->
    expect_validation_error (fun () ->
      validate_input "01x" valid_machine.alphabet valid_machine.blank));

  run "validate_input rejects blank in input" (fun () ->
    expect_validation_error (fun () ->
      validate_input "01.0" valid_machine.alphabet valid_machine.blank));

  if !failed = 0 then
    Printf.printf "OK: %d tests\n" !total
  else begin
    Printf.eprintf "FAILED: %d/%d tests failed\n" !failed !total;
    exit 1
  end

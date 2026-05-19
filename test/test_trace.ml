open Types
open Trace

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

let machine =
  {
    name = "trace_machine";
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
              to_state = "HALT";
              write = '1';
              action = Right;
            };
          ]);
        ("HALT", []);
      ];
  }

let tape =
  {
    left = [];
    current = '0';
    right = ['1'];
  }

let step_result =
  Continue
    ( "q0",
      tape,
      {
        read = '0';
        to_state = "HALT";
        write = '1';
        action = Right;
      } )

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

let with_temp_file f =
  let path = Filename.temp_file "ft_turing_trace" ".log" in
  try
    let result = f path in
    Sys.remove path;
    result
  with exn ->
    (try Sys.remove path with Sys_error _ -> ());
    raise exn

let rec remove_tree path =
  if Sys.file_exists path then
    if Sys.is_directory path then begin
      Array.iter (fun name -> remove_tree (Filename.concat path name)) (Sys.readdir path);
      Sys.rmdir path
    end else
      Sys.remove path

let with_temp_dir f =
  let path = Filename.temp_file "ft_turing_trace" ".dir" in
  Sys.remove path;
  Sys.mkdir path 0o755;
  try
    let result = f path in
    remove_tree path;
    result
  with exn ->
    remove_tree path;
    raise exn

let with_temp_cwd f =
  with_temp_dir (fun dir ->
    let cwd = Sys.getcwd () in
    Sys.chdir dir;
    try
      let result = f dir in
      Sys.chdir cwd;
      result
    with exn ->
      Sys.chdir cwd;
      raise exn)

let () =
  Printf.printf "\ntrace.ml\n%!";

  run "info_message writes the message and a newline" (fun () ->
    with_temp_file (fun path ->
      let out = open_out path in
      info_message "hello" out;
      close_outfile out;
      expect_equal "hello\n" (read_file path) "unexpected info_message output"));

  run "step_info writes the formatted step and a newline" (fun () ->
    with_temp_file (fun path ->
      let out = open_out path in
      step_info step_result machine out;
      close_outfile out;
      expect_equal
        (Format.string_of_step step_result machine false^ "\n")
        (read_file path)
        "unexpected step_info output"));

  run "machine_info writes machine details and transitions" (fun () ->
    with_temp_file (fun path ->
      let out = open_out path in
      machine_info machine out;
      close_outfile out;
      expect_equal
        (Format.string_of_machine machine ^ "\n")
        (read_file path)
        "unexpected machine_info output"));

  run "header_info writes the header then the machine details" (fun () ->
    with_temp_file (fun path ->
      let out = open_out path in
      let returned = header_info  machine out in
      close_outfile out;
      expect (returned == out) "header_info should return the same out_channel";
      expect_equal
        (Format.string_of_header machine.name ^ "\n" ^ Format.string_of_machine machine ^ "\n")
        (read_file path)
        "unexpected header_info output"));

  run "init_machine_info_file creates the log directory and writes the header" (fun () ->
    with_temp_cwd (fun _ ->
      expect (not (Sys.file_exists "log")) "expected missing log directory before init";
      let out = init_machine_info_file true machine in
      close_outfile out;
      expect (Sys.file_exists "log") "expected log directory to be created";
      expect (Sys.file_exists "log/trace_machine_info.log") "expected log file to be created";
      expect_equal
        (Format.string_of_header machine.name ^ "\n" ^ Format.string_of_machine machine ^ "\n")
        (read_file "log/trace_machine_info.log")
        "unexpected init_machine_info_file content"));

  run "init_machine_info_file overwrites an existing log file" (fun () ->
    with_temp_cwd (fun _ ->
      Sys.mkdir "log" 0o755;
      let stale = open_out "log/trace_machine_info.log" in
      output_string stale "stale content\n";
      close_out stale;
      let out = init_machine_info_file true machine in
      close_outfile out;
      expect_equal
        (Format.string_of_header machine.name ^ "\n" ^ Format.string_of_machine machine ^ "\n")
        (read_file "log/trace_machine_info.log")
        "expected init_machine_info_file to overwrite old content"));

  let ok = !total - !failed in
  Printf.printf "SUMMARY: %d OK / %d FAIL\n%!" ok !failed;
  if !failed <> 0 then
    exit 1

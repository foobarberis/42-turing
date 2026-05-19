let usage =
  "usage: ft_turing [-h] jsonfile input\n\n" ^
  "positional arguments:\n" ^
  "  jsonfile    json description of the machine\n" ^
  "  input       input of the machine\n\n" ^
  "optional arguments:\n" ^
  "  -h, --help  show this help message and exit"

let print_usage channel = output_string channel (usage ^ "\n")

let run jsonfile input =
  let machine =
    try Parse.load_machine jsonfile with
    | Parse.Parse_error message ->
        raise (Parse.Parse_error (jsonfile ^ ": " ^ message))
  in
  begin
    try Validate.validate_machine machine with
    | Validate.Validation_error message ->
        raise (Validate.Validation_error (jsonfile ^ ": " ^ message))
  end;
  begin
    try Validate.validate_input input machine.alphabet machine.blank with
    | Validate.Validation_error message ->
        raise (Validate.Validation_error ("input: " ^ message))
  end;
  machine

let main () =
  match Array.to_list Sys.argv with
  | [_; "-h"] | [_; "--help"] ->
      print_usage stdout;
      0
  | [_; jsonfile; input] ->
      let machine = run jsonfile input in
      let out = Trace.init_machine_info_file machine in
      let step_res = Execute.execute machine (Format.tape_of_string ~blank:machine.blank input) machine.initial out in 
      Trace.step_info step_res machine out;
      Trace.close_outfile out;
      0
  | _ ->
      print_usage stderr;
      1

let () =
  try exit (main ()) with
  | Parse.Parse_error message ->
      Printf.eprintf "Parse error: %s\n" message;
      exit 1
  | Validate.Validation_error message ->
      Printf.eprintf "Validation error: %s\n" message;
      exit 1
  | Sys_error message ->
      Printf.eprintf "Error: %s\n" message;
      exit 1
  | exception_raised ->
      Printf.eprintf "Error: %s\n" (Printexc.to_string exception_raised);
      exit 1

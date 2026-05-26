open Types

let usage =
  "usage: ft_turing [-h] [-l logfile] [--] jsonfile input\n\n"
  ^ "positional arguments:\n"
  ^ "  jsonfile    json description of the machine\n"
  ^ "  input       input of the machine\n\n"
  ^ "optional arguments:\n"
  ^ "  -h, --help  show this help message and exit\n"
  ^ "  -l logfile, --log logfile\n"
  ^ "              write trace to logfile instead of stdout\n"
  ^ "  --          end option parsing"

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

let run_machine m input sink =
  let out, style = Trace.init_output sink m in
  Fun.protect
    ~finally:(fun () -> Trace.close_outfile out)
    (fun () ->
      let tape = Format.tape_of_string ~blank:m.blank input in
      let step_res = Execute.execute m tape m.initial style out in
      Trace.step_info step_res m style out)

type cli =
  | Help
  | Run of sink * string * string
  | Error

let parse_args args =
  let finalize sink positional =
    match List.rev positional with
    | [jsonfile; input] -> Run (sink, jsonfile, input)
    | _ -> Error
  in
  let rec loop sink positional allow_options = function
    | [] -> finalize sink positional
    | arg :: rest when not allow_options -> loop sink (arg :: positional) false rest
    | "--" :: rest -> loop sink positional false rest
    | ["-h"] | ["--help"] when sink = Stdout && positional = [] -> Help
    | ("-l" | "--log") :: [] -> Error
    | ("-l" | "--log") :: path :: rest ->
        begin
          match sink with
          | Stdout -> loop (File path) positional true rest
          | File _ -> Error
        end
    | ("-h" | "--help") :: _ -> Error
    | arg :: _ when String.length arg > 0 && arg.[0] = '-' -> Error
    | arg :: rest -> loop sink (arg :: positional) true rest
  in
  loop Stdout [] true args

let main () =
  match Array.to_list Sys.argv with
  | _ :: args ->
      begin
        match parse_args args with
        | Help ->
            print_usage stdout;
            0
        | Run (sink, jsonfile, input) ->
            let machine = run jsonfile input in
            run_machine machine input sink;
            0
        | Error ->
            print_usage stderr;
            1
      end
  | [] ->
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

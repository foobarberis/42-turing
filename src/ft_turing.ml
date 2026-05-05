let usage =
  "usage: ft_turing [-h] jsonfile input\n\n" ^
  "positional arguments:\n" ^
  "  jsonfile    json description of the machine\n" ^
  "  input       input of the machine\n\n" ^
  "optional arguments:\n" ^
  "  -h, --help  show this help message and exit"

let print_usage channel = output_string channel (usage ^ "\n")

let run _jsonfile _input = ()

let main () =
  match Array.to_list Sys.argv with
  | [_; "-h"] | [_; "--help"] ->
      print_usage stdout;
      0
  | [_; jsonfile; input] ->
      run jsonfile input;
      0
  | _ ->
      print_usage stderr;
      1

let () =
  try exit (main ()) with
  | Sys_error message ->
      Printf.eprintf "Error: %s\n" message;
      exit 1
  | exception_raised ->
      Printf.eprintf "Error: %s\n" (Printexc.to_string exception_raised);
      exit 1

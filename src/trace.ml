open Types

(* Create a directory and its missing parents. *)
let rec create_dir_if_missing (path : string) : unit =
  if path = "" || path = "." || path = "/" then
    ()
  else if Sys.file_exists path then begin
    if not (Sys.is_directory path) then begin
      Printf.eprintf "Error: %s exists and is not a directory\n" path;
      exit 1
    end
  end else begin
    create_dir_if_missing (Filename.dirname path);
    try Sys.mkdir path 0o755 with
    | Sys_error message ->
        Printf.eprintf "Error creating directory %s: %s\n" path message;
        exit 1
  end

(* Ensure the parent directory of a file path exists. *)
let ensure_parent_dir (path : string) : unit =
  create_dir_if_missing (Filename.dirname path)

(* Open a trace file for writing. *)
let open_outfile (path : string) : out_channel =
  ensure_parent_dir path;
  try open_out path with
  | Sys_error message ->
      Printf.eprintf "Error opening file %s: %s\n" path message;
      exit 1

(* Close a trace output channel. *)
let close_outfile (out : out_channel) : unit =
  if out != stdout then
    try close_out out with
    | Sys_error message ->
        Printf.eprintf "Error closing file: %s\n" message;
        exit 1

(* Write the machine description. *)
let machine_info (m : machine) (out : out_channel) : unit =
  Printf.fprintf out "%s\n" (Format.string_of_machine m)

(* Write one line to the trace output. *)
let info_message (msg : string) (out : out_channel) : unit =
  Printf.fprintf out "%s\n" msg

(* Use color only on an interactive stdout. *)
let stdout_style () : style =
  try
    if Unix.isatty (Unix.descr_of_out_channel stdout) then
      Color
    else
      Plain
  with _ -> Plain

(* Write one execution step. *)
let step_info (info : step_res) (machine : machine) (style : style) (out : out_channel) : unit =
  Printf.fprintf out "%s\n" (Format.string_of_step info machine style)

(* Write the header and machine description. *)
let header_info (m : machine) (out : out_channel) : out_channel =
  info_message (Format.string_of_header m.name) out;
  machine_info m out;
  out

(* Open the requested sink and write the trace header. *)
let init_output (sink : sink) (m : machine) : out_channel * style =
  match sink with
  | Stdout ->
      let out = header_info m stdout in
      (out, stdout_style ())
  | File path ->
      let out = open_outfile path in
      let out = header_info m out in
      (out, Plain)

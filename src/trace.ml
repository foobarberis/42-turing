open Types

(*open and charge log info in file name trace
	@return file descriptor of file info*)
let open_outfile (path: string) : out_channel = 
	try open_out path with
	| Sys_error message ->
			Printf.eprintf "Error opening file %s: %s\n" path message;
			exit 1

(*close file descriptor for info
	@param out file descriptor*)
let close_outfile (out : out_channel): unit =
	if out <> stdout then
		try close_out out with
		| Sys_error message ->
				Printf.eprintf "Error closing file: %s\n" message;
				exit 1

(*print the rules of the machine
	@param m current machine
	@param out file descriptor*)
let machine_info (m: machine) (out: out_channel): unit =
	Printf.fprintf out "%s\n" (Format.string_of_machine m);
	if out <> stdout then
		Printf.printf "%s\n" (Format.string_of_machine m)

let info_message (msg: string) (out: out_channel): unit = 
	Printf.fprintf out "%s\n" msg;
	if out <> stdout then
		Printf.printf "%s\n" msg

(*print one step of the machine
	@param info result of the one step
	@param m current machine 
	@param out file descriptor*)
let step_info (info: step_res) (machine: machine) (out: out_channel): unit =
	Printf.fprintf out "%s\n" (Format.string_of_step info machine); (*TODO verify out*)
	if out <> stdout then
		Printf.printf "%s\n" (Format.string_of_step info machine)

(*print the header info of the machine
	@param msg string of header of the current machine
	@param out file descriptor*)
let header_info (m: machine) (out: out_channel): out_channel =
	(* output_string out ((Format.string_of_header m.name) ^ "\n"); *)
	info_message (Format.string_of_header m.name) out;
	machine_info m out;
	out

(*create a directory if it doesn't exist
  @param path the path to the directory*)
let create_dir_if_missing (path : string): unit =
	if not (Sys.file_exists path) then
		try Sys.mkdir path 0o755 with
		| Sys_error message ->
				Printf.eprintf "Error creating directory %s: %s\n" path message;
				exit 1

(*open info file and write header of the machine
	@param m current machine
	@return file descriptor*)
let init_machine_info_file (flag: bool) (m: machine): out_channel =
		if flag = true then begin
			create_dir_if_missing "log";
			let out = open_outfile ("log/" ^ m.name ^ "_info.log") in
			header_info m out end
		else
			header_info m stdout

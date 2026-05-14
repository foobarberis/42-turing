open Types

(*open and charge log info in file name trace
	@return file descriptor of file info*)
let open_outfile (path: string) : out_channel = 
	open_out path (*TODO verify open ?*)

(*close file descriptor for info
	@param out file descriptor*)
let close_outfile (out : out_channel): unit =
	close_out out (*TODO verify close ?*)

(*print the rules of the machine
	@param m current machine
	@param out file descriptor*)
let machine_info (m: machine) (out: out_channel): unit =
	Printf.fprintf out "%s\n" (Format.string_of_machine m) (*TODO verify out*)

let info_message (msg: string) (out: out_channel): unit = 
	Printf.fprintf out "%s\n" msg

(*print one step of the machine
	@param info result of the one step
	@param m current machine 
	@param out file descriptor*)
let step_info (info: step_res) (machine: machine) (out: out_channel): unit =
	Printf.fprintf out "%s\n" (Format.string_of_step info machine) (*TODO verify out*)
(*print the header info of the machine
	@param msg string of header of the current machine
	@param out file descriptor*)
let header_info (out: out_channel) (m: machine): out_channel =
	output_string out ((Format.string_of_header m.name) ^ "\n");
	machine_info m out;
	out

(*open info file and write header of the machine
	@param m current machine
	@return file descriptor of the *)
let init_machine_info_file (m: machine): out_channel =
		let out = open_outfile "Trace" in
		header_info out m

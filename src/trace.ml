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

(*print one step of the machine
	@param info result of the one step
	@param m current machine 
	@param out file descriptor*)
let step_info (info: step_res) (machine: machine) (out: out_channel): unit =
	match info with
	| Continue(state, tape, transition) ->
			Printf.fprintf out "%s\n" (Format.string_of_step info machine) (*TODO verify out*)
(*
(*print error*)
let error (message: string): unit = *)

(*let init_trace (machine : machine) : out_channel =
	try open_out machine*)

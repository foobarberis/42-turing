open Types
open Format
open Trace 
open Execute

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

let trim_end_blanks str blank =
	let rec trim_right s =
		if String.length s = 0 then s
		else if String.get s (String.length s - 1) = blank then
			trim_right (String.sub s 0 (String.length s - 1))
		else s
	in
	trim_right str

let convert_res_to_string result (m: machine): string =
match result with
| Halted tape -> 
	let str = (string_of_char (List.rev tape.left) ^ String.make 1 tape.current ^ string_of_char tape.right) in
		trim_end_blanks str m.blank 
| _ -> ""

let is_not_accepted result =
  match result with
  | Halted tape ->
      tape.current = 'n'
      || List.mem 'n' tape.left
      || List.mem 'n' tape.right
  | _ -> false

let palindrome_machine : machine = {
	name    = "is_palindrome";
	alphabet = [ '0'; '1'; 'y'; 'n'; '.'; '-' ];
	blank   = '.';
	states  = ["init";"is_zero";"get_last_zero";"is_one";"get_last_one";"get_most_left";"deny";"HALT"	];
	initial = "init";
	finals  = [ "HALT"];
	transitions =
      [ ( "init", [
        	{read = '.'; to_state = "HALT"; write = 'y'; action = Left};
        	{read = '-'; to_state = "init"; write = '-'; action = Right};
        	{read = '0'; to_state = "get_last_zero"; write = '-'; action = Right};
        	{read = '1'; to_state = "get_last_one"; write = '-'; action = Right};
        	{read = 'y'; to_state = "HALT"; write = 'y'; action = Left};
        	{read = 'n'; to_state = "HALT"; write = 'n'; action = Left}
        ]);
      ("get_last_zero", [
        	{read = '-'; to_state = "get_last_zero"; write = '-'; action = Right};
        	{read = '0'; to_state = "get_last_zero"; write = '0'; action = Right};
        	{read = '1'; to_state = "get_last_zero"; write = '1'; action = Right};
        	{read = '.'; to_state = "is_zero"; write = 'y'; action = Left};
        	{read = 'y'; to_state = "is_zero"; write = 'y'; action = Left}
        ]);
			(	"get_last_one", [
						{read = '-'; to_state = "get_last_one"; write = '-'; action = Right};
						{read = '0'; to_state = "get_last_one"; write = '0'; action = Right};
						{read = '1'; to_state = "get_last_one"; write = '1'; action = Right};
						{read = '.'; to_state = "is_one"; write = 'y'; action = Left};
						{read = 'y'; to_state = "is_one"; write = 'y'; action = Left}
				]);
      ("is_one", [
        	{read = '-'; to_state = "is_one"; write = '-'; action = Left};
        	{read = '.'; to_state = "HALT"; write = '.'; action = Left};
        	{read = '1'; to_state = "get_most_left"; write = '-'; action = Left};
        	{read = '0'; to_state = "deny"; write = '0'; action = Right}
        ]);

      ("is_zero", [
        	{read = '-'; to_state = "is_zero"; write = '-'; action = Left};
        	{read = '.'; to_state = "HALT"; write = '.'; action = Left};
        	{read = '0'; to_state = "get_most_left"; write = '-'; action = Left};
        	{read = '1'; to_state = "deny"; write = '1'; action = Right}
        ]);
      ("get_most_left", [
        	{read = '-'; to_state = "get_most_left"; write = '-'; action = Left};
        	{read = '1'; to_state = "get_most_left"; write = '1'; action = Left};
        	{read = '0'; to_state = "get_most_left"; write = '0'; action = Left};
        	{read = '.'; to_state = "init"; write = '.'; action = Right}
        ]);
      ("deny", [
			{read = '1'; to_state = "deny"; write = '1'; action = Right};
			{read = '0'; to_state = "deny"; write = '0'; action = Right};
			{read = '-'; to_state = "deny"; write = '-'; action = Right};
			{read = '.'; to_state = "deny"; write = '.'; action = Right};
			{read = 'y'; to_state = "HALT"; write = 'n'; action = Right};
			{read = 'n'; to_state = "HALT"; write = 'n'; action = Left}
        ]);]}

let unary_add_machine :machine = {
	name = "unary_add";
	alphabet = [ '1'; '.'; '+'; '=' ];
	blank   = '.';
	states  = ["A";"B";"C";"D";"E"];
	initial = "A";
	finals  = [ "E" ];
	transitions = [
		("A", [
			{read = '.'; to_state = "A"; write = '.'; action = Right};
			{read = '1'; to_state = "A"; write = '1'; action = Right};
			{read = '+'; to_state = "A"; write = '+'; action = Right};
			{read = '='; to_state = "B"; write = '.'; action = Left}]);
		("B", [
			{read = '1'; to_state = "C"; write = '='; action = Left};
			{read = '+'; to_state = "E"; write = '.'; action = Left}]);
		("C", [
			{read = '1'; to_state = "C"; write = '1'; action = Left};
			{read = '+'; to_state = "D"; write = '1'; action = Right}]);
		("D", [
			{read = '1'; to_state = "D"; write = '1'; action = Right};
			{read = '='; to_state = "E"; write = '.'; action = Right}]);
	]}

let () =
  Printf.printf "== execute tests ==\n\n%!";

  let out = open_outfile "Trace.log" in
  run "palindrome_machine [0101] Not Palindrome" (fun () ->
    expect_equal
      true			
		(is_not_accepted
     	 (execute 
		 		palindrome_machine 
			 	(Format.tape_of_string "0101") 
				palindrome_machine.initial 
				out))
      "expected palindrome to be rejected"
  );

  run "palindrome_machine [0100] Not Palindrome" (fun () ->
    expect_equal
      true
		(is_not_accepted
    		(execute 
				palindrome_machine 
				(Format.tape_of_string "0100") 
				palindrome_machine.initial
				out))
      "expected palindrome to be rejected"
  );

  run "palindrome_machine [1001] Palindrome" (fun () ->
    expect_equal
      false
		(is_not_accepted
    		(execute 
				palindrome_machine 
				(Format.tape_of_string "1001") 
				palindrome_machine.initial
				out))
      "expected palindrome to be accepted"
  );

  run "palindrome_machine [00100] Palindrome" (fun () ->
    expect_equal
      false
		(is_not_accepted
    		(execute 
				palindrome_machine 
				(Format.tape_of_string "00100") 
				palindrome_machine.initial
				out))
      "expected palindrome to be accepted"
  );

	run "Unary_add_machine [111+11=] = 11111" (fun () ->
		expect_equal
			"11111"
		(convert_res_to_string
			(execute 
				unary_add_machine 
				(Format.tape_of_string "111+11=") 
				unary_add_machine.initial
				out)
			unary_add_machine)
			"expected unary addition to be correct"
	);

	run "Unary_add_machine [111+1=] = 1111" (fun () ->
		expect_equal
			"1111"
		(convert_res_to_string
			(execute 
				unary_add_machine 
				(Format.tape_of_string "111+1=") 
				unary_add_machine.initial
				out)
			unary_add_machine)
			"expected unary addition to be correct"
	);

	run "Unary_add_machine [11111+1111=] = 111111111" (fun () ->
		expect_equal
			"111111111"
		(convert_res_to_string
			(execute 
				unary_add_machine 
				(Format.tape_of_string "11111+1111=") 
				unary_add_machine.initial
				out)
			unary_add_machine)
			"expected unary addition to be correct"
	);

	run "Unary_add_machine [+111111111111111111111111111111111111111111111111=] = 111111111111111111111111111111111111111111111111" (fun () ->
		expect_equal
			"111111111111111111111111111111111111111111111111"
		(convert_res_to_string
			(execute 
				unary_add_machine 
				(Format.tape_of_string "+111111111111111111111111111111111111111111111111=") 
				unary_add_machine.initial
				out)
			unary_add_machine)
			"expected unary addition to be correct"
	);

	close_outfile out;
	if !failed = 0 then
		Printf.printf "OK: %d tests\n" !total
	else begin
		 Printf.eprintf "FAILED: %d/%d tests failed\n" !failed !total;
	exit 1
	end
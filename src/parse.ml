open Types

exception Parse_error of string

let load_json (path : string) : Yojson.Basic.t =
  try Yojson.Basic.from_file path with
  | Sys_error message ->
      raise (Parse_error message)
  | Yojson.Json_error message ->
      raise (Parse_error message)

let field name (json : Yojson.Basic.t) : Yojson.Basic.t =
  match json with
  | `Assoc fields ->
      begin match List.assoc_opt name fields with
      | Some value -> value
      | None -> raise (Parse_error ("missing field: " ^ name))
      end
  | _ -> raise (Parse_error ("expected JSON object for field: " ^ name))

let as_string (json : Yojson.Basic.t) : string =
  match json with
  | `String s -> s
  | _ -> raise (Parse_error "expected JSON string")

let as_list (json : Yojson.Basic.t) : Yojson.Basic.t list =
  match json with
  | `List xs -> xs
  | _ -> raise (Parse_error "expected JSON list")

let as_char (json : Yojson.Basic.t) : char =
  let s = as_string json in
  if String.length s = 1 then
    s.[0]
  else
    raise (Parse_error "expected string of length 1")

let parse_name json =
  as_string (field "name" json)

let parse_alphabet json =
  List.map as_char (as_list (field "alphabet" json))

let parse_blank json =
  as_char (field "blank" json)

let parse_initial json =
  as_string (field "initial" json)

let parse_states json =
  List.map as_string (as_list (field "states" json))

let parse_finals json =
  List.map as_string (as_list (field "finals" json))

let parse_action json =
  match as_string json with
  | "LEFT" -> Left
  | "RIGHT" -> Right
  | s -> raise (Parse_error ("invalid action: " ^ s))

let parse_transition (json : Yojson.Basic.t) : transition =
  {
    read = as_char (field "read" json);
    to_state = as_string (field "to_state" json);
    write = as_char (field "write" json);
    action = parse_action (field "action" json);
  }

let parse_transitions (json : Yojson.Basic.t) : (string * transition list) list =
  match field "transitions" json with
  | `Assoc fields ->
      List.map
        (fun (state, transitions_json) ->
          (state, List.map parse_transition (as_list transitions_json)))
        fields
  | _ -> raise (Parse_error "expected JSON object for field: transitions")

let parse_machine (json : Yojson.Basic.t) : machine =
  {
    name = parse_name json;
    alphabet = parse_alphabet json;
    blank = parse_blank json;
    states = parse_states json;
    initial = parse_initial json;
    finals = parse_finals json;
    transitions = parse_transitions json;
  }

let load_machine path =
  parse_machine (load_json path)

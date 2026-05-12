# ft_turing

`ft_turing` is a Turing machine simulator written in OCaml. It reads a machine description from a JSON file and runs it on a given input.

## Bootstrap

```sh
sudo apt update
sudo apt install -y build-essential m4 pkg-config opam
make
```

## Usage

Build the project:

```sh
make
```

Run the program:

```sh
./ft_turing res/unary_sub.json "111-11="
```

## Make targets

- `make` or `make all` — install required dependencies if needed, then build `ft_turing`
- `make byte` — build the bytecode binary `ft_turing.byte`
- `make unit` or `make ut` — build and run the unit tests
- `make setup` — create the local `opam` switch and install required dependencies
- `make test` — run `test/run_all.sh` and write the output to `test/log.txt`
- `make clean` — remove the build directory `_build/`
- `make fclean` — run `clean` and remove `ft_turing` and `ft_turing.byte`
- `make re` — run `fclean` then rebuild everything
- `make distclean` — run `fclean` and also remove the local `_opam/` switch

## Project layout

- `src/types.ml` — domain types used by the whole program
- `src/parse.ml` — JSON loading and structural parsing
- `src/validate.ml` — semantic validation of a parsed machine
- `src/execute.ml` — machine execution
- `src/ft_turing.ml` — CLI entry point
- `res/` — example machine descriptions
- `test/test_parse.ml` — lightweight parser unit tests
- `test/fixtures/parse/` — broken JSON fixtures used by parser tests
- `test/run_all.sh` — integration-style run script

## Parsing overview

The parsing code is intentionally split into small steps.

### 1. Domain types first

`src/types.ml` contains the OCaml representation of a machine.

```ocaml
type action =
  | Left
  | Right

type transition = {
  read : char;
  to_state : string;
  write : char;
  action : action;
}

type machine = {
  name : string;
  alphabet : char list;
  blank : char;
  states : string list;
  initial : string;
  finals : string list;
  transitions : (string * transition list) list;
}
```

If you come from C:

- a variant such as `Left | Right` is close to an `enum`
- a record such as `transition = { ... }` is close to a `struct`
- a `list` is an immutable linked list

The parser converts raw JSON into these types. After that, the rest of the program no longer works with raw JSON strings such as `"LEFT"`; it works with typed values such as `Left`.

### 2. Raw JSON is loaded first

`load_json` uses `Yojson.Basic.from_file`.

- input: file path
- output: `Yojson.Basic.t`

`Yojson.Basic.t` is the library's generic JSON tree type. It can represent any JSON value: object, array, string, number, boolean, or null.

This is not yet a `machine`. It is only the raw parsed JSON tree.

### 3. Small helper functions narrow the JSON shape

`src/parse.ml` defines four small helpers:

- `field name json` — expects a JSON object and returns one field from it
- `as_string json` — expects a JSON string and returns an OCaml `string`
- `as_list json` — expects a JSON array and returns an OCaml list of JSON values
- `as_char json` — expects a JSON string of length 1 and returns an OCaml `char`

These helpers do only one job each. If the JSON shape is wrong, they raise `Parse_error`.

This keeps the rest of the parser simple: the higher-level functions can say what they want to extract instead of re-checking the JSON type every time.

### 4. Field parsers build the machine piece by piece

Examples:

- `parse_name`
- `parse_alphabet`
- `parse_blank`
- `parse_states`
- `parse_initial`
- `parse_finals`

They all follow the same pattern:

1. fetch one field from the JSON object
2. convert it to the expected OCaml type

For example, `parse_alphabet` means:

1. get the `"alphabet"` field
2. verify that it is a JSON array
3. convert each element of that array from a one-character string to an OCaml `char`

### 5. Transition parsing mirrors the JSON structure

One transition in JSON looks like this:

```json
{ "read": ".", "to_state": "scanright", "write": ".", "action": "RIGHT" }
```

It becomes this OCaml record:

```ocaml
{
  read = '.';
  to_state = "scanright";
  write = '.';
  action = Right;
}
```

The parser has two levels:

- `parse_transition` parses one transition object
- `parse_transitions` parses the full `transitions` field, which is a JSON object mapping each state name to a list of transition objects

The final step is `parse_machine`, which assembles a complete `machine` record.

### 6. Parsing and validation are separate

This separation is important.

`src/parse.ml` answers:

- is the file readable?
- is the JSON syntax valid?
- are the required fields present?
- do those fields have the expected JSON shape?

`src/validate.ml` is responsible for semantic rules such as:

- is `blank` inside `alphabet`?
- is `initial` inside `states`?
- are `finals` a subset of `states`?
- do transition symbols belong to `alphabet`?
- do transition destination states exist?

In other words:

- parsing checks structure
- validation checks meaning

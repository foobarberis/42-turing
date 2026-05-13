# ft_turing

`ft_turing` is a Turing machine simulator written in OCaml. It reads a machine
description from a JSON file and runs it on a given input.

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
./ft_turing res/unary_add.json "11+1111="
```

## Make targets

- `make` or `make all` — install required dependencies if needed, then build `ft_turing`
- `make byte` — build the bytecode binary `ft_turing.byte`
- `make unit` or `make ut` — build and run the unit tests
- `make e2e` — run the end-to-end cases from `test/run_all.sh` and write the output to `test/log.txt`
- `make test` — run both the unit tests and the end-to-end cases
- `make setup` — create the local `opam` switch and install required dependencies
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
- `test/test_parse.ml` — parser unit tests
- `test/test_validate.ml` — validation unit tests
- `test/fixtures/parse/` — broken JSON fixtures used by parser tests
- `test/run_all.sh` — integration-style run script

## How a Turing machine works

A Turing machine has:

- a tape
- a head on one tape cell
- a current state
- a transition table

The usual model assumes an unbounded tape: the machine can always move farther
left or right, and cells outside the currently used area are blank. In a
simulator, this is handled by growing the represented tape when needed and
treating unseen cells as the blank symbol. That is the intended execution model
here, even though `src/execute.ml` is still empty.

Each step reads the current symbol, finds the transition for `(state, symbol)`,
writes a symbol, moves left or right, and switches state. In this codebase, one
transition is represented by:

```ocaml
type transition = {
  read : char;
  to_state : string;
  write : char;
  action : action;
}
```

A run stops when the machine reaches a final state or when no transition matches
the current `(state, symbol)` pair.

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

The parser converts raw JSON into these types. After that, the rest of the
program no longer works with raw JSON strings such as `"LEFT"`; it works with
typed values such as `Left`.

### 2. Raw JSON is loaded first

`load_json` uses `Yojson.Basic.from_file`.

- input: file path
- output: `Yojson.Basic.t`

`Yojson.Basic.t` is the library's generic JSON tree type. It can represent any
JSON value: object, array, string, number, boolean, or null.

This is not yet a `machine`. It is only the raw parsed JSON tree.

### 3. Small helper functions narrow the JSON structure

`src/parse.ml` defines four small helpers:

- `field name json` — expects a JSON object and returns one field from it
- `as_string json` — expects a JSON string and returns an OCaml `string`
- `as_list json` — expects a JSON array and returns an OCaml list of JSON values
- `as_char json` — expects a JSON string of length 1 and returns an OCaml `char`

These helpers do only one job each. If the JSON structure is wrong, they raise `Parse_error`.

This keeps the rest of the parser simple: the higher-level functions can say
what they want to extract instead of re-checking the JSON type every time.

### 4. Field parsers use those helpers

`parse_name`, `parse_alphabet`, `parse_blank`, `parse_states`,
`parse_initial`, and `parse_finals` all follow the same pattern: fetch one
field, then convert it to the expected OCaml type.

For example, `parse_alphabet`:

1. gets the `"alphabet"` field
2. checks that it is a JSON array
3. converts each one-character string into an OCaml `char`

This keeps the parser regular: once the helpers exist, each field parser is a
small description of the data it expects.

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
- `parse_transitions` parses the full `transitions` field, which is a JSON
  object mapping each state name to a list of transition objects

The final step is `parse_machine`, which assembles a complete `machine` record.

### 6. Parsing and validation are separate

This separation is important.

`src/parse.ml` answers:

- is the file readable?
- is the JSON syntax valid?
- are the required fields present?
- do those fields have the expected JSON structure?

`src/validate.ml` is responsible for semantic rules such as:

- is `blank` inside `alphabet`?
- is `initial` inside `states`?
- are `finals` a subset of `states`?
- do transition symbols belong to `alphabet`?
- do transition destination states exist?

In other words:

- parsing checks structure
- validation checks meaning

## Validation overview

The validation code is also split into small steps.

### Validation rules and why they exist

The current implementation enforces these rules:

- `alphabet` must be non-empty and contain no duplicates, so symbols form a usable set.
- `blank` must belong to `alphabet`, so empty tape cells use a legal tape symbol.
- `states` must be non-empty and contain no duplicates, so state names are usable and unambiguous.
- `initial` must be in `states`, and `finals` must be a duplicate-free subset of `states`, so execution only starts or halts in declared states.
- each transition source state and each transition `to_state` must be in `states`, so the transition table never references unknown states.
- each transition `read` and `write` symbol must be in `alphabet`, so the machine never reads or writes unknown symbols.
- within one source state, `read` symbols must be unique, so `(state, symbol)` lookup stays deterministic.
- runtime input must use only alphabet symbols and must not contain `blank`, so user input starts as tape data, not empty cells.

### 1. Validation works on typed values, not raw JSON

By the time validation starts, the file has already been parsed into a `machine` record.

That means `src/validate.ml` does not need to ask questions such as:

- is this field a JSON string?
- is this field a JSON array?
- is this key missing?

Those were parser concerns.

The validator only checks semantic rules on already-typed values such as:

- `char list`
- `string list`
- `transition`
- `machine`

### 2. A dedicated exception separates semantic failures from parse failures

`src/validate.ml` defines:

```ocaml
exception Validation_error of string
```

This keeps validation errors separate from parser errors:

- `Parse_error` — the file or JSON structure is wrong
- `Validation_error` — the machine structure is parseable, but invalid

For example, a machine may parse successfully and still be rejected because:

- `blank` is not in `alphabet`
- `initial` is not in `states`
- a transition points to an unknown state

### 3. Small helpers keep the validation rules readable

The validator uses a few tiny helpers:

- `ensure condition message` — raise `Validation_error` if `condition` is false
- `is_in x xs` — membership check
- `all_in xs allowed` — subset-style check
- `has_duplicates xs` — duplicate detection

This allows the actual validation functions to read like direct statements of the rules.

For example:

```ocaml
ensure (is_in blank alphabet) "blank must be in alphabet"
```

That is easier to read than repeating the same `if ... then raise ...` logic everywhere.

### 4. Machine and transition validation follow the structure of the data

`validate_machine` checks the machine in a fixed order:

1. alphabet
2. blank
3. states
4. initial
5. finals
6. transitions

The order matters because validation stops at the first error.

The field-level functions (`validate_alphabet`, `validate_blank`,
`validate_states`, `validate_initial`, `validate_finals`) cover the rules
summarized above. In this project, `alphabet` acts as the tape alphabet, so the
blank symbol must belong to it even though the runtime input itself must not
contain blank.

Transition validation is split into three levels:

- `validate_transition` checks one transition
- `validate_state_transitions` checks one source state's transition list,
  including unique `read` symbols
- `validate_transitions` checks the full transition table, including valid and
  unique source states

This mirrors the shape of the machine description and keeps each function
focused.

### 5. Input validation is separate from machine validation

The machine description and the runtime input are different things, so they are validated separately.

`validate_input` checks:

- every input symbol is in `alphabet`
- the input does not contain `blank`

This is the usual distinction:

- the tape alphabet includes the blank symbol
- the user-provided input must not already contain blank cells

### 6. Tests focus on one broken rule at a time

`test/test_validate.ml` builds a known-good machine value and then changes one part per test.

That test style is useful because validation stops at the first failure. If one
test breaks several rules at once, it becomes harder to tell which rule is
actually being exercised.

## Functional programming examples

Here, "functional programming" mostly means: describe data with types, pass
values through small functions, and process lists without mutable state.

### 1. Variants encode a closed set of values

```ocaml
type action =
  | Left
  | Right
```

`action` can only be `Left` or `Right`. This is safer than keeping head movement
as a free-form string everywhere in the program.

### 2. Pattern matching converts raw input into typed values

```ocaml
let parse_action json =
  match as_string json with
  | "LEFT" -> Left
  | "RIGHT" -> Right
  | s -> raise (Parse_error ("invalid action: " ^ s))
```

Read this as:

1. extract a string from JSON
2. convert `"LEFT"` to `Left`
3. convert `"RIGHT"` to `Right`
4. reject anything else immediately

After this step, the rest of the code no longer needs to compare movement strings.

### 3. List functions transform and validate data

```ocaml
let parse_alphabet json =
  List.map as_char (as_list (field "alphabet" json))
```

This is a compact pipeline:

1. get the `alphabet` field
2. ensure it is a JSON list
3. convert each JSON value into a `char`
4. return a new `char list`

`List.map` builds a new list instead of modifying an existing one.

The same style appears in validation:

```ocaml
let validate_state_transitions transitions alphabet states =
  let reads = List.map (fun transition -> transition.read) transitions in
  ensure (not (has_duplicates reads)) "transition reads must be unique within one source state";
  List.iter (fun transition -> validate_transition transition alphabet states) transitions
```

Here, `List.map` first derives the list of read symbols, then `List.iter`
checks each transition. The code says what must be checked, without counters,
indexes, or mutable flags.

### 4. Recursion follows the shape of an immutable list

```ocaml
let rec has_duplicates xs =
  match xs with
  | [] | [_] -> false
  | x :: rest -> is_in x rest || has_duplicates rest
```

The logic is structural:

- an empty list has no duplicates
- a one-element list has no duplicates
- otherwise, check whether the head appears in the tail, then recurse on the tail

### 5. Small functions compose into larger behavior

```ocaml
let validate_machine machine =
  validate_alphabet machine.alphabet;
  validate_blank machine.blank machine.alphabet;
  validate_states machine.states;
  validate_initial machine.initial machine.states;
  validate_finals machine.finals machine.states;
  validate_transitions machine.transitions machine.alphabet machine.states
```

Each helper checks one rule. The top-level validator is just the ordered composition of those smaller checks.

# ft_turing

`ft_turing` is a Turing machine simulator written in OCaml. It reads a machine
description from a JSON file and runs it on a given input.

## Table of contents

- [Getting started](#getting-started)
  - [Bootstrap](#bootstrap)
  - [Usage](#usage)
  - [Runtime output](#runtime-output)
  - [Make targets](#make-targets)
- [Project overview](#project-overview)
  - [Project layout](#project-layout)
  - [Tests](#tests)
- [How a Turing machine works](#how-a-turing-machine-works)
- [Machines in `res/`](#machines-in-res)
- [Implementation notes](#implementation-notes)
  - [Parsing overview](#parsing-overview)
  - [Validation overview](#validation-overview)
  - [Functional programming examples](#functional-programming-examples)

## Getting started

### Bootstrap

```sh
sudo apt update
sudo apt install -y build-essential m4 pkg-config opam
make
```

### Usage

Build the project:

```sh
make
```

Run the program and print the trace to stdout:

```sh
./ft_turing res/unary_add.json "11+1111="
```

### Runtime output

- Successful runs write a trace file to `log/<machine>_info.log`.
- A successful simulator run exits with status `0`.
- CLI errors, parse errors, validation errors, and system errors exit with status `1`.
- If the machine becomes blocked, that blocked state is reported in the final line of the log file.
- On success, the program is otherwise quiet on `stdout` and `stderr`.

### Make targets

- `make` or `make all` — install required dependencies if needed, then build `ft_turing`
- `make byte` — build the bytecode binary `ft_turing.byte`
- `make unit` or `make ut` — build and run the unit tests
- `make e2e` — run the shell-based CLI checks and end-to-end cases from `test/test_cli.sh` and `test/run_all.sh`
- `make test` — run the unit tests, CLI checks, and end-to-end cases
- `make setup` — create the local `opam` switch and install required dependencies
- `make clean` — remove the build directory `_build/` and generated `log/` files
- `make fclean` — run `clean` and remove `ft_turing` and `ft_turing.byte`
- `make re` — run `fclean` then rebuild everything
- `make distclean` — run `fclean` and also remove the local `_opam/` switch

## Project overview

### Project layout

- `docs/ft_turing.md` — project subject/specification
- `docs/ft_turing.pdf` — PDF version of the subject
- `src/types.ml` — domain types used by the whole program
- `src/parse.ml` — JSON loading and structural parsing
- `src/validate.ml` — semantic validation of a parsed machine and runtime input
- `src/format.ml` — rendering helpers for machines, tapes, and steps
- `src/trace.ml` — log file creation and trace writing
- `src/execute.ml` — machine execution
- `src/ft_turing.ml` — CLI entry point
- `res/` — example machine descriptions
- `test/test_parse.ml` — parser unit tests
- `test/test_validate.ml` — validation unit tests
- `test/test_execute.ml` — execution unit tests
- `test/test_format.ml` — formatting unit tests
- `test/test_trace.ml` — trace/logging unit tests
- `test/test_cli.sh` — CLI checks
- `test/run_all.sh` — end-to-end run script
- `test/fixtures/parse/` — broken JSON fixtures used by parser tests
- `test/fixtures/validate/` — invalid machine fixtures used by validation/CLI tests
- `test/fixtures/e2e/` — small machine fixtures used by end-to-end tests
- `log/` — generated execution logs

### Tests

The test suite has three layers:

- unit tests in `test/test_*.ml` for parsing, validation, execution, formatting, and trace/log writing
- CLI tests in `test/test_cli.sh` for help, bad arguments, stdout tracing, file logging, and parse/validation errors
- end-to-end tests in `test/run_all.sh` that run sample machines from `res/`, plus a blocked-machine fixture, then inspect the generated logs

Use `make unit` for the OCaml unit tests, `make e2e` for the shell-based CLI and end-to-end checks, or `make test` for everything.

## How a Turing machine works

A Turing machine has:

- a tape
- a head on one tape cell
- a current state
- a transition table

The usual model assumes an unbounded tape: the machine can always move farther
left or right, and cells outside the currently used area are blank. In a
simulator, this is handled by growing the represented tape when needed and
treating unseen cells as the blank symbol.

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

## Machines in `res/`

The five JSON files in `res/` are intentionally written as readable, phase-based
machines, not as the smallest possible constructions.

### Common choices used by all sample machines

- `.` is the blank symbol everywhere.
- The project format has one `alphabet` field. It does not separate:
  - the symbols the user is supposed to type
  - the extra symbols the machine needs for work or output
- Because of that, the decision machines include helper symbols in the same alphabet:
  - `y` and `n` are the final answers written on the tape
  - `-` means "this symbol was already consumed/matched"
- The intended external inputs are smaller than the full machine alphabet:
  - `res/02n.json` expects only `0`s
  - `res/0n1n.json` expects a binary word
  - `res/is_palindrome.json` expects a binary word
  - `res/unary_add.json` expects `1*+1*=`
  - `res/utm.json` expects an encoded unary-add machine followed by an encoded input
- State names such as `get_last_one`, `get_most_left`, and `deny` were chosen on purpose.
  They describe the current phase of the algorithm, which makes the machines much easier to audit.

### Inputs intentionally not supported

The simulator only validates that input symbols belong to the machine alphabet and that the blank symbol is not typed directly. It does not enforce a custom grammar for each sample machine.

Because of that, some strings are intentionally outside the supported input domain even if they use only allowed symbols:

- `res/02n.json` is only intended for words made of `0`s. Inputs containing `y` or `n` are not meant to be user data.
- `res/0n1n.json` and `res/is_palindrome.json` are only intended for binary words over `0` and `1`. Inputs containing `-`, `y`, or `n` are not supported as external inputs because those symbols are reserved for work/output on the tape.
- `res/unary_add.json` is only intended for inputs of the form `1*+1*=`. Inputs such as `1+11+111=`, `111`, or `1=+1` are intentionally not supported, even though some of them still pass the generic alphabet check.
- `res/utm.json` does not support raw JSON machine descriptions as runtime input, and it is not a fully generic universal machine for arbitrary encodings. It supports the documented flat encoding used here for the unary-add machine family.

### `res/02n.json`

Goal: decide whether the input is in `0^(2n)`.

This means the word must contain only `0`s, and their total count must be even: `""`, `00`, `0000`, `000000`, and so on.

This is the simplest machine in the folder. It only needs to remember one thing:
`have I seen an even number of 0s so far, or an odd number?`

- `init` means: an even number of `0`s has been seen so far
- `get_pair_zero` means: an odd number of `0`s has been seen so far, so the machine is waiting for the second `0` of the pair

Each `0` just flips between those two states. When the machine reaches the first blank cell:

- from `init`, it writes `y` and halts
- from `get_pair_zero`, it writes `n` and halts

So the machine is really a parity checker written as a Turing machine.
The empty word is accepted because it is `0^(2*0)`.

### `res/0n1n.json`

Goal: decide whether the input is in `0^n1^n`.

This means the word must be made of some number of `0`s followed immediately by exactly the same number of `1`s: `""`, `01`, `0011`, `000111`, and so on.

Idea: repeatedly remove one `0` from the left part and one matching `1` from the right part.
Matched symbols are replaced with `-`.

The main states are:

- `init`:
  - skip old `-` markers
  - if the first unprocessed symbol is `0`, mark it as `-` and start looking for a matching `1`
  - if the first unprocessed symbol is `1`, reject immediately because a valid word must start with all its `0`s
  - if only blank/answer remains, accept
- `get_last_one`: move to the right end of the still-active word
- `is_one`: walk left from that end and check that the last unprocessed symbol is `1`
- `get_most_left`: return to the far left and start the next round
- `deny`: run to the reserved answer cell and change the result to `n`

Why it writes `y` early:

- when `get_last_one` reaches the right edge, it writes `y` in the first blank cell
- that reserves the output position required by the subject: the answer must appear to the right of the word
- if the check later fails, `deny` comes back and overwrites that `y` with `n`

So an accepting run looks like this at a high level:

1. mark one leftmost `0`
2. mark one rightmost `1`
3. go back to the left
4. repeat until only `-` markers remain
5. keep the reserved `y` and halt

If a `0` cannot find a matching `1`, or if a `1` appears before all `0`s are consumed, the machine rejects.

### `res/is_palindrome.json`

Goal: decide whether a binary word reads the same from left to right and from right to left.

Idea: compare the outside symbols first, then move inward.
Matched symbols are replaced with `-`.

The machine works in rounds:

1. `init` reads the leftmost unprocessed symbol
2. if it was `0`, go to `get_last_zero`; if it was `1`, go to `get_last_one`
3. move to the right end and reserve the answer cell with `y`
4. move left over `-` markers until the last unprocessed symbol is found
5. compare it with what was remembered in the state name:
   - `is_zero` accepts `0` and rejects `1`
   - `is_one` accepts `1` and rejects `0`
6. if it matches, replace it with `-`, return with `get_most_left`, and start again

Important edge case: odd-length palindromes.

If `is_zero` or `is_one` moves left and reaches the blank on the far left before
finding another unmatched symbol, then the symbol removed at the beginning of
the round was the middle character. That is still a valid palindrome, so the
machine halts and leaves the already-written `y` in place.

If a mismatch is found, `deny` moves right until it reaches the reserved answer
cell and changes `y` to `n`.

### `res/unary_add.json`

Goal: compute unary addition on inputs of the form `1*+1*=`.

Example:

```text
11+1111=   means 2 + 4
```

The result should be six `1`s on the tape.

This machine does not need an extra marker symbol. It only has to remove the
separators while preserving the number of `1`s.

The states are:

- `A`: scan right until `=`
- `B`: look one cell left of `=`
  - if it is `1`, move `=` one position left by rewriting that `1` as `=`
  - if it is `+`, the right operand is empty, so erase `+` and halt
- `C`: move left until `+`, then rewrite `+` as `1`
- `D`: move right until `=`, then erase `=`
- `E`: halt

A full run for `11+1111=` is:

```text
11+1111=
11+111=
111111=
111111
```

What happened:

- one `1` from the right operand is reused to replace `+`
- the `=` marker shifts left onto that reused position
- then `=` is erased

The total number of `1`s is preserved, so the final block of `1`s has length `a + b`.

### `res/utm.json`

Goal: simulate the unary-add machine from `res/unary_add.json` using only another Turing machine.

This file looks very different from the others because a Turing machine cannot read JSON objects directly.
It only sees a tape of symbols. So the simulated machine is encoded as a flat string on the tape.

The encoded input format is:

```text
alphabet|blank|states|initial|finals|transitions|_data
```

For the bundled unary-add machine, the sample input from `test/run_all.sh` is:

```text
1.+=|.|ABCDE|A|E|A.A.RA1A1RA+A+RA=B.LB1C=LB+E.LC1C1LC+D1RD1D1RD=E.R|_11+1111=
```

Read it as:

- `1.+=` — simulated alphabet
- `.` — simulated blank
- `ABCDE` — simulated states, encoded as single characters
- `A` — simulated initial state
- `E` — simulated final state
- `A.A.RA1A1RA+A+RA=B.L...` — simulated transitions
- `_11+1111=` — simulated tape, where `_` marks the simulated head position

One encoded transition always uses 5 characters:

```text
<from><read><to><write><move>
```

Examples:

- `A1A1R` means: in state `A`, reading `1`, stay in `A`, write `1`, move right
- `B1C=L` means: in state `B`, reading `1`, go to `C`, write `=`, move left

High-level loop of the universal machine:

1. find `_` to know where the simulated head is
2. recover the simulated current symbol
3. recover the simulated current state
4. scan the encoded transition list for the block matching `(state, symbol)`
5. copy the encoded `to`, `write`, and `move` fields into working positions
6. update the simulated tape after the last `|`
7. move `_` left or right
8. update the stored simulated state and repeat
9. stop when the stored simulated state is final

Why `utm.json` is so large:

- every tiny subtask above must be expressed as ordinary TM transitions
- a plain TM has no variables, no stack, and no parser helpers
- each branch such as `read symbol is +` or `current state is C` becomes its own cluster of states

That is why the state names are long and mechanical. They encode the job being done, for example:

- `40_st_1_A_...` means "searching a transition for simulated state `A` while the simulated read symbol is `1`"
- `42_extract_R_...` means "apply the transition and perform a simulated right move"

This is not a fully generic JSON interpreter. It is a deliberate, subject-focused universal machine for the encoded unary-add machine family above. That tradeoff keeps the construction understandable and still satisfies the requirement: one machine in `res/` can run the unary-add machine from the same folder.

## Implementation notes

The sections below explain the main design choices in parsing, validation, and
OCaml style.

### Parsing overview

The parsing code is intentionally split into small steps.

#### 1. Domain types first

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

#### 2. Raw JSON is loaded first

`load_json` uses `Yojson.Basic.from_file`.

- input: file path
- output: `Yojson.Basic.t`

`Yojson.Basic.t` is the library's generic JSON tree type. It can represent any
JSON value: object, array, string, number, boolean, or null.

This is not yet a `machine`. It is only the raw parsed JSON tree.

#### 3. Small helper functions narrow the JSON structure

`src/parse.ml` defines four small helpers:

- `field name json` — expects a JSON object and returns one field from it
- `as_string json` — expects a JSON string and returns an OCaml `string`
- `as_list json` — expects a JSON array and returns an OCaml list of JSON values
- `as_char json` — expects a JSON string of length 1 and returns an OCaml `char`

These helpers do only one job each. If the JSON structure is wrong, they raise `Parse_error`.

This keeps the rest of the parser simple: the higher-level functions can say
what they want to extract instead of re-checking the JSON type every time.

#### 4. Field parsers use those helpers

`parse_name`, `parse_alphabet`, `parse_blank`, `parse_states`,
`parse_initial`, and `parse_finals` all follow the same pattern: fetch one
field, then convert it to the expected OCaml type.

For example, `parse_alphabet`:

1. gets the `"alphabet"` field
2. checks that it is a JSON array
3. converts each one-character string into an OCaml `char`

This keeps the parser regular: once the helpers exist, each field parser is a
small description of the data it expects.

#### 5. Transition parsing mirrors the JSON structure

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

#### 6. Parsing and validation are separate

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

### Validation overview

The validation code is also split into small steps.

#### Validation rules and why they exist

The current implementation enforces these rules:

- `alphabet` must be non-empty and contain no duplicates, so symbols form a usable set.
- `blank` must belong to `alphabet`, so empty tape cells use a legal tape symbol.
- `states` must be non-empty and contain no duplicates, so state names are usable and unambiguous.
- `initial` must be in `states`, and `finals` must be a duplicate-free subset of `states`, so execution only starts or halts in declared states.
- each transition source state and each transition `to_state` must be in `states`, so the transition table never references unknown states.
- each transition `read` and `write` symbol must be in `alphabet`, so the machine never reads or writes unknown symbols.
- within one source state, `read` symbols must be unique, so `(state, symbol)` lookup stays deterministic.
- runtime input must use only alphabet symbols and must not contain `blank`, so user input starts as tape data, not empty cells.

#### 1. Validation works on typed values, not raw JSON

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

#### 2. A dedicated exception separates semantic failures from parse failures

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

#### 3. Small helpers keep the validation rules readable

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

#### 4. Machine and transition validation follow the structure of the data

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

#### 5. Input validation is separate from machine validation

The machine description and the runtime input are different things, so they are validated separately.

`validate_input` checks:

- every input symbol is in `alphabet`
- the input does not contain `blank`

This is the usual distinction:

- the tape alphabet includes the blank symbol
- the user-provided input must not already contain blank cells

#### 6. Tests focus on one broken rule at a time

`test/test_validate.ml` builds a known-good machine value and then changes one part per test.

That test style is useful because validation stops at the first failure. If one
test breaks several rules at once, it becomes harder to tell which rule is
actually being exercised.

### Functional programming examples

Here, "functional programming" mostly means: describe data with types, pass
values through small functions, and process lists without mutable state.

#### 1. Variants encode a closed set of values

```ocaml
type action =
  | Left
  | Right
```

`action` can only be `Left` or `Right`. This is safer than keeping head movement
as a free-form string everywhere in the program.

#### 2. Pattern matching converts raw input into typed values

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

#### 3. List functions transform and validate data

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

#### 4. Recursion follows the shape of an immutable list

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

#### 5. Small functions compose into larger behavior

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

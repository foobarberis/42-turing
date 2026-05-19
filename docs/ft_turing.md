# Chapter IV — Generic rules

- The project must be written in OCaml and follow a functional programming style.
- You may use OCaml and its basic libraries. A library that does all the work for you is forbidden.
- Submit a `Makefile` able to compile the code with `ocamlopt` and `ocamlc`. It must detect any missing libraries and/or tools required by the program and install them via `opam`. The evaluator must not need to install anything manually before the defense.
- The special token `;;` is only used to terminate an expression in the interpreter. It must not appear in submitted source files.
- Do not rely on imperative style. Prefer iterators such as `iter`, `map`, and `fold`, along with anonymous functions and immutable values.

# Chapter V — Mandatory part

## V.1 The Turing machine

Write a program able to simulate a single-head, single-tape Turing machine from a JSON machine description given as a parameter to the program. The JSON machine description is slightly simpler than a formal description of the same machine.

### Example JSON machine description

```json
{
  "name": "unary_sub",
  "alphabet": ["1", ".", "-", "="],
  "blank": ".",
  "states": ["scanright", "eraseone", "subone", "skip", "HALT"],
  "initial": "scanright",
  "finals": ["HALT"],
  "transitions": {
    "scanright": [
      { "read": ".", "to_state": "scanright", "write": ".", "action": "RIGHT" },
      { "read": "1", "to_state": "scanright", "write": "1", "action": "RIGHT" },
      { "read": "-", "to_state": "scanright", "write": "-", "action": "RIGHT" },
      { "read": "=", "to_state": "eraseone", "write": ".", "action": "LEFT" }
    ],
    "eraseone": [
      { "read": "1", "to_state": "subone", "write": "=", "action": "LEFT" },
      { "read": "-", "to_state": "HALT", "write": ".", "action": "LEFT" }
    ],
    "subone": [
      { "read": "1", "to_state": "subone", "write": "1", "action": "LEFT" },
      { "read": "-", "to_state": "skip", "write": "-", "action": "LEFT" }
    ],
    "skip": [
      { "read": ".", "to_state": "skip", "write": ".", "action": "LEFT" },
      { "read": "1", "to_state": "scanright", "write": ".", "action": "RIGHT" }
    ]
  }
}
```

### JSON fields

- `name`: The name of the described machine.
- `alphabet`: The input alphabet and working alphabet merged into a single alphabet for simplicity, including the blank character. Each character of the alphabet must be a string of length exactly `1`.
- `blank`: The blank character. It must be part of the alphabet and must **not** be part of the input.
- `states`: The exhaustive list of the machine's state names.
- `initial`: The initial state of the machine. It must be part of the `states` list.
- `finals`: The exhaustive list of the machine's final states. This list must be a sub-list of the `states` list.
- `transitions`: A dictionary of the machine's transitions indexed by state name. Each transition is a list of dictionaries, and each dictionary describes the transition for a given character under the head of the machine.
  - `read`: The character of the machine's alphabet on the tape under the head.
  - `to_state`: The new state of the machine after the transition.
  - `write`: The character of the machine's alphabet to write on the tape before moving the head.
  - `action`: Head movement for this transition: either `LEFT` or `RIGHT`.

### Required command-line help

```text
$ ./ft_turing --help
usage: ft_turing [-h] [-l logfile] jsonfile input

positional arguments:
  jsonfile    json description of the machine
  input       input of the machine

optional arguments:
  -h, --help  show this help message and exit
  -l logfile, --log logfile
              write trace to logfile instead of stdout
```

### Required behavior

- The program must detect and reject ill-formatted or invalid machine descriptions and inputs with a relevant error message.
- The program must never crash for any reason.
- The program must output at least the state of the tape with a visible representation of the head at each transition. For example:

```text
$ ./ft_turing res/unary_sub.json "111-11="
********************************************************************************
*                                                                              *
*                                  unary_sub                                   *
*                                                                              *
********************************************************************************
Alphabet: [ 1, ., -, = ]
States : [ scanright, eraseone, subone, skip, HALT ]
Initial : scanright
Finals : [ HALT ]
(scanright, .) -> (scanright, ., RIGHT)
(scanright, 1) -> (scanright, 1, RIGHT)
(scanright, -) -> (scanright, -, RIGHT)
(scanright, =) -> (eraseone, ., LEFT)
(eraseone, 1) -> (subone, =, LEFT)
(eraseone, -) -> (HALT, ., LEFT)
(subone, 1) -> (subone, 1, LEFT)
(subone, -) -> (skip, -, LEFT)
(skip, .) -> (skip, ., LEFT)
(skip, 1) -> (scanright, ., RIGHT)
********************************************************************************
[<1>11-11=.............] (scanright, 1) -> (scanright, 1, RIGHT)
[1<1>1-11=.............] (scanright, 1) -> (scanright, 1, RIGHT)
[11<1>-11=.............] (scanright, 1) -> (scanright, 1, RIGHT)
[111<->11=.............] (scanright, -) -> (scanright, -, RIGHT)
[111-<1>1=.............] (scanright, 1) -> (scanright, 1, RIGHT)
[111-1<1>=.............] (scanright, 1) -> (scanright, 1, RIGHT)
[111-11<=>.............] (scanright, =) -> (eraseone, ., LEFT)
[111-1<1>..............] (eraseone, 1) -> (subone, =, LEFT)
[111-<1>=..............] (subone, 1) -> (subone, 1, LEFT)
[111<->1=..............] (subone, -) -> (skip, -, LEFT)
[11<1>-1=..............] (skip, 1) -> (scanright, ., RIGHT)
[11.<->1=..............] (scanright, -) -> (scanright, -, RIGHT)
[11.-<1>=..............] (scanright, 1) -> (scanright, 1, RIGHT)
[11.-1<=>..............] (scanright, =) -> (eraseone, ., LEFT)
[11.-<1>...............] (eraseone, 1) -> (subone, =, LEFT)
[11.<->=...............] (subone, -) -> (skip, -, LEFT)
[11<.>-=...............] (skip, .) -> (skip, ., LEFT)
[1<1>.-=...............] (skip, 1) -> (scanright, ., RIGHT)
[1.<.>-=...............] (scanright, .) -> (scanright, ., RIGHT)
[1..<->=...............] (scanright, -) -> (scanright, -, RIGHT)
[1..-<=>...............] (scanright, =) -> (eraseone, ., LEFT)
[1..<->................] (eraseone, -) -> (HALT, ., LEFT)
```

- Logging the tape state to a file instead of the terminal is also acceptable if it improves readability or clarity. In this implementation, `-l` or `--log` writes the trace to a file.
- If the machine becomes blocked, the program must detect it and inform the user what happened.

## V.2 Machine descriptions

Writing a Turing machine is a lot of fun. Using it to compute actual things is even better. In the previous section, the example machine computes unary subtraction. In that example, the alphabet is given, but choosing an alphabet is not always straightforward because the working alphabet can be larger than the input alphabet.

Write 5 machine descriptions for the program:

1. A machine able to compute unary addition.
2. A machine able to decide whether its input is a palindrome. Before halting, write the result on the tape as `n` or `y` to the right of the rightmost character on the tape.
3. A machine able to decide whether the input is a word of the language `0^n1^n`, for example `000111` or `0000011111`. Before halting, write the result on the tape as `n` or `y` to the right of the rightmost character on the tape.
4. A machine able to decide whether the input is a word of the language `0^(2n)`, for example `00` or `0000`, but not `000` or `00000`. Before halting, write the result on the tape as `n` or `y` to the right of the rightmost character on the tape.
5. A machine able to run the first machine in this list, the one computing unary addition. The machine alphabet, states, transitions, and input **are** the input of the machine you are writing, encoded as you see fit.

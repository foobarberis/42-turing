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

# Evaluation

## Scale for Project FT_TURING

### Introduction

For the good of this evaluation, we ask you to:

- Stay mannerly, polite, respectful, and constructive during this evaluation. The trust between you and the 42 community depends on it.
- Bring out to the graded student (or team) any mistake they might have made.
- Accept that there might be differences of interpretation of the subject or the rules between you and the graded student (or team). Stay open-minded and grade as honestly as possible.

### Guidelines

- You must grade only what is present in the graded student's (or team's) repository.

### Attachments

- [Subject](https://cdn.intra.42.fr/pdf/pdf/3708/ft_turing.en.pdf)

## Preliminaries

This section is dedicated to setting up the evaluation and testing the prerequisites. It does not reward points, but if something is wrong at this step or at any point of the evaluation, the grade is 0, and an appropriate flag might be checked if needed.

### Respect of the rules

- The graded student (or team) work is present on their repository.
- The graded student (or team) is able to explain their work at any time of the evaluation.
- The generic rules of the subject are respected at any time of the evaluation.
- According to the subject, the program can be built with `ocamlc` or `ocamlopt` by using a `Makefile`. This `Makefile` also installs anything necessary by using OPAM.

- [ ] Yes
- [ ] No

## Mandatory part - The program

The first section of the mandatory part is to write a program in OCaml (or Haskell) able to simulate a Turing machine according to a machine description.

### Usage

Launch the program without parameters to display its usage. Is the usage what is expected according to the subject?

- [ ] Yes
- [ ] No

### JSON description

Machine descriptions are fed to the program as JSON descriptions. Is the program able to:

- Read this description?
- Assert that this description is valid syntactically and semantically according to the subject?
- Reject empty and ill-formatted descriptions, nonexistent description files, etc.?

- [ ] Yes
- [ ] No

### Execution

Test if the program is able to execute the machine given in the JSON description on the input given as a parameter to the program. You must ensure that:

- The machine computes the expected result, including if that result is the machine being blocked. In that case, correct error handling is expected.
- The program displays at least the state of the tape for each transition. If the tape states are logged into a file to free display room on standard output and allow a dynamic observation of the tape by using the `\r` character, give the points.

- [ ] Yes
- [ ] No

## Mandatory part - The 5 machine descriptions

The second section of the mandatory part is to write 5 machine descriptions that the program can simulate.

### Unary addition

A machine able to compute a unary addition.

Test the machine with different valid and invalid inputs. Does the machine compute the correct result or report an error consistently?

- [ ] Yes
- [ ] No

### Palindrome

A machine able to detect a palindrome.

Does the machine write an `n` or a `y` on the tape before halting, and is this result always consistent with the input?

- [ ] Yes
- [ ] No

### `0^n1^n`

A machine able to decide if the input is a word of the language `0^n1^n`, for instance the words `000111` or `0000011111`.

Does the machine write an `n` or a `y` on the tape before halting, and is this result always consistent with the input?

- [ ] Yes
- [ ] No

### `0^2n`

A machine able to decide if the input is a word of the language `0^2n`, for instance the words `00` or `0000`, but not the words `000` or `00000`.

Does the machine write an `n` or a `y` on the tape before halting, and is this result always consistent with the input?

- [ ] Yes
- [ ] No

### Simulation of simulation

A machine able to simulate the first machine, `unary_addition`. The simulated machine's alphabet, states, transitions, and input are the input of the simulating machine, encoded as the group has seen fit.

Is the simulated machine's result always consistent with its input?

- [ ] Yes
- [ ] No


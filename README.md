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
- `make setup` — create the local `opam` switch and install required dependencies
- `make test` — run `test/run_all.sh` and write the output to `test/log.txt`
- `make clean` — remove the build directory `_build/`
- `make fclean` — run `clean` and remove `ft_turing` and `ft_turing.byte`
- `make re` — run `fclean` then rebuild everything
- `make distclean` — run `fclean` and also remove the local `_opam/` switch

## Layout

- `src/types.ml`
- `src/parse.ml`
- `src/validate.ml`
- `src/execute.ml`
- `src/ft_turing.ml`
- `res/`
- `test/run_all.sh`

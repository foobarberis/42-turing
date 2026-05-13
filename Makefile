.DEFAULT_GOAL := all

NAME = ft_turing
BYTE = $(NAME).byte
SRCDIR = src
BUILDDIR = _build
UNIT = $(BUILDDIR)/test_unit.byte
UNIT_OBJ = $(BUILDDIR)/test_parse.cmo $(BUILDDIR)/test_validate.cmo

MODULES = types parse validate execute ft_turing
NATIVE_OBJ = $(addprefix $(BUILDDIR)/,$(addsuffix .cmx,$(MODULES)))
BYTE_OBJ = $(addprefix $(BUILDDIR)/,$(addsuffix .cmo,$(MODULES)))

SWITCH = .
OCAML_VERSION = 5.2.1
PACKAGES = yojson

RUN = opam exec --switch=$(SWITCH) --
PKG = -package $(PACKAGES)
OCAMLFLAGS = -g -I $(BUILDDIR)

all: $(NAME)

byte: $(BYTE)

setup:
	@command -v opam >/dev/null 2>&1 || { echo "Error: opam is required"; exit 1; }
	@opam init --disable-sandboxing --bare -y >/dev/null 2>&1 || true
	@if [ ! -d _opam ]; then opam switch create $(SWITCH) ocaml-base-compiler.$(OCAML_VERSION) -y; fi
	@opam install --switch=$(SWITCH) -y ocamlfind $(PACKAGES)

$(BUILDDIR):
	@mkdir -p $(BUILDDIR)

$(BUILDDIR)/%.cmx: $(SRCDIR)/%.ml Makefile | $(BUILDDIR) setup
	$(RUN) ocamlfind ocamlopt $(OCAMLFLAGS) $(PKG) -c $< -o $@

$(BUILDDIR)/%.cmo: $(SRCDIR)/%.ml Makefile | $(BUILDDIR) setup
	$(RUN) ocamlfind ocamlc $(OCAMLFLAGS) $(PKG) -c $< -o $@

$(BUILDDIR)/test_parse.cmo: test/test_parse.ml Makefile | $(BUILDDIR) setup
	$(RUN) ocamlfind ocamlc $(OCAMLFLAGS) $(PKG) -c $< -o $@

$(BUILDDIR)/test_validate.cmo: test/test_validate.ml Makefile | $(BUILDDIR) setup
	$(RUN) ocamlfind ocamlc $(OCAMLFLAGS) $(PKG) -c $< -o $@

$(NAME): $(NATIVE_OBJ)
	$(RUN) ocamlfind ocamlopt $(OCAMLFLAGS) $(PKG) -linkpkg $^ -o $@

$(BYTE): $(BYTE_OBJ)
	$(RUN) ocamlfind ocamlc $(OCAMLFLAGS) $(PKG) -linkpkg $^ -o $@

$(UNIT): $(BUILDDIR)/types.cmo $(BUILDDIR)/parse.cmo $(BUILDDIR)/validate.cmo $(UNIT_OBJ)
	$(RUN) ocamlfind ocamlc $(OCAMLFLAGS) $(PKG) -linkpkg $^ -o $@

unit ut: $(UNIT)
	$(RUN) ./$(UNIT)

test: $(NAME) test/run_all.sh
	$(RUN) ./test/run_all.sh

clean:
	@rm -rf $(BUILDDIR)

fclean: clean
	@rm -f $(NAME) $(BYTE)

re: fclean all

distclean: fclean
	@rm -rf _opam

.PHONY: all byte setup unit ut test clean fclean re distclean

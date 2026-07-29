.DEFAULT_GOAL := all

NAME = ft_turing
BYTE = $(NAME).byte
SRCDIR = src
BUILDDIR = _build
UNIT = $(BUILDDIR)/test_unit.byte
UNIT_OBJ = $(BUILDDIR)/test_parse.cmo \
		   $(BUILDDIR)/test_validate.cmo \
		   $(BUILDDIR)/test_execute.cmo \
		   $(BUILDDIR)/test_format.cmo \
		   $(BUILDDIR)/test_trace.cmo

MODULES = types format trace parse validate execute ft_turing
SRC_ML = $(addprefix $(SRCDIR)/,$(addsuffix .ml,$(MODULES)))
TEST_ML = test/test_parse.ml \
		  test/test_validate.ml \
		  test/test_execute.ml \
		  test/test_format.ml \
		  test/test_trace.ml
NATIVE_OBJ = $(addprefix $(BUILDDIR)/,$(addsuffix .cmx,$(MODULES)))
BYTE_OBJ = $(addprefix $(BUILDDIR)/,$(addsuffix .cmo,$(MODULES)))
DEPFILE = $(BUILDDIR)/depend.mk

SWITCH = .
OCAML_VERSION = 5.2.1
FIND_PACKAGES = yojson,unix
OPAM_PACKAGES = yojson

OPAMROOT = $(CURDIR)/.opam
OPAM = OPAMROOT="$(OPAMROOT)" opam
RUN = $(OPAM) exec --switch=$(SWITCH) --
PKG = -package $(FIND_PACKAGES)
OCAMLFLAGS = -g -I $(BUILDDIR)
DEPFLAGS = -I $(SRCDIR)

ifneq ($(filter clean fclean distclean setup,$(MAKECMDGOALS)),)
SKIP_DEPS = 1
endif

ifneq ($(SKIP_DEPS),1)
-include $(DEPFILE)
endif

all: $(NAME)

byte: $(BYTE)

setup:
	@command -v opam >/dev/null 2>&1 || { echo "Error: opam is required"; exit 1; }
	@[ -f "$(OPAMROOT)/config" ] || $(OPAM) init --disable-sandboxing --bare -y
	@if [ ! -d _opam ]; then $(OPAM) switch create $(SWITCH) ocaml-base-compiler.$(OCAML_VERSION) -y; fi
	@$(OPAM) install --switch=$(SWITCH) -y ocamlfind $(OPAM_PACKAGES)

$(BUILDDIR):
	@mkdir -p $(BUILDDIR)

$(DEPFILE): $(SRC_ML) $(TEST_ML) Makefile | $(BUILDDIR) setup
	$(RUN) ocamlfind ocamldep $(PKG) $(DEPFLAGS) $(SRC_ML) $(TEST_ML) | \
		sed \
			-e 's#^\(src\|test\)/\([^ ]*\)\.cmo:#$(BUILDDIR)/\2.cmo:#' \
			-e 's#^\(src\|test\)/\([^ ]*\)\.cmx:#$(BUILDDIR)/\2.cmx:#' \
			-e 's#\(src\|test\)/\([^ ]*\)\.cmo#$(BUILDDIR)/\2.cmo#g' \
			-e 's#\(src\|test\)/\([^ ]*\)\.cmx#$(BUILDDIR)/\2.cmx#g' > $@

$(BUILDDIR)/%.cmx: $(SRCDIR)/%.ml Makefile | $(BUILDDIR) setup
	$(RUN) ocamlfind ocamlopt $(OCAMLFLAGS) $(PKG) -c $< -o $@

$(BUILDDIR)/%.cmo: $(SRCDIR)/%.ml Makefile | $(BUILDDIR) setup
	$(RUN) ocamlfind ocamlc $(OCAMLFLAGS) $(PKG) -c $< -o $@

$(BUILDDIR)/test_parse.cmo: test/test_parse.ml Makefile | $(BUILDDIR) setup
	$(RUN) ocamlfind ocamlc $(OCAMLFLAGS) $(PKG) -c $< -o $@

$(BUILDDIR)/test_validate.cmo: test/test_validate.ml Makefile | $(BUILDDIR) setup
	$(RUN) ocamlfind ocamlc $(OCAMLFLAGS) $(PKG) -c $< -o $@

$(BUILDDIR)/test_execute.cmo: test/test_execute.ml Makefile | $(BUILDDIR) setup
	$(RUN) ocamlfind ocamlc $(OCAMLFLAGS) $(PKG) -c $< -o $@

$(BUILDDIR)/test_format.cmo: test/test_format.ml Makefile | $(BUILDDIR) setup
	$(RUN) ocamlfind ocamlc $(OCAMLFLAGS) $(PKG) -c $< -o $@

$(BUILDDIR)/test_trace.cmo: test/test_trace.ml Makefile | $(BUILDDIR) setup
	$(RUN) ocamlfind ocamlc $(OCAMLFLAGS) $(PKG) -c $< -o $@

$(NAME): $(NATIVE_OBJ)
	$(RUN) ocamlfind ocamlopt $(OCAMLFLAGS) $(PKG) -linkpkg $^ -o $@

$(BYTE): $(BYTE_OBJ)
	$(RUN) ocamlfind ocamlc $(OCAMLFLAGS) $(PKG) -linkpkg $^ -o $@

$(UNIT): $(BUILDDIR)/types.cmo $(BUILDDIR)/format.cmo $(BUILDDIR)/trace.cmo $(BUILDDIR)/parse.cmo $(BUILDDIR)/validate.cmo $(BUILDDIR)/execute.cmo $(UNIT_OBJ)
	$(RUN) ocamlfind ocamlc $(OCAMLFLAGS) $(PKG) -linkpkg $^ -o $@

unit ut: $(UNIT)
	@$(RUN) ./$(UNIT)

e2e: $(NAME) test/test_cli.sh test/run_all.sh
	@chmod +x test/test_cli.sh test/run_all.sh
	@printf '\n'
	@$(RUN) ./test/test_cli.sh
	@$(RUN) ./test/run_all.sh

test: unit e2e

clean:
	@rm -rf $(BUILDDIR)
	@rm -rf log

fclean: clean
	@rm -f $(NAME) $(BYTE)

re: fclean all

distclean: fclean
	@rm -rf _opam .opam

.PHONY: all byte setup unit ut e2e test clean fclean re distclean

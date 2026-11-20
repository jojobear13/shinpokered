.DEFAULT_GOAL := all
.PHONY: all red clean tidy
.DELETE_ON_ERROR:

RGBDS ?=
RGBASM ?= $(RGBDS)rgbasm
RGBFIX ?= $(RGBDS)rgbfix
RGBGFX ?= $(RGBDS)rgbgfx
RGBLINK ?= $(RGBDS)rgblink

# Resolve repo-relative tool paths before entering the temporary build tree.
tool_path = $(if $(findstring /,$(1)),$(abspath $(1)),$(1))

all red: red.gbc
clean tidy:
	rm -f red.gbc

ifeq ($(BUILD_IN_TEMP),1)
.SUFFIXES:
objects := audio.o main.o text.o wram.o
RGBASMFLAGS := -Weverything -h -l -D _RED -D _ENCRED -D _SWBACKS -D _FPLAYER -D _MOVENPCS -D _RUNSHOES -D _EXPBAR

$(shell $(MAKE) -C tools >&2)
ifeq ($(wildcard tools/scan_includes tools/gfx tools/pkmncompress),tools/scan_includes tools/gfx tools/pkmncompress)
else
$(error Could not build the graphics and dependency tools)
endif

rgbdscheck.o: rgbdscheck.asm
	$(RGBASM) -o $@ $<

define assemble
$(1): $(2) $(shell tools/scan_includes $(2)) | rgbdscheck.o
	$$(RGBASM) $$(RGBASMFLAGS) -o $$@ $$<
endef
$(foreach obj,$(objects),$(eval $(call assemble,$(obj),$(obj:.o=.asm))))

red.gbc: $(objects) layout.link
	$(RGBLINK) -d -l layout.link -o $@ $(objects)
	$(RGBFIX) -cjsv -k 01 -l 0x33 -m 0x13 -p 0 -r 03 -t "POKEMON RED" $@

gfx/red/intro_nido_1.2bpp: rgbgfx += -h
gfx/red/intro_nido_2.2bpp: rgbgfx += -h
gfx/red/intro_nido_3.2bpp: rgbgfx += -h

gfx/game_boy.2bpp: tools/gfx += --remove-duplicates
gfx/theend.2bpp: tools/gfx += --interleave --png=$<
gfx/tilesets/%.2bpp: tools/gfx += --trim-whitespace

%.png: ;

%.2bpp: %.png
	$(RGBGFX) $(rgbgfx) -o $@ $<
	$(if $(tools/gfx),\
		tools/gfx $(tools/gfx) -o $@ $@)
%.1bpp: %.png
	$(RGBGFX) $(rgbgfx) -d1 -o $@ $<
	$(if $(tools/gfx),\
		tools/gfx $(tools/gfx) -d1 -o $@ $@)
%.pic:  %.2bpp
	tools/pkmncompress $< $@

else
source_dirs := audio constants custom_functions data engine gfx home macros maps pic scripts text
tool_sources := $(wildcard tools/*.c tools/*.h) tools/Makefile
source_files := $(shell find $(source_dirs) -type f ! -name '*.1bpp' ! -name '*.2bpp' ! -name '*.pic')
fixed_graphics := gfx/oak_title_layers.2bpp
inputs := Makefile layout.link $(wildcard *.asm) $(tool_sources) $(source_files) $(fixed_graphics)

red.gbc: $(inputs)
	+@set -eu; \
	build_dir=$$(mktemp -d); \
	trap 'rm -rf "$$build_dir"' EXIT; \
	trap 'exit 1' HUP INT TERM; \
	tar -cf "$$build_dir/inputs.tar" $(inputs); \
	tar -xf "$$build_dir/inputs.tar" -C "$$build_dir"; \
	$(MAKE) -C "$$build_dir" BUILD_IN_TEMP=1 \
		RGBASM="$(call tool_path,$(RGBASM))" RGBFIX="$(call tool_path,$(RGBFIX))" \
		RGBGFX="$(call tool_path,$(RGBGFX))" RGBLINK="$(call tool_path,$(RGBLINK))" red.gbc; \
	cp "$$build_dir/red.gbc" "$@"
endif

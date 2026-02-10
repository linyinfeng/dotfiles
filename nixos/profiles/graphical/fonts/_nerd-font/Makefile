FONT_FILES = $(shell ls ./fonts)
FONTS = $(basename $(FONT_FILES))
OUT_PATH = ${out}/share/fonts/truetype

all: install

.PHONY: all build install clean test

build: $(foreach font,$(FONTS),patched/$(font)-nf.ttf)
install: $(foreach font,$(FONTS),$(OUT_PATH)/$(font)-nf.ttf)

patched/%-nf.ttf: fonts/%.ttf patched
	{ \
	  tmp=$$(mktemp -t --directory nerf-font-patcher.XXXXXXXXXX); \
	  echo $$tmp; \
	  nerd-font-patcher $< \
          --complete \
          --careful \
          --outputdir $$tmp; \
	  cp $$tmp/* $@; \
	  rm -rf $$tmp; \
	}

$(OUT_PATH)/%: patched/% $(OUT_PATH)
	cp $< $@

patched:
	mkdir -p $@

$(OUT_PATH):
	mkdir -p $@

clean:
	rm -rf patched
	rm -rf $(OUT_PATH)

test:

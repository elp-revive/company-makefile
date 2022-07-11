EMACS ?= emacs
EASK ?= eask
wget  ?= wget
ruby  ?= ruby

.PHONY: test help all
all: help 

test:  ## Run tests
	$(EMACS) -Q -batch -L . -l ert -l test/company-makefile-tests.el \
		-f ert-run-tests-batch-and-exit

README.md: el2markdown.el company-makefile.el  ## Create README.md
	$(EMACS) -batch -l $< company-makefile.el -f el2markdown-write-readme
	$(RM) $@~

.INTERMEDIATE: el2markdown.el
el2markdown.el:  ## Download el2markdown.el converter
	$(wget) -q -O $@                                                 \
	"https://github.com/Lindydancer/el2markdown/raw/master/el2markdown.el"

company-makefile-data.el: build/impvars.json build/defaults.el  ## Generate completion data
	$(EMACS) -batch -L . -l build/build.el -f batch-create-data $^

.INTERMEDIATE: build/defaults.el
build/defaults.el: build/defaults ## Get default make values from local make
	@(cd build && ./$(<F))

.INTERMEDIATE: build/impvars.json
build/impvars.json: build/vars.rb build/build.el ## Implicit variable info to JSON
	$(ruby) build/vars.rb

help:  ## Show help
	@grep -E '^[/.%a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) |         \
	sort | awk                                                       \
	'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: clean checkdoc lint package install compile test

ci: clean package install compile

package:
	@echo "Packaging..."
	$(EASK) package

install:
	@echo "Installing..."
	$(EASK) install

compile:
	@echo "Compiling..."
	$(EASK) compile

test:
	@echo "Testing..."
	$(EASK) test ert ./test/*.el

checkdoc:
	@echo "Run checkdoc..."
	$(EASK) lint checkdoc

lint:
	@echo "Run package-lint..."
	$(EASK) lint package

clean:
	$(EASK) clean-all

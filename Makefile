#-*- mode: makefile; -*-
SHELL := /bin/bash

.SHELLFLAGS := -ec

VERSION := $(shell test -e VERSION || echo 1.0.0 > VERSION; cat VERSION)

MODULE_NAME  ?= $(shell perl -MCwd=getcwd,abs_path -MFile::Basename=basename -e '$$m=basename(abs_path getcwd); $$m =~s/\-/::/g; print $$m')

MODULE_PATH = lib/$(shell echo $(MODULE_NAME) | perl -npe 's/::/\//g;').pm

PROJECT_NAME ?= $(shell echo $(MODULE_NAME) | sed -e 's/::/-/g;')

UNIT_TEST_NAME = $(shell TEST_NAME=$(PROJECT_NAME) perl -e 'printf q{t/00-%s.t}, lc $$ENV{TEST_NAME}')

MAKE_CPAN_DIST := $(shell command -v make-cpan-dist.pl)
SCANDEPS       := $(shell command -v scandeps-static.pl)
POD2MARKDOWN   := $(shell command -v pod2markdown)
GIT            := $(shell command -v git)

GIT_NAME     ?= $(shell $(GIT) config --global user.name || echo "Anonymouse")
GIT_EMAIL    ?= $(shell $(GIT) config --global user.email || echo "anonymouse@example.org")
GITHUB_USER  ?= $(shell $(GIT) config --global user.github || echo "anonymouse")

MIN_PERL_VERSION ?= 5.010

BUILDSPEC_TEMPLATE := $(shell perl -MFile::ShareDir=dist_file -e 'print dist_file(q{CPAN-Maker-Bootstrapper}, q{buildspec.yml.tmpl});' 2>/dev/null || echo buildspec.yml.tmpl )

UNIT_TEST_TEMPLATE := $(shell perl -MFile::ShareDir=dist_file -e 'print dist_file(q{CPAN-Maker-Bootstrapper}, q{test.t.tmpl});' 2>/dev/null || echo test.t.tmpl )

CPAN_MAKER_SCAN ?= ON

define find-files
$(1) := $(patsubst %.in,%,$(shell find $(2) -type f -name "$(3)"))
endef

$(eval $(call find-files,PERL_MODULES,lib,*.pm.in))
$(eval $(call find-files,BIN_FILES,bin,*.sh.in))
$(eval $(call find-files,TESTS,t,*.t))
$(eval $(call find-files,SOURCE_FILES,lib bin,*.p[ml].in))

%.pm: %.pm.in
	@sed -e 's/[@]PACKAGE_VERSION[@]/$(VERSION)/' \
	    -e 's/[@]MODULE_NAME[@]/$(MODULE_NAME)/' < $< > $@

%.pl: %.pl.in
	@sed -e 's/[@]PACKAGE_VERSION[@]/$(VERSION)/' \
	    -e 's/[@]MODULE_NAME[@]/$(MODULE_NAME)/' < $< > $@; \
	chmod +x $@

%.sh: %.sh.in
	@sed -e 's/[@]PACKAGE_VERSION[@]/$(VERSION)/' \
	    -e 's/[@]MODULE_NAME[@]/$(MODULE_NAME)/' < $< > $@; \
	chmod +x $@

TARBALL = $(PROJECT_NAME)-$(VERSION).tar.gz

DEPS = \
    buildspec.yml \
    $(MODULE_PATH).in \
    $(PERL_MODULES) \
    $(BIN_FILES) \
    requires \
    test-requires \
    $(UNIT_TEST_NAME) \
    README.md \
    ChangeLog

all: $(TARBALL)

$(TARBALL): $(DEPS)
	$(MAKE_CPAN_DIST) -b $<

module.pm.tmpl:
	@if [[ -n "$(STUB)" ]]; then \
	  cp --preserve=all --update=none $(STUB) $@; \
	  chmod +w $@; \
	else \
	  touch $@; \
	fi; \

$(MODULE_PATH).in: module.pm.tmpl
	@mkdir -p $$(dirname $@); \
	test -e $@ || sed -e 's/[@]MODULE_NAME[@]/$(MODULE_NAME)/' \
	    -e 's/[@]GIT_NAME[@]/$(GIT_NAME)/' \
	    -e 's/[@]GIT_EMAIL[@]/$(GIT_EMAIL)/' < $< > $@

$(UNIT_TEST_NAME): $(UNIT_TEST_TEMPLATE)
	@sed -e 's/[@]MODULE_NAME[@]/$(MODULE_NAME)/' < $< > $@

README.md: $(MODULE_PATH)
	@$(POD2MARKDOWN) $< > $@

define scan-deps
	requires=$$(mktemp); \
	packages=$$(mktemp); \
	trap 'rm -f "$$requires" "$$packages" $(1).tmp' EXIT; \
	for a in $$(find $(2) -name "$(3)"); do \
	  perl -ne 'print "$$1 \n" if /^package +(.*?);/' $$a >> $$packages; \
	  $(SCANDEPS) -r --no-core $$a | awk '{printf "%s %s\n", $$1,$$2}' >> $$requires; \
	done; \
	if test -s "$$requires"; then \
	  sort -u $$requires > $(1).tmp; \
	  grep -vFf "$$packages" "$(1).tmp" > $(1); \
	else \
	  touch $(1); \
	fi
endef

requires: $(SOURCE_FILES)
	@if [[ "$(CPAN_MAKER_SCAN)" = "ON" ]]; then \
	  $(call scan-deps,$@,lib bin,*.p[ml].in); \
	fi

test-requires: $(TESTS)
	@if [[ "$(CPAN_MAKER_SCAN)" = "ON" ]]; then \
	  $(call scan-deps,$@,t,*.t); \
	fi

ChangeLog:
	@touch $@

buildspec.yml: $(BUILDSPEC_TEMPLATE)
	@sed -e 's/[@]MODULE_NAME[@]/$(MODULE_NAME)/g' \
	    -e 's/[@]GIT_NAME[@]/$(GIT_NAME)/g' \
	    -e 's/[@]GITHUB_USER[@]/$(GITHUB_USER)/g' \
	    -e 's/[@]GIT_EMAIL[@]/$(GIT_EMAIL)/g' \
	    -e 's/[@]PROJECT_NAME[@]/$(PROJECT_NAME)/g' \
	    -e 's/[@]MIN_PERL_VERSION[@]/$(MIN_PERL_VERSION)/g' $< > $@

include version.mk

include release-notes.mk

CLEANFILES = \
    $(BIN_FILES) \
    $(PERL_MODULES) \
    *.tar.gz \
    *.tmp \
    extra-files \
    provides \
    module.pm.tmpl \
    resources \
    release-*.{lst,diffs}

clean:
	rm -f $(CLEANFILES)

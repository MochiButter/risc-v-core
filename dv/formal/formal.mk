ROOT_DIR := $(shell git rev-parse --show-toplevel)

PREFIX := build/$(TESTNAME)
TESTDIRS := $(foreach task,cover prove bmc,$(addprefix $(PREFIX)_,$(task)))
TESTS := $(addsuffix /PASS,$(TESTDIRS))
SBY := sby --prefix $(PREFIX) -f $(TESTNAME).sby

.PHONY: all cover prove bmc clean

all: $(TESTS)

build/sv2v.v: $(VERILOG_SOURCES)
	@mkdir -p build
	sv2v --exclude Assert -DFORMAL $^ --write $@

build/$(TESTNAME)_prove/PASS: build/sv2v.v
	$(SBY) prove

build/$(TESTNAME)_cover/PASS: build/sv2v.v
	$(SBY) cover

build/$(TESTNAME)_bmc/PASS: build/sv2v.v
	$(SBY) bmc

clean:
	rm -rf build

# RISC-V design verification and compliance

## Simple testbenches
Prerequisites:

- RISC-V GNU toolchain (assumes rv32i)
- cocotb >= 2.0
- iverilog
- verilator
- yosys
- zachjs/sv2v

### Cocotb tests
The directory `tb/cocotb_asm` contains a cocotb testbench with several tests
that check if a set of instructions will execute and produce the expected
results on the core.
Each assembly file in `asm` will be compiled and loaded into the memory model.
At the end of each test, the testbench will check the register and data memory
values against the expected values.

### Block level SystemVerilog tests
The directories  `tb/sv_*` contains testbenches for block-level tests.
These are sanity check tests so that each module functions as expected.
Each test will run both icarus and verilator simulators, and will run on pre-
and post-sytthesis top modules.
Synthesis is done with `yosys` and `sv2v`.

You can choose which tests to run with:
```
make iverilog.vcd
make iverilog_gls.vcd
make verilator.vcd
make verilator_gls.vcd
```

## uvm testbench
The directory `tb/uvm` contains the uvm testbench structure.
The uvm testbenches can load hex files similar to the cocotb testbench.
It's main usage for now is for [riscof](#riscv-arch-test).
For usage refer to the uvm [document](uvm.md)

## riscv-arch-test
Prerequisites:

- riscof
- riscv-arch-test
- sail-riscv >= 0.8
- RISC-V GNU toolchain (assumes rv32i)
- The [uvm testbench](#uvm-testbench)

The test already assumes riscof and sail-riscv is installed and in the `PATH`,
and that the environment variable `ARCH_TEST_DIR` points to the cloned
riscv-arch-test repository (by default in `dv/riscof`).
Sail can be version 0.8 / 0.9.

To install riscof to run without any additonal config:
```
python3 -m venv .venv
source .venv/bin/activate
git clone https://github.com/riscv-non-isa/riscv-arch-test
pip3 install --editable riscv-arch-test/riscv-ctg
pip3 install --editable riscv-arch-test/riscv-isac
pip3 install git+https://github.com/riscv/riscof.git
```

Run the tests with
```
make run-riscof
```

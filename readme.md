# risc v core
A cpu core that implements the RV32I instruction set.

## Verification
Testbenches are placed in the `tb/` directory.
Design verification tools are placed in the `dv/` directory.

To run basic tests, you can choose to run either a basic SystemVerilog testbench, Cocotb tests, or a uvm test.

To run the RISC-V architectural tests, go to the `dv/riscof` dir and run `make run-riscof`.
See the expectations in the readme file in `dv/`.

## References

[veryl-riscv-book](https://cpu.kanataso.net/)

[Patterson & Hennessy, Computer organization and design : the hardware/software interface, RISC-V edition](https://search.worldcat.org/en/title/1383657830)

[riscv-card](https://github.com/jameslzhu/riscv-card)

[RISC-V Ratified Specification](https://riscv.org/specifications/ratified/)

# risc v core

A 5-stage RISC-V core that implements the RV64I_Zicsr instruction set.

## Verification

Test benches are placed in the `tb/` directory.
Design verification tools are placed in the `dv/` directory.
See the
![readme](doc/verification.md)
in the `doc/` directory for more details on how to run each test.

To run the RISC-V architectural tests, go to the `dv/riscof` dir and run
`make run-riscof`.

## CSR implementation details

The core implements the csr instructions (write, set, clear, and their
immediate counterparts), as well as the ecall, ebreak, and mret instructions.
The `mhartid`, `mtvec`, `mscratch`, `mepc`, `mcause` registers are supported.

## References

[veryl-riscv-book](https://cpu.kanataso.net/)

[Patterson & Hennessy, Computer organization and design : the hardware/software interface, RISC-V edition](https://search.worldcat.org/en/title/1383657830)

[rice](https://github.com/taichi-ishitani/rice/)

[ibex](https://github.com/lowRISC/ibex/)

[cva6](https://github.com/openhwgroup/cva6)

[riscv-card](https://github.com/jameslzhu/riscv-card)

[RISC-V Ratified Specification](https://riscv.org/specifications/ratified/)

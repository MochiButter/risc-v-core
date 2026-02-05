# riscv core

A 5-stage RISC-V core that implements the RV64I_Zicsr_Zifencei instruction set.

## Verification

Test benches are placed in the `tb/` directory.
Design verification tools are placed in the `dv/` directory.
See the
![readme](doc/verification.md)
in the `doc/` directory for more details on how to run each test.

To run the RISC-V architectural tests, go to the `dv/riscof` dir and run
`make run-riscof`.
To run the formal tests, go to the `dv/riscv-formal` dir and run
`make run`

## CSR implementation details

The core implements the csr instructions (write, set, clear, and their
immediate counterparts), as well as the ecall, ebreak, and mret instructions.
The `mhartid`, `misa`, `mtvec`, `mscratch`, `mepc`, `mcause`, `mtval` registers are supported.

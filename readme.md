**this project is very lacking in verification at the moment**

# risc v core
A cpu core that implements the RV32I instruction set.

## Verification
Testbenches are placed in the `tb/` directory.
You can run basic, systemverilog test benches with `make` in the directory, or go into each subdirectory and run these tests bt themselves.

The `cocotb_asm` directory is for testing different `.s` files on the core.

Running the cocotb testbench requires the following:

```
cocotb>=2.0
riscv32-unknown-elf-as
riscv32-unknown-elf-objcopy
```

## References

[veryl-riscv-book](https://cpu.kanataso.net/)

[Patterson & Hennessy, Computer organization and design : the hardware/software interface, RISC-V edition](https://search.worldcat.org/en/title/1383657830)

[riscv-card](https://github.com/jameslzhu/riscv-card)

[RISC-V Ratified Specification](https://riscv.org/specifications/ratified/)

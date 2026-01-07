# UVM testbench

Run `make simulate` to build and run the testbench in its default configuration.
Use `ASM_FILE` to specify the assembly file to run the test on.
Use `UVM_TEST` to specify which uvm test should be used.

## RISCOF
Set `UVM_TEST` to `core_test_riscof` to run the riscof testbench.
Use `RISCOF_SIG_PATH` to specify the path to where the RISCOF signature file
should be written to.
The begin and end signature must be written to `0x80000000` and
`0x80000008` respectively before terminating the test.
The testbench is terminated when the core writes anything to the address
`0x80000010`

The makefile is based on the one used in
[verilator-verification](https://github.com/antmicro/verilator-verification).

## Overview
When the core makes a request to the memory, the monitor catches the
transaction and creates an item with the address, data (if any) and the
write mask.
The monitor writes the item to its port connected to the sequencer.
The sequence gets the item from the p_sequencer port, then reads/writes to the
array at that address and creates a new item based on the memory action.
The sequence then starts and finishes the item to write it to the driver.
The driver gets the item and drives the rvalid signal high until the next clock
cycle.
The rvalid signal is set low until the next item comes.
When the rvalid signal goes high after an item is passed to the sequencer, the
monitor passes the completed transaction to the test class for checking.

The current termination condition is hardcoded to be when the core writes
`0xdeadbeef` to `0x000000038`.

## Running
The testbench can be run with verilator, but a newer version must be used.

Because of a bug with virtual interfaces, only versions between
```
Verilator 5.041 devel rev v5.040-181-ga64774726
```
and
```
Verilator 5.041 devel rev v5.040-242-g2c7476524
```
will work (maybe more).

The modified uvm library files are also needed, which can be found
[here](https://github.com/antmicro/uvm-verilator/tree/uvm-1.2-current-patches).
It is set as a submodule in the third-party directory, which can be downloaded
with `git submodule update --init --recursive`

## Acknowledgements
This setup was based on the testbenches in the
[rice](https://github.com/taichi-ishitani/rice)
and
[ibex](https://github.com/lowRISC/ibex)
repositories.

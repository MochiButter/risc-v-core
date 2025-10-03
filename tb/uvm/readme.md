# UVM testbench

This setup was based on the testbenches in the
[rice](https://github.com/taichi-ishitani/rice)
and
[ibex](https://github.com/lowRISC/ibex)
repositories.

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

## Running
The testbench can be run with verilator, but a newer version must be used.

Version 5.041 or above should work.
```
Verilator 5.041 devel rev v5.040-181-ga64774726
```

The modified uvm library files are also needed, which can be found
[here](https://github.com/antmicro/uvm-verilator/tree/uvm-1.2-current-patches).
It is set as a submodule in the third-party directory, which can be downloaded
with `git submodule update --init --recursive`

To build and run the simulation:
```
make
```

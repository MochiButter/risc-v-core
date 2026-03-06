# Design of the SoC module
The top level SoC module contains a single core, an arbiter, a core-bus to
AXI4-Lite bus converter, and an SRAM cell that takes AXI4-Lite signals.
The arbiter allows all data bus transactions through with priority over the
instruction bus. Requests from the core are translated to the corresponding
AXI4-Lite signals and sent to the ram module, and responses are converted back
to the signals on the core. The ram can be configured as a simple dual-port,
1r1w mode or a single port 1rw mode with a prameter.

## References

- [Buidilng an AXI-Lite slave the easy way](https://zipcpu.com/blog/2020/03/08/easyaxil.html)
- [pulp-platform/axi](https://github.com/pulp-platform/axi)
- [alexforencich/verilog-axi](https://github.com/alexforencich/verilog-axi)

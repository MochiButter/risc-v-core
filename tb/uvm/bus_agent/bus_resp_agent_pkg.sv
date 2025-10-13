package bus_resp_agent_pkg;

  import uvm_pkg::*;

  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  parameter AddrWidth = 64;
  parameter DataWidth = 64;
  localparam MaskBits = DataWidth / 8;
  localparam AddrShift = $clog2(MaskBits);

  `include "bus_seq_item.sv"
  `include "bus_resp_sequencer.sv"
  `include "bus_resp_seq_lib.sv"
  `include "bus_resp_driver.sv"
  `include "bus_resp_monitor.sv"
  `include "bus_resp_agent.sv"

endpackage

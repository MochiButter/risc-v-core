`ifdef VERILATOR
class bus_resp_sequencer extends uvm_sequencer #(bus_seq_item, bus_seq_item);
`else
class bus_resp_sequencer extends uvm_sequencer #(bus_seq_item);
`endif

  uvm_tlm_analysis_fifo #(bus_seq_item) from_mon_port;

  `uvm_component_utils(bus_resp_sequencer)

  function new (string name = "", uvm_component parent = null);
    super.new(name, parent);
    from_mon_port = new("from_mon_port", this);
  endfunction : new

endclass : bus_resp_sequencer

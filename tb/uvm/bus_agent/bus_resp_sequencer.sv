`ifdef VERILATOR
class bus_resp_sequencer #(int AddrWidth, int DataWidth) extends uvm_sequencer #(bus_seq_item #(AddrWidth, DataWidth), bus_seq_item #(AddrWidth, DataWidth));
`else
class bus_resp_sequencer #(int AddrWidth, int DataWidth) extends uvm_sequencer #(bus_seq_item #(AddrWidth, DataWidth));
`endif

  uvm_tlm_analysis_fifo #(bus_seq_item #(AddrWidth, DataWidth)) from_mon_port;

  `uvm_component_param_utils(bus_resp_sequencer #(AddrWidth, DataWidth))

  function new (string name = "", uvm_component parent = null);
    super.new(name, parent);
    from_mon_port = new("from_mon_port", this);
  endfunction : new

endclass : bus_resp_sequencer

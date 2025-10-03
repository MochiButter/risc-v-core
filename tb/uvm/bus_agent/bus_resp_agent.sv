class bus_resp_agent extends uvm_agent;

  bus_resp_monitor   monitor;
  bus_resp_sequencer sequencer;
  bus_resp_driver    driver;

  `uvm_component_utils(bus_resp_agent)
  `uvm_comp_new

  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    monitor = bus_resp_monitor::type_id::create("monitor", this);

    if(get_is_active() == UVM_ACTIVE) begin
      driver = bus_resp_driver::type_id::create("driver", this);
      sequencer = bus_resp_sequencer::type_id::create("sequencer", this);
    end
  endfunction : build_phase

  function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    if(get_is_active() == UVM_ACTIVE) begin
      // the driver and sequencer classes inherently have these ports
      driver.seq_item_port.connect(sequencer.seq_item_export);
      monitor.to_seqr_port.connect(sequencer.from_mon_port.analysis_export);
    end
  endfunction : connect_phase

endclass : bus_resp_agent

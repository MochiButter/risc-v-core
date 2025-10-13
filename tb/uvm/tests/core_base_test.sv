class core_base_test extends uvm_test;

  core_env env;
  bus_resp_seq_base inst_seq;
  bus_resp_seq_base data_seq;

  uvm_tlm_analysis_fifo #(bus_seq_item) watch_datamem_port;
  uvm_tlm_analysis_fifo #(bus_seq_item) watch_instmem_port;

  string text_hex_path;
  string data_hex_path;

  `uvm_component_utils(core_base_test)
  `uvm_comp_new

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    watch_datamem_port = new("watch_datamem_port", this);
    watch_instmem_port = new("watch_instmem_port", this);
    env = core_env::type_id::create("env", this);
    inst_seq = bus_resp_seq_base::type_id::create("inst_seq", this);
    data_seq = bus_resp_seq_base::type_id::create("data_seq", this);
  endfunction : build_phase

  function void connect_phase (uvm_phase phase);
    env.data_if_resp_agent.monitor.item_collected_port.connect(this.watch_datamem_port.analysis_export);
    env.inst_if_resp_agent.monitor.item_collected_port.connect(this.watch_instmem_port.analysis_export);
  endfunction : connect_phase

  virtual task run_phase (uvm_phase phase);
    phase.raise_objection(this);
    init_mem();
    // FIXME constant addr halt signal
    watch_bus_event('h38, 'hdeadbeef, watch_datamem_port);
    phase.drop_objection(this);
  endtask

  task init_mem ();
    if ($value$plusargs("TEXT_HEX=%s", text_hex_path)) begin
      inst_seq.load_program(text_hex_path);
    end else begin
      $error("Need test hex");
    end
    if ($value$plusargs("DATA_HEX=%s", data_hex_path)) begin
      data_seq.load_program(data_hex_path);
    end else begin
      $error("Need test hex");
    end

    fork
      inst_seq.start(env.inst_if_resp_agent.sequencer);
      data_seq.start(env.data_if_resp_agent.sequencer);
    join_none
  endtask : init_mem

  virtual task watch_bus_event(
    input bit [AddrWidth - 1:0] ref_addr,
    input bit [DataWidth - 1:0] ref_data,
    uvm_tlm_analysis_fifo #(bus_seq_item) txn_port
  );
    bus_seq_item item;
    forever begin
      txn_port.get(item);
      if (item.addr == ref_addr && item.data == ref_data) begin
        return;
      end
    end
  endtask : watch_bus_event

endclass : core_base_test

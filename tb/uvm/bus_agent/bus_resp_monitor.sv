class bus_resp_monitor #(int AddrWidth, int DataWidth) extends uvm_monitor;

  virtual bus_if #(AddrWidth, DataWidth) vif;

  typedef bus_seq_item #(AddrWidth, DataWidth) item_t;

  uvm_analysis_port #(item_t) item_collected_port;
  uvm_analysis_port #(item_t) to_seqr_port;

  mailbox #(item_t) resp_queue;

  `uvm_component_param_utils(bus_resp_monitor #(AddrWidth, DataWidth))
  `uvm_comp_new

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    to_seqr_port = new("to_seqr_port", this);
    item_collected_port = new("item_collected_port", this);
    resp_queue = new();

    if (!uvm_config_db #(virtual bus_if #(AddrWidth, DataWidth))::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction : build_phase

  virtual task run_phase (uvm_phase phase);
    fork
      monitor_addr();
      monitor_resp();
    join_none
  endtask : run_phase

  virtual task monitor_addr();
    item_t trans_collected;

    forever begin
      @(posedge vif.clk_i);
      trans_collected = item_t::type_id::create("trans_collected");
      while (!(vif.ready && vif.valid)) begin
        @(posedge vif.clk_i);
      end

      trans_collected.addr = vif.addr;
      trans_collected.data = vif.wdata;
      trans_collected.wmask = vif.wmask;

      if (vif.wmask != '0) begin
        `uvm_info(get_full_name(), $sformatf("wdata: MEM[0x%h] 0b%b 0x%h",vif.addr, vif.wmask, vif.wdata), UVM_HIGH)
      end
      to_seqr_port.write(trans_collected);
      resp_queue.put(trans_collected);
    end
  endtask : monitor_addr

  // this is not connected to the memory model, but it is a way to pass bus
  // events to the test class so that a certain address may be monitored for
  // a termination signal
  virtual task monitor_resp();
    item_t trans_collected;
    forever begin
      resp_queue.get(trans_collected);

      do
        @(posedge vif.clk_i);
      while (!vif.rvalid);

      if (trans_collected.wmask == '0) begin
        trans_collected.data = vif.rdata;
      end

      item_collected_port.write(trans_collected);
    end
  endtask : monitor_resp

endclass : bus_resp_monitor

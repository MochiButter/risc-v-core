class bus_resp_driver #(int AddrWidth, int DataWidth) extends uvm_driver #(bus_seq_item #(AddrWidth, DataWidth));

  virtual bus_if #(AddrWidth, DataWidth) vif;

  `uvm_component_param_utils(bus_resp_driver #(AddrWidth, DataWidth))
  `uvm_comp_new

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual bus_if #(AddrWidth, DataWidth))::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction : build_phase

  virtual task run_phase (uvm_phase phase);
    // sram is always ready
    vif.ready <= 1'b1;
    vif.rvalid <= 1'b0;
    vif.rdata  <= 'x;
    forever begin
      @(posedge vif.clk_i);
      vif.rvalid <= 1'b0;
      vif.rdata  <= 'x;

      // req is part of the driver class
      seq_item_port.get_next_item(req);

      vif.rvalid <= 1'b1;
      // rdata out doesn't matter when writing
      vif.rdata <= req.data;
      if (req.wmask == '0) begin
        `uvm_info(get_full_name(), $sformatf("rdata: MEM[0x%h] 0x%h", req.addr, req.data), UVM_HIGH)
      end
      seq_item_port.item_done();
    end
  endtask : run_phase

endclass : bus_resp_driver

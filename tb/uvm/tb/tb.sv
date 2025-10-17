module tb();
  import uvm_pkg::*;
  import core_test_pkg::*;

  logic clk_i;
  logic rst_i;

  always #5 clk_i = ~clk_i;

  initial begin
    rst_i = 1'b0;
  end

  int cycles = 0;

  parameter AddrWidth = 64;
  parameter DataWidth = 64;
  bus_if #(AddrWidth, DataWidth) inst_if(.clk_i(clk_i));
  bus_if #(AddrWidth, DataWidth) data_if(.clk_i(clk_i));

  core #() core_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),

    .instmem_ready_i (inst_if.ready),
    .instmem_valid_o (inst_if.valid),
    .instmem_addr_o  (inst_if.addr),
    .instmem_wdata_o (inst_if.wdata),
    .instmem_wmask_o (inst_if.wmask),
    .instmem_rdata_i (inst_if.rdata),
    .instmem_rvalid_i(inst_if.rvalid),

    .datamem_ready_i (data_if.ready),
    .datamem_valid_o (data_if.valid),
    .datamem_addr_o  (data_if.addr),
    .datamem_wdata_o (data_if.wdata),
    .datamem_wmask_o (data_if.wmask),
    .datamem_rdata_i (data_if.rdata),
    .datamem_rvalid_i(data_if.rvalid)
  );

  initial begin
    uvm_config_db#(virtual bus_if #(AddrWidth, DataWidth))::set(uvm_root::get(),"*inst_if_resp_agent*","vif",inst_if);
    uvm_config_db#(virtual bus_if #(AddrWidth, DataWidth))::set(uvm_root::get(),"*data_if_resp_agent*","vif",data_if);
  end

  initial begin
    run_test();
  end
endmodule

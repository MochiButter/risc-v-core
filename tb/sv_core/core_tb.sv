`ifndef DUMPFILE
`define DUMPFILE "dump.vcd"
`endif
module core_tb();

  logic [0:0] clk_i, rst_i;

  /* verilator lint_off UNUSEDSIGNAL */
  logic [31:0] mem_addr_l, datamem_addr_l;
  /* verilator lint_on UNUSEDSIGNAL */

  logic [0:0] mem_ready_l, mem_valid_l, mem_rvalid_l;
  logic [3:0] mem_wmask_l;
  logic [31:0] mem_wdata_l, mem_rdata_l;

  logic [0:0] datamem_ready_l, datamem_valid_l, datamem_rvalid_l;
  logic [3:0] datamem_wmask_l;
  logic [31:0] datamem_wdata_l, datamem_rdata_l;

  parameter timeout_cycles = 50;
  int cycles = 0;

  parameter ram_file = "tb/sv_core/arith.mem";

  logic [31:0] pc;
  logic [31:0] instr;

  initial begin
    clk_i = '0;
    forever begin
      clk_i = ~clk_i;
      #5;
    end
  end

  core #() core_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),

    .instmem_ready_i(mem_ready_l),
    .instmem_valid_o(mem_valid_l),
    .instmem_addr_o(mem_addr_l),
    .instmem_wdata_o(mem_wdata_l),
    .instmem_wmask_o(mem_wmask_l),
    .instmem_rdata_i(mem_rdata_l),
    .instmem_rvalid_i(mem_rvalid_l),

    .datamem_ready_i(datamem_ready_l),
    .datamem_valid_o(datamem_valid_l),
    .datamem_addr_o(datamem_addr_l),
    .datamem_wdata_o(datamem_wdata_l),
    .datamem_wmask_o(datamem_wmask_l),
    .datamem_rdata_i(datamem_rdata_l),
    .datamem_rvalid_i(datamem_rvalid_l)
  );

  ram_1rw_sync #(.Width(32), .Depth(256), 
    .UseInitFile(1), .InitFile({`BINPATH, ram_file}))
    mem_inst(
    .clk_i(clk_i),
    .ready_o(mem_ready_l),
    .valid_i(mem_valid_l),
    .addr_i(mem_addr_l[7:0]),
    .wr_data_i(mem_wdata_l),
    .wmask_i(mem_wmask_l),
    .rd_data_o(mem_rdata_l),
    .rd_valid_o(mem_rvalid_l)
  );

  ram_1rw_sync #(.Width(32), .Depth(256), 
    .UseInitFile(1), .InitFile({`BINPATH, ram_file}))
    datamem_inst(
    .clk_i(clk_i),
    .ready_o(datamem_ready_l),
    .valid_i(datamem_valid_l),
    .addr_i(datamem_addr_l[7:0]),
    .wr_data_i(datamem_wdata_l),
    .wmask_i(datamem_wmask_l),
    .rd_data_o(datamem_rdata_l),
    .rd_valid_o(datamem_rvalid_l)
  );

  initial begin
    /*
`ifdef VERILATOR
  $dumpfile("verilator.vcd");
`else
  $dumpfile("iverilog.vcd");
`endif
*/

`ifdef DUMPFILE
  $dumpfile(`DUMPFILE);
  $display(`DUMPFILE);
  $dumpvars;
`endif
    
    rst_i = 1'b0;
    #20;
    rst_i = 1'b1;
    #15;
    rst_i = 1'b0;
    
    while (instr !== 32'h00100073) begin
      pc = core_inst.inst_pc;
      instr = core_inst.inst_data;
      //pc = core_inst.pc_q;
      //instr = mem_inst.mem[pc >> 2]; 
      if (core_inst.inst_valid) begin
        $display("[0x%08h] 0x%08h", pc, instr);
      end
      if (core_inst.datamem_valid_o) begin
        if (core_inst.datamem_wmask_o == '0) begin
          $display("data rd req [0x%08h]", core_inst.datamem_addr_o);
        end else begin
          $display("data wr req [0x%08h] 0x%08h", core_inst.datamem_addr_o, core_inst.datamem_wdata_o);
        end
      end

      #10;
      cycles ++;
      if (cycles >= timeout_cycles) begin
        $display("Timeout reached");
        $finish();
      end
    end

    $display("ebreak called, ending");

    $display("No bad outputs detected");
    $display("SIM PASSED");
    $finish();
  end
endmodule

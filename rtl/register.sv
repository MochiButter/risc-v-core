/* Registers for the RISC-V core
 * x0 is a constant 0, so no writes are allowed
 * rs1 and rs2 always output the contents of the register at addr
 * rd can be written to when rd_wr_en_i is asserted
 * NOTE: at the moment all registers are reset to 0 when the 
 * reset signal is high.
 */
module register
  #(parameter RegWidth = 32,
    parameter RegDepth = 32)
  (input logic clk_i

  ,input  logic [$clog2(RegDepth) - 1:0] rs1_addr_i
  ,input  logic [$clog2(RegDepth) - 1:0] rs2_addr_i
  ,input  logic [$clog2(RegDepth) - 1:0] rd_addr_i
  ,input  logic [RegWidth - 1:0]         rd_data_i
  ,input  logic                          rd_write_en_i
  ,output logic [RegWidth - 1:0]         rs1_data_o
  ,output logic [RegWidth - 1:0]         rs2_data_o
  );

  logic [RegWidth - 1:0] regs_q [RegDepth - 1:1];

  // Dump register values for surfer. icarus borked
  `ifdef VERILATOR
  initial begin
    for (int i = 1; i < RegDepth; i ++) begin
      $dumpfile("verilator.vcd");
      $dumpvars(0, regs_q[i]);
    end
  end
  `endif

  // x0 will always be 0, otherwise output register contents
  assign rs1_data_o = rs1_addr_i != '0 ? regs_q[rs1_addr_i] : '0;
  assign rs2_data_o = rs2_addr_i != '0 ? regs_q[rs2_addr_i] : '0;

  always_ff @(posedge clk_i) begin
    if (rd_write_en_i && (rd_addr_i != '0)) begin
      regs_q[rd_addr_i] <= rd_data_i;
    end
  end
endmodule

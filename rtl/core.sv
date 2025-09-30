/* Harvard arcchitecture
 */

module core import core_pkg::*;
  (input clk_i
  ,input [0:0] rst_i

  ,input  [0:0]  instmem_ready_i
  ,output [0:0]  instmem_valid_o
  ,output [Xlen - 1:0] instmem_addr_o
  ,output [Ilen - 1:0] instmem_wdata_o
  ,output [(Ilen / 8) - 1:0]  instmem_wmask_o
  ,input  [Ilen - 1:0] instmem_rdata_i
  ,input  [0:0]  instmem_rvalid_i

  ,input  [0:0]  datamem_ready_i
  ,output [0:0]  datamem_valid_o
  ,output [Xlen - 1:0] datamem_addr_o
  ,output [Xlen - 1:0] datamem_wdata_o
  ,output [(Xlen / 8 ) - 1:0]  datamem_wmask_o
  ,input  [Xlen - 1:0] datamem_rdata_i
  ,input  [0:0]  datamem_rvalid_i
  );

  /* Instruction fetch fifo signals */
  logic [0:0] inst_valid;
  wire [Xlen - 1:0] inst_pc;
  wire [Ilen - 1:0] inst_data;

  /* Decode signals */
  wire [31:0] imm_w;
  aluop_e aluop_w;
  jump_type_e jump_w;
  wire [0:0] alu_use_imm_w, reg_wb_w, reg_lui_w, is_auipc_w,
    branch_w, mem_read_w, mem_write_w, mem_to_reg_w;

  wire [2:0] funct3_w;
  wire [6:0] funct7_w;
  assign funct3_w = inst_data[14:12];
  assign funct7_w = inst_data[31:25];

  wire [4:0] rs1_addr_w, rs2_addr_w, rd_addr_w;
  assign rs1_addr_w = inst_data[19:15];
  assign rs2_addr_w = inst_data[24:20];
  assign rd_addr_w = inst_data[11:7];

  /* ALU signals */
  wire [0:0] alu_zero_w;
  wire [Xlen - 1:0] alu_res_w;

  /* Register signals */
  wire [Xlen - 1:0] rs1_data_w, rs2_data_w;
  logic [Xlen - 1:0] rd_data_w;

  /* Data memory signals */
  wire [0:0] load_valid_w, mem_busy_w;
  wire [Xlen - 1:0] load_data_w;

  /* Program counter signals */
  logic [0:0] fifo_rd_ready;
  logic [(Xlen + Ilen) - 1:0] fifo_wr_data, fifo_rd_data;

  wire [0:0] fifo_wr_ready, fifo_flush, fifo_rst;

  logic [Xlen - 1:0] pc_request_d, pc_request_q, pc_d, pc_q;

  // really long comb chain?
  assign fifo_flush = inst_valid && (jump_w != None || (branch_w && alu_zero_w));
  assign fifo_rst = rst_i || fifo_flush;

  // don't fetch until memop is done
  assign instmem_valid_o = fifo_wr_ready && !(inst_valid && mem_busy_w);
  assign instmem_addr_o = pc_request_d;
  assign instmem_wdata_o = 'x;
  assign instmem_wmask_o = '0;
  
  wire [Xlen - 1:0] jalr_slice = {alu_res_w[Xlen - 1:1], 1'b0};

  always_comb begin
    if (fifo_flush && jump_w == Jalr) begin
      // jalr
      pc_d = jalr_slice;
    end else if (fifo_flush) begin
      // jal and br
      pc_d = inst_pc + imm_w;
    end else begin
      // the rest of instructions
      pc_d = pc_q + 32'd4;
    end
  end

  // bypass jump destination to instr mem fetch
  always_comb begin
    if (fifo_flush) begin
      pc_request_d = pc_d;
    end else begin
      pc_request_d = pc_q;
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      pc_q <= '0;
      // pc_request_q isn't used until at least 1 clk after fetch.
      // no need to reset as it is filled with valid data by that time
    end else if (instmem_ready_i && instmem_valid_o) begin
      pc_q <= pc_d;
      pc_request_q <= pc_request_d;
    end
  end

  assign inst_pc = fifo_rd_data[(Xlen + Ilen) - 1:Xlen];
  assign inst_data = fifo_rd_data[Ilen - 1:0];

  assign fifo_wr_data = {pc_request_q, instmem_rdata_i};
  // dispatch new instr when the fifo is not empty and the current mem op is done
  assign fifo_rd_ready = !mem_busy_w;

  fifo #(.DepthLog2(2), .Width(Xlen + Ilen)) fifo_inst (
    .clk_i(clk_i),
    .rst_i(fifo_rst),
    .wr_valid_i(instmem_rvalid_i),
    .wr_data_i(fifo_wr_data),
    .wr_ready_o(fifo_wr_ready),
    .rd_ready_i(fifo_rd_ready),
    .rd_data_o(fifo_rd_data),
    .rd_valid_o(inst_valid)
  );

  always_comb begin
    if (mem_to_reg_w && load_valid_w) begin
      rd_data_w = load_data_w;
    end else if (reg_lui_w) begin
      rd_data_w = imm_w;
    end else if (jump_w != None) begin
      rd_data_w = inst_pc + 32'd4;
    end else begin
      rd_data_w = alu_res_w;
    end
  end

  decode #() decode_inst (
    .instr_i(inst_data),
    .imm_o(imm_w),
    .aluop_o(aluop_w),
    .alu_use_imm_o(alu_use_imm_w),
    .reg_wb_o(reg_wb_w),
    .reg_lui_o(reg_lui_w),
    .is_auipc_o(is_auipc_w),
    .branch_o(branch_w),
    .jump_o(jump_w),
    .mem_read_o(mem_read_w),
    .mem_write_o(mem_write_w),
    .mem_to_reg_o(mem_to_reg_w)
  );

  alu32 #() alu32_inst (
    .funct3_i(funct3_w),
    .funct7_i(funct7_w),
    .itype_i(alu_use_imm_w),
    .aluop_i(aluop_w),
    .a_i(is_auipc_w ? inst_pc : rs1_data_w),
    .b_i(alu_use_imm_w ? imm_w : rs2_data_w),
    .res_o(alu_res_w),
    .zero_o(alu_zero_w)
  );

  register #() reg_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .rs1_addr_i(rs1_addr_w),
    .rs2_addr_i(rs2_addr_w),
    .rd_addr_i(rd_addr_w),
    .rd_data_i(rd_data_w),
    // when current instruction is valid, and when the memop finishes
    .rd_wr_en_i(reg_wb_w && inst_valid && !mem_busy_w),
    .rs1_data_o(rs1_data_w),
    .rs2_data_o(rs2_data_w)
  );

  mem_state #() ms_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),

    .read_i(mem_read_w),
    .write_i(mem_write_w),
    .addr_i(alu_res_w),
    .wdata_i(rs2_data_w),
    .funct3_i(funct3_w),
    .rdata_o(load_data_w),
    .rvalid_o(load_valid_w),
    .mem_busy_o(mem_busy_w),

    .mem_ready_i(datamem_ready_i),
    .mem_valid_o(datamem_valid_o),
    .mem_addr_o(datamem_addr_o),
    .mem_wdata_o(datamem_wdata_o),
    .mem_wmask_o(datamem_wmask_o),
    .mem_rdata_i(datamem_rdata_i),
    .mem_rvalid_i(datamem_rvalid_i)
  );

endmodule

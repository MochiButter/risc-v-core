module core import core_pkg::*;
  (input logic clk_i
  ,input logic rst_i

  ,input  logic                    instmem_ready_i
  ,output logic                    instmem_valid_o
  ,output logic [Xlen - 1:0]       instmem_addr_o
  ,output logic [Xlen - 1:0]       instmem_wdata_o
  ,output logic [MaskBits - 1:0]   instmem_wmask_o
  ,input  logic [Xlen - 1:0]       instmem_rdata_i
  ,input  logic                    instmem_rvalid_i

  ,input  logic                    datamem_ready_i
  ,output logic                    datamem_valid_o
  ,output logic [Xlen - 1:0]       datamem_addr_o
  ,output logic [Xlen - 1:0]       datamem_wdata_o
  ,output logic [MaskBits - 1:0]   datamem_wmask_o
  ,input  logic [Xlen - 1:0]       datamem_rdata_i
  ,input  logic                    datamem_rvalid_i
  );

  /* Instruction fetch signals */
  logic [0:0] inst_valid;
  logic [Xlen - 1:0] inst_pc;
  logic [Ilen - 1:0] inst_data;
  assign instmem_wmask_o = '0;
  assign instmem_wdata_o = 'x;

  /* Decode signals */
  logic [Xlen - 1:0] inst_imm;
  aluop_e inst_aluop;
  jump_type_e inst_jump_type;
  logic alu_use_imm, reg_wb, is_lui, is_auipc, is_branch, mem_to_reg;
  memop_type_e mem_type;

  logic [2:0] funct3;
  logic [6:0] funct7;
  assign funct3 = inst_data[14:12];
  assign funct7 = inst_data[31:25];

  logic [4:0] rs1_addr, rs2_addr, rd_addr;
  assign rs1_addr = inst_data[19:15];
  assign rs2_addr = inst_data[24:20];
  assign rd_addr = inst_data[11:7];

  /* ALU signals */
  logic alu_zero;
  logic [Xlen - 1:0] alu_res;

  /* Register signals */
  logic [Xlen - 1:0] rs1_data, rs2_data;
  logic [Xlen - 1:0] rd_data;

  /* Data memory signals */
  logic load_valid, mem_busy;
  logic [Xlen - 1:0] load_data;

  logic control_hazard;
  logic [Xlen - 1:0] jalr_slice, pc_target;

  assign jalr_slice = {alu_res[Xlen - 1:1], 1'b0};
  assign control_hazard =
    inst_valid && (inst_jump_type != JmpNone || (is_branch && alu_zero));

  always_comb begin
    pc_target = 'x;
    if (control_hazard && inst_jump_type == Jalr) begin
      pc_target = jalr_slice;
    end else if (control_hazard) begin
      pc_target = inst_pc + inst_imm;
    end
  end

  fetch #() fetch_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .control_hazard_i(control_hazard),
    .pc_target_i(pc_target),
    .mem_ready_i(instmem_ready_i),
    .mem_valid_o(instmem_valid_o),
    .mem_addr_o(instmem_addr_o),
    .mem_rdata_i(instmem_rdata_i),
    .mem_rvalid_i(instmem_rvalid_i),
    .inst_ready_i(!mem_busy),
    .inst_pc_o(inst_pc),
    .inst_data_o(inst_data),
    .inst_valid_o(inst_valid)
  );

  always_comb begin
    if (mem_to_reg && load_valid) begin
      rd_data = load_data;
    end else if (is_lui) begin
      rd_data = inst_imm;
    end else if (inst_jump_type != JmpNone) begin
      rd_data = inst_pc + 4;
    end else begin
      rd_data = alu_res;
    end
  end

  decode #() decode_inst (
    .instr_i(inst_data),
    .imm_o(inst_imm),
    .aluop_o(inst_aluop),
    .alu_use_imm_o(alu_use_imm),
    .reg_wb_o(reg_wb),
    .reg_lui_o(is_lui),
    .is_auipc_o(is_auipc),
    .branch_o(is_branch),
    .jump_o(inst_jump_type),
    .mem_type_o(mem_type),
    .mem_to_reg_o(mem_to_reg)
  );

  alu #() alu_inst (
    .funct3_i(funct3),
    .funct7_i(funct7),
    .itype_i(alu_use_imm),
    .aluop_i(inst_aluop),
    .a_i(is_auipc ? inst_pc : rs1_data),
    .b_i(alu_use_imm ? inst_imm : rs2_data),
    .res_o(alu_res),
    .zero_o(alu_zero)
  );

  register #(.RegWidth(Xlen)) reg_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .rs1_addr_i(rs1_addr),
    .rs2_addr_i(rs2_addr),
    .rd_addr_i(rd_addr),
    .rd_data_i(rd_data),
    // when current instruction is valid, and when the memop finishes
    .rd_write_en_i(reg_wb && inst_valid && !mem_busy),
    .rs1_data_o(rs1_data),
    .rs2_data_o(rs2_data)
  );

  mem_lsu #() lsu_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),

    .valid_inst_i(inst_valid),
    .mem_type_i(mem_type),
    .addr_i(alu_res),
    .wdata_i(rs2_data),
    .funct3_i(funct3),
    .rdata_o(load_data),
    .rvalid_o(load_valid),
    .mem_busy_o(mem_busy),

    .mem_ready_i(datamem_ready_i),
    .mem_valid_o(datamem_valid_o),
    .mem_addr_o(datamem_addr_o),
    .mem_wdata_o(datamem_wdata_o),
    .mem_wmask_o(datamem_wmask_o),
    .mem_rdata_i(datamem_rdata_i),
    .mem_rvalid_i(datamem_rvalid_i)
  );

endmodule

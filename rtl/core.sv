module core import core_pkg::*;
  (input logic clk_i
  ,input logic rst_ni

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
  logic inst_valid;
  logic [Xlen - 1:0] inst_pc;
  logic [Ilen - 1:0] inst_data;
  assign instmem_wmask_o = '0;
  assign instmem_wdata_o = 'x;

  /* Decode signals */
  logic [Xlen - 1:0] inst_imm;
  inst_type_e inst_type;
  jump_type_e jump_type;
  alu_op_e alu_op;
  reg_wb_src_e reg_wb_src;
  mem_type_e mem_type;
  csr_op_e csrop;
  logic [11:0] csr_addr;
  logic csr_use_imm, reg_wb_en;

  logic [2:0] funct3;
  assign funct3 = inst_data[14:12];

  logic [4:0] rs1_addr, rs2_addr, rd_addr;

  /* ALU signals */
  logic branch_take;
  logic [Xlen - 1:0] alu_res;

  /* Register signals */
  logic [Xlen - 1:0] rs1_data, rs2_data;
  logic [Xlen - 1:0] rd_data;

  /* CSR signals */
  logic [Xlen - 1:0] csr_rs1_data, csr_rd_data, csr_trap_vector;
  assign csr_rs1_data = csr_use_imm ? inst_imm : rs1_data;
  logic csr_raise_trap;

  /* Data memory signals */
  logic mem_busy;
  logic [Xlen - 1:0] load_data;

  logic control_hazard;
  logic [Xlen - 1:0] jalr_slice, pc_target;

  assign jalr_slice = {alu_res[Xlen - 1:1], 1'b0};
  assign control_hazard = inst_valid && (
    (jump_type == JmpJal || jump_type == JmpJalr) ||
    (jump_type == JmpBr && branch_take) ||
    csr_raise_trap
  );

  always_comb begin
    pc_target = 'x;
    if (control_hazard && jump_type == JmpJalr) begin
      pc_target = jalr_slice;
    end else if (control_hazard && csr_raise_trap) begin
      pc_target = csr_trap_vector;
    end else if (control_hazard) begin
      pc_target = inst_pc + inst_imm;
    end
  end

  fetch #() fetch_inst (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
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
    case (reg_wb_src)
      WbLsu: rd_data = load_data;
      WbCsr: rd_data = csr_rd_data;
      WbLui: rd_data = inst_imm;
      WbJmp: rd_data = inst_pc + 4;
      default: rd_data = alu_res;
    endcase
  end

  assign reg_wb_en = (reg_wb_src != WbNone) && inst_valid && !mem_busy;

  decode #() decode_inst (
    .inst_i(inst_data),
    .imm_o(inst_imm),
    .inst_type_o(inst_type),
    .jump_type_o(jump_type),
    .reg_wb_src_o(reg_wb_src),
    .alu_op_o(alu_op),
    .mem_type_o(mem_type),
    .rs1_addr_o(rs1_addr),
    .rs2_addr_o(rs2_addr),
    .rd_addr_o(rd_addr),
    .csr_op_o(csrop),
    .csr_imm_o(csr_use_imm),
    .csr_addr_o(csr_addr)
  );

  logic [Xlen - 1:0] alu_a, alu_b;
  always_comb begin
    case (inst_type)
      Rtype, Btype: begin alu_a = rs1_data; alu_b = rs2_data; end
      Itype, Stype: begin alu_a = rs1_data; alu_b = inst_imm; end
      Utype:        begin alu_a = inst_pc;  alu_b = inst_imm; end
      default:      begin alu_a = 'x;       alu_b = 'x;       end
    endcase
  end

  alu #() alu_inst (
    .alu_op_i(alu_op),
    .a_i(alu_a),
    .b_i(alu_b),
    .res_o(alu_res),
    .branch_take_o(branch_take)
  );

  register #(.RegWidth(Xlen)) reg_inst (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .rs1_addr_i(rs1_addr),
    .rs2_addr_i(rs2_addr),
    .rd_addr_i(rd_addr),
    .rd_data_i(rd_data),
    .rd_write_en_i(reg_wb_en),
    .rs1_data_o(rs1_data),
    .rs2_data_o(rs2_data)
  );

  csr #(.MHartId('h0)) csr_inst (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .valid_i(inst_valid),
    .csr_op_i(csrop),
    .rs1_data_i(csr_rs1_data),
    .csr_addr_i(csr_addr),
    .rd_data_o(csr_rd_data),
    .pc_i(inst_pc),
    .raise_trap_o(csr_raise_trap),
    .trap_vector_o(csr_trap_vector)
  );

  mem_lsu #() lsu_inst (
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .valid_inst_i(inst_valid),
    .mem_type_i(mem_type),
    .addr_i(alu_res),
    .wdata_i(rs2_data),
    .funct3_i(funct3),
    .rdata_o(load_data),
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

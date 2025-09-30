module decode import core_pkg::*;
  (input [Ilen - 1:0] instr_i
  ,output [31:0] imm_o
  ,output aluop_e aluop_o
  ,output [0:0] alu_use_imm_o
  ,output [0:0] reg_wb_o 
  ,output [0:0] reg_lui_o
  ,output [0:0] is_auipc_o
  ,output [0:0] branch_o
  ,output [1:0] jump_o
  ,output [0:0] mem_read_o
  ,output [0:0] mem_write_o
  ,output [0:0] mem_to_reg_o
  );

  typedef enum logic [6:0] {
    OpALU    = 7'b0110011,
    OpALUImm = 7'b0010011,
    OpLoad   = 7'b0000011,
    OpStore  = 7'b0100011,
    OpBranch = 7'b1100011,
    OpJal    = 7'b1101111,
    OpJalr   = 7'b1100111,
    OpLui    = 7'b0110111,
    OpAuipc  = 7'b0010111,
    OpEnv    = 7'b1110011
  } opcode_e;

  wire [6:0] opcode_w;
  assign opcode_w = instr_i[6:0];

  wire [31:0] imm_i_w, imm_s_w, imm_b_w, imm_u_w, imm_j_w;
  assign imm_i_w = {{20{instr_i[31]}}, instr_i[31:20]};
  assign imm_s_w = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
  assign imm_b_w = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
  assign imm_u_w = {instr_i[31:12], 12'b0};
  assign imm_j_w = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};

  logic [0:0] reg_wb_l, reg_lui_l, is_auipc_l, alu_use_imm_l, branch_l, mem_read_l, mem_write_l, mem_to_reg_l;
  aluop_e aluop_l;
  jump_type_e jump_l;
  logic [31:0] imm_l;
  always_comb begin
    reg_wb_l = 1'b0;
    reg_lui_l = 1'b0;
    is_auipc_l = 1'b0;
    alu_use_imm_l = 1'b0;
    branch_l = 1'b0;
    jump_l = None;
    mem_read_l = 1'b0;
    mem_write_l = 1'b0;
    mem_to_reg_l = 1'b0;
    aluop_l = Add;
    imm_l = '0;
    case (opcode_w)
      OpALU: begin
        reg_wb_l = 1'b1;
        aluop_l = Funct;
      end
      OpALUImm: begin
        reg_wb_l = 1'b1;
        aluop_l = Funct;
        alu_use_imm_l = 1'b1;
        imm_l = imm_i_w;
      end
      OpLoad: begin
        reg_wb_l = 1'b1;
        mem_read_l = 1'b1;
        mem_to_reg_l = 1'b1;
        aluop_l = Add;
        alu_use_imm_l = 1'b1;
        imm_l = imm_i_w;
      end
      OpStore: begin
        mem_write_l = 1'b1;
        aluop_l = Add;
        alu_use_imm_l = 1'b1;
        imm_l = imm_s_w;
      end
      OpBranch: begin
        branch_l = 1'b1;
        aluop_l = Branch;
        imm_l = imm_b_w;
      end
      OpJal: begin
        reg_wb_l = 1'b1;
        imm_l = imm_j_w;
        aluop_l = Add;
        jump_l = Jal;
      end
      OpJalr: begin
        reg_wb_l = 1'b1;
        alu_use_imm_l = 1'b1;
        imm_l = imm_i_w;
        aluop_l = Add;
        jump_l = Jalr;
      end
      OpLui: begin
        reg_wb_l = 1'b1;
        reg_lui_l = 1'b1;
        alu_use_imm_l = 1'b1;
        imm_l = imm_u_w;
      end
      OpAuipc: begin
        reg_wb_l = 1'b1;
        alu_use_imm_l = 1'b1;
        imm_l = imm_u_w;
        is_auipc_l = 1'b1;
        aluop_l = Add;
      end
      //OpEnv: begin
        // TODO
      //end
      default: begin
        //$warning("Opcode not supported: %b", opcode_w);
      end
    endcase
  end

  assign reg_wb_o = reg_wb_l;
  assign reg_lui_o = reg_lui_l;
  assign is_auipc_o = is_auipc_l;
  assign alu_use_imm_o = alu_use_imm_l;
  assign imm_o = imm_l;
  assign branch_o = branch_l;
  assign jump_o = jump_l;
  assign mem_read_o = mem_read_l;
  assign mem_write_o = mem_write_l;
  assign aluop_o = aluop_l;
  assign mem_to_reg_o = mem_to_reg_l;
endmodule

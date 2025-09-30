module decode import core_pkg::*;
  (input  logic [Ilen - 1:0] instr_i
  ,output logic [31:0]       imm_o
  ,output logic [1:0]        aluop_o
  ,output logic              alu_use_imm_o
  ,output logic              reg_wb_o
  ,output logic              reg_lui_o
  ,output logic              is_auipc_o
  ,output logic              branch_o
  ,output logic [1:0]        jump_o
  ,output logic              mem_read_o
  ,output logic              mem_write_o
  ,output logic              mem_to_reg_o
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

  logic [6:0] opcode;
  assign opcode = instr_i[6:0];

  logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
  assign imm_i = {{20{instr_i[31]}}, instr_i[31:20]};
  assign imm_s = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
  assign imm_b = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
  assign imm_u = {instr_i[31:12], 12'b0};
  assign imm_j = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};

  always_comb begin
    reg_wb_o = 1'b0;
    reg_lui_o = 1'b0;
    is_auipc_o = 1'b0;
    alu_use_imm_o = 1'b0;
    branch_o = 1'b0;
    jump_o = None;
    mem_read_o = 1'b0;
    mem_write_o = 1'b0;
    mem_to_reg_o = 1'b0;
    aluop_o = Add;
    imm_o = '0;
    case (opcode)
      OpALU: begin
        reg_wb_o = 1'b1;
        aluop_o = Funct;
      end
      OpALUImm: begin
        reg_wb_o = 1'b1;
        aluop_o = Funct;
        alu_use_imm_o = 1'b1;
        imm_o = imm_i;
      end
      OpLoad: begin
        reg_wb_o = 1'b1;
        mem_read_o = 1'b1;
        mem_to_reg_o = 1'b1;
        aluop_o = Add;
        alu_use_imm_o = 1'b1;
        imm_o = imm_i;
      end
      OpStore: begin
        mem_write_o = 1'b1;
        aluop_o = Add;
        alu_use_imm_o = 1'b1;
        imm_o = imm_s;
      end
      OpBranch: begin
        branch_o = 1'b1;
        aluop_o = Branch;
        imm_o = imm_b;
      end
      OpJal: begin
        reg_wb_o = 1'b1;
        imm_o = imm_j;
        aluop_o = Add;
        jump_o = Jal;
      end
      OpJalr: begin
        reg_wb_o = 1'b1;
        alu_use_imm_o = 1'b1;
        imm_o = imm_i;
        aluop_o = Add;
        jump_o = Jalr;
      end
      OpLui: begin
        reg_wb_o = 1'b1;
        reg_lui_o = 1'b1;
        alu_use_imm_o = 1'b1;
        imm_o = imm_u;
      end
      OpAuipc: begin
        reg_wb_o = 1'b1;
        alu_use_imm_o = 1'b1;
        imm_o = imm_u;
        is_auipc_o = 1'b1;
        aluop_o = Add;
      end
      //OpEnv: begin
        // TODO
      //end
      default: begin
        //$warning("Opcode not supported: %b", opcode_w);
      end
    endcase
  end
endmodule

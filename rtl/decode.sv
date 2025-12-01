module decode import core_pkg::*;
  (input  logic [Ilen - 1:0] inst_i
  ,output logic [Xlen - 1:0] imm_o
  ,output inst_type_e        inst_type_o
  ,output jump_type_e        jump_type_o
  ,output reg_wb_src_e       reg_wb_src_o

  ,output alu_op_e           alu_op_o
  ,output mem_type_e         mem_type_o

  ,output logic [4:0]        rs1_addr_o
  ,output logic [4:0]        rs2_addr_o
  ,output logic [4:0]        rd_addr_o

  ,output csr_op_e           csr_op_o
  ,output logic              csr_imm_o
  ,output logic [11:0]       csr_addr_o
  );

  typedef enum logic [6:0] {
    OpALU    = 7'b0110011,
    OpALUImm = 7'b0010011,
    OpALU32  = 7'b0111011,
    OpALU32I = 7'b0011011,
    OpLoad   = 7'b0000011,
    OpStore  = 7'b0100011,
    OpBranch = 7'b1100011,
    OpJal    = 7'b1101111,
    OpJalr   = 7'b1100111,
    OpLui    = 7'b0110111,
    OpAuipc  = 7'b0010111,
    OpSys    = 7'b1110011
  } opcode_e;

  logic [6:0] opcode, funct7;
  logic [4:0] funct5;
  logic [2:0] funct3;
  assign opcode = inst_i[6:0];
  assign funct7 = inst_i[31:25];
  assign funct5 = funct7[6:2];
  assign funct3 = inst_i[14:12];

  assign rs1_addr_o = inst_i[19:15];
  assign rs2_addr_o = inst_i[24:20];
  assign rd_addr_o = inst_i[11:7];

  assign csr_addr_o = inst_i[31:20];
  assign csr_imm_o = funct3[2];

  localparam imm_i_rep_bits = Xlen - 12;
  localparam imm_s_rep_bits = Xlen - 12;
  localparam imm_b_rep_bits = Xlen - 13;
  localparam imm_u_rep_bits = Xlen - 32;
  localparam imm_j_rep_bits = Xlen - 21;
  localparam imm_sys_rep_bits = Xlen - 5;
  logic [Xlen - 1:0] imm_i, imm_s, imm_b, imm_u, imm_j, imm_sys;
  assign imm_i = {{imm_i_rep_bits{inst_i[31]}}, inst_i[31:20]};
  assign imm_s = {{imm_s_rep_bits{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
  assign imm_b = {{imm_b_rep_bits{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
  assign imm_u = {{imm_u_rep_bits{inst_i[31]}}, inst_i[31:12], 12'b0};
  assign imm_j = {{imm_j_rep_bits{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
  assign imm_sys = {{imm_sys_rep_bits{1'b0}}, inst_i[19:15]};

  always_comb begin
    imm_o = 'x;
    inst_type_o = Rtype;
    jump_type_o = JmpNone;
    reg_wb_src_o = WbNone;
    alu_op_o = OpAdd;
    mem_type_o = MemNone;
    csr_op_o = OpCSRNone;

    case (opcode)
      OpALU: begin
        case (funct3)
          3'h0: alu_op_o = alu_op_e'((funct7 == 7'h20) ? OpSub : OpAdd);
          3'h4: alu_op_o = OpXor;
          3'h6: alu_op_o = OpOr;
          3'h7: alu_op_o = OpAnd;
          3'h1: alu_op_o = OpSll;
          3'h5: alu_op_o = alu_op_e'((funct5 == 5'h08) ? OpSra : OpSrl);
          3'h2: alu_op_o = OpSlt;
          3'h3: alu_op_o = OpSltu;
        endcase

        inst_type_o = Rtype;
        reg_wb_src_o = WbAlu;
      end
      OpALUImm: begin
        case (funct3)
          3'h0: alu_op_o = OpAdd;
          3'h4: alu_op_o = OpXor;
          3'h6: alu_op_o = OpOr;
          3'h7: alu_op_o = OpAnd;
          3'h1: alu_op_o = OpSll;
          3'h5: alu_op_o = alu_op_e'((funct5 == 5'h08) ? OpSra : OpSrl);
          3'h2: alu_op_o = OpSlt;
          3'h3: alu_op_o = OpSltu;
        endcase

        inst_type_o = Itype;
        reg_wb_src_o = WbAlu;
        imm_o = imm_i;
      end
      OpALU32: begin
        case (funct3)
          3'h0: alu_op_o = alu_op_e'((funct7 == 7'h20) ? OpSubw : OpAddw);
          3'h1: alu_op_o = OpSllw;
          3'h5: alu_op_o = alu_op_e'((funct7 == 7'h20) ? OpSraw : OpSrlw);
          default: ;
        endcase

        inst_type_o = Rtype;
        reg_wb_src_o = WbAlu;
      end
      OpALU32I: begin
        case (funct3)
          3'h0: alu_op_o = OpAddw;
          3'h1: alu_op_o = OpSllw;
          3'h5: alu_op_o = alu_op_e'((funct7 == 7'h20) ? OpSraw : OpSrlw);
          default: ;
        endcase

        inst_type_o = Itype;
        reg_wb_src_o = WbAlu;
        imm_o = imm_i;
      end
      OpLoad: begin
        inst_type_o = Itype;
        reg_wb_src_o = WbLsu;
        imm_o = imm_i;
        mem_type_o = MemLoad;
      end
      OpStore: begin
        inst_type_o = Stype;
        imm_o = imm_s;
        mem_type_o = MemStore;
      end
      OpBranch: begin
        case (funct3)
          3'h0: alu_op_o = OpBeq;
          3'h1: alu_op_o = OpBne;
          3'h4: alu_op_o = OpBlt;
          3'h5: alu_op_o = OpBge;
          3'h6: alu_op_o = OpBltu;
          3'h7: alu_op_o = OpBgeu;
          default: ;
        endcase

        inst_type_o = Btype;
        jump_type_o = JmpBr;
        imm_o = imm_b;
      end
      OpJal: begin
        inst_type_o = Jtype;
        jump_type_o = JmpJal;
        reg_wb_src_o = WbJmp;
        imm_o = imm_j;
      end
      OpJalr: begin
        inst_type_o = Itype;
        jump_type_o = JmpJalr;
        reg_wb_src_o = WbJmp;
        imm_o = imm_i;
      end
      OpLui: begin
        inst_type_o = Utype;
        reg_wb_src_o = WbLui;
        imm_o = imm_u;
      end
      OpAuipc: begin
        inst_type_o = Utype;
        reg_wb_src_o = WbAlu;
        imm_o = imm_u;
      end
      OpSys: begin
        inst_type_o = Itype;
        case (funct3)
          3'h0: begin
            if (rs1_addr_o != '0 || rd_addr_o != '0) begin
              // invalid instruction
              // Not the case for SFENCE.VM
            end
            case (csr_addr_o)
              12'h000: csr_op_o = OpEcall;
              12'h001: csr_op_o = OpEbreak;
              12'h302: csr_op_o = OpMret;
              12'h002, 12'h102, 12'h202, 12'h7b2,
                12'h104, 12'h105: ; // unimplemented
              default: ;
            endcase
          end
          3'h1, 3'h5: csr_op_o = OpCSRRW;
          3'h2, 3'h6: csr_op_o = csr_op_e'((rs1_addr_o == '0) ? OpCSRRdonly : OpCSRRS);
          3'h3, 3'h7: csr_op_o = csr_op_e'((rs1_addr_o == '0) ? OpCSRRdonly : OpCSRRC);
          default: ;
        endcase
        reg_wb_src_o = WbCsr;
        imm_o = imm_sys;
      end
      default: ;
    endcase
  end
endmodule

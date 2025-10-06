module alu32 import core_pkg::*;
  (input  logic [2:0]        funct3_i
  ,input  logic [6:0]        funct7_i
  ,input  logic              itype_i
  ,input  logic [1:0]        aluop_i
  ,input  logic [Xlen - 1:0] a_i
  ,input  logic [Xlen - 1:0] b_i
  ,output logic [Xlen - 1:0] res_o
  ,output logic              zero_o
  );

  logic [Xlen - 1:0] add_l, sub_l, xor_l, or_l, and_l, sll_l, srl_l, sra_l;
  logic slt_l, sltu_l;
  assign add_l  = a_i + b_i;
  assign sub_l  = a_i - b_i;
  assign xor_l  = a_i ^ b_i;
  assign or_l   = a_i | b_i;
  assign and_l  = a_i & b_i;
  assign sll_l  = a_i << b_i[4:0];
  assign srl_l  = a_i >> b_i[4:0];
  assign sra_l  = $signed(a_i) >>> b_i[4:0];
  assign slt_l  = ($signed(a_i) < $signed(b_i));
  assign sltu_l = (a_i < b_i);

  logic sub_reduce;
  assign sub_reduce = |sub_l;

  always_comb begin
    res_o = 'x;
    zero_o = 'x;
    case (aluop_i)
      Add:   res_o = add_l;
      Sleft: res_o = sll_l;
      Branch: begin
        case (funct3_i)
          3'h0: zero_o = ~sub_reduce;
          3'h1: zero_o = sub_reduce;
          3'h4: zero_o = slt_l;
          3'h5: zero_o = ~slt_l;
          3'h6: zero_o = sltu_l;
          3'h7: zero_o = ~sltu_l;
          default: zero_o = 'x;
        endcase
      end
      Funct: begin
        case (funct3_i)
          3'h0: res_o = (itype_i || funct7_i == 7'h00) ? add_l : sub_l;
          3'h4: res_o = xor_l;
          3'h6: res_o = or_l;
          3'h7: res_o = and_l;
          3'h1: res_o = sll_l;
          3'h5: res_o = funct7_i == 7'h20 ? sra_l : srl_l;
          3'h2: res_o = slt_l ? 32'h1 : 32'h0;
          3'h3: res_o = sltu_l ? 32'h1 : 32'h0;
          default: res_o = 'x;
        endcase
      end
    endcase
  end
endmodule

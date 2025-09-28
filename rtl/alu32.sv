module alu32
  (input [2:0] funct3_i
  ,input [6:0] funct7_i
  ,input [0:0] itype_i
  ,input [1:0] aluop_i
  ,input [31:0] a_i // should be rs1 or pc
  ,input [31:0] b_i // should be rs2 or imm
  ,output [31:0] res_o
  ,output [0:0] zero_o
  );

  typedef enum logic [1:0] {
    Add, Sleft, Branch, Funct
  } aluop_e;

  wire [31:0] add_w, sub_w, xor_w, or_w, and_w, sll_w, srl_w, sra_w;
  wire [0:0] slt_w, sltu_w;
  assign add_w  = a_i + b_i;
  assign sub_w  = a_i - b_i;
  assign xor_w  = a_i ^ b_i;
  assign or_w   = a_i | b_i;
  assign and_w  = a_i & b_i;
  assign sll_w  = a_i << b_i;
  assign srl_w  = a_i >> b_i;
  assign sra_w  = $signed(a_i) >>> b_i;
  assign slt_w  = ($signed(a_i) < $signed(b_i));
  assign sltu_w = (a_i < b_i);

  wire [0:0] sub_reduce;
  assign sub_reduce = |sub_w;

  logic [31:0] res_l;
  logic [0:0] zero_l;
  always_comb begin
    res_l = 'x;
    zero_l = 'x;
    case (aluop_i)
      Add:   res_l = add_w;
      Sleft: res_l = sll_w;
      Branch: begin
        case (funct3_i)
          3'h0: zero_l = ~sub_reduce;
          3'h1: zero_l = sub_reduce;
          3'h4: zero_l = slt_w;
          3'h5: zero_l = ~slt_w;
          3'h6: zero_l = sltu_w;
          3'h7: zero_l = ~sltu_w;
          default: zero_l = 'x;
        endcase
      end
      Funct: begin
        case (funct3_i)
          3'h0: res_l = (itype_i || funct7_i == 7'h00) ? add_w : sub_w;
          3'h4: res_l = xor_w;
          3'h6: res_l = or_w;
          3'h7: res_l = and_w;
          3'h1: res_l = sll_w;
          3'h5: res_l = funct7_i == 7'h20 ? sra_w : srl_w;
          3'h2: res_l = slt_w ? 32'h1 : 32'h0;
          3'h3: res_l = sltu_w ? 32'h1 : 32'h0;
          default: res_l = 'x;
        endcase
      end
    endcase
  end

  assign res_o = res_l;
  assign zero_o = zero_l;
endmodule

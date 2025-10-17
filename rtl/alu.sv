module alu import core_pkg::*;
  (input  logic [2:0]        funct3_i
  ,input  logic [6:0]        funct7_i
  ,input  logic              itype_i
  ,input  aluop_e            aluop_i
  ,input  logic [Xlen - 1:0] a_i
  ,input  logic [Xlen - 1:0] b_i
  ,output logic [Xlen - 1:0] res_o
  ,output logic              zero_o
  );

  localparam ShamtWidth = $clog2(Xlen) - 1;

  logic [4:0] funct5;
  assign funct5 = funct7_i[6:2];

  logic [Xlen - 1:0] add_l, sub_l, xor_l, or_l, and_l, sll_l, srl_l, sra_l;
  logic slt_l, sltu_l;
  assign add_l  = a_i + b_i;
  assign sub_l  = a_i - b_i;

  assign xor_l  = a_i ^ b_i;
  assign or_l   = a_i | b_i;
  assign and_l  = a_i & b_i;
  assign sll_l  = a_i << b_i[ShamtWidth:0];
  assign srl_l  = a_i >> b_i[ShamtWidth:0];
  assign sra_l  = $signed(a_i) >>> b_i[ShamtWidth:0];
  assign slt_l  = ($signed(a_i) < $signed(b_i));
  assign sltu_l = (a_i < b_i);

  logic [Xlen - 1:0] res_xlen;
  logic [Xlen - 1:0] res_ext;

  logic sub_reduce;
  assign sub_reduce = |sub_l;

  always_comb begin
    case (aluop_i)
      Add: res_o = add_l;
      Op32: res_o = res_ext;
      Funct: res_o = res_xlen;
      default: res_o = 'x;
    endcase
  end

  if (Xlen == 64) begin : l_Xlen_64
    logic [31:0] res32;
    logic [31:0] op32_a;
    logic [4:0] op32_b;
    assign op32_a = a_i[31:0];
    assign op32_b = b_i[4:0];

    logic [31:0] addw_l, subw_l, sllw_l, srlw_l, sraw_l;
    assign addw_l = add_l[31:0];
    assign subw_l = sub_l[31:0];
    assign sllw_l = op32_a << op32_b[4:0];
    assign srlw_l = op32_a >> op32_b[4:0];
    assign sraw_l = $signed(op32_a) >>> op32_b[4:0];

    always_comb begin
      case (funct3_i)
        3'h0: res32 = (itype_i || funct7_i == 7'h00) ? addw_l : subw_l;
        3'h1: res32 = sllw_l;
        3'h5: res32 = funct7_i == 7'h20 ? sraw_l : srlw_l;
        default: res32 = 'x;
      endcase
    end

    assign res_ext = {{Xlen - 32{res32[31]}}, res32[31:0]};
  end else begin : l_Xlen_32
    assign res_ext = 'x;
  end

  always_comb begin
    case (funct3_i)
      3'h0: res_xlen = (itype_i || funct7_i == 7'b0000000) ? add_l : sub_l;
      3'h4: res_xlen = xor_l;
      3'h6: res_xlen = or_l;
      3'h7: res_xlen = and_l;
      3'h1: res_xlen = sll_l;
      3'h5: res_xlen = funct5 == 5'b01000 ? sra_l : srl_l;
      3'h2: res_xlen = slt_l ? 'h1 : 'h0;
      3'h3: res_xlen = sltu_l ? 'h1 : 'h0;
      default: res_xlen = 'x;
    endcase
  end

  always_comb begin
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
endmodule

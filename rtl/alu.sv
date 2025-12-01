module alu import core_pkg::*;
  (input  alu_op_e           alu_op_i
  ,input  logic [Xlen - 1:0] a_i
  ,input  logic [Xlen - 1:0] b_i
  ,output logic [Xlen - 1:0] res_o
  ,output logic              branch_take_o
  );

  logic subtract, signed_op, is_op32;
  always_comb begin
    case (alu_op_i)
      OpSub, OpBeq, OpBne, OpBlt, OpBge,
        OpBltu, OpBgeu, OpSlt, OpSltu, OpSubw: subtract = 1'b1;
      default: subtract = 1'b0;
    endcase
    case (alu_op_i)
      OpSll, OpSrl, OpSltu, OpBltu, OpBgeu, OpSllw, OpSrlw: signed_op = 1'b0;
      default: signed_op = 1'b1;
    endcase
    case (alu_op_i)
      OpAddw, OpSubw: is_op32 = 1'b1;
      default: is_op32 = 1'b0;
    endcase
  end

  logic [Xlen + 1:0] adder_in_a, adder_in_b;
  logic [Xlen:0] in_b_extend;

  assign in_b_extend = {signed_op & b_i[Xlen - 1], b_i};
  assign adder_in_a = {signed_op & a_i[Xlen - 1], a_i, 1'b1};
  assign adder_in_b = subtract ? {~in_b_extend, 1'b1} : {in_b_extend, 1'b0};

  logic [Xlen + 1:0] adder_out;
  logic [Xlen - 1:0] adder_result;

  assign adder_out = adder_in_a + adder_in_b;
  assign adder_result = is_op32 ?
    {{32{adder_out[32]}}, adder_out[32:1]} :
    adder_out[Xlen:1];

  logic lessthan;
  assign lessthan = adder_out[Xlen + 1];

  logic [Xlen:0] shift_op_a;
  logic [32:0] shift32_op_a;

  assign shift_op_a = {signed_op & a_i[Xlen - 1], a_i};
  assign shift32_op_a = {signed_op & a_i[31], a_i[31:0]};

  /* verilator lint_off UNUSEDSIGNAL */
  logic [Xlen:0] shift_right_out;
  logic [32:0] shift32_right_out;
  /* verilator lint_on UNUSEDSIGNAL */
  logic [Xlen - 1:0] shift_left, shift_right,
    shift32_left_ext, shift32_right_ext;
  logic [31:0] shift32_left;

  assign shift_left = a_i << b_i[5:0];
  assign shift_right_out = $signed(shift_op_a) >>> b_i[5:0];
  assign shift_right = shift_right_out[Xlen - 1:0];
  assign shift32_left = a_i[31:0] << b_i[4:0];
  assign shift32_right_out = $signed(shift32_op_a) >>> b_i[4:0];
  assign shift32_left_ext =
    {{Xlen - 32{shift32_left[31]}}, shift32_left[31:0]};
  assign shift32_right_ext =
    {{Xlen - 32{shift32_right_out[31]}}, shift32_right_out[31:0]};

  logic sub_reduce;
  assign sub_reduce = |adder_result;

  always_comb begin
    case (alu_op_i)
      OpAdd, OpSub, OpAddw, OpSubw: res_o = adder_result;
      OpXor:                        res_o = a_i ^ b_i;
      OpOr:                         res_o = a_i | b_i;
      OpAnd:                        res_o = a_i & b_i;
      OpSll:                        res_o = shift_left;
      OpSrl, OpSra:                 res_o = shift_right;
      OpSlt, OpSltu:                res_o = lessthan ? 'h1 : 'h0;
      OpSllw:                       res_o = shift32_left_ext;
      OpSrlw, OpSraw:               res_o = shift32_right_ext;
      default: res_o = 'x;
    endcase
  end

  always_comb begin
    case (alu_op_i)
      OpBeq:          branch_take_o = ~sub_reduce;
      OpBne:          branch_take_o =  sub_reduce;
      OpBlt, OpBltu:  branch_take_o =  lessthan;
      OpBge, OpBgeu:  branch_take_o = ~lessthan;
      default: branch_take_o = 'x;
    endcase
  end
endmodule

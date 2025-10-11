module mem_lsu import core_pkg::*;
  (input logic clk_i
  ,input logic rst_i

  ,input  logic valid_inst_i
  ,input  logic [1:0] mem_type_i
  ,input  logic [Xlen - 1:0] addr_i
  ,input  logic [Xlen - 1:0] wdata_i
  ,input  logic [2:0] funct3_i
  ,output logic [Xlen - 1:0] rdata_o
  ,output logic rvalid_o
  ,output logic mem_busy_o

  ,input  logic mem_ready_i
  ,output logic mem_valid_o
  ,output logic [Xlen - 1:0] mem_addr_o
  ,output logic [Xlen - 1:0] mem_wdata_o
  ,output logic [MaskBits - 1:0] mem_wmask_o
  ,input  logic [Xlen - 1:0] mem_rdata_i
  ,input  logic mem_rvalid_i
  );

  typedef enum logic [1:0] {
    Idle, WaitForReady, WaitForValid
  } mem_state_e;

  mem_state_e state_d, state_q;

  localparam bytesel_bits = $clog2(Xlen / 8);

  logic [Xlen - 1:0] addr_q, wdata_d, wdata_q;
  logic [MaskBits - 1:0] wmask_d, wmask_q;
  logic req_ff_en;

  logic [Xlen - 1:0] rdata_byte_0, rdata_byte_1, rdata_byte_2, rdata_byte_3;
  logic [Xlen - 1:0] rdata_half_0, rdata_half_2;
  logic [bytesel_bits - 1:0] addr_i_byte, addr_q_byte;
  logic sign_extend;

  assign sign_extend = !funct3_i[2];

  localparam byte_rep_bits = Xlen - 8;
  localparam half_rep_bits = Xlen - 16;
  assign rdata_byte_0 = {{byte_rep_bits{sign_extend && mem_rdata_i[7]}},  mem_rdata_i[7:0]};
  assign rdata_byte_1 = {{byte_rep_bits{sign_extend && mem_rdata_i[15]}}, mem_rdata_i[15:8]};
  assign rdata_byte_2 = {{byte_rep_bits{sign_extend && mem_rdata_i[23]}}, mem_rdata_i[23:16]};
  assign rdata_byte_3 = {{byte_rep_bits{sign_extend && mem_rdata_i[31]}}, mem_rdata_i[31:24]};

  assign rdata_half_0 = {{half_rep_bits{sign_extend && mem_rdata_i[15]}}, mem_rdata_i[15:0]};
  assign rdata_half_2 = {{half_rep_bits{sign_extend && mem_rdata_i[31]}}, mem_rdata_i[31:16]};

  assign addr_i_byte = addr_i[bytesel_bits - 1:0];
  assign addr_q_byte = addr_q[bytesel_bits - 1:0];

  assign wdata_d = wdata_i << {addr_i_byte, 3'b0};

  if (Xlen == 32) begin : l_Xlen_32
    always_comb begin
      if (mem_type_i === MemLoad) begin
        wmask_d = '0;
      end else begin
        case (funct3_i)
          3'h0: wmask_d = 4'b0001 << addr_i_byte;
          3'h1: wmask_d = addr_i_byte == 2'b00 ? 4'b0011 :
                        addr_i_byte == 2'b10 ? 4'b1100 : 'x;
          3'h2: wmask_d = 4'b1111;
          default: wmask_d = 'x;
        endcase
      end
      case (funct3_i)
        3'h0, 3'h4: begin
          case (addr_q_byte)
            2'h0: rdata_o = rdata_byte_0;
            2'h1: rdata_o = rdata_byte_1;
            2'h2: rdata_o = rdata_byte_2;
            2'h3: rdata_o = rdata_byte_3;
          endcase
        end
        3'h1, 3'h5: rdata_o = addr_q_byte == 2 ? rdata_half_2 :
                              addr_q_byte == 0 ? rdata_half_0 : 'x;
        3'h2: rdata_o = mem_rdata_i;
        default: rdata_o = 'x;
      endcase
    end
  end else begin : l_Xlen_64
  end

  always_comb begin
    state_d = state_q;

    mem_valid_o = 1'b0;
    rvalid_o = 1'b0;
    mem_busy_o = 1'b0;
    req_ff_en = 1'b0;

    case (state_q)
      Idle: begin
        if (valid_inst_i && (mem_type_i != MemNone)) begin
          mem_busy_o = 1'b1;
          req_ff_en = 1'b1;
          state_d = WaitForReady;
        end
      end
      WaitForReady: begin
        mem_valid_o = 1'b1;
        mem_busy_o = 1'b1;
        if (mem_ready_i) begin
          state_d = WaitForValid;
        end
      end
      WaitForValid: begin
        if (mem_rvalid_i) begin
          rvalid_o = 1'b1;
          state_d = Idle;
        end else begin
          mem_busy_o = 1'b1;
        end
      end
      default: state_d = Idle;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      state_q <= Idle;
    end else begin
      state_q <= state_d;
    end
  end

  always_ff @(posedge clk_i) begin
    if (req_ff_en) begin
      addr_q <= addr_i;
      wdata_q <= wdata_d;
      wmask_q <= wmask_d;
    end
  end

  assign mem_addr_o = addr_q;
  assign mem_wdata_o = wdata_q;
  assign mem_wmask_o = wmask_q;
endmodule

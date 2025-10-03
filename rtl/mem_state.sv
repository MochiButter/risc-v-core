module mem_state import core_pkg::*;
  (input logic clk_i
  ,input logic rst_i

  /* From core */
  ,input  logic valid_inst_i
  ,input  logic read_i // S type
  ,input  logic write_i // I type opcode 3
  ,input  logic [Xlen - 1:0] addr_i // rs1 + imm
  ,input  logic [Xlen - 1:0] wdata_i // S type r2
  ,input  logic [2:0] funct3_i
  ,output logic [Xlen - 1:0] rdata_o // I type rd
  ,output logic rvalid_o // is read data valid
  ,output logic mem_busy_o

  /* To data memory */
  ,input  logic mem_ready_i
  ,output logic mem_valid_o
  ,output logic [Xlen - 1:0] mem_addr_o
  ,output logic [Xlen - 1:0] mem_wdata_o
  ,output logic [(Xlen / 8) - 1:0] mem_wmask_o
  ,input  logic [Xlen - 1:0] mem_rdata_i
  ,input  logic mem_rvalid_i
  );

  typedef enum logic [1:0] {
    Idle, WaitForMem, WaitForValid
  } mem_state_e;

  mem_state_e state_d, state_q;

  logic [(Xlen / 8) - 1:0] wmask_d, wmask_q;
  logic [Xlen - 1:0] addr_d, addr_q, wdata_d, wdata_q;

  logic [Xlen - 1:0] rdata_byte_0, rdata_byte_1, rdata_byte_2, rdata_byte_3;
  logic [Xlen - 1:0] rdata_half_0, rdata_half_2;
  logic [1:0] addr_i_byte, addr_q_byte, funct3_loadbyte;
  logic sign_extend;

  assign sign_extend = !funct3_i[2];

  assign rdata_byte_0 = {{24{sign_extend && mem_rdata_i[7]}}, mem_rdata_i[7:0]};
  assign rdata_byte_1 = {{24{sign_extend && mem_rdata_i[15]}}, mem_rdata_i[15:8]};
  assign rdata_byte_2 = {{24{sign_extend && mem_rdata_i[23]}}, mem_rdata_i[23:16]};
  assign rdata_byte_3 = {{24{sign_extend && mem_rdata_i[31]}}, mem_rdata_i[31:24]};

  assign rdata_half_0 = {{16{sign_extend && mem_rdata_i[15]}}, mem_rdata_i[15:0]};
  assign rdata_half_2 = {{16{sign_extend && mem_rdata_i[31]}}, mem_rdata_i[31:16]};

  assign addr_i_byte = addr_i[1:0];
  assign addr_q_byte = addr_q[1:0];
  assign funct3_loadbyte = funct3_i[1:0];

  always_comb begin
    state_d = state_q;

    mem_valid_o = 1'b0;
    rvalid_o = 1'b0;
    mem_busy_o = 1'b0;

    wmask_d = wmask_q;
    addr_d = addr_q;
    wdata_d = wdata_q;
    rdata_o = '0;

    case (state_q)
      Idle: begin
        if (valid_inst_i && (read_i || write_i)) begin
          if (read_i) begin
            wmask_d = 4'b0000;
          end else begin
            case (funct3_i)
              // sb
              3'h0: wmask_d = 4'b0001 << addr_i_byte;
              // sh
              3'h1: begin
                wmask_d = addr_i_byte == 2 ? 4'b1100 :
                          addr_i_byte == 0 ? 4'b0011 : 'x;
              end
              // sw
              3'h2: wmask_d = 4'b1111;
              default: wmask_d = 'x;
            endcase
          end
          addr_d = addr_i;
          wdata_d = wdata_i << {addr_i_byte, 3'b0};

          mem_busy_o = 1'b1;

          state_d = WaitForMem;
        end
      end
      WaitForMem: begin
        mem_valid_o = 1'b1;
        mem_busy_o = 1'b1;
        if (mem_ready_i) begin
          state_d = WaitForValid;
        end
      end
      WaitForValid: begin
        if (mem_rvalid_i) begin
          case (funct3_loadbyte)
            0: begin
              case (addr_q_byte)
                0: rdata_o = rdata_byte_0;
                1: rdata_o = rdata_byte_1;
                2: rdata_o = rdata_byte_2;
                3: rdata_o = rdata_byte_3;
              endcase
            end
            1: begin
              rdata_o = addr_i_byte == 0 ? rdata_half_0 :
                        addr_i_byte == 2 ? rdata_half_2 : 'x;
            end
            2: rdata_o = mem_rdata_i;
            default: rdata_o = 'x;
          endcase
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

  // no need to reset, since state will overwrite anyways
  always_ff @(posedge clk_i) begin
    wmask_q <= wmask_d;
    addr_q <= addr_d;
    wdata_q <= wdata_d;
  end

  assign mem_addr_o = addr_q;
  assign mem_wdata_o = wdata_q;
  assign mem_wmask_o = wmask_q;
endmodule

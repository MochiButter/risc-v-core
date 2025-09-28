module mem_state
  (input [0:0] clk_i
  ,input [0:0] rst_i

  /* From core */
  ,input [0:0] read_i // S type
  ,input [0:0] write_i // I type opcode 3
  ,input [31:0] addr_i // rs1 + imm
  ,input [31:0] wdata_i // S type r2
  ,input [2:0] funct3_i
  ,output [31:0] rdata_o // I type rd
  ,output [0:0] rvalid_o // is read data valid
  ,output [0:0] mem_busy_o

  /* To data memory */
  ,input [0:0] mem_ready_i
  ,output [0:0] mem_valid_o
  ,output [31:0] mem_addr_o
  ,output [31:0] mem_wdata_o
  ,output [3:0] mem_wmask_o
  ,input [31:0] mem_rdata_i
  ,input[0:0] mem_rvalid_i
  );

  typedef enum {
    Idle, WaitForMem, WaitForValid
  } mem_state_e;

  mem_state_e state_d, state_q;
  logic [0:0] mem_valid_l, rvalid_l, mem_busy_l;

  logic [3:0] wmask_d, wmask_q;
  logic [31:0] addr_d, addr_q, wdata_d, wdata_q;
  logic [31:0] rdata_l;

  wire [31:0] rdata_byte_0, rdata_byte_1, rdata_byte_2, rdata_byte_3;
  wire [31:0] rdata_half_0, rdata_half_2;
  wire [1:0] addr_i_byte, addr_q_byte, funct3_loadbyte;
  wire [0:0] sign_extend;

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

    mem_valid_l = 1'b0;
    rvalid_l = 1'b0;
    mem_busy_l = 1'b0;

    wmask_d = wmask_q;
    addr_d = addr_q;
    wdata_d = wdata_q;
    rdata_l = '0;

    case (state_q)
      Idle: begin
        if (read_i || write_i) begin
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

          mem_busy_l = 1'b1;

          state_d = WaitForMem;
        end
      end
      WaitForMem: begin
        mem_valid_l = 1'b1;
        mem_busy_l = 1'b1;
        if (mem_ready_i) begin
          state_d = WaitForValid;
        end
      end
      WaitForValid: begin
        if (mem_rvalid_i) begin
          case (funct3_loadbyte)
            0: begin
              case (addr_q_byte)
                0: rdata_l = rdata_byte_0;
                1: rdata_l = rdata_byte_1;
                2: rdata_l = rdata_byte_2;
                3: rdata_l = rdata_byte_3;
              endcase
            end
            1: begin
              rdata_l = addr_i_byte == 0 ? rdata_half_0 :
                        addr_i_byte == 2 ? rdata_half_2 : 'x;
            end
            2: rdata_l = mem_rdata_i;
            default: rdata_l = 'x;
          endcase
          rvalid_l = 1'b1;
          state_d = Idle;
        end else begin
          mem_busy_l = 1'b1;
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

  assign rdata_o = rdata_l;
  assign rvalid_o = rvalid_l;
  assign mem_busy_o = mem_busy_l;

  assign mem_valid_o = mem_valid_l;
  assign mem_addr_o = addr_q;
  assign mem_wdata_o = wdata_q;
  assign mem_wmask_o = wmask_q;
endmodule

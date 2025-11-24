module fetch import core_pkg::*;
  (input logic clk_i
  ,input logic rst_ni

  ,input logic control_hazard_i
  ,input logic [Xlen - 1:0] pc_target_i

  ,input  logic mem_ready_i
  ,output logic mem_valid_o
  ,output logic [Xlen - 1:0] mem_addr_o
  ,input  logic [Xlen - 1:0] mem_rdata_i
  ,input  logic mem_rvalid_i

  ,input  logic inst_ready_i
  ,output logic [Xlen - 1:0] inst_pc_o
  ,output logic [Ilen - 1:0] inst_data_o
  ,output logic inst_valid_o
  );

  logic [(Xlen + Ilen) - 1:0] fifo_wr_data;
  logic [Xlen - 1:0] pc_next_d, pc_next_q, fetch_addr_d, fetch_addr_q;
  logic fifo_rst, fifo_wr_valid, fifo_wr_ready;

  typedef enum logic [1:0] {Idle, Fetching, Hazard} fetch_state_e;

  fetch_state_e fetch_state_d, fetch_state_q;

  assign mem_valid_o = fifo_wr_ready;
  assign mem_addr_o  = fetch_addr_d;

  assign fifo_rst = !rst_ni || control_hazard_i;
  assign fifo_wr_valid = mem_rvalid_i && fetch_state_q != Hazard;

  assign pc_next_d = fetch_addr_d + 'h4;

  always_comb begin
    if (control_hazard_i) begin
      fetch_addr_d = pc_target_i;
    end else begin
      fetch_addr_d = pc_next_q;
    end
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      pc_next_q <= BootAddr;
    end else if (mem_ready_i && mem_valid_o) begin
      pc_next_q <= pc_next_d;
      fetch_addr_q <= fetch_addr_d;
    end else if (control_hazard_i) begin
      pc_next_q <= pc_target_i;
    end
  end

  always_comb begin
    fetch_state_d = fetch_state_q;

    case (fetch_state_q)
      Idle: if (mem_ready_i && mem_valid_o) fetch_state_d = Fetching;
      Fetching: begin
        if (control_hazard_i && !mem_rvalid_i) begin
          fetch_state_d = Hazard;
        end else if (!(mem_ready_i && mem_valid_o)) begin
          fetch_state_d = Idle;
        end
      end
      Hazard: if (mem_rvalid_i) fetch_state_d = Fetching;
      default: fetch_state_d = Idle;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      fetch_state_q <= Fetching;
    end else begin
      fetch_state_q <= fetch_state_d;
    end
  end

  logic [31:0] instmem_high, instmem_low, fetch_rdata;
  assign instmem_high = mem_rdata_i[63:32];
  assign instmem_low  = mem_rdata_i[31:00];
  assign fetch_rdata = fetch_addr_q[2] == 1'b0 ? instmem_low : instmem_high;

  assign fifo_wr_data = {fetch_addr_q, fetch_rdata};

  fifo #(.DepthLog2(2), .Width(Xlen + Ilen)) fifo_inst (
    .clk_i(clk_i),
    .rst_ni(!fifo_rst),
    .wr_valid_i(fifo_wr_valid),
    .wr_data_i(fifo_wr_data),
    .wr_ready_o(),
    .wr_ready_two_o(fifo_wr_ready),
    .rd_ready_i(inst_ready_i),
    .rd_data_o({inst_pc_o, inst_data_o}),
    .rd_valid_o(inst_valid_o)
  );

endmodule

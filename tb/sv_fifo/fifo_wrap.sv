module fifo_wrap
  (input [0:0] clk_i
  ,input [0:0] rst_ni

  ,input [0:0] wr_valid_i
  ,input [63:0] wr_data_i
  ,output [0:0] wr_ready_o
  ,output [0:0] wr_ready_two_o

  ,input [0:0] rd_ready_i
  ,output [63:0] rd_data_o
  ,output [0:0] rd_valid_o
  );
  fifo #(.DepthLog2(2), .Width(64))
    fifo (.*);
endmodule

module pipeline_reg_wrap
  (input [0:0] clk_i
  ,input [0:0] rst_i

  ,input [0:0] wr_valid_i
  ,input [63:0] wr_data_i
  ,output [0:0] wr_ready_o

  ,input [0:0] rd_ready_i
  ,output [63:0] rd_data_o
  ,output [0:0] rd_valid_o
  );
  pipeline_reg #(.Width(64))
    pipeline (.*);
endmodule

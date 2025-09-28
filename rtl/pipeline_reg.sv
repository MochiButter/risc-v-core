module pipeline_reg 
  #(parameter Width = 32)
  (input [0:0] clk_i
  ,input [0:0] rst_i

  ,input [0:0] wr_valid_i
  ,input [Width - 1:0] wr_data_i
  ,output [0:0] wr_ready_o

  ,input [0:0] rd_ready_i
  ,output [Width - 1:0] rd_data_o
  ,output [0:0] rd_valid_o
  );

  logic [0:0] write, rd_valid_q;
  logic [Width - 1:0] rd_data_q;

  always_comb begin
    write = wr_valid_i && wr_ready_o;
  end
  
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      rd_valid_q <= 1'b0;
    end else begin
      if (write) begin
        rd_data_q <= wr_data_i;
        rd_valid_q <= 1'b1;
      end else if (rd_ready_i) begin
        rd_valid_q <= 1'b0;
      end
    end
  end

  assign wr_ready_o = !rd_valid_o || rd_ready_i;
  assign rd_valid_o = rd_valid_q;
  assign rd_data_o = rd_data_q;
endmodule

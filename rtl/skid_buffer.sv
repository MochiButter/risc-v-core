module skid_buffer
  #(parameter Width = 32)
  (input  logic clk_i
  ,input  logic rst_ni

  ,input  logic               wr_valid_i
  ,input  logic [Width - 1:0] wr_data_i
  ,output logic               wr_ready_o

  ,input  logic               rd_ready_i
  ,output logic [Width - 1:0] rd_data_o
  ,output logic               rd_valid_o
  );

  logic [Width - 1:0] reg_data_d, reg_data_q;
  logic reg_valid_d, reg_valid_q;

  always_comb begin
    reg_valid_d = reg_valid_q;
    reg_data_d  = reg_data_q;

    if (wr_valid_i && wr_ready_o && rd_valid_o && !rd_ready_i) begin
      reg_valid_d = 1'b1;
      reg_data_d  = wr_data_i;
    end else if (rd_ready_i) begin
      reg_valid_d = 1'b0;
    end
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      reg_valid_q <= 1'b0;
      reg_data_q  <= '0;
    end else begin
      reg_valid_q <= reg_valid_d;
      reg_data_q  <= reg_data_d;
    end
  end

  assign wr_ready_o = !reg_valid_q;
  assign rd_valid_o = reg_valid_q || wr_valid_i;
  assign rd_data_o  = reg_valid_q ? reg_data_q : wr_data_i;
endmodule

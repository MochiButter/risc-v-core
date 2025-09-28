module ram_tb ();
  logic [0:0] clk_i, valid_i, rd_valid_o, ready_o;
  logic [3:0] wr_en_i;
  logic [7:0] addr_i;
  logic [31:0] wr_data_i, rd_data_o;
  
  initial begin
    clk_i = 1'b0;
    #5;
    forever begin
      clk_i = ~clk_i;
      #5;
    end
  end

  ram_wrap ram_inst (.*);

  initial begin
  $dumpfile(`DUMPFILE);
  $dumpvars;
    @(negedge clk_i);
    wr_en_i = '0;
    valid_i = 1'b0;
    addr_i = '0;
    wr_data_i = '0;
    @(posedge clk_i);

    // rd testing
    for (int i = 0; i < 16; i += 4) begin
      @(negedge clk_i);
      valid_i = 1'b1;
      addr_i = i[7:0];
      @(posedge clk_i);
      #1;
      if (!ready_o) begin
        $display("ready_o didn't go high");
        $display("\033[0;31mSIM FAILED\033[0m");
        $finish();
      end
      if (~rd_valid_o) begin
        $display("rd_valid_o didn't go high");
        $display("\033[0;31mSIM FAILED\033[0m");
        $finish();
      end
      $display("[0x%08h] 0x%08h", addr_i, rd_data_o);
    end

    addr_i = 8'h10;
    wr_data_i = '0;
    wr_en_i = 4'b1111;
    @(posedge clk_i);
    $display("wrote 0x%08h to [0x%08h] with mask %b", wr_data_i, addr_i, wr_en_i);
    #1;
    wr_data_i = 32'h42df_03ff;
    wr_en_i = 4'b1001;
    @(posedge clk_i);
    $display("wrote 0x%08h to [0x%08h] with mask %b", wr_data_i, addr_i, wr_en_i);
    #1;
    wr_en_i = '0;
    @(posedge clk_i);
    #1;
    if (rd_data_o != 32'h4200_00ff) begin
      $display("read data doesn't match expected: 0x%08h", rd_data_o);
      $display("\033[0;31mSIM FAILED\033[0m");
      $finish();
    end
    $display("[0x%08h] 0x%08h", addr_i, rd_data_o);

    $display("No bad outputs detected");
    $display("\033[0;32mSIM PASSED\033[0m");
    $finish();
  end

endmodule

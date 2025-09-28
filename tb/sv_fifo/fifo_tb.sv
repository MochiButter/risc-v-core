// Since fifos and pipeline registers are so mimilar in the ports and testing
// criteria, I decided to reuse the fifo tb for both of them. The macro
// SIM_PIPELINE alters tests slightly.
module fifo_tb();
`ifdef SIM_PIPELINE
  parameter DepthLog2 = 0;
`else
  parameter DepthLog2 = 2;
`endif
  localparam Depth = (1 << DepthLog2);
  parameter Width = 64;
  
  parameter bit verbose = 0;

  initial begin
    `ifdef SIM_PIPELINE
      $display("Testing pipeline reg with width %d", Width);
    `else
      $display("Testing fifo of depth %d, width %d", Depth, Width);
    `endif
  end

  logic [0:0] clk_i, rst_i;
  logic [0:0] wr_valid_i, wr_ready_o, rd_ready_i, rd_valid_o;
  logic [Width - 1:0] wr_data_i, rd_data_o;
  int count, tmp_count, random;
  logic [Width - 1:0] fifo_qu [$:Depth];
    
  initial begin
    clk_i = 1'b0;
    #5;
    forever begin
      clk_i = ~clk_i;
      #5;
    end
  end
  
  task reset();
    wr_valid_i = 1'b0;
    wr_data_i = '0;
    rd_ready_i = 1'b0;
    fifo_qu.delete();
    count = 0;
    rst_i = 1'b0;
    #10;
    rst_i = 1'b1;
    #20;
    rst_i = 1'b0;
    @(negedge clk_i);
  endtask

`ifdef SIM_PIPELINE
  pipeline_reg_wrap pr_inst (.*);
`else
  fifo_wrap fifo_inst (.*);
`endif

  task check_transfer();
    tmp_count = count;

    @(posedge clk_i);
    // A fifo with depth 1 is just a single pipeline register. It has to be
    // able to read and write on the same cycle when it already has one word
    // saved. It has special cases for writes compared to regular fifos
    if (count == Depth && wr_ready_o && (Depth > 1 || !rd_ready_i)) begin
      $display("Fifo was ready when full");
      $display("\033[0;31mSIM FAILED\033[0m");
      $finish();
    end
    if ((wr_valid_i && tmp_count < Depth)
      || (Depth == 1 && wr_valid_i && rd_ready_i)) begin
      if (!wr_ready_o) begin
        $display("Fifo was not ready when writable");
        $display("\033[0;31mSIM FAILED\033[0m");
        $finish();
      end
      if (verbose) $display("Wrote [0x%8h] %8h", wr_data_i[63:32], wr_data_i[31:0]);
      count ++;
      fifo_qu.push_back(wr_data_i);
    end
    if (count == 0 && rd_valid_o) begin
      $display("Fifo was valid when empty");
      $display("\033[0;31mSIM FAILED\033[0m");
      $finish();
    end
    if (rd_ready_i && tmp_count > 0) begin
      if (!rd_valid_o) begin
        $display("Fifo was not valid when readable");
        $display("\033[0;31mSIM FAILED\033[0m");
        $finish();
      end
      if (verbose) $display("Read [0x%8h] %8h", rd_data_o[63:32], rd_data_o[31:0]);
      count --;
      if (rd_data_o !== fifo_qu.pop_front()) begin
        $display("Bad rd output: %16h", rd_data_o);
        $display("\033[0;31mSIM FAILED\033[0m");
        $finish();
      end
    end
    @(negedge clk_i);
    if (rst_i) begin
      fifo_qu.delete();
      count = 0;
    end
    rd_ready_i = 1'b0;
    wr_valid_i = 1'b0;
    wr_data_i = '0;
    rst_i = 1'b0;
  endtask

  initial begin
  $dumpfile(`DUMPFILE);
  $dumpvars;

    reset();
    if (verbose) $display("=== FIFO WRITE THEN READ ===");
    for (int i = 0; i < (2 * Depth); i ++) begin
      wr_valid_i = 1'b1;
      wr_data_i = {i, $random()};
      check_transfer();
    end
    for (int i = 0; i < (2 * Depth); i ++) begin
      rd_ready_i = 1'b1;
      check_transfer();
    end

    reset();
    if (verbose) $display("=== FIFO RDWR STREAM ===");
    for (int i = 0; i < Depth; i ++) begin
      wr_valid_i = 1'b1;
      wr_data_i = {i, $random()};
      check_transfer();
    end
    for (int i = 0; i < 16; i ++) begin
      wr_valid_i = 1'b1;
      wr_data_i = {i, $random()};
      rd_ready_i = 1'b1;
      check_transfer();
    end

    reset();
    if (verbose) $display("=== FIFO RANDOM ===");
    for (int i = 0; i < 32; i ++) begin
      random = ($random() >> 29);
      if (random < 2)begin
        wr_valid_i = 1'b1;
        wr_data_i = {i, $random()};
        if (verbose) $display("wr only");
      end else if (random < 4) begin
        rd_ready_i = 1'b1;
        if (verbose) $display("rd only");
      end else if (random < 6) begin
        wr_valid_i = 1'b1;
        wr_data_i = {i, $random()};
        rd_ready_i = 1'b1;
        if (verbose) $display("rdwr");
      end else if (random == 6) begin
        rst_i = 1'b1;
        if (verbose) $display("Flush");
      end else begin
        if (verbose) $display("Delay");
      end
      check_transfer();
    end

    $display("No bad outputs detected");
    $display("\033[0;32mSIM PASSED\033[0m");
    $finish();
  end
endmodule

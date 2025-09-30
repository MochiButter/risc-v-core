/* A 1r1w FIFO module
 * DepthLog2 defines how many slots are available: 2 ** DepthLog2
 * Two pointers determine where the data is to be read/written from.
 * The last operation determines if the fifo is full or empty when the
 * pointers overlap.
 */
module fifo
  #(parameter DepthLog2 = 2
  ,parameter Width = 32)
  (input logic clk_i
  ,input logic rst_i

  ,input  logic               wr_valid_i
  ,input  logic [Width - 1:0] wr_data_i
  ,output logic               wr_ready_o

  ,input  logic               rd_ready_i
  ,output logic [Width - 1:0] rd_data_o
  ,output logic               rd_valid_o
  );

  if (DepthLog2 < 1) begin
    $error("Fifo must have depth of at least 2; use pipeline_reg instead.");
  end

  localparam Depth = (1 << DepthLog2);

  logic [Width - 1:0] mem [0:Depth - 1];
  logic [DepthLog2 - 1:0] ptr_write_q, ptr_write_d, ptr_read_q, ptr_read_d;
  logic [0:0] write, read, last_wr_q, last_rd_q;

  always_comb begin
    write = wr_valid_i && wr_ready_o;
    read = rd_valid_o && rd_ready_i;
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      last_wr_q <= 1'b0;
      last_rd_q <= 1'b1;
    end else if (write || read) begin
      last_wr_q <= write;
      last_rd_q <= read;
    end
  end

  always_comb begin
    ptr_write_d = ptr_write_q + 1'b1;
    ptr_read_d = ptr_read_q + 1'b1;
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      ptr_write_q <= '0;
      ptr_read_q <= '0;
    end else begin
      ptr_write_q <= write ? ptr_write_d : ptr_write_q;
      ptr_read_q <= read ? ptr_read_d : ptr_read_q;
    end
  end
  
  // The memory won't be reset as the garbage data must be overwritten in
  // order to be ready anyways
  always_ff @(posedge clk_i) begin
    if (write) begin
      mem[ptr_write_q] <= wr_data_i;
    end
  end

  assign wr_ready_o = !(ptr_write_q == ptr_read_q && last_wr_q);
  assign rd_valid_o = !(ptr_read_q == ptr_write_q && last_rd_q);
  assign rd_data_o = mem[ptr_read_q];
endmodule

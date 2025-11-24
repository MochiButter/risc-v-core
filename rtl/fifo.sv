/* A 1r1w FIFO module
 * DepthLog2 defines how many slots are available: 2 ** DepthLog2
 * Two pointers determine where the data is to be read/written from.
 * The last operation determines if the fifo is full or empty when the
 * pointers overlap.
 * Uses a 1r1w ram for sotrage. Since the ram takes 1 cycle to read an element,
 * the latest write on an empty cycle will be stored on a flip-flop, and
 * given to the reader until the ram catches up.
 */
module fifo
  #(parameter DepthLog2 = 2
  ,parameter Width = 32)
  (input logic clk_i
  ,input logic rst_ni

  ,input  logic               wr_valid_i
  ,input  logic [Width - 1:0] wr_data_i
  ,output logic               wr_ready_o
  ,output logic               wr_ready_two_o

  ,input  logic               rd_ready_i
  ,output logic [Width - 1:0] rd_data_o
  ,output logic               rd_valid_o
  );

  if (DepthLog2 < 1) begin : l_depth_warning
    $error("Fifo must have depth of at least 2; use pipeline_reg instead.");
  end : l_depth_warning

  localparam Depth = (1 << DepthLog2);

  logic [DepthLog2 - 1:0] ptr_write_q, ptr_write_d, ptr_read_q, ptr_read_d,
    ptr_write_two;
  logic [Width - 1:0] rd_data_mem, rd_data_reg;
  logic [0:0] write, read, last_wr_q, last_rd_q, addr_equal,
    forward_data_d, forward_data_q;

  assign write = wr_valid_i && wr_ready_o;
  assign read = rd_valid_o && rd_ready_i;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      last_wr_q <= 1'b0;
      last_rd_q <= 1'b1;
    end else if (write || read) begin
      last_wr_q <= write;
      last_rd_q <= read;
    end
  end

  assign ptr_write_d = ptr_write_q + write;
  assign ptr_read_d = ptr_read_q + read;
  assign ptr_write_two = ptr_write_q + 'h1;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      ptr_write_q <= '0;
      ptr_read_q <= '0;
    end else begin
      ptr_write_q <= ptr_write_d;
      ptr_read_q <= ptr_read_d;
    end
  end

  ram_1r1w_sync #(
    .Width(Width), .Depth(Depth)
  ) u_mem (
    .clk_i(clk_i),
    .w_en_i(write),
    .waddr_i(ptr_write_q),
    .wdata_i(wr_data_i),
    .r_en_i(!forward_data_d),
    .raddr_i(ptr_read_d),
    .rdata_o(rd_data_mem)
  );

  assign forward_data_d = (ptr_write_q == ptr_read_d && write);

  always_ff @(posedge clk_i) begin
    // not necessary to reset, as the first cycle will never be able to read
    // by the second cycle, this will no longer be 1'bx
    forward_data_q <= forward_data_d;
  end

  always_ff @(posedge clk_i) begin
    // also not necessary to reset for the same reason as above
    if (forward_data_d) begin
      rd_data_reg <= wr_data_i;
    end
  end

  assign addr_equal = (ptr_write_q == ptr_read_q);
  assign wr_ready_o = !(addr_equal && last_wr_q);
  assign wr_ready_two_o = !(ptr_write_two == ptr_read_q);
  assign rd_valid_o = !(addr_equal && last_rd_q);
  assign rd_data_o = forward_data_q ? rd_data_reg : rd_data_mem;
endmodule

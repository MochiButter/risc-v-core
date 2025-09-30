/* RAM module for use with the RISC-V core.
 * BINPATH is the relative directory from where the command is being executed,
 * to the project root.
 * The write enable signal uses four bits, representing bytes in a word.
 * If all four are zeros, then the operation is a read.
 * For each 1, write that byte to memory.
 * If the address is valid on a rising edge, the memory will assert a valid
 * read, or if the write bits are set, then those bytes will be written to
 * memory.
 */
`ifndef BINPATH
  `define BINPATH ""
`endif

module ram_1rw_sync
  #(parameter Width = 32
  ,parameter Depth = 256
  ,parameter UseInitFile = 0
  ,parameter InitFile = {`BINPATH, "rtl/program.mem"}
  )
  (input logic clk_i

  ,output logic                       ready_o
  ,input  logic                       valid_i
  ,input  logic [$clog2(Depth) - 1:0] addr_i
  ,input  logic [Width - 1:0]         wr_data_i
  ,input  logic [(Width / 8) - 1:0]   wmask_i // 0 for rd, then write mask for wr

  ,output logic [Width - 1:0] rd_data_o
  ,output logic               rd_valid_o
  );

  logic [Width - 1:0] mem [0:Depth - 1];
  if (UseInitFile) begin
    initial begin
      $display("ram_1rw_sync: Create mem sync with init file '%s'.", InitFile);
      $readmemh(InitFile, mem);//, 0, 31);
    end
  end

  logic [Width - 1:0] rd_data_q;
  logic [0:0] rd_valid_q;

  // as a sram cell, this should always be ready
  assign ready_o = 1'b1;

  always_ff @(posedge clk_i) begin
    rd_data_q <= '0;
    rd_valid_q <= 1'b0;
    if (valid_i) begin
      rd_data_q <= mem[addr_i >> 2];
      rd_valid_q <= 1'b1;
      if (wmask_i[0]) mem[addr_i >> 2][7:0] <= wr_data_i[7:0];
      if (wmask_i[1]) mem[addr_i >> 2][15:8] <= wr_data_i[15:8];
      if (wmask_i[2]) mem[addr_i >> 2][23:16] <= wr_data_i[23:16];
      if (wmask_i[3]) mem[addr_i >> 2][31:24] <= wr_data_i[31:24];
    end
  end

  assign rd_data_o = rd_data_q;
  assign rd_valid_o = rd_valid_q;
endmodule

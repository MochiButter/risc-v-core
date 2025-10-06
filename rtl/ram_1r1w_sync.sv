module ram_1r1w_sync
  #(parameter Width = 32
  ,parameter Depth = 256)
  (input  logic clk_i

  ,input  logic                       w_en_i
  ,input  logic [$clog2(Depth) - 1:0] waddr_i
  ,input  logic [Width - 1:0]         wdata_i

  ,input  logic                       r_en_i
  ,input  logic [$clog2(Depth) - 1:0] raddr_i
  ,output logic [Width - 1:0]         rdata_o
  );

  logic [Width - 1:0] mem [0:Depth - 1];

  always_ff @(posedge clk_i) begin
    if (w_en_i) begin
      mem[waddr_i] <= wdata_i;
    end
    if (r_en_i) begin
      rdata_o <= mem[raddr_i];
    end
  end
endmodule

`ifndef BINPATH
  `define BINPATH ""
`endif

module ram_1rw_sync
  #(parameter DataWidth   = 32
  ,parameter  AddrWidth   = 8
  ,localparam MaskBits    = DataWidth / 8
  ,parameter  UseInitFile = 0
  ,parameter  InitFile    = {`BINPATH, "rtl/program.mem"}
  )
  (input  logic clk_i

  ,input  logic                   valid_i
  ,input  logic [AddrWidth - 1:0] addr_i
  ,input  logic                   wr_en_i
  ,input  logic [DataWidth - 1:0] wdata_i
  ,input  logic [MaskBits  - 1:0] wmask_i
  ,output logic [DataWidth - 1:0] rdata_o
  );

  logic [DataWidth - 1:0] mem [0:(2 ** AddrWidth) - 1];

  initial begin
    if (UseInitFile) begin
      $display("Initialized %m with '%s'.", InitFile);
      $readmemh(InitFile, mem);
    end
  end

  always_ff @(posedge clk_i) begin
    if (valid_i) begin
      if (wr_en_i) begin
        for (int i = 0; i < MaskBits; i ++) begin
          if (wmask_i[i]) mem[addr_i][8 * i+:8] <= wdata_i[8 * i+:8];
        end
      end else begin
        rdata_o <= mem[addr_i];
      end
    end
  end
endmodule

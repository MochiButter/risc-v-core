`ifndef BINPATH
  `define BINPATH ""
`endif

module ram_1r1w_sync
  #(parameter DataWidth = 32
  ,parameter  AddrWidth = 8
  ,localparam MaskBits  = DataWidth / 8
  ,parameter  UseMask   = 0
  ,parameter  UseInitFile = 0
  ,parameter  InitFile    = {`BINPATH, "rtl/program.mem"}
  )
  (input  logic clk_i

  ,input  logic                   w_en_i
  ,input  logic [AddrWidth - 1:0] waddr_i
  ,input  logic [DataWidth - 1:0] wdata_i
  ,input  logic [MaskBits  - 1:0] wmask_i

  ,input  logic                   r_en_i
  ,input  logic [AddrWidth - 1:0] raddr_i
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
    if (w_en_i) begin
      if (UseMask) begin
        for (int i = 0; i < MaskBits; i ++) begin
          if (wmask_i[i]) mem[waddr_i][8 * i+:8] <= wdata_i[8 * i+:8];
        end
      end else begin
        mem[waddr_i] <= wdata_i;
      end
    end
    if (r_en_i) begin
      rdata_o <= mem[raddr_i];
    end
  end

  if (!UseMask) begin : l_no_mask
    logic [MaskBits - 1:0] __unused;
    assign __unused = wmask_i;
  end
endmodule

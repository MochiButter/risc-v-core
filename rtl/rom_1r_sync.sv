`ifndef BINPATH
  `define BINPATH ""
`endif

module rom_1r_sync
  #(parameter DataWidth   = 32
  ,parameter  AddrWidth   = 8
  ,parameter  UseInitFile = 0
  ,parameter  InitFile    = {`BINPATH, "rtl/program.mem"}
  )
  (input  logic clk_i

  ,input  logic                   valid_i
  ,input  logic [AddrWidth - 1:0] addr_i
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
      rdata_o <= mem[addr_i];
    end
  end
endmodule

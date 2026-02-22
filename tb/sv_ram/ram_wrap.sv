module ram_wrap
  (input [0:0] clk_i

  ,output [0:0] ready_o
  ,input [0:0] valid_i
  ,input [7:0] addr_i
  ,input [31:0] wr_data_i
  ,input [3:0] wr_en_i // 0 for rd, then write mask for wr

  ,output [31:0] rd_data_o
  ,output [0:0] rd_valid_o
  );
  logic [3:0] wmask_i;
  assign wmask_i = wr_en_i;
  ram_1rw_sync #(.Width(32), .Depth(256), .UseInitFile(1),
    .InitFile({`BINPATH, "tb/sv_ram/ram_init.hex"})) 
    ram_inst (.*);
endmodule

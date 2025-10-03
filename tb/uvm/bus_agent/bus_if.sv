interface bus_if #(
    parameter AddrWidth = 32,
    parameter DataWidth = 32
  ) (
    input logic clk_i
  );

  logic ready;
  logic valid;
  logic [AddrWidth - 1:0] addr;
  logic [DataWidth - 1:0] wdata;
  logic [(DataWidth / 8) - 1:0]  wmask;
  logic [DataWidth- 1:0] rdata;
  logic rvalid;

  modport requester
  (input  ready, rdata, rvalid
  ,output valid, addr, wdata, wmask
  );

  modport responder
  (input valid, addr, wdata, wmask
  ,output ready, rdata, rvalid
  );
endinterface

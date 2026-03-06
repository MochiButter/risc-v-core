interface axil_if
  import axil_pkg::*;
  #(parameter BusWidth = 64
  ,localparam MaskBits = BusWidth / 8)
  ();

  logic                  awvalid;
  logic                  awready;
  logic [BusWidth - 1:0] awaddr;
  /* verilator lint_off UNUSEDSIGNAL */
  axil_prot_t            awprot;
  /* verilator lint_on UNUSEDSIGNAL */

  logic                  wvalid;
  logic                  wready;
  logic [BusWidth - 1:0] wdata;
  logic [MaskBits - 1:0] wstrb;

  logic                  bvalid;
  logic                  bready;
  /* verilator lint_off UNUSEDSIGNAL */
  axil_resp_e            bresp;
  /* verilator lint_on UNUSEDSIGNAL */

  logic                  arvalid;
  logic                  arready;
  logic [BusWidth - 1:0] araddr;
  /* verilator lint_off UNUSEDSIGNAL */
  axil_prot_t            arprot;
  /* verilator lint_on UNUSEDSIGNAL */

  logic                  rvalid;
  logic                  rready;
  logic [BusWidth - 1:0] rdata;
  /* verilator lint_off UNUSEDSIGNAL */
  axil_resp_e            rresp;
  /* verilator lint_on UNUSEDSIGNAL */

  modport m (
    input
      awready,
      wready,
      bvalid, bresp,
      arready,
      rvalid, rdata, rresp,
    output
      awvalid, awaddr, awprot,
      wvalid, wdata, wstrb,
      bready,
      arvalid, araddr, arprot,
      rready
  );

  modport s (
    input
      awvalid, awaddr, awprot,
      wvalid, wdata, wstrb,
      bready,
      arvalid, araddr, arprot,
      rready,
    output
      awready,
      wready,
      bvalid, bresp,
      arready,
      rvalid, rdata, rresp
  );
endinterface

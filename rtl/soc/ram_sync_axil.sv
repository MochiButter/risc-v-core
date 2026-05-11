`ifndef BINPATH
  `define BINPATH ""
`endif

module ram_sync_axil
  import axil_pkg::*;
  #(parameter BusWidth = 64
  ,localparam MaskBits = BusWidth / 8
  ,parameter AddrWidth = 8
  ,parameter bit DualPort = 1'b0
  ,parameter UseInitFile = 0
  ,parameter InitFile = {`BINPATH, "soc/arithmetic.hex"}
  )
  (input  logic clk_i
  ,input  logic rst_ni
  `S_AXIL_IO
  );

  localparam ShiftBits = $clog2(MaskBits);
  localparam AddrWidthWord = AddrWidth - ShiftBits;

  logic [BusWidth - 1:0] saved_wdata;
  logic [AddrWidthWord - 1:0] mem_addr_w, mem_addr_r, saved_addr_w, saved_addr_r;
  logic [MaskBits - 1:0] saved_wmask;
  logic skid_addr_w_valid, skid_addr_w_ready,
    skid_wdata_valid, skid_wdata_ready,
    skid_addr_r_valid, skid_addr_r_ready,
    saved_addr_w_valid, saved_wdata_valid, saved_addr_r_valid,
    wr_en, rd_en, bvalid_d, rvalid_d;

  assign mem_addr_w = s_axil_awaddr[AddrWidthWord + ShiftBits - 1:ShiftBits];
  assign mem_addr_r = s_axil_araddr[AddrWidthWord + ShiftBits - 1:ShiftBits];

  assign wr_en = saved_addr_w_valid && saved_wdata_valid &&
    (!s_axil_bvalid || s_axil_bready);
  assign rd_en = saved_addr_r_valid && (!s_axil_rvalid || s_axil_rready);

  assign s_axil_bresp = axil_pkg::OKAY;
  assign s_axil_rresp = axil_pkg::OKAY;

  assign bvalid_d = wr_en ? 1'b1 :
                    s_axil_bready ? 1'b0 :
                    s_axil_bvalid;
  assign rvalid_d = rd_en ? 1'b1 :
                    s_axil_rready ? 1'b0 :
                    s_axil_rvalid;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      s_axil_bvalid <= 1'b0;
      s_axil_rvalid <= 1'b0;
    end else begin
      s_axil_bvalid <= bvalid_d;
      s_axil_rvalid <= rvalid_d;
    end
  end

  skid_buffer #(
    .Width(AddrWidthWord)
  ) save_waddr (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .wr_valid_i (skid_addr_w_valid),
    .wr_data_i  (mem_addr_w),
    .wr_ready_o (skid_addr_w_ready),
    .rd_ready_i (wr_en),
    .rd_data_o  (saved_addr_w),
    .rd_valid_o (saved_addr_w_valid)
  );

  skid_buffer #(
    .Width(BusWidth + MaskBits)
  ) save_wdata (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .wr_valid_i (skid_wdata_valid),
    .wr_data_i  ({s_axil_wdata, s_axil_wstrb}),
    .wr_ready_o (skid_wdata_ready),
    .rd_ready_i (wr_en),
    .rd_data_o  ({saved_wdata, saved_wmask}),
    .rd_valid_o (saved_wdata_valid)
  );

  skid_buffer #(
    .Width(AddrWidthWord)
  ) save_raddr (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .wr_valid_i (skid_addr_r_valid),
    .wr_data_i  (mem_addr_r),
    .wr_ready_o (skid_addr_r_ready),
    .rd_ready_i (rd_en),
    .rd_data_o  (saved_addr_r),
    .rd_valid_o (saved_addr_r_valid)
  );

  if (DualPort) begin : l_dualport
    /* The standard configuration where both writes and reads can happen
     * simultaneously. Acts the same as a normal axi lite register
     */
    assign skid_addr_w_valid = s_axil_awvalid;
    assign skid_wdata_valid = s_axil_wvalid;
    assign skid_addr_r_valid = s_axil_arvalid;
    assign s_axil_awready = skid_addr_w_ready;
    assign s_axil_wready  = skid_wdata_ready;
    assign s_axil_arready = skid_addr_r_ready;

    ram_1r1w_sync #(
      .DataWidth   (BusWidth),
      .AddrWidth   (AddrWidthWord),
      .UseMask     (1),
      .UseInitFile (UseInitFile),
      .InitFile    (InitFile)
    ) u_mem (
      .clk_i      (clk_i),
      .w_en_i     (wr_en),
      .waddr_i    (saved_addr_w),
      .wdata_i    (saved_wdata),
      .wmask_i    (saved_wmask),
      .r_en_i     (rd_en),
      .raddr_i    (saved_addr_r),
      .rdata_o    (s_axil_rdata)
    );
  end else begin : l_singleport
    /* A version that uses a single-port memory instead
     * When both a write and a read are present, favors the read request over
     * the write request. Also, it will only accept a write request when both
     * the addr and data are valid.
     */
    logic [AddrWidthWord - 1:0] mem_addr;
    logic req_is_write, write_ready;

    assign write_ready = skid_addr_w_ready && skid_wdata_ready && req_is_write;
    assign req_is_write = !s_axil_arvalid && s_axil_awvalid && s_axil_wvalid;
    assign mem_addr = req_is_write ? saved_addr_w : saved_addr_r;

    assign skid_addr_w_valid = req_is_write;
    assign skid_wdata_valid  = req_is_write;
    assign skid_addr_r_valid = s_axil_arvalid;
    assign s_axil_awready = write_ready;
    assign s_axil_wready  = write_ready;
    assign s_axil_arready = skid_addr_r_ready;

    ram_1rw_sync #(
      .DataWidth   (BusWidth),
      .AddrWidth   (AddrWidthWord),
      .UseInitFile (UseInitFile),
      .InitFile    (InitFile)
    ) u_mem (
      .clk_i      (clk_i),
      .valid_i    (wr_en || rd_en),
      .wr_en_i    (wr_en),
      .addr_i     (mem_addr),
      .wdata_i    (saved_wdata),
      .wmask_i    (saved_wmask),
      .rdata_o    (s_axil_rdata)
    );
  end

  logic [BusWidth - AddrWidthWord - 1:0] __unused_waddr, __unused_raddr;
  assign __unused_waddr =
    {s_axil_awaddr[BusWidth - 1:AddrWidthWord + ShiftBits],
    s_axil_awaddr[ShiftBits - 1:0]};
  assign __unused_raddr =
    {s_axil_araddr[BusWidth - 1:AddrWidthWord + ShiftBits],
    s_axil_araddr[ShiftBits - 1:0]};

`ifdef FORMAL
  `define IS_S_AXIL

  `ifdef IS_M_AXIL
    `define M_AXIL_CHECK assert
    `define S_AXIL_CHECK assume
  `elsif IS_S_AXIL
    `define M_AXIL_CHECK assume
    `define S_AXIL_CHECK assert
  `else
    `define M_AXIL_CHECK assert
    `define S_AXIL_CHECK assert
  `endif

  // require a reset at the beginning
  always_comb assume (rst_ni == !$initstate);

  // the valid signals must not go high until one clock after a reset
  // Can't use past on the 0th cycle
  always_ff @(posedge clk_i) begin
    if ($rose(rst_ni)) begin
      `M_AXIL_CHECK (!s_axil_awvalid);
      `M_AXIL_CHECK (!s_axil_wvalid);
      `M_AXIL_CHECK (!s_axil_arvalid);

      `S_AXIL_CHECK (!s_axil_bvalid);
      `S_AXIL_CHECK (!s_axil_rvalid);
    end
  end

  // The initial value without a reset is not known so it is excluded from the
  // assertions
  // valid signals must not go low until a handshake
  // valid data must not change until a handshake
  always_ff @(posedge clk) begin
    if (!$initstate && $past(rst_ni)) begin
      if ($past(s_axil_awvalid && !s_axil_awready)) begin
        `M_AXIL_CHECK (s_axil_awvalid);
        `M_AXIL_CHECK ($stable(s_axil_awaddr));
        `M_AXIL_CHECK ($stable(s_axil_awprot));
      end
      if ($past(s_axil_wvalid && !s_axil_wready)) begin
        `M_AXIL_CHECK (s_axil_wvalid);
        `M_AXIL_CHECK ($stable(s_axil_wdata));
        `M_AXIL_CHECK ($stable(s_axil_wstrb));
      end
      if ($past(s_axil_arvalid && !s_axil_arready)) begin
        `M_AXIL_CHECK (s_axil_arvalid);
        `M_AXIL_CHECK ($stable(s_axil_araddr));
        `M_AXIL_CHECK ($stable(s_axil_arprot));
      end
      if ($past(s_axil_rvalid && !s_axil_rready)) begin
        `S_AXIL_CHECK (s_axil_rvalid);
        `S_AXIL_CHECK ($stable(s_axil_rdata));
        `S_AXIL_CHECK ($stable(s_axil_rresp));
      end
      if ($past(s_axil_bvalid && !s_axil_bready)) begin
        `S_AXIL_CHECK (s_axil_bvalid);
        `S_AXIL_CHECK ($stable(s_axil_bresp));
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_ni) begin
      cover (s_axil_awready && s_axil_awvalid);
      cover (s_axil_wready && s_axil_wvalid);
      cover (s_axil_arready && s_axil_arvalid);
      cover (s_axil_bready && s_axil_bvalid);
      cover (s_axil_rready && s_axil_rvalid);
    end
  end

`endif
endmodule

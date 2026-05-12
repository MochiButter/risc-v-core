module axil_interconnect
  import axil_pkg::*;
  #(parameter BusWidth = 64
  ,localparam MaskBits = BusWidth / 8
  ,parameter NumS = 1
  ,localparam IdWidth = $clog2(NumS))
  (input  logic clk_i
  ,input  logic rst_ni

  `S_AXIL_IO

  ,output logic                  m_axil_awvalid [0:NumS - 1]
  ,input  logic                  m_axil_awready [0:NumS - 1]
  ,output logic [BusWidth - 1:0] m_axil_awaddr  [0:NumS - 1]
  ,output logic                  m_axil_wvalid  [0:NumS - 1]
  ,input  logic                  m_axil_wready  [0:NumS - 1]
  ,output logic [BusWidth - 1:0] m_axil_wdata   [0:NumS - 1]
  ,output logic [MaskBits - 1:0] m_axil_wstrb   [0:NumS - 1]
  ,input  logic                  m_axil_bvalid  [0:NumS - 1]
  ,output logic                  m_axil_bready  [0:NumS - 1]
  ,output logic                  m_axil_arvalid [0:NumS - 1]
  ,input  logic                  m_axil_arready [0:NumS - 1]
  ,output logic [BusWidth - 1:0] m_axil_araddr  [0:NumS - 1]
  ,input  logic                  m_axil_rvalid  [0:NumS - 1]
  ,output logic                  m_axil_rready  [0:NumS - 1]
  ,input  logic [BusWidth - 1:0] m_axil_rdata   [0:NumS - 1]
  /* verilator lint_off UNUSEDSIGNAL */
  ,output axil_prot_t            m_axil_awprot  [0:NumS - 1]
  ,input  axil_resp_e            m_axil_bresp   [0:NumS - 1]
  ,output axil_prot_t            m_axil_arprot  [0:NumS - 1]
  ,input  axil_resp_e            m_axil_rresp   [0:NumS - 1]
  /* verilator lint_on UNUSEDSIGNAL */
  );

  /* write signals */
  logic [BusWidth - 1:0] wr_req_addr, wr_req_data;
  logic [MaskBits - 1:0] wr_req_strb;
  logic [IdWidth - 1:0] wr_req_id, wr_resp_id;
  axil_resp_e sel_bresp;
  logic aw_req_valid, w_req_valid, wr_req_ready,
    wr_can_req, wr_is_requesting, sel_bvalid, sel_bready,
    wr_req_ack, wr_resp_ack;

  assign wr_req_ready = wr_can_req &&
    m_axil_awready[wr_req_id] && m_axil_wready[wr_req_id];
  assign wr_req_ack = aw_req_valid && w_req_valid && wr_req_ready;
  assign wr_resp_ack = sel_bvalid && sel_bready;

  always_comb begin
    sel_bresp = axil_pkg::OKAY;
    sel_bvalid = 1'b0;
    if (wr_is_requesting) begin
      sel_bresp = m_axil_bresp[wr_resp_id];
      sel_bvalid = m_axil_bvalid[wr_resp_id];
    end
  end

  skid_buffer #(
    .Width(BusWidth)
  ) aw_incoming (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .wr_valid_i (s_axil_awvalid),
    .wr_data_i  (s_axil_awaddr),
    .wr_ready_o (s_axil_awready),
    .rd_ready_i (wr_req_ready),
    .rd_data_o  (wr_req_addr),
    .rd_valid_o (aw_req_valid)
  );

  skid_buffer #(
    .Width(BusWidth + MaskBits)
  ) w_incoming (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .wr_valid_i (s_axil_wvalid),
    .wr_data_i  ({s_axil_wdata, s_axil_wstrb}),
    .wr_ready_o (s_axil_wready),
    .rd_ready_i (wr_req_ready),
    .rd_data_o  ({wr_req_data, wr_req_strb}),
    .rd_valid_o (w_req_valid)
  );

  addr_decode #(
    .BusWidth (BusWidth),
    .NumS     (NumS)
  ) wr_addr_dec (
    .addr_i       (wr_req_addr),
    .decerr_o     (),
    .request_id_o (wr_req_id)
  );

  pipeline_reg #(
    .Width(IdWidth)
  ) wr_req_buf (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .wr_valid_i (wr_req_ack),
    .wr_data_i  (wr_req_id),
    .wr_ready_o (wr_can_req),
    .rd_ready_i (wr_resp_ack),
    .rd_data_o  (wr_resp_id),
    .rd_valid_o (wr_is_requesting)
  );

  skid_buffer #(
    .Width($bits(axil_resp_e))
  ) wr_return (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .wr_valid_i (sel_bvalid),
    .wr_data_i  (sel_bresp),
    .wr_ready_o (sel_bready),
    .rd_ready_i (s_axil_bready),
    .rd_data_o  (s_axil_bresp),
    .rd_valid_o (s_axil_bvalid)
  );

  /* read signals */
  logic [BusWidth - 1:0] rd_req_addr, sel_rdata;
  logic [IdWidth - 1:0] rd_req_id, rd_resp_id;
  axil_resp_e sel_rresp;
  logic rd_req_ready, rd_req_valid, rd_can_req, rd_is_requesting,
    sel_rvalid, sel_rready, rd_req_ack, rd_resp_ack;

  assign rd_req_ready = rd_can_req && m_axil_arready[rd_req_id];
  assign rd_req_ack = rd_req_ready && rd_req_valid;
  assign rd_resp_ack = sel_rvalid && sel_rready;

  always_comb begin
    sel_rdata = '0;
    sel_rresp = axil_pkg::OKAY;
    sel_rvalid = 1'b0;
    if (rd_is_requesting) begin
      sel_rdata = m_axil_rdata[rd_resp_id];
      sel_rresp = m_axil_rresp[rd_resp_id];
      sel_rvalid = m_axil_rvalid[rd_resp_id];
    end
  end

  skid_buffer #(
    .Width(BusWidth)
  ) rd_incoming (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .wr_valid_i (s_axil_arvalid),
    .wr_data_i  (s_axil_araddr),
    .wr_ready_o (s_axil_arready),
    .rd_ready_i (rd_req_ready),
    .rd_data_o  (rd_req_addr),
    .rd_valid_o (rd_req_valid)
  );

  addr_decode #(
    .BusWidth (BusWidth),
    .NumS     (NumS)
  ) rd_addr_dec (
    .addr_i       (rd_req_addr),
    .decerr_o     (),
    .request_id_o (rd_req_id)
  );

  pipeline_reg #(
    .Width(IdWidth)
  ) rd_req_buf (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .wr_valid_i (rd_req_ack),
    .wr_data_i  (rd_req_id),
    .wr_ready_o (rd_can_req),
    .rd_ready_i (rd_resp_ack),
    .rd_data_o  (rd_resp_id),
    .rd_valid_o (rd_is_requesting)
  );

  skid_buffer #(
    .Width(BusWidth + $bits(axil_resp_e))
  ) rd_return (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .wr_valid_i (sel_rvalid),
    .wr_data_i  ({sel_rdata, sel_rresp}),
    .wr_ready_o (sel_rready),
    .rd_ready_i (s_axil_rready),
    .rd_data_o  ({s_axil_rdata, s_axil_rresp}),
    .rd_valid_o (s_axil_rvalid)
  );

  always_comb begin
    for (int i = 0; i < NumS; i ++) begin
      m_axil_awvalid[i] = 1'b0;
      m_axil_awaddr[i]  = '0;
      m_axil_wvalid[i]  = 1'b0;
      m_axil_wdata[i]   = '0;
      m_axil_wstrb[i]   = '0;
      m_axil_bready[i]  = 1'b0;
      m_axil_arvalid[i] = 1'b0;
      m_axil_araddr[i]  = '0;
      m_axil_rready[i]  = 1'b0;

      m_axil_awprot[i] = '0;
      m_axil_arprot[i] = '0;

      if (wr_can_req && aw_req_valid && w_req_valid && wr_req_id == IdWidth'(i)) begin
        m_axil_awvalid[i] = 1'b1;
        m_axil_awaddr[i]  = wr_req_addr;
        m_axil_wvalid[i]  = 1'b1;
        m_axil_wdata[i]   = wr_req_data;
        m_axil_wstrb[i]   = wr_req_strb;
      end
      if (wr_is_requesting && sel_bvalid && wr_resp_id == IdWidth'(i)) begin
        m_axil_bready[i] = 1'b1;
      end
      if (rd_can_req && rd_req_valid && rd_req_id == IdWidth'(i)) begin
        m_axil_arvalid[i] = 1'b1;
        m_axil_araddr[i]  = rd_req_addr;
      end
      if (rd_is_requesting && sel_rvalid && rd_resp_id == IdWidth'(i)) begin
        m_axil_rready[i] = 1'b1;
      end
    end
  end
endmodule

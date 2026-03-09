package axil_pkg;
  typedef enum logic [1:0] {
    OKAY   = 2'b00,
    EXOKAY = 2'b01,
    SLVERR = 2'b10,
    DECERR = 2'b11
  } axil_resp_e;

  typedef struct packed {
    logic privilege;
    logic secure;
    logic instruction;
  } axil_prot_t;

`ifndef AXIL_LOGIC
  `define AXIL_LOGIC(prefix) \
    logic                  ``prefix``_awvalid;  \
    logic                  ``prefix``_awready;  \
    logic [BusWidth - 1:0] ``prefix``_awaddr;   \
    logic                  ``prefix``_wvalid;   \
    logic                  ``prefix``_wready;   \
    logic [BusWidth - 1:0] ``prefix``_wdata;    \
    logic [MaskBits - 1:0] ``prefix``_wstrb;    \
    logic                  ``prefix``_bvalid;   \
    logic                  ``prefix``_bready;   \
    logic                  ``prefix``_arvalid;  \
    logic                  ``prefix``_arready;  \
    logic [BusWidth - 1:0] ``prefix``_araddr;   \
    logic                  ``prefix``_rvalid;   \
    logic                  ``prefix``_rready;   \
    logic [BusWidth - 1:0] ``prefix``_rdata;    \
    /* verilator lint_off UNUSEDSIGNAL */     \
    axil_prot_t            ``prefix``_awprot;   \
    axil_resp_e            ``prefix``_bresp;    \
    axil_prot_t            ``prefix``_arprot;   \
    axil_resp_e            ``prefix``_rresp;    \
    /* verilator lint_on UNUSEDSIGNAL */
`endif

`ifndef S_AXIL_IO
  `define S_AXIL_IO \
    ,input  logic                  s_axil_awvalid   \
    ,output logic                  s_axil_awready   \
    ,input  logic [BusWidth - 1:0] s_axil_awaddr    \
    ,input  logic                  s_axil_wvalid    \
    ,output logic                  s_axil_wready    \
    ,input  logic [BusWidth - 1:0] s_axil_wdata     \
    ,input  logic [MaskBits - 1:0] s_axil_wstrb     \
    ,output logic                  s_axil_bvalid    \
    ,input  logic                  s_axil_bready    \
    ,input  logic                  s_axil_arvalid   \
    ,output logic                  s_axil_arready   \
    ,input  logic [BusWidth - 1:0] s_axil_araddr    \
    ,output logic                  s_axil_rvalid    \
    ,input  logic                  s_axil_rready    \
    ,output logic [BusWidth - 1:0] s_axil_rdata     \
    /* verilator lint_off UNUSEDSIGNAL */           \
    ,input  axil_prot_t            s_axil_awprot    \
    ,output axil_resp_e            s_axil_bresp     \
    ,input  axil_prot_t            s_axil_arprot    \
    ,output axil_resp_e            s_axil_rresp     \
    /* verilator lint_on UNUSEDSIGNAL */
`endif

`ifndef M_AXIL_IO
  `define M_AXIL_IO \
    ,output logic                  m_axil_awvalid   \
    ,input  logic                  m_axil_awready   \
    ,output logic [BusWidth - 1:0] m_axil_awaddr    \
    ,output logic                  m_axil_wvalid    \
    ,input  logic                  m_axil_wready    \
    ,output logic [BusWidth - 1:0] m_axil_wdata     \
    ,output logic [MaskBits - 1:0] m_axil_wstrb     \
    ,input  logic                  m_axil_bvalid    \
    ,output logic                  m_axil_bready    \
    ,output logic                  m_axil_arvalid   \
    ,input  logic                  m_axil_arready   \
    ,output logic [BusWidth - 1:0] m_axil_araddr    \
    ,input  logic                  m_axil_rvalid    \
    ,output logic                  m_axil_rready    \
    ,input  logic [BusWidth - 1:0] m_axil_rdata     \
    /* verilator lint_off UNUSEDSIGNAL */           \
    ,output axil_prot_t            m_axil_awprot    \
    ,input  axil_resp_e            m_axil_bresp     \
    ,output axil_prot_t            m_axil_arprot    \
    ,input  axil_resp_e            m_axil_rresp     \
    /* verilator lint_on UNUSEDSIGNAL */
`endif

`ifndef S_AXIL_CONN
  `define S_AXIL_CONN(prefix) \
    .s_axil_awvalid (``prefix``_awvalid), \
    .s_axil_awready (``prefix``_awready), \
    .s_axil_awaddr  (``prefix``_awaddr ), \
    .s_axil_awprot  (``prefix``_awprot ), \
    .s_axil_wvalid  (``prefix``_wvalid ), \
    .s_axil_wready  (``prefix``_wready ), \
    .s_axil_wdata   (``prefix``_wdata  ), \
    .s_axil_wstrb   (``prefix``_wstrb  ), \
    .s_axil_bvalid  (``prefix``_bvalid ), \
    .s_axil_bready  (``prefix``_bready ), \
    .s_axil_bresp   (``prefix``_bresp  ), \
    .s_axil_arvalid (``prefix``_arvalid), \
    .s_axil_arready (``prefix``_arready), \
    .s_axil_araddr  (``prefix``_araddr ), \
    .s_axil_arprot  (``prefix``_arprot ), \
    .s_axil_rvalid  (``prefix``_rvalid ), \
    .s_axil_rready  (``prefix``_rready ), \
    .s_axil_rdata   (``prefix``_rdata  ), \
    .s_axil_rresp   (``prefix``_rresp  )
`endif

`ifndef M_AXIL_CONN
  `define M_AXIL_CONN(prefix) \
    .m_axil_awvalid (``prefix``_awvalid), \
    .m_axil_awready (``prefix``_awready), \
    .m_axil_awaddr  (``prefix``_awaddr ), \
    .m_axil_awprot  (``prefix``_awprot ), \
    .m_axil_wvalid  (``prefix``_wvalid ), \
    .m_axil_wready  (``prefix``_wready ), \
    .m_axil_wdata   (``prefix``_wdata  ), \
    .m_axil_wstrb   (``prefix``_wstrb  ), \
    .m_axil_bvalid  (``prefix``_bvalid ), \
    .m_axil_bready  (``prefix``_bready ), \
    .m_axil_bresp   (``prefix``_bresp  ), \
    .m_axil_arvalid (``prefix``_arvalid), \
    .m_axil_arready (``prefix``_arready), \
    .m_axil_araddr  (``prefix``_araddr ), \
    .m_axil_arprot  (``prefix``_arprot ), \
    .m_axil_rvalid  (``prefix``_rvalid ), \
    .m_axil_rready  (``prefix``_rready ), \
    .m_axil_rdata   (``prefix``_rdata  ), \
    .m_axil_rresp   (``prefix``_rresp  )
`endif
endpackage

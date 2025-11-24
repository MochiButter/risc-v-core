module csr import core_pkg::*;
  #(parameter logic [Xlen - 1:0] MHartId = 0)
  (input  logic clk_i
  ,input  logic rst_i

  ,input  logic valid_i
  ,input  csr_op_e csr_op_i

  ,input  logic [Xlen - 1:0] rs1_data_i
  ,input  logic [11:0] csr_addr_i
  ,output logic [Xlen - 1:0] rd_data_o

  ,input  logic [Xlen - 1:0] pc_i
  ,output logic raise_trap_o
  ,output logic [Xlen - 1:0] trap_vector_o
  );

  typedef enum logic [11:0] {
    CSRmhartid   = 12'hf14,
    CSRmstatus   = 12'h300,
    CSRmisa      = 12'h301,
    CSRmie       = 12'h304,
    CSRmtvec     = 12'h305,
    CSRmstatush  = 12'h310,
    CSRmscratch  = 12'h340,
    CSRmepc      = 12'h341,
    CSRmcause    = 12'h342,
    CSRmtval     = 12'h343,
    CSRmip       = 12'h344
  } csr_addrs_e;

  typedef enum logic [30:0] {
    SSoftInt  = 1,
    MSoftInt  = 3,
    STimerInt = 5,
    MTimerInt = 7,
    SExtInt   = 9,
    MExtInt   = 11,
    CntOfInt  = 13
  } csr_mcause_int_e;

  typedef enum logic [30:0] {
    InstAddrMisa = 0,
    InstAccFlt   = 1,
    IllegalInst  = 2,
    Breakpoint   = 3,
    LdAddrMisa   = 4,
    LdAccFlt     = 5,
    StAddrMisa   = 6,
    StAccFlt     = 7,
    EcallU       = 8,
    EcallS       = 9,
    EcallM       = 10,
    InstPageFlt  = 11,
    LdPageFlt    = 12,
    StPageFlt    = 15,
    DblTrap      = 16,
    SWCheck      = 18,
    HWError      = 19
  } csr_mcause_e;

  logic [Xlen - 1:0] csr_wdata;

  logic [Xlen - 1:0] mtvec_d, mtvec_q;
  // FIXME Only supports direct mode
  logic [Xlen - 1:0] mtvec_mask;
  assign mtvec_mask = {csr_wdata[Xlen - 1:2], 2'b00};

  logic [Xlen - 1:0] mscratch_d, mscratch_q;

  logic [Xlen - 1:0] mepc_d, mepc_q;
  logic [Xlen - 1:0] mepc_mask;
  localparam PcClearBits = 1;
  assign mepc_mask = pc_i & {{Xlen - PcClearBits{1'b1}}, '0};

  logic csr_wsc, csr_ecall, csr_ebreak, csr_mret;
  assign csr_wsc = csr_op_i == OpCSRRW ||
    csr_op_i == OpCSRRS || csr_op_i == OpCSRRC;
  assign csr_ecall = csr_op_i == OpEcall;
  assign csr_ebreak = csr_op_i == OpEbreak;
  assign csr_mret = csr_op_i == OpMret;

  logic [Xlen - 1:0] mcause_d, mcause_q;
  logic [Xlen - 1:0] mcause_tmp;
  localparam McausePadding = Xlen - 32;
  always_comb begin
    if (csr_ecall) begin
      mcause_tmp = {1'b1, {McausePadding{1'b0}}, MExtInt};
    end else if (csr_ebreak) begin
      mcause_tmp = {1'b0, {McausePadding{1'b0}}, Breakpoint};
    end else begin
      mcause_tmp = '0;
    end
  end

  logic raise_expt;
  assign raise_expt = valid_i && (csr_ecall || csr_ebreak);
  assign raise_trap_o = raise_expt || (valid_i && csr_mret);
  assign trap_vector_o = raise_expt ? mtvec_q : mepc_q;

  always_comb begin
    case (csr_addr_i)
      CSRmhartid:  rd_data_o = MHartId;
      CSRmtvec:    rd_data_o = mtvec_q;
      CSRmscratch: rd_data_o = mscratch_q;
      CSRmepc:     rd_data_o = mepc_q;
      CSRmcause:   rd_data_o = mcause_q;
      // unimplemented csrs shouls read 0
      // for forwards compatibility
      default: rd_data_o = '0;
    endcase
    case (csr_op_i)
      OpCSRRW: csr_wdata = rs1_data_i;
      OpCSRRS: csr_wdata = rs1_data_i | rd_data_o;
      OpCSRRC: csr_wdata = ~rs1_data_i & rd_data_o;
      default: csr_wdata = 'x;
    endcase
    mtvec_d = mtvec_q;
    mscratch_d = mscratch_q;
    mepc_d = mepc_q;
    mcause_d = mcause_q;
    if (valid_i && raise_expt && raise_trap_o) begin
      mepc_d = mepc_mask;
      mcause_d = mcause_tmp;
    end else if (valid_i && csr_wsc) begin
      case (csr_addr_i)
        CSRmtvec:    mtvec_d = mtvec_mask;
        CSRmscratch: mscratch_d = csr_wdata;
        CSRmepc:     mepc_d = csr_wdata;
        CSRmcause:   mcause_d = csr_wdata;
        default: ;
      endcase
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      mtvec_q <= '0;
      mscratch_q <= '0;
      mepc_q <= '0;
      mcause_q <= '0;
    end else begin
      mtvec_q <= mtvec_d;
      mscratch_q <= mscratch_d;
      mepc_q <= mepc_d;
      mcause_q <= mcause_d;
    end
  end
endmodule

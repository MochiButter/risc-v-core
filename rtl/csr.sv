module csr
  import core_pkg::*;
  import csr_pkg::*;
  #(parameter logic [Xlen - 1:0] MHartId = 0)
  (input  logic clk_i
  ,input  logic rst_ni

  ,input  logic              valid_i
  ,input  csr_op_e           csr_op_i

  ,input  logic              expt_valid_i
  ,input  csr_mcause_e       expt_cause_i
  ,input  logic [Xlen - 1:0] expt_value_i

  ,input  logic [Xlen - 1:0] rs1_data_i
  ,input  logic [11:0]       csr_addr_i
  ,output logic [Xlen - 1:0] rd_data_o

  ,input  logic [Xlen - 1:0] pc_i
  ,output logic              raise_trap_o
  ,output logic [Xlen - 1:0] trap_vector_o
  );

  localparam logic [Xlen - 1:0] Misa =
    (Xlen'(1) << 8) |         // I - RV32I/64I base ISA
    (Xlen'(2) << (Xlen - 2)); // MXLEN - 2 for 64 bits

  logic [Xlen - 1:0] csr_wdata;

  logic [Xlen - 1:0] mtvec_d, mtvec_q;
  // FIXME Only supports direct mode
  logic [Xlen - 1:0] mtvec_mask;
  assign mtvec_mask = {csr_wdata[Xlen - 1:2], 2'b00};

  logic [Xlen - 1:0] mscratch_d, mscratch_q;

  logic [Xlen - 1:0] mepc_d, mepc_q;
  localparam PcClearBits = Ilen / 16;
  localparam logic [Xlen - 1:0] MepcMask =
    {{Xlen - PcClearBits{1'b1}}, PcClearBits'(0)};

  logic [Xlen - 1:0] mcause_d, mcause_q;
  logic [Xlen - 1:0] mtval_d, mtval_q;

  logic csr_wsc, csr_mret;
  assign csr_wsc = csr_op_i == OpCSRRW ||
    csr_op_i == OpCSRRS || csr_op_i == OpCSRRC;
  assign csr_mret = csr_op_i == OpMret;

  logic raise_expt;
  assign raise_expt = valid_i && expt_valid_i;
  assign raise_trap_o = raise_expt || (valid_i && csr_mret);
  assign trap_vector_o = raise_expt ? mtvec_q : mepc_q;

  always_comb begin
    case (csr_addr_i)
      CSRmhartid:  rd_data_o = MHartId;
      CSRmisa:     rd_data_o = Misa;
      CSRmtvec:    rd_data_o = mtvec_q;
      CSRmscratch: rd_data_o = mscratch_q;
      CSRmepc:     rd_data_o = mepc_q;
      CSRmcause:   rd_data_o = mcause_q;
      CSRmtval:    rd_data_o = mtval_q;
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
    mtval_d = mtval_q;
    if (valid_i && raise_expt) begin
      mepc_d   = pc_i;
      mcause_d = expt_cause_i;
      mtval_d  = expt_value_i;
    end else if (valid_i && csr_wsc) begin
      case (csr_addr_i)
        CSRmtvec:    mtvec_d    = mtvec_mask;
        CSRmscratch: mscratch_d = csr_wdata;
        CSRmepc:     mepc_d     = csr_wdata & MepcMask;
        CSRmcause:   mcause_d   = csr_wdata;
        CSRmtval:    mtval_d    = csr_wdata;
        default: ;
      endcase
    end
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      mtvec_q    <= '0;
      mscratch_q <= '0;
      mepc_q     <= '0;
      mcause_q   <= '0;
      mtval_q    <= '0;
    end else begin
      mtvec_q    <= mtvec_d;
      mscratch_q <= mscratch_d;
      mepc_q     <= mepc_d;
      mcause_q   <= mcause_d;
      mtval_q    <= mtval_d;
    end
  end
endmodule

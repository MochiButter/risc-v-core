module aclint
  import core_pkg::*;
  (input  logic clk_i
  ,input  logic rst_ni

  ,input  logic                  valid_i
  ,input  logic [12:0]           addr_i
  ,input  logic                  wr_en_i
  ,input  logic [Xlen - 1:0]     wdata_i
  ,input  logic [MaskBits - 1:0] wstrb_i
  ,output logic [Xlen - 1:0]     rdata_o
  ,output logic                  error_o

  ,output logic                  msip_o
  ,output logic                  mtip_o
  ,output logic [Xlen - 1:0]     mtime_o
  );
  /* ACLINT register map
   * 0x0000 - 0x3fff    MSWI
   *    0x0000 - 0x3ffb MSIP
   *    0x3ffc - 0x3fff RESERVED
   * 0x4000 - 0xbfff    MTIMER
   *    0x4000 - 0xbff7 MTIMECMP
   *    0xbff8 - 0xbfff MTIME
   * 0xc000 - 0xffff    SSWI
   *    0xc000 - 0xfffb SETSSIP
   *    0xfffc - 0xffff RESERVED
   */

  logic [Xlen - 1:0] mtimecmp_d, mtimecmp_q, mtime_d, rdata_d, rdata, wmask, wdata;
  logic [15:0] addr_shift;
  logic msip_d;

  always_comb begin
    mtimecmp_d = mtimecmp_q;
    mtip_o = (mtime_o >= mtimecmp_q);
    msip_d = msip_o;
    mtime_d = mtime_o + 1;

    addr_shift = {addr_i, 3'h0};
    rdata = '0;
    rdata_d = rdata_o;
    error_o = 1'b0;

    for (int i = 0; i < MaskBits; i ++) begin
      wmask[8 * i+:8] = {8{wstrb_i[i]}};
    end
    wdata = (wmask & wdata_i) | (~wmask & rdata);

    if (valid_i) begin
      case (addr_shift)
        16'h0000: rdata = {63'h0, msip_o};
        16'h4000: rdata = mtimecmp_q;
        16'hbff8: rdata = mtime_o;
        // 16'hc000: ; S mode unimplemented
        default: error_o = 1'b1;
      endcase
      if (wr_en_i) begin
        case (addr_shift)
          16'h0000: msip_d     = wdata[0];
          16'h4000: mtimecmp_d = wdata;
          16'hbff8: mtime_d    = wdata;
          // 16'hc000: ; S mode unimplemented
          default: ;
        endcase
      end else begin
        rdata_d = rdata;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      mtime_o <= '0;
      // on reset, the mtimecmp registers are in an unknown state
      msip_o  <= '0;
      rdata_o <= '0;
    end else begin
      mtime_o    <= mtime_d;
      mtimecmp_q <= mtimecmp_d;
      msip_o     <= msip_d;
      rdata_o    <= rdata_d;
    end
  end
endmodule

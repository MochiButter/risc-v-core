package csr_pkg;

  typedef enum logic[11:0] {
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

  typedef enum logic [63:0] {
    SSoftInt  = {1'b1, 63'd1},
    MSoftInt  = {1'b1, 63'd3},
    STimerInt = {1'b1, 63'd5},
    MTimerInt = {1'b1, 63'd7},
    SExtInt   = {1'b1, 63'd9},
    MExtInt   = {1'b1, 63'd11},
    CntOfInt  = {1'b1, 63'd13},
    InstAddrMisaligned = 0,
    InstAccessFalut    = 1,
    IllegalInst        = 2,
    Breakpoint         = 3,
    LdAddrMisaligned   = 4,
    LdAccessFalut      = 5,
    StAddrMisaligned   = 6,
    StAccessFalut      = 7,
    EcallU             = 8,
    EcallS             = 9,
    EcallM             = 11,
    InstPageFalut      = 12,
    LdPageFalut        = 13,
    StPageFalut        = 15,
    DoubleTrap         = 16,
    SoftwareCheck      = 18,
    HardwareError      = 19
  } csr_mcause_e;

endpackage

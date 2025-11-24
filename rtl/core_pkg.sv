package core_pkg;
  parameter Xlen = 64;
  parameter Ilen = 32;

  localparam MaskBits = Xlen / 8;

  localparam logic [Xlen - 1:0] BootAddr = '0;

  typedef enum logic [1:0] {
    Add, Op32, Funct
  } aluop_e;

  typedef enum logic [1:0] {
    MemNone, MemLoad, MemStore
  } mem_type_e;

  typedef enum logic [2:0] {
    Rtype, Itype, Stype, Btype, Utype, Jtype, Fence
  } inst_type_e;

  typedef enum logic [1:0] {
    JmpNone, JmpBr, JmpJal, JmpJalr
  } jump_type_e;

  typedef enum logic [3:0] {
    OpCSRNone,
    OpCSRRW, OpCSRRdonly, OpCSRRS, OpCSRRC,
    OpEcall, OpEbreak,
    OpUret, OpSret, OpHret, OpMret, OpDret,
    OpSfence, OpWfi
  } csr_op_e;

  typedef enum logic [2:0] {
    WbNone, WbAlu, WbLsu, WbCsr, WbLui, WbJmp
  } reg_wb_src_e;
endpackage

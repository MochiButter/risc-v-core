package core_pkg;
  parameter Xlen = 64;
  parameter Ilen = 32;

  localparam MaskBits = Xlen / 8;

  typedef enum logic [1:0] {
    Add, Op32, Funct
  } aluop_e;

  typedef enum logic [1:0] {
    JmpNone, Jal, Jalr
  } jump_type_e;

  typedef enum logic [1:0] {
    MemNone, MemLoad, MemStore
  } memop_type_e;
endpackage

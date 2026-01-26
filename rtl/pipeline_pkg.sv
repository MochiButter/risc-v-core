package pipeline_pkg;
  import core_pkg::*;
  import csr_pkg::*;

  /* Icarus says */
  /* sorry: Unpacked structs not supported. */
  /* Not a big deal but that is the reason why these are packed */

  typedef struct packed {
    /* To Ex, Mem, Wb */
    logic [Xlen - 1:0] inst_pc;
    logic [Xlen - 1:0] inst_imm;

    /* To Ex, Mem */
    logic [4:0] rs1_addr, rs2_addr;

    /* To Ex */
    inst_type_e inst_type;
    alu_op_e alu_op;

    /* To Mem */
    mem_type_e mem_type;
    logic [2:0] funct3;

    csr_op_e csr_op;
    logic [11:0] csr_addr;
    logic csr_use_imm;
    logic expt_valid;
    csr_mcause_e expt_cause;
    logic [Xlen - 1:0] expt_value;

    jump_type_e jump_type;

    logic is_fencei;

    /* To Wb */
    reg_wb_src_e reg_wb_src;
    logic [4:0] rd_addr;
  } idex_reg_t;

  typedef struct packed {
    /* To Mem, Wb*/
    logic [Xlen - 1:0] inst_pc;
    logic [Xlen - 1:0] inst_imm;
    logic [Xlen - 1:0] alu_res;

    /* To Mem */
    logic [4:0] rs1_addr, rs2_addr;
    logic [Xlen - 1:0] rs1_data, rs2_data;

    mem_type_e mem_type;
    logic [2:0] funct3;

    csr_op_e csr_op;
    logic [11:0] csr_addr;
    logic csr_use_imm;
    logic expt_valid;
    csr_mcause_e expt_cause;
    logic [Xlen - 1:0] expt_value;

    jump_type_e jump_type;
    logic branch_take;

    logic is_fencei;

    /* To wb */
    reg_wb_src_e reg_wb_src;
    logic [4:0] rd_addr;
  } exmem_reg_t;

  typedef struct packed {
    reg_wb_src_e reg_wb_src;
    logic [Xlen - 1:0] load_data;
    logic [Xlen - 1:0] csr_rd_data;
    logic [Xlen - 1:0] inst_imm;
    logic [Xlen - 1:0] inst_pc;
    logic [Xlen - 1:0] alu_res;
    logic [4:0] rd_addr;
    logic raise_trap;
  } memwb_reg_t;
endpackage

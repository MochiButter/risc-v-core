class mem_model #(int AddrWidth, int DataWidth) extends uvm_object;

  localparam MaskBits = DataWidth / 8;
  localparam AddrShift = $clog2(MaskBits);

  logic [DataWidth - 1:0] mem [0:(1 <<  22) - 1];

  `uvm_object_param_utils(mem_model #(AddrWidth, DataWidth))
  `uvm_obj_new

  function void write (
    input bit [AddrWidth - 1:0] addr,
    input bit [DataWidth - 1:0] wdata,
    input bit [MaskBits - 1:0] wmask
  );
    bit [DataWidth - 1:0] wdata_tmp;
    wdata_tmp = mem[addr >> AddrShift];
    for (int i = 0; i < MaskBits; i ++) begin
      if (wmask[i]) begin
        wdata_tmp[(i * 8)+:8] = wdata[(i * 8)+:8];
      end
    end
    mem[addr >> AddrShift] = wdata_tmp;
  endfunction : write

  task load_program(input string path);
    $readmemh(path, mem);
  endtask : load_program

  function logic[DataWidth - 1:0] get_word_at(input logic[AddrWidth - 1:0] addr);
    return mem[addr >> AddrShift];
  endfunction : get_word_at

endclass : mem_model

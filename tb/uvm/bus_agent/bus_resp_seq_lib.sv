class bus_resp_seq_base extends uvm_sequence #(bus_seq_item);

  bus_seq_item item;
  logic [DataWidth - 1:0] mem [0:(1 <<  22) - 1];

  `uvm_object_utils(bus_resp_seq_base)
  `uvm_declare_p_sequencer(bus_resp_sequencer)
  `uvm_obj_new

  virtual task body();
    forever begin
      p_sequencer.from_mon_port.get(item);

      // req is part of the sequence class
      req = bus_seq_item::type_id::create("req");
      req.addr = item.addr;
      req.data = item.data;
      req.wmask = item.wmask;

      if (item.wmask == '0) begin
        req.data = mem[item.addr >> AddrShift];
      end else begin
        write(item.addr, item.data, item.wmask);
      end

      start_item(req);
      finish_item(req);
    end
  endtask : body

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
  endfunction

  task load_program(input string path);
    $readmemh(path, mem);
  endtask

  function logic[DataWidth - 1:0] get_word_at(input logic[AddrWidth - 1:0] addr);
    return mem[addr >> AddrShift];
  endfunction : get_word_at

endclass : bus_resp_seq_base

class bus_resp_seq_base extends uvm_sequence #(bus_seq_item);

  bus_seq_item item;
  logic [31:0] mem [0:255];

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

      if (item.wmask == 4'b0000) begin
        req.data = mem[item.addr >> 2];
      end else begin
        if (item.wmask[0]) mem[item.addr >> 2][7:0]   <= item.data[7:0];
        if (item.wmask[1]) mem[item.addr >> 2][15:8]  <= item.data[15:8];
        if (item.wmask[2]) mem[item.addr >> 2][23:16] <= item.data[23:16];
        if (item.wmask[3]) mem[item.addr >> 2][31:24] <= item.data[31:24];
      end

      start_item(req);
      finish_item(req);
    end
  endtask : body

  task load_program(input string path);
    $readmemh(path, mem);
  endtask

  function logic[31:0] get_word_at(input logic[31:0] addr);
    return mem[addr >> 2];
  endfunction
endclass : bus_resp_seq_base

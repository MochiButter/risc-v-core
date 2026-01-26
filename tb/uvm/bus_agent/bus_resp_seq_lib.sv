class bus_resp_seq_base #(int AddrWidth, int DataWidth) extends uvm_sequence #(bus_seq_item #(AddrWidth, DataWidth));

  bus_seq_item #(AddrWidth, DataWidth) item;
  mem_model #(AddrWidth, DataWidth) mem;

  `uvm_object_param_utils(bus_resp_seq_base#(AddrWidth, DataWidth))
  `uvm_declare_p_sequencer(bus_resp_sequencer #(AddrWidth, DataWidth))
  `uvm_obj_new

  virtual task body();
    if (mem == null) `uvm_fatal(get_full_name(), "Failed to get system memory")
    forever begin
      p_sequencer.from_mon_port.get(item);

      // req is part of the sequence class
      req = bus_seq_item #(AddrWidth, DataWidth)::type_id::create("req");
      req.addr = item.addr;
      req.data = item.data;
      req.wmask = item.wmask;

      if (item.wmask == '0) begin
        req.data = mem.get_word_at(item.addr);
      end else begin
        mem.write(item.addr, item.data, item.wmask);
      end

      start_item(req);
      finish_item(req);
    end
  endtask : body

endclass : bus_resp_seq_base

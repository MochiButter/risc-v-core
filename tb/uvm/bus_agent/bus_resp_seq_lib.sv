class bus_resp_seq_base extends uvm_sequence #(bus_seq_item);

  bus_seq_item item;
  logic [31:0] mem [0:255];

  `uvm_object_utils(bus_resp_seq_base)
  `uvm_declare_p_sequencer(bus_resp_sequencer)
  `uvm_obj_new

  /*
   * addi x1, x0, 0x42
   * addi x2, x0, 0x64
   * li x3, 0xdeadbeef
   * loop:
   * blt x2, x1, target
   * addi x1, x1, 0x10
   * jal x0, loop
   * target:
   * sw x3, 0x20(x0)
   * ebreak
   */
  virtual task body();
    mem[0] = 32'h04200093;
    mem[1] = 32'h06400113;
    mem[2] = 32'hDEADC1B7;
    mem[3] = 32'hEEF18193;
    mem[4] = 32'h00114663;
    mem[5] = 32'h01008093;
    mem[6] = 32'hFF9FF06F;
    mem[7] = 32'h02302023;
    mem[8] = 32'h00100073;

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

endclass : bus_resp_seq_base

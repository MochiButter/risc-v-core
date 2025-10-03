class bus_seq_item extends uvm_sequence_item;

  rand bit [AddrWidth - 1:0] addr;
  rand bit [DataWidth - 1:0] data;
  rand bit [(DataWidth / 8) - 1:0]  wmask;

  `uvm_object_utils_begin(bus_seq_item)
    `uvm_field_int(addr, UVM_DEFAULT)
    `uvm_field_int(data, UVM_DEFAULT)
    `uvm_field_int(wmask, UVM_DEFAULT)
  `uvm_object_utils_end

  `uvm_obj_new

endclass : bus_seq_item

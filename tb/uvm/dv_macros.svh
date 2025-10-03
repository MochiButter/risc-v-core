`ifndef uvm_obj_new
  `define uvm_obj_new \
    function new (string name = ""); \
      super.new(name); \
    endfunction : new
`endif

`ifndef uvm_comp_new
  `define uvm_comp_new \
    function new (string name = "", uvm_component parent = null); \
      super.new(name, parent); \
    endfunction : new
`endif

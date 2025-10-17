class core_env #(int AddrWidth, int DataWidth) extends uvm_env;

  bus_resp_agent #(AddrWidth, DataWidth) inst_if_resp_agent;
  bus_resp_agent #(AddrWidth, DataWidth) data_if_resp_agent;

  `uvm_component_param_utils(core_env #(AddrWidth, DataWidth))
  `uvm_comp_new

  function void build_phase (uvm_phase phase);
    inst_if_resp_agent = bus_resp_agent #(AddrWidth, DataWidth)::type_id::create("inst_if_resp_agent ", this);
    data_if_resp_agent = bus_resp_agent #(AddrWidth, DataWidth)::type_id::create("data_if_resp_agent ", this);
  endfunction : build_phase

endclass : core_env

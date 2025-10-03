class core_env extends uvm_env;

  bus_resp_agent inst_if_resp_agent;
  bus_resp_agent data_if_resp_agent;

  `uvm_component_utils(core_env)
  `uvm_comp_new

  function void build_phase (uvm_phase phase);
    inst_if_resp_agent = bus_resp_agent::type_id::create("inst_if_resp_agent ", this);
    data_if_resp_agent = bus_resp_agent::type_id::create("data_if_resp_agent ", this);
  endfunction : build_phase

endclass : core_env

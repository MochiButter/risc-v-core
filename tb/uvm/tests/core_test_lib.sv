class core_test_riscof extends core_base_test;

  string signature_path;

  `uvm_component_utils(core_test_riscof)
  `uvm_comp_new

  task run_phase (uvm_phase phase);
    if (!$value$plusargs("RISCOF_SIG_PATH=%s", signature_path)) begin
      `uvm_info(get_full_name(), "No signature path given, dumping to \"riscof.log\"", UVM_INFO)
      signature_path = "riscof.log";
    end

    // the test ends when the objection is dropped
    phase.raise_objection(this);
    init_mem();
    riscof_signature_dump();
    phase.drop_objection(this);
  endtask : run_phase

  task riscof_signature_dump();
    bus_seq_item item;
    bit [AddrWidth - 1:0] begin_signature, end_signature;
    // FIXME constant length mmio addr
    const bit [AddrWidth - 1:0] mmio_addr = 'h80000000;
    int fd;
    const int inc_amt = DataWidth / 8;
    forever begin
      watch_datamem_port.get(item);
      if (item.addr == mmio_addr && item.wmask != '0) begin
        begin_signature = item.data;
      end else if (item.addr == (mmio_addr + 8) && item.wmask != '0) begin
        end_signature = item.data;
      end else if (item.addr == (mmio_addr + 16) && item.wmask != '0) begin
        fd = $fopen(signature_path, "w");
        if (!fd) begin
          `uvm_warning(get_full_name(), "Failed to open signature file for writing")
        end else begin
          while (begin_signature < end_signature) begin
            $fdisplay(fd, $sformatf("%h", data_seq.get_word_at(begin_signature)));
            begin_signature += inc_amt;
          end
          $fclose(fd);
        end
        return;
      end
    end
  endtask : riscof_signature_dump

endclass : core_test_riscof

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
    bit [31:0] begin_signature, end_signature;
    const bit [31:0] mmio_addr = 32'h80000000;
    int fd;
    forever begin
      watch_datamem_port.get(item);
      if (item.addr === mmio_addr && item.wmask === 4'b1111) begin
        begin_signature = item.data;
      end else if (item.addr === (mmio_addr + 32'd4) && item.wmask === 4'b1111) begin
        end_signature = item.data;
      end else if (item.addr === (mmio_addr + 32'd8) && item.wmask === 4'b1111) begin
        fd = $fopen(signature_path, "w");
        if (!fd) begin
          `uvm_warning(get_full_name(), "Failed to open signature file for writing")
        end else begin
          while (begin_signature < end_signature) begin
            $fdisplay(fd, $sformatf("%08h", data_seq.get_word_at(begin_signature)));
            begin_signature += 4;
          end
          $fclose(fd);
        end
        return;
      end
    end
  endtask : riscof_signature_dump

endclass : core_test_riscof

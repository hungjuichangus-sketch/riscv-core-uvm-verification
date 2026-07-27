class data_mem_seq_item extends uvm_sequence_item;

    rand int unsigned gnt_delay;
    rand int unsigned rvalid_delay;

    bit [31:0] rdata;
    bit [6:0] rdata_intg;
    bit error;

    `uvm_object_utils_begin(data_mem_seq_item)
        `uvm_field_int(gnt_delay, UVM_ALL_ON)
        `uvm_field_int(rvalid_delay, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(rdata_intg, UVM_ALL_ON)
        `uvm_field_int(error, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "data_mem_seq_item");
        super.new(name);
    endfunction

    constraint response_timing_c {
        gnt_delay inside{[0:7]};
        rvalid_delay inside{[0:7]};
    }
endclass

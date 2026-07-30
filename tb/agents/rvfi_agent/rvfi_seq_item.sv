class rvfi_seq_item extends uvm_sequence_item;
    bit rvfi_valid;
    bit [63:0] rvfi_order;
    bit [31:0] rvfi_insn;
    bit rvfi_trap;
    bit rvfi_intr;
    bit [4:0] rvfi_rs1_addr;
    bit [4:0] rvfi_rs2_addr;
    bit [31:0] rvfi_rs1_rdata;
    bit [31:0] rvfi_rs2_rdata;
    bit [4:0] rvfi_rd_addr;
    bit [31:0] rvfi_rd_wdata;
    bit [31:0] rvfi_pc_rdata;
    bit [31:0] rvfi_pc_wdata;
    bit [31:0] rvfi_mem_addr;
    bit [3:0] rvfi_mem_rmask;
    bit [3:0] rvfi_mem_wmask;
    bit [31:0] rvfi_mem_rdata;
    bit [31:0] rvfi_mem_wdata;

    `uvm_object_utils_begin(rvfi_seq_item)
        `uvm_field_int(rvfi_valid, UVM_ALL_ON)
        `uvm_field_int(rvfi_order, UVM_ALL_ON)
        `uvm_field_int(rvfi_insn, UVM_ALL_ON)
        `uvm_field_int(rvfi_trap, UVM_ALL_ON)
        `uvm_field_int(rvfi_intr, UVM_ALL_ON)
        `uvm_field_int(rvfi_rs1_addr, UVM_ALL_ON)
        `uvm_field_int(rvfi_rs2_addr, UVM_ALL_ON)
        `uvm_field_int(rvfi_rs1_rdata, UVM_ALL_ON)
        `uvm_field_int(rvfi_rs2_rdata, UVM_ALL_ON)
        `uvm_field_int(rvfi_rd_addr, UVM_ALL_ON)
        `uvm_field_int(rvfi_rd_wdata, UVM_ALL_ON)
        `uvm_field_int(rvfi_pc_rdata, UVM_ALL_ON)
        `uvm_field_int(rvfi_pc_wdata, UVM_ALL_ON)
        `uvm_field_int(rvfi_mem_addr, UVM_ALL_ON)
        `uvm_field_int(rvfi_mem_rmask, UVM_ALL_ON)
        `uvm_field_int(rvfi_mem_wmask, UVM_ALL_ON)
        `uvm_field_int(rvfi_mem_rdata, UVM_ALL_ON)
        `uvm_field_int(rvfi_mem_wdata, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "rvfi_seq_item");
        super.new(name);
    endfunction
endclass

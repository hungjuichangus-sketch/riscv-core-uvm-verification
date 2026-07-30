class rvfi_monitor extends uvm_monitor;
    `uvm_component_utils(rvfi_monitor)
    virtual rvfi_if.MONITOR vif;
    uvm_analysis_port #(rvfi_seq_item) ap;

    function new(string name = "rvfi_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual rvfi_if.MONITOR)::get(this, "", "vif", vif))
            `uvm_fatal("RVFI MON", "Could not get virtual interface from config db")
        ap = new("ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        rvfi_seq_item item;
        forever begin
            item = rvfi_seq_item::type_id::create("item");
            @(vif.mon_cb iff vif.mon_cb.rvfi_valid);
            item.rvfi_valid = vif.mon_cb.rvfi_valid;
            item.rvfi_order = vif.mon_cb.rvfi_order;
            item.rvfi_insn = vif.mon_cb.rvfi_insn;
            item.rvfi_trap = vif.mon_cb.rvfi_trap;
            item.rvfi_intr = vif.mon_cb.rvfi_intr;
            item.rvfi_rs1_addr = vif.mon_cb.rvfi_rs1_addr;
            item.rvfi_rs1_rdata = vif.mon_cb.rvfi_rs1_rdata;
            item.rvfi_rs2_addr = vif.mon_cb.rvfi_rs2_addr;
            item.rvfi_rs2_rdata = vif.mon_cb.rvfi_rs2_rdata;
            item.rvfi_rd_addr = vif.mon_cb.rvfi_rd_addr;
            item.rvfi_rd_wdata = vif.mon_cb.rvfi_rd_wdata;
            item.rvfi_pc_rdata = vif.mon_cb.rvfi_pc_rdata;
            item.rvfi_pc_wdata = vif.mon_cb.rvfi_pc_wdata;
            item.rvfi_mem_addr = vif.mon_cb.rvfi_mem_addr;
            item.rvfi_mem_rmask = vif.mon_cb.rvfi_mem_rmask;
            item.rvfi_mem_wmask = vif.mon_cb.rvfi_mem_wmask;
            item.rvfi_mem_rdata = vif.mon_cb.rvfi_mem_rdata;
            item.rvfi_mem_wdata = vif.mon_cb.rvfi_mem_wdata;
            ap.write(item);
        end
    endtask
endclass

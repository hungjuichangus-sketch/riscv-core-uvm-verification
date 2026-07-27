class instr_mem_monitor extends uvm_monitor;
    `uvm_component_utils(instr_mem_monitor)

    virtual instr_mem_if.MONITOR vif;
    uvm_analysis_port #(instr_mem_seq_item) ap;
    instr_mem_seq_item pending_req[$];

    function new(string name = "instr_mem_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual instr_mem_if.MONITOR)::get(this, "", "vif", vif))
            `uvm_fatal("INSTR MON", "Could not get virtual interface from config db")
        ap = new("ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        instr_mem_seq_item item, req;
        fork
            forever begin: accept_loop
                req = instr_mem_seq_item::type_id::create("req");
                @(vif.mon_cb iff (vif.mon_cb.instr_req_o && vif.mon_cb.instr_gnt_i));
                req.addr = vif.mon_cb.instr_addr_o;
                pending_req.push_back(req);
            end

            forever begin: respond_loop
                @(vif.mon_cb iff vif.mon_cb.instr_rvalid_i);
                if(pending_req.size() != 0) begin
                    item = instr_mem_seq_item::type_id::create("item");
                    item = pending_req.pop_front();
                    item.rdata = vif.mon_cb.instr_rdata_i;
                    item.error = vif.mon_cb.instr_err_i;
                    item.rdata_intg = vif.mon_cb.instr_rdata_intg_i;
                    ap.write(item);
                end
            end
        join_none
    endtask
endclass


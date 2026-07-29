class data_mem_monitor extends uvm_monitor;
    `uvm_component_utils(data_mem_monitor)
    virtual data_mem_if.MONITOR vif;
    uvm_analysis_port #(data_mem_seq_item) ap;
    data_mem_seq_item pending_req[$];

    function new(string name = "data_mem_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual data_mem_if.MONITOR)::get(this, "", "vif", vif))
            `uvm_fatal("DATA MEM MON", "Could not get the virtual interface from config db")
        ap = new("ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        data_mem_seq_item req, item;
        fork
            forever begin: accept_loop
                req = data_mem_seq_item::type_id::create("req");
                @(vif.mon_cb iff (vif.mon_cb.data_req_o && vif.mon_cb.data_gnt_i));
                req.addr = vif.mon_cb.data_addr_o;
                pending_req.push_back(req);
            end

            forever begin: response_loop
                @(vif.mon_cb iff vif.mon_cb.data_rvalid_i);
                if(pending_req.size() != 0)begin
                    item = pending_req.pop_front();
                    item.rdata = vif.mon_cb.data_rdata_i;
                    item.rdata_intg = vif.mon_cb.data_rdata_intg_i;
                    item.error = vif.mon_cb.data_err_i;
                    ap.write(item);
                end
            end
        join_none
    endtask
endclass

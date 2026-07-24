class instr_mem_driver extends uvm_driver #(instr_mem_seq_item);
    `uvm_component_utils(instr_mem_driver)

    virtual instr_mem_if.DRIVER vif;

    instr_mem_seq_item pending_req[$];

    function new(string name = "instr_mem_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual instr_mem_if.DRIVER)::get(this, "", "vif", vif))
            `uvm_fatal("INSTR DRV", "Could not get the virtual interface from config db")
    endfunction

    task run_phase(uvm_phase phase);
        fork
            forever begin : accept_loop
                vif.drv_cb.instr_gnt_i <= 0;
                seq_item_port.get_next_item(req);
                wait(vif.drv_cb.instr_req_o == 1);
                repeat (req.gnt_delay) @(vif.drv_cb);
                vif.drv_cb.instr_gnt_i <= 1;
                @(vif.drv_cb);
                pending_req.push_back(req);
                seq_item_port.item_done();
            end
            forever begin : respond_loop
                vif.drv_cb.instr_rvalid_i <= 0;
                instr_mem_seq_item item;
                wait(pending_req.size() != 0) begin
                    item = pending_req.pop_front();
                    repeat (item.rvalid_delay) @(vif.drv_cb);
                    vif.drv_cb.instr_rvalid_i <= 1;
                    vif.drv_cb.instr_rdata_i <= item.rdata;
                    vif.drv_cb.instr_rdata_intg_i <= item.rdata_intg;
                    vif.drv_cb.instr_err_i <= item.error;
                    @(vif.drv_cb);
                end
            end
        join_none
    endtask

endclass

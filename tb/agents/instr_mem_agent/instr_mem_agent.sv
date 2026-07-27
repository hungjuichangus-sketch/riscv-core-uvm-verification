class instr_mem_agent extends uvm_agent;
    `uvm_component_utils(instr_mem_agent)

    instr_mem_driver drv;
    instr_mem_monitor mon;
    uvm_sequencer #(instr_mem_seq_item) sqr;
    uvm_analysis_port #(instr_mem_seq_item) ap;

    function new(string name = "instr_mem_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = instr_mem_monitor::type_id::create("mon", this);
        ap = new("ap", this);
        if(get_is_active() == UVM_ACTIVE)begin
            drv = instr_mem_driver::type_id::create("drv", this);
            sqr = uvm_sequencer #(instr_mem_seq_item)::type_id::create("sqr", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon.ap.connect(this.ap);
        if(get_is_active() == UVM_ACTIVE)begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction
endclass

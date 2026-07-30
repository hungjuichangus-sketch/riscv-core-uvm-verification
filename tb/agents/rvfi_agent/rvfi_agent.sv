class rvfi_agent extends uvm_agent;
    `uvm_component_utils(rvfi_agent)
    rvfi_monitor mon;
    uvm_analysis_port #(rvfi_seq_item) ap;

    function new(string name = "rvfi_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = rvfi_monitor::type_id::create("mon", this);
        ap = new("ap", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon.ap.connect(this.ap);
    endfunction
endclass

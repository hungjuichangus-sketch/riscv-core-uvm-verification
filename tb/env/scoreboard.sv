`uvm_analysis_imp_decl(_rvfi)
`uvm_analysis_imp_decl(_spike)

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_analysis_imp_rvfi #(rvfi_seq_item, scoreboard) rvfi_imp;
    uvm_analysis_imp_spike #(rvfi_seq_item, scoreboard) spike_imp;

    rvfi_seq_item rvfi_q[$];
    rvfi_seq_item spike_q[$];

    int num_compared = 0;
    int num_mismatch = 0;

    function new(string name = "scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        rvfi_imp = new("rvfi_imp", this);
        spike_imp = new("spike_imp", this);
    endfunction

    function void write_rvfi(rvfi_seq_item t);
        rvfi_q.push_back(t);
        try_compare();
    endfunction

    function void write_spike(rvfi_seq_item t);
        spike_q.push_back(t);
        try_compare();
    endfunction

    function void try_compare();
        while(rvfi_q.size() > 0 && spike_q.size() > 0)begin
            rvfi_seq_item dut = rvfi_q.pop_front();
            rvfi_seq_item exp = spike_q.pop_front();
            compare(dut, exp);
        end
    endfunction

    function void compare(rvfi_seq_item dut, rvfi_seq_item exp);
        bit match = 1'b1;
        string msg = "";

        if(dut.rvfi_insn !== exp.rvfi_insn)begin
            match = 1'b0;
            msg = {msg, $sformatf("Instruction mismatch: dut=0x%08h exp=0x%08h\n",
                                   dut.rvfi_insn, exp.rvfi_insn)};
        end
        if(dut.rvfi_pc_rdata !== exp.rvfi_pc_rdata)begin
            match = 1'b0;
            msg = {msg, $sformatf("Program Counter Read Data mismatch: dut=0x%08h exp=0x%08h\n",
                                dut.rvfi_pc_rdata, exp.rvfi_pc_rdata)};
        end
        if(dut.rvfi_pc_wdata !== exp.rvfi_pc_wdata)begin
            match = 1'b0;
            msg = {msg, $sformatf("Program Counter Write Data mismatch: dut=0x%08h exp=0x%08h\n",
                                dut.rvfi_pc_wdata, exp.rvfi_pc_wdata)};
        end
        if(dut.rvfi_mem_rmask !== exp.rvfi_mem_rmask)begin
            match = 1'b0;
            msg = {msg, $sformatf("Memory read mask mismatch: dut=0x%04b exp=0x%04b\n",
                                dut.rvfi_mem_rmask, exp.rvfi_mem_rmask)};
        end
        if(dut.rvfi_mem_wmask !== exp.rvfi_mem_wmask)begin
            match = 1'b0;
            msg = {msg, $sformatf("Memory write mask mismatch: dut=0x%04b exp=0x%04b\n",
                                dut.rvfi_mem_wmask, exp.rvfi_mem_wmask)};
        end
        if(dut.rvfi_trap !== exp.rvfi_trap)begin
            match = 1'b0;
            msg = {msg, $sformatf("Trap flag mismatch: dut=0x%08h exp=0x%08h\n",
                                dut.rvfi_trap, exp.rvfi_trap)};
        end
        if(dut.rvfi_mem_rmask != 0 || dut.rvfi_mem_wmask != 0)begin
            if(dut.rvfi_mem_addr !== exp.rvfi_mem_addr)begin
                match = 1'b0;
                msg = {msg, $sformatf("Memory address mismatch: dut=0x%08h exp=0x%08h\n",
                                    dut.rvfi_mem_addr, exp.rvfi_mem_addr)};
            end
        end
        if(dut.rvfi_trap == 0)begin
            if(dut.rvfi_rs1_rdata !== exp.rvfi_rs1_rdata)begin
                match = 1'b0;
                msg = {msg, $sformatf("Register source 1 mismatch: dut=0x%08h exp=0x%08h\n",
                                    dut.rvfi_rs1_rdata, exp.rvfi_rs1_rdata)};
            end
            if(dut.rvfi_rs2_rdata !== exp.rvfi_rs2_rdata)begin
                match = 1'b0;
                msg = {msg, $sformatf("Register source 2 mismatch: dut=0x%08h exp=0x%08h\n",
                                    dut.rvfi_rs2_rdata, exp.rvfi_rs2_rdata)};
            end
            if(dut.rvfi_rd_addr != 0)begin
                if(dut.rvfi_rd_wdata !== exp.rvfi_rd_wdata)begin
                    match = 1'b0;
                    msg = {msg, $sformatf("Register destination mismatch: dut=0x%08h exp=0x%08h\n",
                                        dut.rvfi_rd_wdata, exp.rvfi_rd_wdata)};
                end
            end
            if(dut.rvfi_mem_rmask != 0)begin
                if(dut.rvfi_mem_rdata !== exp.rvfi_mem_rdata)begin
                    match = 1'b0;
                    msg = {msg, $sformatf("Memory read data mismatch: dut=0x%08h exp=0x%08h\n",
                                        dut.rvfi_mem_rdata, exp.rvfi_mem_rdata)};
                end
            end
            if(dut.rvfi_mem_wmask != 0)begin
                if(dut.rvfi_mem_wdata !== exp.rvfi_mem_wdata)begin
                    match = 1'b0;
                    msg = {msg, $sformatf("Memory write data mismatch: dut=0x%08h exp=0x%08h\n",
                                        dut.rvfi_mem_wdata, exp.rvfi_mem_wdata)};
                end
            end
        end

        num_compared++;
        if(match == 0)begin
            num_mismatch++;
            `uvm_error("SCB", msg)
        end
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (rvfi_q.size() != 0)
            `uvm_error("SCOREBOARD",
                       $sformatf("%0d unmatched RVFI transactions left over", rvfi_q.size()))
        if (spike_q.size() != 0)
            `uvm_error("SCOREBOARD",
                       $sformatf("%0d unmatched Spike transactions left over", spike_q.size()))
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCOREBOARD",
                  $sformatf("Compared %0d instructions, %0d mismatches",
                            num_compared, num_mismatch), UVM_LOW)
    endfunction

endclass

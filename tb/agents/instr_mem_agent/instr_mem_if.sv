interface instr_mem_if (input logic clk_i, rst_ni);
    logic         instr_req_o;       // request
    logic [31:0]  instr_addr_o;      // the fetch address
    logic         instr_gnt_i;       // request accepted
    logic         instr_rvalid_i;    // rdata valid this cycle
    logic [31:0]  instr_rdata_i;     // the fetched instruction
    logic         instr_err_i;       // error response
    logic [6:0]   instr_rdata_intg_i;// integrity/ECC bits

    clocking drv_cb @(posedge clk_i);
        input instr_req_o, instr_addr_o;
        output instr_gnt_i, instr_rvalid_i, instr_rdata_i, instr_err_i, instr_rdata_intg_i;
    endclocking

    clocking mon_cb @(posedge clk_i);
        input instr_req_o, instr_addr_o, instr_gnt_i, instr_rvalid_i, instr_rdata_i,
              instr_err_i, instr_rdata_intg_i;
    endclocking

    modport DRIVER (clocking drv_cb, input rst_ni);
    modport MONITOR (clocking mon_cb, input rst_ni);
endinterface

interface rvfi_if (input logic clk_i, rst_ni);
    logic rvfi_valid;
    logic [63:0] rvfi_order;
    logic [31:0] rvfi_insn;
    logic rvfi_trap;
    logic rvfi_intr;
    logic [4:0] rvfi_rs1_addr;
    logic [4:0] rvfi_rs2_addr;
    logic [31:0] rvfi_rs1_rdata;
    logic [31:0] rvfi_rs2_rdata;
    logic [4:0] rvfi_rd_addr;
    logic [31:0] rvfi_rd_wdata;
    logic [31:0] rvfi_pc_rdata;
    logic [31:0] rvfi_pc_wdata;
    logic [31:0] rvfi_mem_addr;
    logic [3:0] rvfi_mem_rmask;
    logic [3:0] rvfi_mem_wmask;
    logic [31:0] rvfi_mem_rdata;
    logic [31:0] rvfi_mem_wdata;

    clocking mon_cb @(posedge clk_i);
        input rvfi_valid, rvfi_order, rvfi_insn, rvfi_trap, rvfi_intr,
              rvfi_rs1_addr, rvfi_rs2_addr, rvfi_rs1_rdata, rvfi_rs2_rdata,
              rvfi_rd_addr, rvfi_rd_wdata, rvfi_pc_rdata, rvfi_pc_wdata,
              rvfi_mem_addr, rvfi_mem_rmask, rvfi_mem_wmask, rvfi_mem_rdata,
              rvfi_mem_wdata;
    endclocking

    modport MONITOR (clocking mon_cb, input rst_ni);
endinterface

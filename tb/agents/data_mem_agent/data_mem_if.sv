interface data_mem_if (input logic clk_i, rst_ni);
    logic data_req_o;
    logic [31:0] data_addr_o;
    logic data_we_o;
    logic [3:0] data_be_o;
    logic [31:0] data_wdata_o;
    logic [6:0] data_wdata_intg_o;

    logic data_gnt_i;
    logic data_rvalid_i;
    logic [31:0] data_rdata_i;
    logic [6:0] data_rdata_intg_i;
    logic data_err_i;

    clocking drv_cb @(posedge clk_i);
        input data_req_o, data_addr_o, data_we_o, data_be_o,
              data_wdata_o, data_wdata_intg_o;
        output data_gnt_i, data_rvalid_i, data_rdata_i,
               data_rdata_intg_i, data_err_i;
    endclocking

    clocking mon_cb @(posedge clk_i);
        input data_req_o, data_addr_o, data_we_o, data_be_o,
              data_wdata_o, data_wdata_intg_o, data_gnt_i,
              data_rvalid_i, data_rdata_i, data_rdata_intg_i, data_err_i;
    endclocking

    modport DRIVER (clocking drv_cb, input rst_ni);
    modport MONITOR (clocking mon_cb, input rst_ni);
endinterface

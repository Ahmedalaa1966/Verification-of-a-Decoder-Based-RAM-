`ifndef RAM_IF_SV
`define RAM_IF_SV

interface ram_if(input clk);

    logic       rst_n ;
    logic       we    ;
    logic       re    ;
    logic [6:0] addr  ;
    logic [7:0] wdata ;
    logic [7:0] rdata ;
    logic       valid ;

    clocking wr_cb @(posedge clk);
        default input #1 output #1 ;
        output rst_n ;
        output we    ;
        output addr  ;
        output wdata ;
        input  valid ;
    endclocking

    // clocking block for read driver
    clocking rd_cb @(posedge clk);
        default input #1 output #1 ;
        output re    ;
        output addr  ;
        input  rdata ;
        input  valid ;
    endclocking

    // clocking block for monitors
    clocking mon_cb @(posedge clk);
        default input #1 ;
        input we    ;
        input re    ;
        input addr  ;
        input wdata ;
        input rdata ;
        input valid ;
    endclocking

    // modport for the DUT itself
    modport DUT (
        input  clk,
        input  rst_n,
        input  we,
        input  re,
        input  addr,
        input  wdata,
        output rdata,
        output valid
    );

    modport WRITE_DRV (clocking wr_cb,  input clk) ;
    modport READ_DRV  (clocking rd_cb,  input clk) ;
    modport WR_MON    (clocking mon_cb, input clk) ;
    modport RD_MON    (clocking mon_cb, input clk) ;

endinterface //ram_if

`endif // RAM_IF_SV
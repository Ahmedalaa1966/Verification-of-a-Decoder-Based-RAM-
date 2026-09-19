`ifndef RAM_DRIVER_SV
`define RAM_DRIVER_SV

`include "ram_transaction.sv"
`include "ram_if.sv"
class ram_wr_driver;

    virtual ram_if.WRITE_DRV vif ;

    mailbox #(transaction) wr_mbox ;             // from the generator to the write driver
    mailbox #(bit)         wr_done_mbox ;
    int unsigned txr_count ;

    function new(virtual ram_if.WRITE_DRV vif, mailbox #(transaction) wr_mbox, mailbox #(bit) wr_done_mbox, int unsigned txr_count);
        this.vif          = vif ;
        this.wr_mbox      = wr_mbox ;
        this.wr_done_mbox = wr_done_mbox ;
        this.txr_count    = txr_count ;
    endfunction

    task reset(int cycles = 4);
    $display("applying the reset task ");
    vif.wr_cb.rst_n <= 0 ;
    vif.wr_cb.we    <= 0 ;
    vif.wr_cb.addr  <= 'b0 ;
    vif.wr_cb.wdata <= 'b0 ;

    repeat(cycles) @(vif.wr_cb) ;
    vif.wr_cb.rst_n <= 1 ;
    $display("reset deasserted ");
endtask

    task drive(transaction txn);

        @(vif.wr_cb) ;
        vif.wr_cb.we    <= 'b1 ;
        vif.wr_cb.addr  <= txn.addr ;
        vif.wr_cb.wdata <= txn.wdata ;

        @(vif.wr_cb) ;
        vif.wr_cb.we    <= 'b0 ;   // deassert after one cycle
        vif.wr_cb.addr  <= 'b0 ;
        vif.wr_cb.wdata <= 'b0 ;

    endtask //drive

    task run ();        // this will be called by the generator

        transaction txn ;
        forever begin
            wr_mbox.get(txn) ;
            drive(txn) ;
            txr_count++ ;
            wr_done_mbox.put(1'b1) ;
        end
    endtask

endclass //ram_wr_driver


class ram_read_driver;

    virtual ram_if.READ_DRV vif ;
    mailbox #(transaction) rd_mbox;
    mailbox #(bit)         rd_done_mbox;
    int unsigned txn_count ;

    function new(virtual ram_if.READ_DRV vif, mailbox #(transaction) rd_mbox, mailbox #(bit) rd_done_mbox, int unsigned txn_count);
        this.vif           = vif ;
        this.rd_mbox       = rd_mbox ;
        this.rd_done_mbox  = rd_done_mbox ;
        this.txn_count     = txn_count ;
    endfunction

    task drive(transaction txn);

        @(vif.rd_cb) ;
        vif.rd_cb.re    <= 'b1 ;
        vif.rd_cb.addr  <= txn.addr ;

        @(vif.rd_cb) ;
        vif.rd_cb.re    <= 'b0 ;
        vif.rd_cb.addr  <= 'b0 ;

    endtask //drive

    task run ();        // this will be called by the generator

        transaction txn ;
        forever begin
            rd_mbox.get(txn) ;
            drive(txn) ;
            txn_count++ ;
            rd_done_mbox.put(1'b1) ;
        end
    endtask

endclass //ram_read_driver

`endif //
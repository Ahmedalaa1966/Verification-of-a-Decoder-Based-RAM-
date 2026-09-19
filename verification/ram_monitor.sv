`ifndef RAM_MONITOR_SV
`define RAM_MONITOR_SV

`include "ram_transaction.sv"
`include "ram_if.sv"

class write_monitor;

    virtual ram_if.WR_MON vif ;

    mailbox #(transaction) sb_wr_mbx ;
    mailbox #(transaction) rm_wr_mbx ;

    int unsigned observed_count ;

    function new(virtual ram_if.WR_MON vif, mailbox #(transaction) sb_wr_mbx, mailbox #(transaction) rm_wr_mbx);
        this.vif        = vif ;
        this.sb_wr_mbx   = sb_wr_mbx ;
        this.rm_wr_mbx   = rm_wr_mbx ;
    endfunction //new()

    task run ();

        transaction txn ;
        $display("WR_MON Started") ;

        forever begin
            @(vif.mon_cb) ;
            if (vif.mon_cb.we == 1) begin

                txn        = new() ;
                txn.op     = transaction::WRITE ;
                txn.addr   = vif.mon_cb.addr  ;
                txn.wdata  = vif.mon_cb.wdata ;

                observed_count++ ;
                txn.print("wr_mon") ;

                sb_wr_mbx.put(txn) ;
                rm_wr_mbx.put(txn) ;

            end
        end
    endtask //run

endclass //write_monitor



class read_monitor;

    virtual ram_if.RD_MON vif ;

    mailbox #(transaction) sb_rd_mbx ;
    mailbox #(transaction) rm_rd_mbx ;

    int unsigned observed_count ;

    function new(virtual ram_if.RD_MON vif, mailbox #(transaction) sb_rd_mbx, mailbox #(transaction) rm_rd_mbx);
        this.vif        = vif ;
        this.sb_rd_mbx   = sb_rd_mbx ;
        this.rm_rd_mbx   = rm_rd_mbx ;
    endfunction //new()

    task run ();

        transaction txn ;
        logic [6:0] pending_addr ;
        bit pending_read ;

        $display("RD_MON Started") ;
        pending_read = 0 ;

        forever begin
            @(vif.mon_cb) ;

            // capture the address the cycle the read request is issued
            if (!pending_read && vif.mon_cb.re == 1) begin
                pending_addr = vif.mon_cb.addr ;
                pending_read = 1 ;
            end

            // once the data comes back valid, build and send the transaction
            if (pending_read && vif.mon_cb.valid == 1) begin

                txn        = new() ;
                txn.op     = transaction::READ ;
                txn.addr   = pending_addr ;
                txn.rdata  = vif.mon_cb.rdata ;
                txn.valid  = vif.mon_cb.valid ;

                observed_count++ ;
                txn.print("rd_mon") ;

                sb_rd_mbx.put(txn) ;
                rm_rd_mbx.put(txn) ;

                pending_read = 0 ;
            end
            else if (!pending_read) begin
                $display("waiting for valid ") ;
            end
        end
    endtask //run

endclass //read_monitor

`endif // RAM_MONITOR_SV
`ifndef RAM_REF_MODEL_SV
`define RAM_REF_MODEL_SV

`include "ram_transaction.sv"
`include "ram_if.sv"

class ref_model;

    logic [7:0] mem [127:0] ;
    mailbox #(transaction) rm_wr_mbx ;      // from the write monitor
    mailbox #(transaction) rm_rd_mbx ;      // from the read monitor
    mailbox #(transaction) sb_exp_wr_mbx ;  // expected writes  -> scoreboard
    mailbox #(transaction) sb_exp_rd_mbx ;  // expected reads   -> scoreboard

    int unsigned wr_processed ;
    int unsigned rd_processed ;

    function new(mailbox #(transaction) rm_wr_mbx, mailbox #(transaction) rm_rd_mbx,
                 mailbox #(transaction) sb_exp_wr_mbx, mailbox #(transaction) sb_exp_rd_mbx);
        this.rm_wr_mbx     = rm_wr_mbx ;
        this.rm_rd_mbx     = rm_rd_mbx ;
        this.sb_exp_wr_mbx = sb_exp_wr_mbx ;
        this.sb_exp_rd_mbx = sb_exp_rd_mbx ;
        wr_processed       = 0 ;
        rd_processed       = 0 ;
    endfunction //new()

    task run_writes ();

        transaction txn, exp_txn ;
        $display("[RM] Reference model write task started") ;

        forever begin
            rm_wr_mbx.get(txn) ;
            mem[txn.addr] = txn.wdata ;

            // build a fresh object instead of mutating the monitor's shared handle
            exp_txn        = new() ;
            exp_txn.op     = txn.op ;
            exp_txn.we     = txn.we ;
            exp_txn.addr   = txn.addr ;
            exp_txn.wdata  = txn.wdata ;
            exp_txn.rdata  = txn.rdata ;
            exp_txn.valid  = txn.valid ;

            sb_exp_wr_mbx.put(exp_txn) ;

            wr_processed++ ;
            $display("[RM] write address = %0h, data = %0h", txn.addr, txn.wdata);
        end

    endtask //run_writes

    task run_reads();

        transaction txn, exp_txn ;
        $display("[RM] Reference model read task started") ;

        forever begin
            rm_rd_mbx.get(txn) ;

            // build a fresh object instead of mutating the monitor's shared handle
            exp_txn        = new() ;
            exp_txn.op     = txn.op ;
            exp_txn.we     = txn.we ;
            exp_txn.addr   = txn.addr ;
            exp_txn.wdata  = txn.wdata ;
            exp_txn.rdata  = mem[txn.addr] ;
            exp_txn.valid  = 'b1 ;

            sb_exp_rd_mbx.put(exp_txn) ;

            rd_processed++ ;
            $display("[RM] read address = %0h, expected data = %0h", txn.addr, exp_txn.rdata);
        end
    endtask

endclass //ref_model

`endif // RAM_REF_MODEL_SV
`ifndef RAM_SCOREBOARD_SV
`define RAM_SCOREBOARD_SV

`include "ram_transaction.sv"
`include "ram_if.sv"

class scoreboard;

    mailbox #(transaction) sb_rd_mbx ;      // actual reads  - from the read monitor
    mailbox #(transaction) sb_wr_mbx ;      // actual writes - from the write monitor
    mailbox #(transaction) sb_exp_rd_mbx ;  // expected reads  - from the reference model
    mailbox #(transaction) sb_exp_wr_mbx ;  // expected writes - from the reference model

    int unsigned pass_count ;
    int unsigned fail_count ;

    function new(mailbox #(transaction) sb_rd_mbx, mailbox #(transaction) sb_exp_rd_mbx,
                 mailbox #(transaction) sb_wr_mbx, mailbox #(transaction) sb_exp_wr_mbx);
        this.sb_rd_mbx     = sb_rd_mbx ;
        this.sb_exp_rd_mbx = sb_exp_rd_mbx ;
        this.sb_wr_mbx     = sb_wr_mbx ;
        this.sb_exp_wr_mbx = sb_exp_wr_mbx ;
        pass_count         = 0 ;
        fail_count         = 0 ;
    endfunction //new()

    task run_check ();      // checks reads

        transaction actual, expected ;
        $display("[SB] read check started");

        forever begin
            sb_rd_mbx.get(actual)       ;
            sb_exp_rd_mbx.get(expected) ;
            check(actual, expected)     ;
        end
    endtask

    task run_check_write ();  // checks writes

        transaction actual, expected ;
        $display("[SB] write check started");

        forever begin
            sb_wr_mbx.get(actual)       ;
            sb_exp_wr_mbx.get(expected) ;
            check(actual, expected)     ;
        end
    endtask

    function void check(transaction actual, transaction expected);

        bit addr_match ;
        bit data_match ;
        bit valid_match ;

        addr_match  = (actual.addr  == expected.addr)  ;

        // reads compare rdata; writes compare wdata
        if (actual.op == transaction::READ)
            data_match = (actual.rdata == expected.rdata) ;
        else
            data_match = (actual.wdata == expected.wdata) ;

        valid_match = (actual.valid == expected.valid) ;

        if (addr_match && data_match && valid_match) begin
            pass_count++ ;
            $display("[SB] PASS: op=%s addr=%0h rdata=%0h wdata=%0h valid=%b",
                       actual.op.name(), actual.addr, actual.rdata, actual.wdata, actual.valid);
        end
        else begin
            fail_count++ ;
            if (!addr_match)
                $display("[SB] FAIL: Address mismatch  actual=%0h expected=%0h", actual.addr, expected.addr);
            else if (!data_match)
                $display("[SB] FAIL: Data mismatch  actual=%0h expected=%0h",
                           (actual.op == transaction::READ) ? actual.rdata : actual.wdata,
                           (actual.op == transaction::READ) ? expected.rdata : expected.wdata);
            else
                $display("[SB] FAIL: Valid mismatch  actual=%b expected=%b", actual.valid, expected.valid);
        end
    endfunction

    function void report();
        $display("");
        $display("==================================================");
        $display("[SB] SCOREBOARD REPORT");
        $display("==================================================");
        $display("[SB] Pass  = %0d", pass_count);
        $display("[SB] Fail  = %0d", fail_count);
        $display("[SB] Total = %0d", pass_count + fail_count);
        if (fail_count == 0 && (pass_count + fail_count) > 0)
            $display("[SB] RESULT: ALL CHECKS PASSED");
        else if (fail_count > 0)
            $display("[SB] RESULT: FAILURES DETECTED");
        else
            $display("[SB] RESULT: NO CHECKS WERE PERFORMED");
        $display("==================================================");
        $display("");
    endfunction

endclass //scoreboard

`endif // RAM_SCOREBOARD_SV
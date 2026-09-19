`ifndef RAM_TRANSACTION_SV
`define RAM_TRANSACTION_SV

class transaction;

    typedef enum {WRITE, READ} op_t;
    rand op_t op;
    rand logic we;
    rand logic [6:0] addr  ;
    rand logic [7:0] wdata ;
    logic [7:0] rdata      ;
    logic       valid      ;

    function new();
        op    = WRITE ;
        we    = 'b0   ;
        rdata = 'b0   ;
        wdata = 'b0   ;
        addr  = 'b0   ;
        valid = 'b0   ;
    endfunction //new()

    function void print(string tag = "");
        $display("%0t : %s | op = %s we = %b addr = %0h wdata = %0h rdata = %0h valid = %b",
                   $time, tag, op.name(), we, addr, wdata, rdata, valid);
    endfunction

endclass

`endif // RAM_TRANSACTION_SV
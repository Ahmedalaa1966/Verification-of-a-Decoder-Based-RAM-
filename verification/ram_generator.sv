`ifndef RAM_GENERATOR_SV
`define RAM_GENERATOR_SV


`include "ram_transaction.sv"
`include "ram_if.sv"
class generator;

  mailbox #(transaction) wr_mbx;
  mailbox #(transaction) rd_mbx;
  mailbox #(bit)         wr_done_mbx;

  function new(mailbox #(transaction) wr_mbx,
               mailbox #(transaction) rd_mbx,
               mailbox #(bit)         wr_done_mbx);
    this.wr_mbx      = wr_mbx;
    this.rd_mbx       = rd_mbx;
    this.wr_done_mbx  = wr_done_mbx;
  endfunction

  local task send_write(transaction txn);
    txn.print("[GEN-WR]");
    wr_mbx.put(txn);
  endtask

  local task wait_writes_done(input int unsigned n);
    bit tok;
    repeat (n) wr_done_mbx.get(tok);
  endtask

  local task send_read(transaction txn);
    txn.print("[GEN-RD]");
    rd_mbx.put(txn);
  endtask

  task run(
    input logic [6:0]  wr_addrs [],
    input logic [7:0]  wr_datas [],
    input int unsigned n_writes,
    input logic [6:0]  rd_addrs [],
    input int unsigned n_reads,
    input bit          randomize_txns = 0
  );

    // ---- Writes ----
    $display("[GEN] Sending %0d writes", n_writes);
    if (!randomize_txns) begin
      if (wr_addrs.size() < n_writes || wr_datas.size() < n_writes)
        $fatal(1, "[GEN] wr_addrs/wr_datas smaller than n_writes");
    end

    if (randomize_txns) begin
      for (int i = 0; i < n_writes; i++) begin
        transaction txn = new();
        if (!txn.randomize() with { op == transaction::WRITE; })
          $fatal(1, "[GEN] randomize() failed for WRITE %0d", i);
        send_write(txn);
      end
    end else begin
      for (int i = 0; i < n_writes; i++) begin
        transaction txn = new();
        txn.op    = transaction::WRITE;
        txn.addr  = wr_addrs[i];
        txn.wdata = wr_datas[i];
        send_write(txn);
      end
    end

    // Drain all writes before issuing reads
    wait_writes_done(n_writes);
    $display("[GEN] All writes done");

    // ---- Reads ----
    $display("[GEN] Sending %0d reads", n_reads);
    if (!randomize_txns) begin
      if (rd_addrs.size() < n_reads)
        $fatal(1, "[GEN] rd_addrs smaller than n_reads");
    end

    if (randomize_txns) begin
      for (int i = 0; i < n_reads; i++) begin
        transaction txn = new();
        if (!txn.randomize() with { op == transaction::READ; })
          $fatal(1, "[GEN] randomize() failed for READ %0d", i);
        send_read(txn);
      end
    end else begin
      for (int i = 0; i < n_reads; i++) begin
        transaction txn = new();
        txn.op   = transaction::READ;
        txn.addr = rd_addrs[i];
        send_read(txn);
      end
    end

  endtask

endclass //generator

`endif //
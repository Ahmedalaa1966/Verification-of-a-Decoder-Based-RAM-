
`include "ram_test.sv"

module ram_tb_top;

  logic clk;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  ram_if ramif(clk);

  decoder_ram dut (
    .vif (ramif)
  );

  ram_base_test test;
  string testname;

  initial begin

    if (!$value$plusargs("TESTNAME=%s", testname)) begin
      $display("\n==================================================");
      $display("[TOP] ERROR : TESTNAME NOT PROVIDED");
      $display("==================================================");
      $display("Usage Example: vsim work.ram_tb_top +TESTNAME=ram_random_test");
      $finish;
    end

    $display("\n==================================================");
    $display("[TOP] RUNNING TEST : %s", testname);
    $display("==================================================\n");

    case (testname)

      "ram_random_test":
        test = ram_random_test::new(ramif, ramif, ramif, ramif);

      "ram_block_boundary_test":
        test = ram_block_boundary_test::new(ramif, ramif, ramif, ramif);

      "ram_full_sweep_test":
        test = ram_full_sweep_test::new(ramif, ramif, ramif, ramif);

      "ram_walking1_data_test":
        test = ram_walking1_data_test::new(ramif, ramif, ramif, ramif);

      "ram_walking0_data_test":
        test = ram_walking0_data_test::new(ramif, ramif, ramif, ramif);

      "ram_walking1_addr_test":
        test = ram_walking1_addr_test::new(ramif, ramif, ramif, ramif);

      "ram_walking0_addr_test":
        test = ram_walking0_addr_test::new(ramif, ramif, ramif, ramif);

      "ram_same_addr_overwrite_test":
        test = ram_same_addr_overwrite_test::new(ramif, ramif, ramif, ramif);

      "ram_toggle_addr_test":
        test = ram_toggle_addr_test::new(ramif, ramif, ramif, ramif);

      "ram_checkerboard_test":
        test = ram_checkerboard_test::new(ramif, ramif, ramif, ramif);

      "ram_block_isolation_test":
        test = ram_block_isolation_test::new(ramif, ramif, ramif, ramif); 

      default: begin
        $display("\n==================================================");
        $display("[TOP] ERROR : UNKNOWN TEST : %s", testname);
        $display("==================================================");
        #20
        $stop;
      end

    endcase

    test.run();

    $display("\n==================================================");
    $display("[TOP] TEST COMPLETED : %s", testname);
    $display("==================================================\n");

    #20;
    $stop;

  end

endmodule
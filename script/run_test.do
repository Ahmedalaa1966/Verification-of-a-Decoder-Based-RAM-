# =====================================================
# Regression Script for RAM Verification
# =====================================================

transcript on

if {[file exists work]} {
    vdel -all -lib work
}

vlib work
vmap work work

file mkdir logs
file mkdir coverage

puts ""
puts "===================================="
puts "COMPILING FILES"
puts "===================================="
puts ""

# +cover=bcesfx enables branch, condition, expression, fsm, statement, and toggle coverage
vlog +cover=bcesfx ./verification/ram_if.sv
vlog +cover=bcesfx ./rtl/decoder_ram.sv

vlog ./verification/ram_transaction.sv
vlog ./verification/ram_generator.sv

vlog ./verification/ram_monitor.sv
vlog ./verification/ram_ref_model.sv
vlog ./verification/ram_scoreboard.sv
vlog ./verification/ram_driver.sv

vlog ./verification/ram_env.sv
vlog ./verification/ram_test.sv

vlog ./verification/ram_tb_top.sv

puts ""
puts "===================================="
puts "ELABORATING DESIGN"
puts "===================================="
puts ""

vopt +acc +cover=bcesfx ram_tb_top -o ram_tb_top_opt

# -----------------------------------------------------
# LIST OF TESTS
# -----------------------------------------------------
set testlist {
    ram_random_test
    ram_block_boundary_test
    ram_full_sweep_test
    ram_walking1_data_test
    ram_walking0_data_test
    ram_walking1_addr_test
    ram_walking0_addr_test
    ram_same_addr_overwrite_test
    ram_toggle_addr_test
    ram_checkerboard_test
    ram_block_isolation_test
}

# -----------------------------------------------------
# RUN EACH TEST IN ITS OWN vsim SESSION / LOG FILE
# -----------------------------------------------------
foreach t $testlist {

    puts ""
    puts "===================================="
    puts "RUNNING TEST: $t"
    puts "===================================="
    puts ""

    vsim -c -coverage ram_tb_top_opt -l logs/${t}.log +TESTNAME=${t}

    run -all

    # save this test's coverage database
    coverage save coverage/${t}.ucdb

    # write a per-test human-readable coverage report
    vcover report coverage/${t}.ucdb -output coverage/${t}_report.txt -details

    
}

# -----------------------------------------------------
# MERGE ALL PER-TEST COVERAGE DATABASES INTO ONE
# -----------------------------------------------------
puts ""
puts "===================================="
puts "MERGING COVERAGE DATABASES"
puts "===================================="
puts ""

set ucdb_files {}
foreach t $testlist {
    lappend ucdb_files coverage/${t}.ucdb
}

vcover merge coverage/merged.ucdb {*}$ucdb_files

vcover report coverage/merged.ucdb -output coverage/regression_summary.txt -details


transcript off
# Verification of a Decoder-Based RAM

A SystemVerilog / UVM-style testbench built to verify a decoder-based RAM design (`decoder_based_RAM.sv`). The environment drives a wide range of directed and randomized test classes at the DUT, checks results against a reference model in a scoreboard, and produces per-test coverage/regression reports and simulation logs.

---

## Testbench Architecture

<img width="2720" height="1840" alt="ram_tb_nested_architecture" src="https://github.com/user-attachments/assets/97ea72b4-3f1d-48cd-8066-0cf67d348ea6" />


The testbench follows a classic layered/nested verification structure:

- **TB_top (`ram_tb_top`)** — the outermost module; instantiates the test, the DUT, and the interface, and connects them together.
- **Test (`ram_base_test`)** — configures and runs the environment; each concrete test class (e.g. `ram_random_test`, `ram_full_sweep_test`, etc.) extends this base and selects which sequence/stimulus to run.
- **Env (`ram_env`)** — the environment container that instantiates the agent and the scoreboard.
- **Agent** — bundles the active verification components:
  - **Generator** — creates transactions (write/read operations, addresses, data).
  - **Drivers** — drive the generated transactions onto the DUT through the interface (write/read).
  - **Monitors** — passively observe the interface activity (write/read) and forward transactions to the scoreboard.
- **Scoreboard** — checks the DUT's actual behavior against a reference model (`ram_ref_model`) to confirm correctness.
- **Interface (`ram_if`)** — the SystemVerilog interface connecting the testbench components to the DUT.
- **DUT (`decoder_based_RAM`)** — the decoder-based RAM design under test.

---

## Test Classes

<img width="1552" height="642" alt="verification plan" src="https://github.com/user-attachments/assets/c041fc3a-434e-43ed-ac3b-858736c216ce" />


The regression suite is made up of 11 test classes, each targeting a different verification goal against the 128-address RAM:

| Test Class | Category | Focus |
|---|---|---|
| `ram_random_test` | Randomized | Fully random address & data (32 writes / 16 reads, `randomize = true`) |
| `ram_block_boundary_test` | Boundary | First & last address of each 32-entry block (`0x00/0x1F/0x20/0x3F...`) |
| `ram_full_sweep_test` | Exhaustive | All 128 addresses written (`data = ~addr`), then read back |
| `ram_walking1_data_test` | Bit-pattern | Data bus walking-1s: `0x01, 0x02, 0x04 ... 0x80` |
| `ram_walking0_data_test` | Bit-pattern | Data bus walking-0s: complement of walking-1s |
| `ram_walking1_addr_test` | Bit-pattern | Address bus walking-1s: `0x01, 0x02, 0x04 ... 0x40` |
| `ram_walking0_addr_test` | Bit-pattern | Address bus walking-0s: complement of walking-1s on address |
| `ram_same_addr_overwrite_test` | Overwrite | Write → overwrite → read; checks last-write wins |
| `ram_toggle_addr_test` | R/W interleave | Write → Read → Write → Read per address; verifies mid-sequence updates |
| `ram_checkerboard_test` | Pattern | `0xAA`/`0x55` alternating, then inverted, across all 128 addresses |
| `ram_block_isolation_test` | Isolation | Block 0 written `0xDE`, Blocks 1–3 written alternating; only Block 0 read back |

Each test also runs a fixed number of **drain cycles** after stimulus to allow the DUT/scoreboard pipeline to settle before the test concludes.

---

## Repository Structure

```
Decoder_Based_RAM/
│
├── rtl/
│   └── decoder_based_RAM.sv        # RTL design under test (DUT)
│
├── verification/
│   ├── ram_driver.sv               # Drives write/read transactions to the DUT
│   ├── ram_env.sv                  # Environment: instantiates agent + scoreboard
│   ├── ram_generator.sv            # Generates randomized/directed transactions
│   ├── ram_if.sv                   # Interface connecting TB to DUT
│   ├── ram_monitor.sv              # Monitors DUT write/read activity
│   ├── ram_ref_model.sv            # Golden reference model for checking
│   ├── ram_scoreboard.sv           # Compares DUT behavior vs. ref_model
│   ├── ram_tb_top.sv               # Top-level testbench module
│   ├── ram_test.sv                 # All test classes (extends ram_base_test)
│   └── ram_transaction.sv          # Transaction/sequence item definition
│
├── script/
│   └── (simulation run/compile scripts used to build and launch the regression)
│
├── logs/
│   ├── regression.log                    # Full regression run log
│   ├── ram_random_test.log
│   ├── ram_block_boundary_test.log
│   ├── ram_full_sweep_test.log
│   ├── ram_walking1_data_test.log
│   ├── ram_walking0_data_test.log
│   ├── ram_walking1_addr_test.log
│   ├── ram_walking0_addr_test.log
│   ├── ram_same_addr_overwrite_test.log
│   ├── ram_toggle_addr_test.log
│   ├── ram_checkerboard_test.log
│   └── ram_block_isolation_test.log
│
└── coverage/
    ├── regression_summary.txt
    ├── ram_random_test_report.txt
    ├── ram_block_boundary_test_report.txt
    ├── ram_full_sweep_test_report.txt
    ├── ram_walking1_data_test_report.txt
    ├── ram_walking0_data_test_report.txt
    ├── ram_walking1_addr_test_report.txt
    ├── ram_walking0_addr_test_report.txt
    ├── ram_same_addr_overwrite_test_report.txt
    ├── ram_toggle_addr_test_report.txt
    ├── ram_checkerboard_test_report.txt
    └── ram_block_isolation_test_report.txt
```

### Folder Overview

- **`rtl/`** — Contains only the design under test: `decoder_based_RAM.sv`.
- **`verification/`** — The full SystemVerilog testbench: transaction, driver, monitor, generator, interface, reference model, scoreboard, environment, top-level, and the test-class library.
- **`script/`** — Scripts used to compile the RTL/TB and launch simulations/regressions.
- **`logs/`** — Raw simulation log output for each individual test, plus a combined `regression.log` for the full suite run.
- **`coverage/`** — Per-test coverage/pass-fail reports plus a `regression_summary.txt` rolling up the results of the entire regression.

---

## Note

Place the two images referenced above at `images/ram_tb_nested_architecture.png` and `images/ram_test_classes_table.png` in the repository root for them to render correctly on GitHub.

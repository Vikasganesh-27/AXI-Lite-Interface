# AXI-Lite-Interface

## Description
This project implements an AXI Lite slave interface in Verilog. The module handles AXI Lite transactions, including write and read operations, following the AXI4-Lite protocol. It supports memory-mapped access to an internal register array.
This repository also contains a SystemVerilog-based verification environment for AXI-Lite interface testing. The environment includes essential components such as a generator, driver, monitor, and scoreboard to ensure comprehensive functional verification.

## Features
- Implements AXI Lite protocol for communication.
- Supports memory-mapped read and write operations.
- Uses a finite state machine (FSM) to handle transactions.
- Includes an internal memory of 128 registers.
- Provides a test interface (`axi_if`) for simulation and debugging.

## File Structure
- `axilite_s.v`: The main AXI Lite slave module.
- `axi_if.sv`: An interface definition for simulation and testbench purposes.

## FSM States
The module uses a finite state machine (FSM) to manage AXI Lite transactions:
- **Idle**: Waiting for a transaction.
- **Send Address Acknowledgment**: Handling write/read address.
- **Send Write Data Acknowledgment**: Processing write data.
- **Update Memory**: Storing data in memory.
- **Generate Data**: Retrieving data for read operations.
- **Send Write/Read Response**: Sending response signals.

### Simulation
To simulate this module, connect it to an AXI Lite master in a testbench. You can use the `axi_if` interface for testing.

### Integration
This module can be integrated into a larger FPGA or SoC design as a memory-mapped peripheral using the AXI Lite interface.

# Verification Script

## Features
- **Randomized Transaction Generation**: Uses constraints for valid address and data ranges.
- **Driver & Monitor**: Implements AXI-Lite read/write operations and observes transactions.
- **Scoreboard**: Compares expected and actual results to validate correctness.
- **Mailbox-based Communication**: Ensures synchronization between components.

## Files
- `tb.sv` - Testbench top module
- `generator.sv` - Generates test transactions
- `driver.sv` - Drives signals to DUT
- `monitor.sv` - Captures DUT responses
- `scoreboard.sv` - Compares expected and actual values


## License
This project is open-source under the MIT License. Feel free to modify and use it in your projects.

# **Welcome to My Design Verification (DV) & RTL Portfolio\! 👋**

Hi there\! I’m an aspiring **ASIC/IC Design Verification Engineer** with a strong foundation in digital logic and FPGA design. This repository serves as a curated gallery of my journey into the world of hardware verification.

My current focus is on building robust testbenches using **SystemVerilog (OOP, Constraints, SVA)**, mastering **UVM** methodologies, and developing deep architectural intuition to verify complex digital systems.

## **🏗️ Featured UVM Testbenches**

### **⚡ PCIe Transaction Layer & Protocol Checker UVM Environment (Featured)**

**Overview:** A complete, Object-Oriented UVM testbench designed to verify a mock PCI Express (PCIe) Endpoint. The environment focuses on advanced protocol compliance, split-transaction architectures, and out-of-order tag matching.
<details>
         
#### **Project Highlights & Key Features**
* **Decoupled RX/TX Hardware Engines:** The RTL is designed with a true split-transaction architecture. It uses independent always_ff blocks for the RX and TX paths, linked by a SystemVerilog queue acting as a Pending Request Table (PRT) to prevent Head-of-Line (HOL) blocking.
* **Out-of-Order "Smart" Scoreboard:** The UVM reference model utilizes $O(1)$ associative arrays keyed by the PCIe Tag. This allows it to instantly match and verify incoming Completions even when the hardware returns them completely out-of-order.
* **Protocol-Aware Transactions:** The pcie_tlp_seq_item leverages post_randomize() to accurately bit-pack and align the PCIe TLP headers (Format, Type, Length, Tag, and Byte Enables) according to the strict PCI Express specification.
* **Strict Bus Isolation (Dual-Lens Clocking):** The physical interface enforces a rigorous separation of concerns by using separate drv_cb (active outputs) and mon_cb (passive inputs) clocking blocks to eliminate testbench-to-DUT race conditions.
* **Dynamic Simulation Control:** The environment integrates SystemVerilog +plusargs and the UVM Factory (set_type_override), allowing users to dynamically scale transaction volumes and swap complete test scenarios from the command line without recompiling the codebase.

#### **Architecture Diagram**
         ___________________________________________________________________
        |                            ENVIRONMENT                            |
        |  _______________________________________           _____________  |
        | |               pcie_agent              |         |             | |
        | |  _____________          _____________ |  cpl_ap | Scoreboard  | |
        | | |             |        |             ||-------->|_____________| |
        | | |  Sequencer  |        |   Monitor   ||  req_ap        ^        |
        | | |_____________|        |_____________||--------.       |        |
        | |       |                      ^        |        |   ____|______  |
        | |  _____V_______               |        |        `->|           | |
        | | |             |              |        |           |  Coverage | |
        | | |   Driver    |              |        |           |___________| |
        | | |_____________|              |        |                         |
        | |_______|______________________|________|                         |
        |_________|______________________|__________________________________|
                  | Drives               | Samples both
                  | rx_* wires           | rx_* and tx_* wires
         _________V______________________|__________________________________
        |                                                                   |
        |                    pcie_tlp_if (Virtual Interface)                |
        |___________________________________________________________________|
                                          ^
         _________________________________|_________________________________
        |                                                                   |
        |                        mock_pcie_ep (DUT)                         |
        |___________________________________________________________________|
        
#### **Comprehensive Test Plan Strategy**
Built a robust, multi-phase verification plan spanning positive compliance and negative error handling:

* **Traffic & Throughput Stress:** Verified back-to-back traffic handling, rapid tag avalanches (queue saturation), and data integrity via hostile walking bit patterns.

* **Architectural Corner Cases:** Targeted extreme boundaries including Maximum/Minimum payload sizes, unaligned memory accesses (verifying 7-bit Lower Address calculations), and zero-length read requests.

* **Negative & Protocol Errors:* Injected malformed TLPs (length mismatches), unsupported requests (expecting UR status returns), and out-of-bounds memory tracking.
</details>

### **🌟 AXI-Lite Slave Protocol Checker & UVM Environment (Featured)**

**Overview:** A complete, Object-Oriented UVM testbench and RTL implementation of an Advanced eXtensible Interface (AXI-Lite) Slave IP. The environment is heavily focused on UVM Factory polymorphism, aggressive negative testing, and hardware protection mechanisms.
<details>
         
#### **Project Highlights & Key Features**
* **Polymorphic Test Matrix:** Implemented **6 distinct test scenarios** (Sanity, Read/Write Bursts, and Negative Tests) leveraging the **UVM Factory** to dynamically swap sequences without modifying the core environment.
* **Aggressive Negative Testing:** Targeted edge cases—such as unaligned addresses and out-of-bounds memory requests—verifying the hardware's ability to defend itself and correctly return `SLVERR` (`2'b10`).
* **Protocol-Aware "Smart" Scoreboard:** Developed an advanced scoreboard featuring predictive error handling and bitwise `for`-loops to accurately track byte-level Write Strobe (`wstrb`) memory masks.
* **CI/CD Log Automation:** Wrote a custom Python parsing script utilizing Regex to automatically scrape UVM simulation logs, extract error counts, and calculate final functional coverage metrics for regression triage.
* **Dual FSM RTL Architecture:** Designed the hardware DUT with independent Write and Read state machines to handle concurrent AXI channel processing.

#### **Architecture Diagram**
        _________________________________________________________________
       |                           ENVIRONMENT                           |
       |  _________________                             ______________   |
       | |                 |                           |              |  |
       | |    axi_agent    |                           | Scoreboard   |  |
       | |  _____________  |       _____________       |______________|  |
       | | |             | |      |             |             ^          |
       | | |  Sequencer  | |      |  Coverage   |             |          |
       | | |_____________| |      |_____________|             |          |
       | |       |         |             ^                    |          |
       | |  _____V_______  |             |                    |          |
       | | |             | |             |                    |          |
       | | |   Driver    | |             |                    |          |
       | | |_____________| |             |                    |          |
       | |       |         |             |                    |          |
       | |  _____V_______  |  ___________|____________________|          |
       | | |             | | |                                           |
       | | |   Monitor   |-|-'                                           |
       | | |_____________| |                                             |
       | |_________________|                                             |
       |_________________________________________________________________|
                 | (AW, W, B, AR, R Channels)        ^
         ________V___________________________________|________
        |                                                     |
        |                  AXI-LITE SLAVE DUT                 |
        |_____________________________________________________|

#### **Test Matrix & Coverage Strategy**
* **Merged Coverage Strategy**: Achieved 100.00% Functional Coverage by merging databases across the full regression suite.

* **Targeted Verification**: Negative tests were explicitly constrained to hit invalid memory spaces (ensuring clean SLVERR Scoreboard passes) to prove the hardware's defensive resilience, perfectly complementing the 100% coverage runs of the valid address tests.
</details>

### **🛰️ Synchronous Adder UVM Environment**

**Overview:** A complete, class-based UVM testbench transitioning from a custom layered architecture to a standard UVM factory-based environment.
<details>
         
#### **Architecture & File Structure**

* **my\_adder.sv**: RTL implementation with synchronous reset.  
* **add\_if.sv**: Interface with clocking blocks for strict setup/hold enforcement.  
* **add\_item.sv**: Transaction class (uvm\_sequence\_item) with arithmetic randomization.  
* **driver.sv**: Translates high-level transactions into pin-level signaling via seq\_item\_port.  
* **monitor.sv**: Passive component broadcasting reconstructed transactions via uvm\_analysis\_port.  
* **scoreboard.sv**: Mathematically verifies and coordinates termination.  
* **coverage.sv**: Implements covergroups ensuring 100% functional coverage of the arithmetic state space.

#### **Architecture Diagram**

         ___________________________________________________________________
       |                           ENVIRONMENT                              |
       |   _______________                                                  |
       |  |               |                                                 |
       |  |  add_sequence |                                                 |
       |  |_______________|                                                 |
       |            |                                                       |
       |  __________V_______       ________________      ________________   |
       | |                  |     |                |    |                |  |
       | |  uvm_sequencer   |     |  Scoreboard    |    |   Coverage     |  |
       | |__________________|     |________________|    |________________|  |
       |            |                      ^                      ^         |
       | (seq_item_port/export)            | (ap_imp)             | (ap_imp)|
       |  __________V_______       ________|______________________|_______  |
       | |                  |     |                                      |  |
       | |      Driver      |     |                Monitor               |  |
       | |__________________|     |______________________________________|  |
       |__________|_________________________________^_______________________|
                  |                                 |
            ______V_________________________________|______
           |                       DUT                     |
           |_______________________________________________|


#### **Coverage Report Summary**

* **Cumulative:** **100.00% Functional Coverage**  
* **Cross Coverage (x\_a\_b):** Successfully hit all combinations of 1-bit inputs a and b.
</details>

### **🔢 Full-Duplex UART Transceiver UVM Environment**

**Overview:** A class-based UVM environment for a UART system, decoupling software TB from hardware using synchronous FIFOs and edge-detection synchronization.
<details>
         
#### **Architecture & File Structure**

* **uart\_top.sv**: Static top module instantiating the UVM interface and FIFO-bridged DUT.  
* **uart\_pkg.sv**: Manages strict top-down compilation of the UVM components.  
* **uart\_seq\_item.sv**: Defines 8-bit payload and transmit\_delay with weighted dist constraints.  
* **tx\_agent.sv & rx\_agent.sv**: Containers for drivers, sequencers, and monitors.  
* **uart\_scoreboard.sv**: Uses TLM analysis FIFOs to compare Tx vs. Rx traffic.  
* **uart\_coverage.sv**: Subscriber class tracking payload distribution and stimulus delays.

#### **Architecture Diagram**

       ___________________________________________________________________________
       |                               ENVIRONMENT                               |
       |  _________________                          _________________           |
       | |                 |                        |                 |          |
       | |    tx_agent     |                        |    rx_agent     |          |
       | |  _____________  |       ___________      |  _____________  |          |
       | | |             | |      |           |     | |             | |          |
       | | |  Sequencer  | |      | Scoreboard|     | |  Sequencer  | |          |
       | | |_____________| |      |___________|     | |_____________| |          |
       | |     |     ^     |        ^       ^       |     |     ^     |          |
       | |  ___V_____|___  |        |       |       |  ___V_____|___  |          |
       | | |             | |        |       |       | |             | |          |
       | | |   Driver    |-|----.   |       |       | |   Driver    | |          |
       | | |_____________| |    |   |       |       | |_____________| |          |
       | |  _____________  |    |   |       |       |  _____________  |          |
       | | |             | |    |   |       |       | |             | |          |
       | | | Monitor (Tx)|-|----|--´        `-------|-| Monitor (Rx)| |          |
       | | |_____________| |    |                   | |_____________| |          |
       | |_________________|    |    __________     |_________________|          |
       |                        |   |          |                                 |
       |                        `-->| Coverage |                                 |
       |                            |__________|                                 |
       |_________________________________________________________________________|
               | (UVM writes)                        ^ (UVM reads)
         ______V_______                        ______|_______
        |              |                      |              |
        |   TX FIFO    |                      |   RX FIFO    |
        |______________|                      |______________|

#### **Test Strategy & Constraints**

* **Distribution Shaping:** 20% of traffic forced to 8'h00 and 8'hFF. 60% uses 0 delay to test back-to-back FIFO pressure.  
* **Full-Duplex:** run\_phase triggers parallel Tx/Rx sequences in a fork...join block.  
* **Results:** Achieved **100.00% Coverage** across all payload and delay bins.
</details>

### **💾 Register Space Verification Environment**

Designed a layered, class-based SystemVerilog verification environment for a register design, separating stimulus generation, pin-level driving, and monitoring into distinct, scalable components.

* **Key Features:** Utilized **Constrained-Random Verification (CRV)** with distribution constraints to balance read/write traffic. Successfully reconstructed physical pin-level signaling back into Transaction-Level Models (TLMs) in the monitor and achieved **100% Functional Coverage** across all targeted address banks and operation cross-products.

### **⚖️ Round Robin Arbiter (Priority Masking)**

Designed a hardware arbiter to manage shared bus access across multiple agents without starvation.

* **RTL:** Implemented the "Masking Trick" and Two's Complement fixed-priority engine (req & \-req) for highly optimized, combinational round-robin rotation.

### **⏱️ High-Frequency Interview Modules & CDC**

A collection of industry-standard whiteboarding modules used to solidify Clock Domain Crossing (CDC) and timing concepts.

* **Clock Dividers:** Implemented even and odd clock dividers, including a Divide-by-3 with a perfect **50% duty cycle**.  
* **Sequence Detectors:** Designed overlapping Moore and Mealy FSMs to detect serial streams (e.g., 1101).

## **🛠 RTL Design & Architecture Foundations**

*Essential computer architecture knowledge for hardware engineering.*

### **🚀 RISC-V Processor (Pipelined & Single-Cycle)**

Developed two versions of a RISC-V (RV32I) processor to explore architectural trade-offs.

* **Single-Cycle:** Implemented full data path and control logic for single-cycle execution.  
* **Pipelined:** Designed a 5-stage pipeline featuring hazard detection units and data forwarding logic.

### **🛰️ ADXL345 I2C Accelerometer Controller**

* Implemented a custom **I2C Master Controller** state machine.  
* Deepened protocol-level understanding applicable to creating Verification IPs (VIPs).

## **⚙️ Skills & Technologies**

* **Verification:** SystemVerilog (OOP, Randomization, Coverage, SVA), UVM (Factory, Phasing, TLM, Sequences).  
* **Design:** Verilog-2001, SystemVerilog RTL, FSM Design.  
* **Core Concepts:** CDC, Setup/Hold Timing.  
* **Software:** C/C++, Python, Linux/Unix Shell, Makefile.  
* **EDA Tools:** Metrics DSim, ModelSim/Questa, EDA Playground, Vivado/Quartus.

## **📫 Contact Me**

I am actively seeking full-time opportunities in **ASIC Design Verification** and **RTL Design**.

* **LinkedIn:** [My Profile](https://www.linkedin.com/in/hung-jui-chang-5b755a312/)  
* **Email:** HungJuiChang.us@gmail.com

*Created by Hung*

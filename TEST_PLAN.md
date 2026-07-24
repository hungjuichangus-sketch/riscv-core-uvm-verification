# Ibex Feature-Level Black-Box Verification — Test Plan & Architecture

## 1. Goal

Black-box, feature-level verification of the [lowRISC Ibex](https://github.com/lowRISC/ibex) RV32I core.
Scope is limited to **externally observable correctness**, not internal microarchitecture:

- Memory read/write correctness (loads, stores, byte enables, misalignment)
- Pipeline hazard correctness (RAW / load-use — verified by *effect*, not by probing forwarding muxes)
- Branch correctness (all conditions, taken/not-taken, redirect PC)
- Jump correctness (JAL/JALR, link register)
- Interrupt & exception handling (external/timer/software/fast IRQs, illegal instruction, misaligned access, ecall/ebreak, mret)

Every check is done by comparing DUT behavior against a **golden ISA reference model (Spike)** — never by asserting on internal Ibex signals.

## 2. DUT Configuration

Top level under test: `ibex_top` (`rtl/ibex_top.sv`), built with `` `define RVFI `` enabled.

Recommended **Phase 1** parameterization (keep the port list and behavior space small while the env is being bootstrapped):

| Parameter | Value | Why |
|---|---|---|
| `RV32M` | `RV32MFast` | exercise mul/div hazards |
| `RV32E` | `0` | full 32-register file |
| `ICache` | `0` | avoids icache RAM-cfg ports and refill timing until core env is solid |
| `SecureIbex` | `0` | avoids scrambling interface / dummy instructions |
| `WritebackStage` | `0` | 2-stage pipeline first; flip to `1` later as a stretch goal (3-stage, more hazard surface) |
| `PMPEnable` | `0` | add in Phase 3 as a stretch goal (feeds exception testing) |

Stretch goals for later phases: `WritebackStage=1`, `PMPEnable=1`, `RV32B` — each adds real verification surface without changing the methodology.

## 3. DUT Interfaces (confirmed from `rtl/ibex_top.sv`)

**Instruction memory (fetch):**
`instr_req_o`, `instr_gnt_i`, `instr_rvalid_i`, `instr_addr_o`, `instr_rdata_i`, `instr_err_i`

**Data memory (load/store):**
`data_req_o`, `data_gnt_i`, `data_rvalid_i`, `data_we_o`, `data_be_o`, `data_addr_o`, `data_wdata_o`, `data_rdata_i`, `data_err_i`

Both are the standard req/grant/rvalid handshake — your UVM environment plays the role of instruction and data memory, so your **driver responds to fetch requests** and your **monitor/scoreboard observes data transactions**.

**Interrupts:**
`irq_software_i`, `irq_timer_i`, `irq_external_i`, `irq_fast_i[14:0]`, `irq_nm_i` (NMI)

**Debug:** `debug_req_i`, `crash_dump_o`, `double_fault_seen_o` — out of scope for Phase 1/2, possible stretch goal.

**RVFI (RISC-V Formal Interface)** — your primary checking interface, emitted once per retired instruction:
`rvfi_valid`, `rvfi_order`, `rvfi_insn`, `rvfi_trap`, `rvfi_intr`, `rvfi_rs1/2/3_addr`, `rvfi_rs1/2/3_rdata`, `rvfi_rd_addr`, `rvfi_rd_wdata`, `rvfi_pc_rdata`, `rvfi_pc_wdata`, `rvfi_mem_addr`, `rvfi_mem_rmask`, `rvfi_mem_wmask`, `rvfi_mem_rdata`, `rvfi_mem_wdata`

This is the key point: RVFI gives you retired-instruction PC, register writeback, and memory access **without touching internal pipeline registers**. It's a standard, documented verification port — still black-box in spirit.

## 4. Verification Architecture

```
                    ________________________________________________
                   |                  UVM ENVIRONMENT                |
                   |                                                  |
                   |   ______________        ____________________    |
                   |  |              |      |                    |   |
                   |  |  Sequencer   |----->|   Instr Mem Agent   |   |
                   |  | (instr progs)|      | (driver = fetch mem)|   |
                   |  |______________|      |____________________|   |
                   |                                  |               |
                   |   ____________________            v              |
                   |  |                    |    instr_req/addr        |
                   |  |  Data Mem Agent    |<----- to DUT ------->    |
                   |  | (driver = data mem)|                          |
                   |  |____________________|                          |
                   |                                                  |
                   |   ____________________                           |
                   |  |                    |   drives irq_* at        |
                   |  |   IRQ/Exception    |-- randomized/directed --> |
                   |  |   Sequencer        |      points               |
                   |  |____________________|                           |
                   |                                                  |
                   |   ____________________       ________________    |
                   |  |                    |     |                |   |
                   |  |  RVFI Monitor      |---->|   Scoreboard   |   |
                   |  |  (samples RVFI     |     |  (per-retired- |   |
                   |  |   each retire)     |     |   instr diff   |   |
                   |  |____________________|     |  vs Spike)     |   |
                   |                              |________________|   |
                   |                                      ^            |
                   |                              ________|_______     |
                   |                             |  Spike (ISS)   |    |
                   |                             |  golden model  |    |
                   |                             |________________|    |
                   |                                                  |
                   |   ____________________                           |
                   |  |   Coverage         |  sampled from RVFI +     |
                   |  |   Collector        |  irq stimulus            |
                   |  |____________________|                           |
                   |__________________________________________________|
                                       |
                                       v
                        ______________________________
                       |         ibex_top (DUT)         |
                       |______________________________ |
```

**Key design decision:** the *same* instruction stream (hand-written or randomly generated) is fed to both the DUT (via the instr mem agent) and Spike (run standalone, log/trace mode). The scoreboard diffs the two instruction-retirement traces field by field. This is the same "step-and-compare" approach Ibex's own `dv/uvm/core_ibex` env and Google's `riscv-dv` use — you're implementing the same industry-standard methodology yourself, at a reduced scope.

## 5. Feature Test Plan

### 5.1 Memory read/write
- LB/LH/LW/LBU/LHU, SB/SH/SW — check `rvfi_mem_addr/rmask/wmask/rdata/wdata` vs Spike
- Byte-enable correctness for sub-word stores
- Misaligned access — **empirically confirmed NOT to trap** on this config: Ibex's LSU handles misaligned loads and stores transparently in hardware via two internal aligned bus transactions, reassembled/split across the word boundary. Confirmed by hand-verified directed asm test (`sim/my_asm_test_sw/my_asm_test_impl.S`) for both a misaligned `lw` (read split correctly, e.g. `sw`+misaligned `lw` reassembled bytes across a word boundary bit-exact) and a misaligned `sw` (write correctly split bytes across two adjacent words, bit-exact on both sides), zero exceptions in either case. Verify via `rvfi_mem_addr/rmask/wmask/rdata/wdata` bit-correctness across the word boundary — **not** via `rvfi_trap`, since none is raised. (Original plan assumed a trap; that assumption was wrong for this DUT config and has been corrected here.)
- Back-to-back loads/stores to same and different addresses

### 5.2 Pipeline hazards (verified by effect, not by design intent)
- RAW hazard: `addi x1,x0,5 / add x2,x1,x1` — result must reflect updated x1
- Load-use hazard: `lw x1,0(x2) / add x3,x1,x1` — stall must not corrupt result
- Back-to-back mul/div feeding a dependent instruction
- Hazard immediately followed by a branch/jump that depends on the hazarded register

### 5.3 Branching
- BEQ/BNE/BLT/BGE/BLTU/BGEU — taken and not-taken, forward and backward targets
- Branch immediately after another branch (back-to-back redirects)
- Branch target crossing instruction-fetch alignment boundaries (relevant once `C` extension is in scope)

### 5.4 Jump
- JAL / JALR — link register correctness (`rd = pc+4`), including `rd = x0` (no writeback)
- JALR with unaligned target (should trap per spec unless C extension enabled)

### 5.5 Interrupts & exceptions
- Each `irq_*` line asserted individually and in combination, at random cycles including mid multi-cycle instruction (mul/div)
- Verify redirect to `mtvec`, correct `mepc`, correct `mcause`, and `mret` returning to the right PC
- Illegal instruction, ecall, ebreak, misaligned instruction/data access exceptions
- Nested/back-to-back interrupts

## 6. Functional Coverage (sketch)

- Instruction type × hazard-distance cross (0/1/2 cycle separation between producer/consumer)
- Branch condition × taken/not-taken × target direction
- Each `mcause` value hit at least once
- Interrupt assertion point × in-flight instruction type (single-cycle vs mul/div)
- Memory access size × alignment × address region

## 7. Repo & File Setup

**Don't cherry-pick RTL files.** `ibex_core.core` (FuseSoC manifest) shows `ibex_core.sv` alone depends on ~19 other files under `rtl/`, plus external `lowrisc:prim:*` packages (assert, clock_gating, lfsr, mubi) that live in `vendor/lowrisc_ip`. Pulling individual `.sv` files will not compile.

**Recommended approach:** add the Ibex repo as a **git submodule** under `dut/ibex` (or `vendor/ibex`), and keep 100% of your own verification code in a separate top-level directory (e.g. `tb/` or `verif/`). This:
- Mirrors how real projects vendor DUT/IP code
- Makes it obvious in the repo (and to anyone reviewing it) exactly which lines are yours
- Lets you pin/update the DUT version deliberately

What you'll actually reference from the cloned repo:
- `rtl/*` + `vendor/lowrisc_ip` — the DUT itself (compiled as-is, never edited)
- `rtl/ibex_top.sv`, `rtl/ibex_core.sv` — for the exact port list (Section 3 above)
- `ibex_core.core` / `ibex_top.core` — authoritative file/dependency list if you hand-roll a filelist for your simulator instead of using FuseSoC
- `examples/simple_system/` — a minimal Verilator harness with a simple RAM wired to the instr/data memory interface. **Worth reading**, not reusing wholesale — it shows exactly how to satisfy the req/gnt/rvalid handshake, which your UVM memory-response driver needs to replicate.
- `dv/uvm/core_ibex/` — **Ibex's own existing verification environment** (built on `riscv-dv` + Spike cosim). Study this for ideas on RVFI hookup and cosim structure, but **do not copy it into your own env** — that would undercut the entire point of the project as a demonstration of your own work. Treat it the way you'd treat reading someone else's solution to learn the pattern, then close the tab and write your own.
- `doc/` — read online or locally for the integration/RVFI spec; you don't need to vendor it.

**What you will need separately (not fully vendored in-repo):** Spike (`riscv-isa-sim`) itself. Ibex's `vendor/riscv-isa-sim` only contains a license file, arch-test target, and tests — not the simulator source. You'll need to clone and build [riscv-software-src/riscv-isa-sim](https://github.com/riscv-software-src/riscv-isa-sim) yourself as your golden reference model.

## 8. Proposed Directory Structure

```
RSIC-V Core Testbench/
├── README.md
├── TEST_PLAN.md
├── dut/
│   └── ibex/              (git submodule, untouched)
├── ref_model/
│   └── (Spike build / wrapper scripts)
├── tb/
│   ├── ibex_pkg/          (your UVM package)
│   ├── agents/
│   │   ├── instr_mem_agent/
│   │   ├── data_mem_agent/
│   │   └── irq_agent/
│   ├── env/
│   │   ├── rvfi_monitor.sv
│   │   ├── scoreboard.sv   (RVFI vs Spike diff)
│   │   └── coverage.sv
│   ├── seq/
│   │   ├── directed/       (hand-written hazard/branch/irq programs)
│   │   └── random/         (constrained-random instruction streams)
│   └── top/
│       └── tb_top.sv
└── sim/
    └── (Makefile / filelist / regression scripts)
```

## 9. Weekly Timeline & Progress Tracker (10 weeks)

Nothing from the original 12-week scope is dropped. Instead, three items that don't strictly need to wait until the end are moved earlier, into weeks that have natural room because they piggyback on work already happening there:

- **IRQ agent** build moves from the old "Phase 5" into Week 3, alongside the other two agents (same kind of work, same sitting).
- **Regression automation script** moves from the old "polish" week into Week 7 — you need repeatable regression running for random-gen anyway, so build it once and reuse it, instead of writing it twice.
- **Documentation** (README, architecture diagram) becomes a light continuous habit (a few lines updated each week) instead of a single write-up crammed at the end.

That leaves Week 10 carrying only what's genuinely last-in-sequence: interrupt corner cases that depend on everything else existing, and coverage closure.

**Risk to watch:** Verilator and Spike aren't native Windows tools — Week 1 likely needs a WSL2/Linux environment. If that's not already set up, it's the most likely place this schedule slips.
**Where this is tight:** Weeks 3, 6, and 7 each now carry two work-streams instead of one. If any single week overruns, that's where it'll happen — treat those as the weeks to check in on progress most closely.

### Week 1
- [x] WSL2/Linux toolchain environment set up (Verilator + Spike build dependencies)
- [x] Ibex submodule compiles standalone (elaborates `ibex_top`, no testbench yet)

### Week 2
- [x] Spike (`riscv-isa-sim`) built and runs a sample RV32IM ELF
- [x] Spike trace/log output format understood (what you'll diff against later)

### Week 3
- [ ] Instr mem agent (driver responds to fetch req/gnt/rvalid)
- [ ] Data mem agent (driver responds to load/store req/gnt/rvalid)
- [ ] IRQ agent skeleton (driver can assert `irq_*` lines on command — sequences come later)

### Week 4
- [ ] `tb_top.sv` wires up DUT + agents + clk/reset
- [ ] One hand-written directed program runs end-to-end (visual waveform trace only, no scoreboard yet)
- [ ] README: short "environment architecture" section drafted from what's actually built so far

### Week 5
- [ ] RVFI monitor samples and packages retired-instruction transactions
- [ ] Spike cosim wrapper produces a comparable per-instruction trace

### Week 6
- [ ] Scoreboard diffs DUT vs Spike field-by-field
- [ ] Directed tests from Week 4 pass cleanly through the scoreboard
- [ ] First directed IRQ test (single interrupt, simple case) run through the scoreboard using the Week 3 IRQ agent

### Week 7
- [ ] Constrained-random instruction stream generator (hazard-distance, branch/jump-weighted)
- [ ] Regression automation script (single command, pass/fail summary) — built now so Week 8's random runs use it from day one

### Week 8
- [ ] Random IRQ/exception injection sequences
- [ ] Functional coverage model (Section 6) implemented and sampling

### Week 9
- [ ] First full regression (random + directed) passes clean
- [ ] README: coverage/methodology section updated with real numbers

### Week 10
- [ ] Interrupt/exception corner cases closed out (nested IRQs, `mcause` coverage)
- [ ] Coverage closure pass (fill remaining bins or document waivers)
- [ ] Final README pass + architecture diagram polish for portfolio


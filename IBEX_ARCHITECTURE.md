# Ibex Architecture — Verification Reference

This is **not** a replacement for Ibex's own documentation — it's a distillation of exactly what you need to build the agents, hazard tests, and scoreboard described in `TEST_PLAN.md`, with pointers back to the authoritative source for anything deeper.

**Canonical docs, for anything not covered here:**
- Local, in the submodule: `dut/ibex/doc/03_reference/` (`.rst` source — pipeline_details, instruction_fetch, load_store_unit, exception_interrupts, rvfi, cs_registers, etc.)
- Hosted, rendered: https://ibex-core.readthedocs.io/

Everything below assumes the **Phase 1 parameterization from `TEST_PLAN.md` Section 2**: `WritebackStage=0` (2-stage pipeline), `ICache=0`, `SecureIbex=0`, `PMPEnable=0`.

---

## 1. Pipeline: 2 stages, not 5

Ibex has just two stages:

| Stage | Does |
|---|---|
| **IF** (Instruction Fetch) | Fetches via a prefetch buffer, 1 instruction/cycle if memory keeps up |
| **ID/EX** (Decode + Execute) | Decodes and *immediately* executes — register read **and** write happen in the same stage |

Every instruction takes a minimum of 2 cycles (1 in IF, 1 in ID/EX). Multi-cycle instructions just **stall the ID/EX stage** — there's no separate stall/hazard-detection unit forwarding data between stages the way a classic 5-stage pipeline needs, because there's only one execute stage to stall. This is *why* Ibex's hazard behavior (Section 5.2 of `TEST_PLAN.md`) is simpler to reason about than a deeper pipeline: a RAW hazard one instruction apart is resolved by the producer having already retired (written the regfile) before the consumer's ID/EX cycle even begins, **as long as the producer didn't stall**. Your hazard tests are really testing "does the core correctly stall/serialize when the producer *does* take multiple cycles" (loads, mul/div), not classic forwarding-mux correctness.

### Per-instruction-type stall cycles (drives your directed hazard tests)

| Instruction type | Stall cycles | Note |
|---|---|---|
| Integer computational, CSR access | 0 | Single-cycle, no hazard window |
| Load/Store | 1 – N | Stalls until `data_rvalid_i`; N depends on your data-mem agent's response latency |
| MUL | 0 (single-cycle) / 2 (fast) | Depends on `RV32M` param (`RV32MFast` per Phase 1 config → 2 cycles) |
| MULH | 1 (single-cycle) / 3 (fast) | |
| DIV/REM | 1 (div-by-zero) or 37 (full division) | Worth a directed test for both paths |
| Jump (JAL/JALR) | 1 – N | New PC hits `instr_addr_o` the *same cycle* the jump enters ID/EX; stall length = however long your instr-mem agent takes to respond |
| Branch, not taken | 0 | |
| Branch, taken | 2 – N (or 1 – N with `BranchTargetALU=1`, not in Phase 1 config) | ALU computes condition cycle 1, target cycle 2, **then** behaves like a jump |

**Direct implication for your Week 3 agents:** your instr/data mem agent's response latency (how many cycles between granting a request and asserting `rvalid`) is not a side detail — it *is* the stall length the DUT will exhibit. Vary it (immediate response vs. multi-cycle delay) deliberately in your agents; that's your main lever for hitting different points in the "hazard-distance" coverage cross in `TEST_PLAN.md` Section 6.

---

## 2. Memory interface protocol (instruction *and* data side)

Both `instr_*` and `data_*` interfaces (see `TEST_PLAN.md` Section 3 for the full signal list) use the **same request/grant/valid handshake** — data adds `we`/`be`/`wdata` for writes, instruction side is read-only.

**The protocol, in order:**
1. DUT asserts `req` + `addr` (+ `we`/`be`/`wdata` for data writes). Must hold `req` high until granted.
2. Your agent asserts `gnt` for exactly one cycle, any number of cycles after `req` goes high (can even be the same cycle). Once granted, the DUT is free to change `addr`/`wdata`/`we`/`be` the *next* cycle — your agent must have already captured/stored what it needs.
3. Your agent asserts `rvalid` for **exactly one cycle** some time later, presenting `rdata`/`err` in that same cycle.
4. **Multiple outstanding requests must be serviced in-order** — if you accept a second request before responding to the first, the two `rvalid` pulses must come back in the order the requests were granted. This matters directly for your "back-to-back loads/stores" test in Section 5.1.

This is exactly the `req`/`gnt`/`rvalid` split-transaction protocol your driver needs to implement in the instr mem agent and data mem agent (Week 3). The key driver decision you get to make per-transaction is **how many cycles to wait before granting, and how many more before asserting rvalid** — that's your test knob for stall-cycle/hazard-distance coverage, not something fixed by the DUT.

**Misaligned accesses** (both instruction and data side): the DUT does **not** send you one misaligned transaction — it splits it into two separate word-aligned transactions itself and issues them as two ordinary requests. Your agent doesn't need special-case misalignment logic; it just needs correct in-order multi-request handling and it'll see two aligned accesses. If the first of the two gets an error response, the second is still issued (but its response is ignored by the DUT) — worth knowing so you don't misinterpret that second transaction in your scoreboard.

---

## 3. Exceptions & interrupts — what actually happens on trap entry/exit

Relevant CSRs: `mepc` (saved PC), `mstatus` (MIE/MPIE bits), `mtvec` (handler base), `mcause`.

- **Entry:** `mepc ← current PC`, `mstatus.MPIE ← mstatus.MIE`, `mstatus.MIE ← 0` (hardware auto-disables interrupts on trap entry — a nested-interrupt test needs the handler to explicitly re-enable via `mstatus.MIE=1` to see a second interrupt land).
- **Exceptions** jump straight to `mtvec` base.
- **Interrupts** are *vectored*: jump to `mtvec base + 4 × interrupt ID`. This means your IRQ agent needs to know each interrupt's ID to predict where the DUT should land:

| Signal | ID | Priority note |
|---|---|---|
| `irq_nm_i` (NMI) | 31 | Highest priority; bypasses `mstatus`/`mie` entirely; not visible in `mip` |
| `irq_fast_i[14:0]` | 30:16 | Platform-defined; in Ibex these outrank everything except NMI; lowest ID wins among fast IRQs |
| `irq_external_i` | 11 | |
| `irq_timer_i` | 7 | |
| `irq_software_i` | 3 | |

- **Exit:** `MRET` restores `mstatus.MIE ← mstatus.MPIE` and jumps to `mepc`.
- **All interrupt lines are level-sensitive** — your IRQ agent must hold the line high until the (simulated) handler "services" it, not pulse it. A directed test should confirm the DUT doesn't re-trap on an already-serviced-but-still-asserted line inappropriately, and does re-trap correctly if you deliberately leave it asserted.
- **Exception causes you can actually hit in Phase 1 config** (`PMPEnable=0`, so PMP-related faults are out of scope): illegal instruction (2), breakpoint/ebreak (3), load access fault (5), store access fault (7), ECALL from U-mode (8) / M-mode (11). This is your concrete `mcause` coverage list for Section 6 — five reachable synchronous causes, not the full RISC-V table.
- **Nesting is entirely software-controlled**, not automatic — the hardware only disables interrupts on entry. Your "nested/back-to-back interrupts" test (Section 5.5) is really testing: does the DUT correctly re-trap when your directed program's simulated handler re-enables `MIE` mid-handler and a second, lower-or-equal-priority IRQ is still pending?

---

## 4. How this maps back to your Week-by-Week plan

| `TEST_PLAN.md` item | What above section to lean on |
|---|---|
| Week 3: instr/data mem agents | §2 (protocol) — your driver's grant/rvalid timing choices *are* the test knob |
| Week 3: IRQ agent skeleton | §3 (levels not pulses, vectored addressing) |
| Week 5: RVFI monitor + Spike cosim | `dut/ibex/doc/03_reference/rvfi.rst` + `TEST_PLAN.md` §3 signal list (this doc doesn't duplicate that) |
| Section 5.2 hazard tests | §1 (stall table) — pick producer instructions by their stall cycles to hit different hazard distances |
| Section 5.5 interrupt/exception tests | §3, directly |
| Section 6 coverage (mcause bins) | §3's 5-cause table — that's your actual reachable coverage space in Phase 1 config |

If you later flip on `WritebackStage=1` or `PMPEnable=1` as stretch goals, §1's stall table and §3's exception-cause list both need revisiting — the 2-stage assumptions and the reduced exception set are specific to the Phase 1 config, not general Ibex facts.

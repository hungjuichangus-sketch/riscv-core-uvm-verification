# RISC-V RV32IMC Assembly Cheat Sheet

A working reference for writing test programs by hand in `sim/*_sw/*.S`. Covers registers, load/store naming, and the common instructions you'll actually reach for.

---

## Naming convention: what the letters mean

This is the part that trips people up, so spelling it out directly:

| Letter | Means | Not |
|---|---|---|
| **B** | **Byte** (8 bits) | — |
| **H** | **Halfword** (16 bits) | NOT "High" |
| **W** | **Word** (32 bits) | — |
| **U** suffix | **Unsigned** — zero-extend into the register | NOT "Upper" |
| *(no U)* | **Signed** — sign-extend into the register | — |

So:
- `LB` = Load **B**yte, sign-extended
- `LBU` = Load **B**yte, **U**nsigned (zero-extended) — *not* "load byte upper"
- `LH` = Load **H**alfword (16-bit), sign-extended — *not* "load high"
- `LHU` = Load **H**alfword, **U**nsigned (zero-extended)
- `LW` = Load **W**ord (32-bit) — no U variant exists, because a 32-bit load into a 32-bit register needs no extension either way

Stores (`SB`/`SH`/`SW`) never have a U variant — extension only matters when a smaller value is being *widened into* a register, and stores go the other direction (register → memory), so there's nothing to sign/zero-extend.

**Sign- vs zero-extend, concretely:** loading the byte `0xFF` —
- `LB` → `0xFFFFFFFF` (treated as -1, sign bit replicated upward)
- `LBU` → `0x000000FF` (treated as 255, zeros padded upward)

---

## Load / Store instructions

| Instruction | Size | Extension | Syntax |
|---|---|---|---|
| `LB rd, imm(rs1)` | 8-bit | sign | `rd = mem[rs1+imm]`, sign-extended |
| `LBU rd, imm(rs1)` | 8-bit | zero | `rd = mem[rs1+imm]`, zero-extended |
| `LH rd, imm(rs1)` | 16-bit | sign | `rd = mem[rs1+imm]`, sign-extended |
| `LHU rd, imm(rs1)` | 16-bit | zero | `rd = mem[rs1+imm]`, zero-extended |
| `LW rd, imm(rs1)` | 32-bit | n/a | `rd = mem[rs1+imm]` |
| `SB rs2, imm(rs1)` | 8-bit | n/a | `mem[rs1+imm] = rs2[7:0]` |
| `SH rs2, imm(rs1)` | 16-bit | n/a | `mem[rs1+imm] = rs2[15:0]` |
| `SW rs2, imm(rs1)` | 32-bit | n/a | `mem[rs1+imm] = rs2` |

Note the operand order difference: loads write to `rd` (destination first, like most instructions); stores read from `rs2` but it's still written *first* in the syntax even though memory is the destination — `SW rs2, imm(rs1)` means "store rs2 into memory at address rs1+imm", not "store into rs2".

---

## Registers

| Register | ABI name | Purpose | Saved by |
|---|---|---|---|
| x0 | `zero` | hardwired constant 0 (writes are discarded) | — |
| x1 | `ra` | return address | **caller** |
| x2 | `sp` | stack pointer | callee |
| x3 | `gp` | global pointer | — |
| x4 | `tp` | thread pointer | — |
| x5–x7 | `t0`–`t2` | temporaries | **caller** |
| x8 | `s0`/`fp` | saved register / frame pointer | callee |
| x9 | `s1` | saved register | callee |
| x10–x11 | `a0`–`a1` | function args / return values | **caller** |
| x12–x17 | `a2`–`a7` | function args | **caller** |
| x18–x27 | `s2`–`s11` | saved registers | callee |
| x28–x31 | `t3`–`t6` | temporaries | **caller** |

**"Saved by caller" vs "saved by callee" — why this matters (this is the exact bug you just hit with `ra`):**
- **Caller-saved** (`ra`, `t0`–`t6`, `a0`–`a7`): a function is free to overwrite these without asking. If *you* need a caller-saved register's value to survive a `call`, **you** must save it yourself (push to stack) before the call and restore it after.
- **Callee-saved** (`sp`, `s0`–`s11`): if a function *uses* one of these, it must save the original value at entry and restore it before returning — the caller is trusting it'll come back unchanged.

This is why `main` needed `sw ra, 12(sp)` before calling `puts`/`puthex`: `ra` is caller-saved, `puts` is allowed to clobber it, and `main` needed its own original `ra` back afterward.

---

## Arithmetic / logic (register-register and register-immediate)

| Instruction | Operation |
|---|---|
| `ADD rd, rs1, rs2` | `rd = rs1 + rs2` |
| `ADDI rd, rs1, imm` | `rd = rs1 + imm` |
| `SUB rd, rs1, rs2` | `rd = rs1 - rs2` (no `SUBI` — use `ADDI` with a negative immediate) |
| `AND rd, rs1, rs2` / `ANDI rd, rs1, imm` | bitwise AND |
| `OR rd, rs1, rs2` / `ORI rd, rs1, imm` | bitwise OR |
| `XOR rd, rs1, rs2` / `XORI rd, rs1, imm` | bitwise XOR |
| `SLL rd, rs1, rs2` / `SLLI rd, rs1, imm` | shift left logical |
| `SRL rd, rs1, rs2` / `SRLI rd, rs1, imm` | shift right logical (zero-fill) |
| `SRA rd, rs1, rs2` / `SRAI rd, rs1, imm` | shift right arithmetic (sign-fill) |
| `SLT rd, rs1, rs2` / `SLTI rd, rs1, imm` | `rd = (rs1 < rs2) ? 1 : 0`, signed |
| `SLTU rd, rs1, rs2` / `SLTIU rd, rs1, imm` | same, unsigned |
| `MUL rd, rs1, rs2` | `rd = (rs1 * rs2)` low 32 bits (M extension) |
| `DIV rd, rs1, rs2` / `REM rd, rs1, rs2` | signed divide / remainder (M extension) |
| `LUI rd, imm` | `rd = imm << 12` (load upper 20 bits) |
| `AUIPC rd, imm` | `rd = PC + (imm << 12)` |

---

## Branches and jumps

| Instruction | Taken when |
|---|---|
| `BEQ rs1, rs2, label` | `rs1 == rs2` |
| `BNE rs1, rs2, label` | `rs1 != rs2` |
| `BLT rs1, rs2, label` | `rs1 < rs2` (signed) |
| `BGE rs1, rs2, label` | `rs1 >= rs2` (signed) |
| `BLTU rs1, rs2, label` | `rs1 < rs2` (unsigned) |
| `BGEU rs1, rs2, label` | `rs1 >= rs2` (unsigned) |
| `JAL rd, label` | jump to label, `rd = return address` (`JAL x0,...` = plain jump, no link) |
| `JALR rd, imm(rs1)` | jump to `rs1+imm`, `rd = return address` — used for indirect jumps/returns |

---

## Common pseudo-instructions (expanded by the assembler into real instructions)

| Pseudo | Expands to / meaning |
|---|---|
| `LI rd, imm` | loads any 32-bit constant (`lui`+`addi` if needed) |
| `LA rd, symbol` | loads a symbol's address (`auipc`+`addi`) |
| `MV rd, rs` | `rd = rs` (really `addi rd, rs, 0`) |
| `NOP` | does nothing (really `addi x0, x0, 0`) |
| `J label` | unconditional jump, no return address kept (`jal x0, label`) |
| `CALL label` | function call, saves return address in `ra` |
| `RET` | return from function (really `jalr x0, 0(ra)`) |
| `BEQZ rs, label` / `BNEZ rs, label` | branch if `rs == 0` / `rs != 0` |

---

## Quick lookup for "what should I use to test X"

| You want to test... | Reach for |
|---|---|
| Sign vs zero extension | `LB` vs `LBU` (or `LH` vs `LHU`) on a value with the high bit set, e.g. `0xFF` or `0x80` |
| Byte-enable correctness | `SB` to sub-word addresses, then `LW` the whole word and check only the targeted byte changed |
| Misaligned access | An address not naturally aligned for the access size (Ibex splits this into two transactions itself — see `IBEX_ARCHITECTURE.md` §2) |
| Load-use hazard | A load immediately followed by an instruction that consumes the loaded register |
| RAW hazard (non-load) | A cheap instruction (e.g. `ADDI`) immediately followed by one consuming its result |

#!/usr/bin/env bash
# Build and run a sim/<name>_sw/ program against Ibex's simple_system
# (Verilator) harness. Stages a copy under $HOME first because GNU Make
# and Verilator's generated Makefiles both refuse to build in a path
# containing spaces, which this repo's own path does.
#
# Usage: ./run_sw_test.sh <test_dir_name>
#   e.g. ./run_sw_test.sh my_asm_test_sw

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <test_dir_name>  (e.g. my_asm_test_sw)"
    exit 1
fi

TEST_NAME="$1"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_DIR/sim/$TEST_NAME"
STAGE_DIR="$HOME/ibex_builds/$TEST_NAME"
COMMON_DIR="$HOME/ibex_builds/common"
SIM_BIN="$HOME/ibex_builds/simple_system/lowrisc_ibex_ibex_simple_system_0/sim-verilator/Vibex_simple_system"
RUN_DIR="$HOME/ibex_builds/${TEST_NAME}_run"

if [ ! -d "$SRC_DIR" ]; then
    echo "No such test directory: $SRC_DIR"
    exit 1
fi
if [ ! -d "$COMMON_DIR" ]; then
    echo "Missing $COMMON_DIR -- copy dut/ibex/examples/sw/simple_system/common there first."
    exit 1
fi
if [ ! -x "$SIM_BIN" ]; then
    echo "Missing simple_system simulator binary at $SIM_BIN -- build it first via fusesoc."
    exit 1
fi

echo "== staging & building =="
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
cp "$SRC_DIR"/* "$STAGE_DIR"/
( cd "$STAGE_DIR" && make CC=riscv64-unknown-elf-gcc ARCH=rv32imc_zicsr_zifencei \
    IBEX_COMMON_DIR="$COMMON_DIR" 2>&1 | grep -v "srec_cat\|No such file or directory\|Error 127" || true )

ELF="$STAGE_DIR/$TEST_NAME.elf"
if [ ! -f "$ELF" ]; then
    # PROGRAM name in the Makefile may differ from the directory name --
    # fall back to whatever .elf actually got produced.
    ELF="$(find "$STAGE_DIR" -maxdepth 1 -name '*.elf' | head -1)"
fi
if [ -z "$ELF" ] || [ ! -f "$ELF" ]; then
    echo "Build did not produce an .elf file -- see build output above."
    exit 1
fi
echo "Built: $ELF"

echo "== running =="
rm -rf "$RUN_DIR"
mkdir -p "$RUN_DIR"
( cd "$RUN_DIR" && timeout 15 "$SIM_BIN" --meminit=ram,"$ELF" )

echo "== program output =="
cat "$RUN_DIR/ibex_simple_system.log" 2>/dev/null || echo "(no output log produced)"
echo
echo "Instruction trace: $RUN_DIR/trace_core_00000000.log"

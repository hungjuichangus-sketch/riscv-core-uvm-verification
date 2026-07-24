# Builds mem_test.c against Ibex's own simple_system software framework
# (dut/ibex/examples/sw/simple_system/common), referenced read-only from
# the submodule -- nothing under dut/ibex is modified.

PROGRAM = mem_test
PROGRAM_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
EXTRA_SRCS :=
IBEX_COMMON_DIR := $(PROGRAM_DIR)/../../dut/ibex/examples/sw/simple_system/common

include $(IBEX_COMMON_DIR)/common.mk

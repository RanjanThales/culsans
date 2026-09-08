# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

  ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
  TESTNAME := $(notdir $(patsubst %/,%,$(ROOT_DIR)))
  include ../../test_automation/Makefile


UVM_TEST_CLASS := $(TESTNAME)_test
VSIM_FLAGS += +UVM_TESTNAME=$(UVM_TEST_CLASS) +TESTNAME=$(TESTNAME)  


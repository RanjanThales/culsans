package tb_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;
`include "./env/culsans_env_config.sv"
`include "./env/dcache_req_sequence_item.sv"
`include "./env/dcache_resp_sequence_item.sv"
`include "./seq_lib/dcache_sequence.sv"
`include "./env/mcache_monitor.sv"
`include "./env/ace_cov_monitor.sv"
`include "./env/dcache_monitor.sv"
`include "./env/dcache_driver.sv"
`include "./env/dcache_sequencer.sv"
`include "./env/dcache_agent.sv"
`include "./env/culsans_env.sv"
`include "./env/culsans_base_test.sv"
//`include "culsans_multicore_assertions.sv"

//Sequences
//`include "../sequences/diff_cache_line_interference_test.sv"
`include "./tests_lib/multicore_ACE_data_con_op_test_01.sv"
`include "./tests_lib/multicore_ACE_data_con_op_test_02.sv"
`include "./tests_lib/cache_line_rw_colision_test.sv"
`include "./tests_lib/read_miss_test.sv"
`include "./tests_lib/cache_evict.sv"
`include "./tests_lib/sample_test.sv"


endpackage

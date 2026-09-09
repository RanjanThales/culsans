`include "uvm_macros.svh" 
import uvm_pkg::*; 
import ariane_pkg::*; 
import snoop_test::*; 
import ace_test::*; 
import tb_ace_ccu_pkg::*; 
import tb_std_cache_subsystem_pkg::*; 
import tb_pkg::*;
//`include "culsans_env.sv"
///------------------------------------------------------------------------------
// Base test class for Culsans verification environment
//------------------------------------------------------------------------------
class culsans_base_test extends uvm_test;
  `uvm_component_utils(culsans_base_test)

  //--------------------------------------------------------------------------
  // Variables
  //--------------------------------------------------------------------------
  string testname;
  uvm_event finish_event;

  culsans_enviroment  c_env_h;
  culsans_env_config  c_env_cfg;
  ace_env_config      ace_env_cfg;

 uvm_tree_printer tree_printer;
 
  // Sequences
  write_dcache    w_dseq;
  read_dcache     r_dseq;
  read2_dcache    r2_dseq;
  pre_seq         p_seq;
  write_seq       w_seq;
  write1_seq      w1_seq;
  read_seq        r_seq;

  string seqr_name;
  virtual clk_rst_intf clk_rst_if;

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name = "culsans_base_test", uvm_component parent = null);
    super.new(name, parent);
    finish_event = new("finish_event");
  endfunction

  //--------------------------------------------------------------------------
  // Build Phase
  //--------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

        tree_printer = new();
    if (!$value$plusargs("TESTNAME=%s", testname)) begin
      `uvm_fatal("TESTNAME", "No +TESTNAME argument provided")
    end else begin
      `uvm_info("TESTNAME", $sformatf("TESTNAME = %s", testname), UVM_LOW)
    end

    uvm_config_db#(uvm_event)::set(this, "*", "finish_event", finish_event);

    if (!uvm_config_db#(virtual clk_rst_intf)::get(this, "*", "clk_rst_if", clk_rst_if)) begin
      `uvm_fatal("NO_CLK_RST_INTF", "clk_rst_if not found in config db!")
    end

    // Create env and config
    c_env_h  = culsans_enviroment::type_id::create("c_env_h", this);
    c_env_cfg = culsans_env_config::type_id::create("c_env_cfg", this);
    ace_env_cfg = ace_env_config::type_id::create("ace_env_cfg", this);
    c_env_cfg.N_D = 3;
    c_env_cfg.N_C = culsans_pkg::NB_CORES;
    ace_env_cfg.NO_OF_AGENTS = 4;
    uvm_config_db#(culsans_env_config)::set(this, "*", "culsans_env_config", c_env_cfg);
    uvm_config_db#(ace_env_config)::set(this, "*", "ace_env_config", ace_env_cfg);

    // Create sequences
    w_dseq = write_dcache::type_id::create("w_dseq");
    r_dseq = read_dcache::type_id::create("r_dseq");
    r2_dseq = read2_dcache::type_id::create("r2_dseq");

    p_seq = pre_seq::type_id::create("p_seq");
    w_seq = write_seq::type_id::create("w_seq");
    w1_seq = write1_seq::type_id::create("w1_seq");
    r_seq = read_seq::type_id::create("r_seq");
  endfunction

  //--------------------------------------------------------------------------
  // End of elaboration
  //--------------------------------------------------------------------------
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    //uvm_top.print_topology(tree_printer);
    uvm_top.print_topology();
  endfunction

  //--------------------------------------------------------------------------
  // Test header display
  //--------------------------------------------------------------------------
  task automatic test_header(string testname, string description = "");
    `uvm_info("TEST_HEADER", "-----------------------------------------------------------", UVM_NONE)
    `uvm_info("TEST_HEADER", $sformatf("Running test: %s", testname), UVM_NONE)
    `uvm_info("TEST_HEADER", description, UVM_NONE)
    `uvm_info("TEST_HEADER", "-----------------------------------------------------------", UVM_NONE)
  endtask

endclass



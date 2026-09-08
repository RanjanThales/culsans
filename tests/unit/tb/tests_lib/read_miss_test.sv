`include "uvm_macros.svh" 
import uvm_pkg::*; 
import ariane_pkg::*; 
import snoop_test::*; 
import ace_test::*; 
import tb_ace_ccu_pkg::*; 
import tb_std_cache_subsystem_pkg::*; 
import tb_pkg::*;

class read_miss_test extends culsans_base_test;
    `uvm_component_utils(read_miss_test)

read_miss_write rmw_seq;
read_miss_read  rmr_seq;

  function new(string name = "read_miss_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    rmw_seq = read_miss_write::type_id::create("rmw_seq");
    rmr_seq = read_miss_read::type_id::create("rmr_seq");

    for (int c = 0; c < c_env_cfg.N_C; c++) begin

         uvm_config_db#(bit)::set(this, $sformatf("c_env_h.d_agt[%0d].cov_mon", c), "enable_cov_A", 1);
         uvm_config_db#(bit)::set(this, $sformatf("c_env_h.d_agt[%0d].cov_mon", c), "enable_cov_B", 0);
    end
  


  endfunction    


 task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info("TESTNAME", $sformatf("Inside multicore_ACE_data_con_op_test_01: testname = %s", testname), UVM_LOW)

    // Wait for reset deassertion
    do begin
      @(posedge clk_rst_if.clk);
    end while (clk_rst_if.rst_n == 1'b0);

    c_env_h.start_monitors();

    repeat (1800) begin @(posedge clk_rst_if.clk);  end

    test_header(testname, "8 consecutive read misses in the same cache set");  

        fork
            begin
             rmw_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);  
            end
        join
            rmr_seq.start(c_env_h.d_agt[0].d_seqr[0][1]);
   repeat(26000) @(posedge clk_rst_if.clk);

  
    $display("Test done");
    $display("------------------------------------------------------------------");
    for (int c = 0; c < c_env_cfg.N_C; c++) begin
      for (int p = 0; p < 3; p++) begin
        c_env_h.d_agt[c].dcache_mon[c][p].print_stats();
      end
    end
    $display("------------------------------------------------------------------");

    $finish();
    phase.drop_objection(this);
  endtask

endclass



`include "uvm_macros.svh" 
import uvm_pkg::*; 
import ariane_pkg::*; 
import snoop_test::*; 
import ace_test::*; 
import tb_ace_ccu_pkg::*; 
import tb_std_cache_subsystem_pkg::*; 
import tb_pkg::*;

class cache_evict_test extends culsans_base_test;
    `uvm_component_utils(cache_evict_test)

cache_evict_w1_seq  evict_w1    ;
cache_evict_w2_seq  evict_w2    ;
cache_evict_r1_seq  evict_r1    ;
cache_evict_r2_seq  evict_r2    ;

  function new(string name = "cache_evict_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);


    evict_w1 = cache_evict_w1_seq::type_id::create("evict_w1");
    evict_w2 = cache_evict_w2_seq::type_id::create("evict_w2");
    evict_r1 = cache_evict_r1_seq::type_id::create("evict_r1");
    evict_r2 = cache_evict_r2_seq::type_id::create("evict_r2");

  endfunction    


 task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info("TESTNAME", $sformatf("cache evict: testname = %s", testname), UVM_LOW)

    // Wait for reset deassertion
    do begin
      @(posedge clk_rst_if.clk);
    end while (clk_rst_if.rst_n == 1'b0);

    c_env_h.start_monitors();

    repeat (1800) begin @(posedge clk_rst_if.clk);  end

    test_header(testname, "8 cache line Eviction");  



                evict_w1.start(c_env_h.d_agt[0].d_seqr[0][0]);
                #500;
                evict_w2.start(c_env_h.d_agt[1].d_seqr[1][0]);
       

/*
        fork
            begin
                evict_w1.start(c_env_h.d_agt[0].d_seqr[0][0]);
            end
    
            begin                
                evict_w2.start(c_env_h.d_agt[1].d_seqr[1][0]);
            end

        join
*/

            #500;
                
                evict_r1.start(c_env_h.d_agt[3].d_seqr[3][0]);
            #500;                
                evict_r2.start(c_env_h.d_agt[2].d_seqr[2][0]);
            
              repeat(16000) @(posedge clk_rst_if.clk);
  
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




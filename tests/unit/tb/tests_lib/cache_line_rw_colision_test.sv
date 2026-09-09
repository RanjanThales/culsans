`include "uvm_macros.svh" 
import uvm_pkg::*; 
import ariane_pkg::*; 
import snoop_test::*; 
import ace_test::*; 
import tb_ace_ccu_pkg::*; 
import tb_std_cache_subsystem_pkg::*; 
import tb_pkg::*;


class cache_line_rw_colision_test extends culsans_base_test;
  `uvm_component_utils(cache_line_rw_colision_test)

write1_seq               w1_seq;   
scnerio2_write1_seq      s2_w1seq;
scnerio2_read_seq        s2_rseq;


cache_rwc_w1_seq       c_coll_w1_seq    ;
cache_rwc_w2_seq       c_coll_w2_seq    ;
cache_rwc_w3_seq       c_coll_w3_seq    ;
cache_rwc_r1_seq       c_coll_r1_seq    ;
cache_rwc_r2_seq       c_coll_r2_seq    ;
cache_rwc_r3_seq       c_coll_r3_seq    ;

cache_rwc_w11_seq      c_coll_w11_seq    ;

  function new(string name = "cache_line_rw_colision_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

  c_coll_w1_seq = cache_rwc_w1_seq::type_id::create("c_coll_w1_seq");
  c_coll_w11_seq = cache_rwc_w11_seq::type_id::create("c_coll_w11_seq");
  c_coll_w2_seq = cache_rwc_w2_seq::type_id::create("c_coll_w2_seq");
  c_coll_w3_seq = cache_rwc_w3_seq::type_id::create("c_coll_w3_seq");
  c_coll_r1_seq = cache_rwc_r1_seq::type_id::create("c_coll_r1_seq");
  c_coll_r2_seq = cache_rwc_r2_seq::type_id::create("c_coll_r2_seq");
  c_coll_r3_seq = cache_rwc_r3_seq::type_id::create("c_coll_r3_seq");

 
for (int c = 0; c < c_env_cfg.N_C; c++) begin

         uvm_config_db#(bit)::set(this, $sformatf("c_env_h.d_agt[%0d].cov_mon", c), "enable_cov_A", 0);
         uvm_config_db#(bit)::set(this, $sformatf("c_env_h.d_agt[%0d].cov_mon", c), "enable_cov_B", 1);
end
  
    endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info("TESTNAME", $sformatf("Inside cache_line_rw_colision_test: testname = %s", testname), UVM_LOW)

    // Wait for reset deassertion
    do begin
      @(posedge clk_rst_if.clk);
    end while (clk_rst_if.rst_n == 1'b0);

    c_env_h.start_monitors();

    repeat (1800) begin @(posedge clk_rst_if.clk);  end

    test_header("cache line read write collision", " cache line read write collision on different collision");


fork begin
    //repeat (2) begin
        // Writing into new cache lines
        fork
            c_coll_w1_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
            c_coll_w2_seq.start(c_env_h.d_agt[1].d_seqr[1][0]);
            c_coll_w3_seq.start(c_env_h.d_agt[2].d_seqr[2][0]);
        join_none
        wait fork;

        // Wait 500 cycles
        repeat (500) @(posedge clk_rst_if.clk);

        // Read phase (parallel with new writes)
        fork
            begin
                c_coll_r1_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
                c_coll_r2_seq.start(c_env_h.d_agt[1].d_seqr[1][0]);
                c_coll_r3_seq.start(c_env_h.d_agt[2].d_seqr[2][0]);
            end
            begin
                fork
                    c_coll_w11_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
                    begin
                        c_coll_r2_seq.start(c_env_h.d_agt[1].d_seqr[1][0]);
                        c_coll_r3_seq.start(c_env_h.d_agt[2].d_seqr[2][0]);
                    end
                join_none
                wait fork;
            end
        join_none
        wait fork;

        // delay before next iteration
        #500;
    //end
end join



/*
fork
    begin
        c_coll_w1_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
        c_coll_w2_seq.start(c_env_h.d_agt[1].d_seqr[1][0]);
    end
join

c_coll_r2_seq.start(c_env_h.d_agt[1].d_seqr[1][0]);
*/
      

      repeat(600) @(posedge clk_rst_if.clk);

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





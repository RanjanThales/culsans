`include "uvm_macros.svh" 
import uvm_pkg::*; 
import ariane_pkg::*; 
import snoop_test::*; 
import ace_test::*; 
import tb_ace_ccu_pkg::*; 
import tb_std_cache_subsystem_pkg::*; 
import tb_pkg::*;


class multicore_ACE_data_con_op_test_01 extends culsans_base_test;
  `uvm_component_utils(multicore_ACE_data_con_op_test_01)

write1_seq               w1_seq;   
write3_seq               w3_seq;   
scnerio2_write1_seq      s2_w1seq;
scnerio2_read_seq        s2_rseq;

  function new(string name = "multicore_ACE_data_con_op_test_01", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    
    w3_seq = write3_seq::type_id::create("w3_seq");
    w1_seq = write1_seq::type_id::create("w1_seq");
    s2_w1seq = scnerio2_write1_seq::type_id::create("s2_w1seq");
    s2_rseq = scnerio2_read_seq::type_id::create("s2_rseq");

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

    test_header("multicore_ACE_data_con_op_test_01", "write write race  in the same cache line");



    // Sequences
    w1_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);  //8006_1000 --- > BEEF
    r_seq.start(c_env_h.d_agt[1].d_seqr[1][0]);

      #1500;

      fork
        begin
           w_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);   //8006_1000 ---> F00D 
 
        end
        
        begin

            s2_w1seq.start(c_env_h.d_agt[1].d_seqr[1][0]);  //----> DEAD
        end
        begin
            s2_rseq.start(c_env_h.d_agt[2].d_seqr[2][0]);
        end

     join

       w1_seq.start(c_env_h.d_agt[2].d_seqr[2][0]);  //--------------> BEEF


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



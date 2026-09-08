`include "uvm_macros.svh" 
import uvm_pkg::*; 
import ariane_pkg::*; 
import snoop_test::*; 
import ace_test::*; 
import tb_ace_ccu_pkg::*; 
import tb_std_cache_subsystem_pkg::*; 
import tb_pkg::*;


class multicore_ACE_data_con_op_test_02 extends culsans_base_test;
  `uvm_component_utils(multicore_ACE_data_con_op_test_02)


 write_seq                w1_seq;  //8061000_FOOD
 write2_seq               w2_seq;  //80061800_FAFA
 write3_seq               w3_seq;  //80060800_BABA
 read1_dcache             r1_seq;  //80061000
 read2_dcache             r2_seq;  //80061800
 read3_dcache             r3_seq;  //80061000
 read4_dcache             r4_seq;  //80061100
 read5_dcache             r5_seq;  //80061300
 read6_dcache             r6_seq;  //80061800


  function new(string name = "multicore_ACE_data_con_op_test_02", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    w1_seq = write_seq::type_id::create("w1_seq");
    w2_seq = write2_seq::type_id::create("w2_seq");
    r1_seq = read1_dcache::type_id::create ("r1_seq");
    r2_seq = read2_dcache::type_id::create ("r2_seq");
    w3_seq = write3_seq::type_id::create("w3_seq");
    r3_seq = read3_dcache::type_id::create("r3_seq");
    r4_seq = read4_dcache::type_id::create("r4_seq");
    r5_seq = read5_dcache::type_id::create("r5_seq");
    r6_seq = read6_dcache::type_id::create("r6_seq");
endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info("TESTNAME", $sformatf("Inside multicore_ACE_data_con_op_test_02: testname = %s", testname), UVM_LOW)

    // Wait for reset deassertion
    do begin
      @(posedge clk_rst_if.clk);
    end while (clk_rst_if.rst_n == 1'b0);

    c_env_h.start_monitors();

    repeat (1800) begin @(posedge clk_rst_if.clk);  end

    test_header("multicore_ACE_data_con_op_test_02", "same cache line interference  in the same cache line set");

    // initial condition
    
      w1_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
      w2_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
      
    #1500;   

 //1st_set   
   fork
 
     begin
     r3_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
     end

     begin
      r1_seq.start(c_env_h.d_agt[2].d_seqr[2][0]);
     end
 
    begin
     r2_seq.start(c_env_h.d_agt[1].d_seqr[1][0]);
    end

join_any

//2nd_set
    fork

    begin
     r4_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
     //r6_seq.start(c_env_h.d_agt[0].d_seqr[0][0]); //hit

    end

    begin
    end

   begin
   end 
    
    join

   
 //3rd_set   
    fork 
    begin
      //w3_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
      //w1_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);

    end

    begin
    end

   begin
   end 
    join_any



     //r5_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);


  
    
    
    
    
    
    
    /*
    fork
 
     
     begin
     r3_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
 
     end

     begin
      r1_seq.start(c_env_h.d_agt[2].d_seqr[2][0]);
     end
 
    begin
     r4_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
    end

    begin
     //w3_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
    end
    
    begin
     r2_seq.start(c_env_h.d_agt[1].d_seqr[1][0]);
 
    end
 
    begin
     //r4_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
    end
   
   
    begin
     w3_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
    end
   
    begin
     r5_seq.start(c_env_h.d_agt[0].d_seqr[0][0]);
    end

   join
*/
      
    repeat(1600) @(posedge clk_rst_if.clk);

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

 

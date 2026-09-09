import uvm_pkg::*; 
import ariane_pkg::*; 
import snoop_test::*; 
import ace_test::*; 
import tb_ace_ccu_pkg::*; 
import tb_std_cache_subsystem_pkg::*; 
import tb_pkg::*;


class ace_write_read_test extends culsans_base_test;
    `uvm_component_utils(ace_write_read_test)

ace_read_sequence    r_seq;
ace_write_sequence   w_seq;


function new(string name = "ace_write_read_test", uvm_component parent);
    super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  r_seq = ace_read_sequence::type_id::create("r_seq");
  w_seq = ace_write_sequence::type_id::create("w_seq");

endfunction


task run_phase(uvm_phase phase);
phase.raise_objection(this);


 // Wait for reset deassertion
    do begin
      @(posedge clk_rst_if.clk);
    end while (clk_rst_if.rst_n == 1'b0);

    //c_env_h.start_monitors();

    repeat (1800) begin @(posedge clk_rst_if.clk);  end

    test_header("multicore_ACE_driver_test", "ace_write_read_test");
    #2000;
    
    


    w_seq.start(c_env_h.ace_agt[0].ace_sqr);   //8006_1000 --- > BEEF
    //w_seq.start(c_env_h.ace_agt[1].ace_sqr); 
    //r_seq.start(c_env_h.ace_agt[2].ace_sqr);

    repeat(8000) @(posedge clk_rst_if.clk);
    $display("Write Test done");
    $display("Read Test starting");
    r_seq.start(c_env_h.ace_agt[2].ace_sqr);
    repeat(9000) @(posedge clk_rst_if.clk);

  
    $display("Test done");
    $display("------------------------------------------------------------------");
    $finish();

phase.drop_objection(this);

endtask

endclass



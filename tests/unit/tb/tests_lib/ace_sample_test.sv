import uvm_pkg::*; 
import ariane_pkg::*; 
import snoop_test::*; 
import ace_test::*; 
import tb_ace_ccu_pkg::*; 
import tb_std_cache_subsystem_pkg::*; 
import tb_pkg::*;


class ace_sample_test extends culsans_base_test;
    `uvm_component_utils(ace_sample_test)

test_sequence t_seq;

function new(string name = "ace_sample_test", uvm_component parent);
    super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  t_seq = test_sequence::type_id::create("t_seq");
endfunction


task run_phase(uvm_phase phase);

phase.raise_objection(this);

    t_seq.start(c_env_h.ace_agt[0].ace_sqr);

phase.drop_objection(this);

endtask

endclass



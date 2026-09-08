
`include "uvm_macros.svh"
import uvm_pkg::*;
class culsans_env_config extends uvm_object;
    `uvm_object_utils(culsans_env_config)

   // core_agent_config core_agt_cfg  ;

   // bit has_core_agent = 1  ;
   // bit has_scoreboard = 0  ;
   // bit has_virtual_sequencer = 1 ;
   // int no_of_core_agents = 19;



     int unsigned  NUM_WORDS     = 4**10; 
     int unsigned  N_D; 
     //int unsigned  NB_CORES      = culsans_pkg::NB_CORES; 
     int unsigned  N_C = 4; 
     bit has_virtual_sequencer   =0;
     string name ="ranjan"; 
function new(string name="culsans_env_config");
    super.new(name);
endfunction

endclass

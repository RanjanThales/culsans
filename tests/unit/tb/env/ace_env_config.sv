
`include "uvm_macros.svh"
import uvm_pkg::*;


class ace_env_config extends uvm_object;
    `uvm_object_utils(ace_env_config)

     int unsigned  NO_OF_AGENTS = 4; 


function new(string name="ace_env_config");
    super.new(name);
endfunction

endclass

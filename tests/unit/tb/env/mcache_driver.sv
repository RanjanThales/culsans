
`include "uvm_macros.svh"
import uvm_pkg::*;

import tb_pkg::*;

class mcache_driver extends uvm_driver;
    `uvm_component_utils(mcache_driver)


 
  function new(string name = "mcache_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass

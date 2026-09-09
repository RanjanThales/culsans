
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;

class ace_sequencer extends uvm_sequencer #(ace_txn_item);
`uvm_component_utils(ace_sequencer)


function new(string name = "ace_sequencer", uvm_component parent = null);
    super.new(name,parent);
endfunction

endclass



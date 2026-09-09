
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;





//class dcache_sequencer extends uvm_sequencer #(dcache_req_seq_item, dcache_resp_seq_item);
class dcache_sequencer extends uvm_sequencer #(dcache_req_seq_item);
  `uvm_component_utils(dcache_sequencer)
  function new(string name = "dcache_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass


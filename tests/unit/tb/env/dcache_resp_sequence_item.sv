
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;
import ariane_pkg::*;


class dcache_resp_seq_item extends uvm_sequence_item;
      `uvm_object_utils(dcache_resp_seq_item)  
        logic                          data_gnt;
        logic                          data_rvalid;
        logic [DCACHE_TID_WIDTH-1:0]   data_rid;
        riscv::xlen_t                  data_rdata;
        logic [DCACHE_USER_WIDTH-1:0]  data_ruser;
        logic  [63:0]            data;       
/*
    `uvm_object_utils_begin(dcache_resp_seq_item)
    `uvm_field_int      (data_gnt,              UVM_DEFAULT)
    `uvm_field_int      (data_rvalid,           UVM_DEFAULT)
    `uvm_field_int      (data_rid,              UVM_DEFAULT)
    `uvm_field_enum     (riscv::xlen_t, data_rdata,  UVM_DEFAULT)
    `uvm_field_int      (data_ruser,            UVM_DEFAULT)
  `uvm_object_utils_end

  `uvm_object_new
*/
    endclass


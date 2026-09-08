`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;
import ariane_pkg::*;


class dcache_req_seq_item extends uvm_sequence_item;
`uvm_object_utils(dcache_req_seq_item)

        logic [DCACHE_INDEX_WIDTH-1:0] address_index;
        logic [DCACHE_TAG_WIDTH-1:0]   address_tag;
        riscv::xlen_t                  data_wdata;
        logic [DCACHE_USER_WIDTH-1:0]  data_wuser;
        logic                          data_req;
        rand logic                          data_we;
        logic [(riscv::XLEN/8)-1:0]    data_be;
        logic [1:0]                    data_size;
        logic [DCACHE_TID_WIDTH-1:0]   data_id;
        logic                          kill_req;
        logic                          tag_valid;
        rand logic  [63:0]              addr;        
        rand logic  [63:0]              data; 
        logic                           data_gnt;    


        logic                          data_rvalid;
        logic [DCACHE_TID_WIDTH-1:0]   data_rid;
        riscv::xlen_t                  data_rdata;
        logic [DCACHE_USER_WIDTH-1:0]  data_ruser;



/*
    `uvm_object_utils_begin(dcache_req_seq_item)
    `uvm_field_int      (address_index,  UVM_DEFAULT)
    `uvm_field_enum     (address_tag  ,  UVM_DEFAULT)
    `uvm_field_int      (riscv::xlen_t, data_wdata   , UVM_DEFAULT,  UVM_DEFAULT)
    `uvm_field_int      (data_wuser   ,  UVM_DEFAULT)
    `uvm_field_int      (data_req     ,  UVM_DEFAULT)
    `uvm_field_int      (data_we      ,  UVM_DEFAULT)
    `uvm_field_int      (data_be      ,  UVM_DEFAULT)
    `uvm_field_int      (data_size    ,  UVM_DEFAULT)
    `uvm_field_int      (data_id      ,  UVM_DEFAULT)
    `uvm_field_int      (kill_req     ,  UVM_DEFAULT)
    `uvm_field_int      (tag_valid    ,  UVM_DEFAULT)
    `uvm_object_utils_end

  `uvm_object_new
  */  
    endclass


`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;
import ariane_pkg::*;



class ace_sequence extends uvm_sequence #(ace_txn_item);
    `uvm_object_utils(ace_sequence)

function new(string name = "ace_sequence");
    super.new(name);
endfunction


endclass



class test_sequence extends ace_sequence;
    `uvm_object_utils(test_sequence)

function new(string name = "test_sequence");
    super.new(name);
endfunction


task body();
  ace_txn_item req;
  req = ace_txn_item::type_id::create("req");


    start_item(req);
    req.is_write  = 1'b1 ;    
    req.ar_addr     = 64'h0000000080061000;
    req.is_write    = 0   ;
    req.ar_id       = 2  ;
    req.ar_len      = 0  ;
    req.ar_size     = 6 ;
    req.ar_burst    = 2'b01  ;
    req.ar_valid    = 1  ;
    req.ar_snoop    =  4'b0011  ;
    req.ar_bar      =  2'b0 ;
    req.ar_domain   =  2'b01 ;

    

  finish_item(req);

endtask

endclass


class ace_write_sequence extends ace_sequence;
    `uvm_object_utils(ace_write_sequence)

function new(string name = "ace_write_sequence");
    super.new(name);
endfunction


task body();
  ace_txn_item req;
  req = ace_txn_item::type_id::create("req");


    start_item(req);

    req.is_write  = 1'b1 ;    
    req.aw_addr     = 64'h0000000080061000;
    req.aw_id       = 2  ;
    req.aw_len      = 10  ;
    req.aw_size     = 6 ;
    req.aw_burst    = 2'b01  ;
    req.aw_valid    = 1  ;
    req.aw_snoop    =  4'b0011  ;
    req.aw_bar      =  2'b0 ;
    req.aw_domain   =  2'b01 ;
    req.b_id   =  2 ;
    
   req.w_strb = 8'b00001111;
    req.w_data = new[req.aw_len];
         foreach(req.w_data[i])
            req.w_data[i] = $urandom();


  finish_item(req);

endtask

endclass




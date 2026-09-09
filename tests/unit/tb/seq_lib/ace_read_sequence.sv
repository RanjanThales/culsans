`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;
import ariane_pkg::*;



class ace_read_sequence extends ace_sequence;
    `uvm_object_utils(ace_read_sequence)

function new(string name = "ace_read_sequence");
    super.new(name);
endfunction


task body();
  ace_txn_item req;
  req = ace_txn_item::type_id::create("req");


  start_item(req);

    req.is_write  = 1'b0 ;
    req.ar_addr     = 64'h0000000080061000;
    req.ar_id       = 1  ;
    //req.r_id       = 1  ;
    req.ar_len      = 10  ;
    req.ar_size     = 6 ;
    req.ar_burst    = 2'b01  ;
    req.ar_valid    = 1  ;
    req.ar_snoop    =  4'b0011  ;
    req.ar_bar      =  2'b0 ;
    req.ar_domain   =  2'b01 ;

   

  finish_item(req);
endtask

endclass

class ace_read_sequence_beat extends ace_sequence;
    `uvm_object_utils(ace_read_sequence_beat)

function new(string name = "ace_read_sequence_beat");
    super.new(name);
endfunction


task body();
  ace_txn_item req;
  req = ace_txn_item::type_id::create("req");


  start_item(req);

    req.is_write  = 1'b0 ;
    req.ar_addr     = 64'h0000000080061000;
    req.ar_id       = 0  ;
    //req.r_id       = 1  ;
    req.ar_len      = 5  ;
    req.ar_size     = 6 ;
    req.ar_burst    = 2'b00  ;
    req.ar_valid    = 1  ;
    req.ar_snoop    =  4'b0001  ;
    req.ar_bar      =  2'b0 ;
    req.ar_domain   =  2'b01 ;

   

  finish_item(req);
endtask

endclass



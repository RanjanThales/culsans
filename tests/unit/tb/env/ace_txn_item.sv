`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;
import ariane_pkg::*;



class ace_txn_item extends uvm_sequence_item;
    `uvm_object_utils(ace_txn_item)

  

    //--------------------------------------------------------------------------
    //Local Varibles
    //--------------------------------------------------------------------------
    rand bit is_write;   // 1 = WRITE transaction, 0 = READ transaction



    //--------------------------------------------------------------------------
    // WRITE ADDRESS CHANNEL
    //--------------------------------------------------------------------------

rand logic  [3:0]   aw_id;
rand logic  [63:0]  aw_addr;
rand logic  [7:0]   aw_len;
rand logic  [2:0]   aw_size;
rand logic  [1:0]   aw_burst;
rand logic          aw_lock;
rand logic  [3:0]   aw_cache;
rand logic  [2:0]   aw_prot;
rand logic  [3:0]   aw_qos;
rand logic  [3:0]   aw_region;
rand logic  [5:0]   aw_atop;
rand logic  [31:0]  aw_user;
rand logic          aw_valid;
rand logic          aw_ready;
rand logic  [2:0]   aw_snoop;
rand logic  [1:0]   aw_bar;
rand logic  [1:0]   aw_domain;
     logic          aw_awunique;

    //--------------------------------------------------------------------------
    // WRITE DATA CHANNEL
    //--------------------------------------------------------------------------

 rand logic  [63:0] w_data[];
//rand logic  [63:0] w_data;
rand logic  [7:0]  w_strb;
logic       [31:0] w_user;
rand logic   w_valid;
 logic   w_ready;
rand  logic   w_last ;



    //--------------------------------------------------------------------------
    // WRITE RESPONSE CHANNEL
    //--------------------------------------------------------------------------

logic   [3:0] b_id;
logic   [1:0] b_resp;
logic   [31:0] b_user;
logic   b_valid;
logic   b_ready;



    //--------------------------------------------------------------------------
    // READ ADDRESS CHANNEL
    //--------------------------------------------------------------------------


logic   [3:0]  ar_id;
logic   [63:0] ar_addr;
logic   [7:0] ar_len;
logic   [2:0] ar_size;
logic   [1:0] ar_burst;
logic   ar_lock;
logic   [3:0] ar_cache;
logic   [2:0] ar_prot;
logic   [3:0] ar_qos;
logic   [3:0] ar_region;
logic   [31:0] ar_user;
logic   ar_valid;
logic   ar_ready;
logic   [2:0] ar_snoop;
logic   [1:0] ar_bar;
logic   [1:0] ar_domain;



    //--------------------------------------------------------------------------
    // READ DATA CHANNEL
    //--------------------------------------------------------------------------

logic  [3:0]  r_id;
logic  [63:0] r_data;
logic  [3:0]  r_resp;
logic  [31:0]  r_user;
logic   r_valid;
logic   r_ready;
logic   r_last;


    //--------------------------------------------------------------------------
    // SNOOP ADRESS CHANNEL
    //--------------------------------------------------------------------------

logic [63:0] ac_addr    ;
logic [2:0]  ac_prot    ;
logic [3:0]  ac_snoop   ;
logic        ac_valid   ;
logic        ac_ready   ;


    //--------------------------------------------------------------------------
    // SNOOP DATA CHANNEL
    //--------------------------------------------------------------------------

logic [63:0]    cd_data     ;
logic           cd_last     ;
logic           cd_valid    ;
logic           cd_ready    ;


    //--------------------------------------------------------------------------
    // SNOOP RESPONSE CHANNEL
    //--------------------------------------------------------------------------
 
logic       cr_resp         ;
logic       cr_valid        ;
logic       cr_ready        ;





function new(string name = "ace_txn_item");
    super.new(name);
endfunction


/*
function void post_randomize();

 for(int i = 0; i < aw_len + 1; i++) begin
        w_data.push_back($urandom_range(1, 10));
    end

    
endfunction
*/

endclass

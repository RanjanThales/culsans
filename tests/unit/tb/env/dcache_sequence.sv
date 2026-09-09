`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;
import ariane_pkg::*;

class dcache_sequence extends uvm_sequence #(dcache_req_seq_item);
  `uvm_object_utils(dcache_sequence)

  // Constructor declaration
  extern function new(string name = "dcache_sequence");
endclass

int data;
int addr;
uvm_event finish_event;
 localparam ariane_cfg_t ArianeCfg        = culsans_pkg::ArianeSocCfg;


// Constructor definition for dcache_sequence
function dcache_sequence::new(string name = "dcache_sequence");
  super.new(name);
endfunction


// Read sequence - single read request
class read_dcache extends dcache_sequence;
  `uvm_object_utils(read_dcache)

  extern function new(string name = "read_dcache");
  extern task body();
endclass


// Constructor for read_dcache
function read_dcache::new(string name = "read_dcache");
  super.new(name);
endfunction


// Sequence body: issue one read transaction with fixed addr and data_we=0
task read_dcache::body();
  begin
    dcache_req_seq_item req;

    // Create and start sequence item
    req = dcache_req_seq_item::type_id::create("req");
    start_item(req);

    // Randomize with constraints (fixed address and data_we)
    assert(req.randomize() with {
      addr == 64'h0000000080061000;
      data_we == 1'b0;
    });

    finish_item(req);
  end
endtask


class read1_dcache extends dcache_sequence;
  `uvm_object_utils(read1_dcache)

  extern function new(string name = "read1_dcache");
  extern task body();
endclass


// Constructor for read1_dcache
function read1_dcache::new(string name = "read1_dcache");
  super.new(name);
endfunction


// Sequence body: issue one read transaction with fixed addr and data_we=0
task read1_dcache::body();
  begin
    dcache_req_seq_item req;

    // Create and start sequence item
    req = dcache_req_seq_item::type_id::create("req");
    start_item(req);
    req.addr     = 64'h0000000080061000; 
    req.data_we  = 1'b0; 
/*
    // Randomize with constraints (fixed address and data_we)
    assert(req.randomize() with {
      addr == 64'h0000000080061000;
      data_we == 1'b0;
    });
*/
    finish_item(req);
  end
endtask









////////////////////////////////////////////////////////////////////////////////////
// Second read sequence with different address
class read3_dcache extends dcache_sequence;
  `uvm_object_utils(read3_dcache)

  extern function new(string name = "read3_dcache");
  extern task body();
endclass


// Constructor for read3_dcache
function read3_dcache::new(string name = "read3_dcache");
  super.new(name);
endfunction


// Sequence body: issue one read transaction with a different fixed addr and data_we=0
task read3_dcache::body();
  begin
    dcache_req_seq_item req;

    req = dcache_req_seq_item::type_id::create("req");
    start_item(req);
    req.addr     = 64'h0000000080061000; 
    req.data_we  = 1'b0; 
    finish_item(req);
/*
    start_item(req);
    req.addr     = 64'h0000000080071000; 
    req.data_we  = 1'b0; 
    finish_item(req);
    
    start_item(req);
    req.addr     = 64'h0000000080061000; 
    req.data_we  = 1'b0; 
    finish_item(req);

    start_item(req);
    req.addr     = 64'h0000000080071000; 
    req.data_we  = 1'b0; 
    finish_item(req);
 
*/


  end
endtask


///////////////////
class read4_dcache extends dcache_sequence;
  `uvm_object_utils(read4_dcache)

  extern function new(string name = "read4_dcache");
  extern task body();
endclass

// Constructor for read2_dcache
function read4_dcache::new(string name = "read4_dcache");
  super.new(name);
endfunction


// Sequence body: issue one read transaction with a different fixed addr and data_we=0
task read4_dcache::body();
  begin
    dcache_req_seq_item req;

    req = dcache_req_seq_item::type_id::create("req");
    start_item(req);
    req.addr     = 64'h0000000080061100; 
    req.data_we  = 1'b0; 
    finish_item(req);

  end
endtask


class read5_dcache extends dcache_sequence;
  `uvm_object_utils(read5_dcache)

  extern function new(string name = "read5_dcache");
  extern task body();
endclass

function read5_dcache::new(string name = "read5_dcache");
  super.new(name);
endfunction


// Sequence body: issue one read transaction with a different fixed addr and data_we=0
task read5_dcache::body();
  begin
    dcache_req_seq_item req;

    req = dcache_req_seq_item::type_id::create("req");
    start_item(req);
    req.addr     = 64'h0000000080061300; 
    req.data_we  = 1'b0; 
    finish_item(req);

  end
endtask

class read6_dcache extends dcache_sequence;
  `uvm_object_utils(read6_dcache)

  extern function new(string name = "read6_dcache");
  extern task body();
endclass

function read6_dcache::new(string name = "read6_dcache");
  super.new(name);
endfunction


// Sequence body: issue one read transaction with a different fixed addr and data_we=0
task read6_dcache::body();
  begin
    dcache_req_seq_item req;

    req = dcache_req_seq_item::type_id::create("req");
    start_item(req);
    req.addr     = 64'h0000000080061800; 
    req.data_we  = 1'b0; 
    finish_item(req);

  end
endtask




////////////////////////////////////////////////////////////////////////////////////
// Write sequence - issues multiple write requests
class write_dcache extends dcache_sequence;
  `uvm_object_utils(write_dcache)

  extern function new(string name = "write_dcache");
  extern task body();
endclass


// Constructor for write_dcache
function write_dcache::new(string name = "write_dcache");
  super.new(name);
endfunction


// Sequence body: issue multiple write transactions with fixed addr/data/data_we=1
task write_dcache::body();
  begin
    dcache_req_seq_item req;

    // First write transaction
    req = dcache_req_seq_item::type_id::create("req");
    start_item(req);

    assert(req.randomize() with {
      addr == 64'h0000000080061000;
      data == 64'hDEAD;
      data_we == 1'b1;
    });

    `uvm_info("write_dcache randomized", "Randomization done properly", UVM_LOW)
    finish_item(req);

    // Second write transaction
    req = dcache_req_seq_item::type_id::create("req");
    start_item(req);

    assert(req.randomize() with {
      addr == 64'h0000000088001500;
      data == 64'hBEEF;
      data_we == 1'b1;
    });

    finish_item(req);




/*
                     for (int i=0; i<3; i++) begin
                    #100;
                     start_item(req);
                     //addr = ArianeCfg.CachedRegionAddrBase[0];
                     addr = 64'h0000000080061000;

                        // write to address 0-7 and then some more
                  //      for (int i=0; i<16; i++) begin
                            req.data_we = 1'b1;
                            req.addr = (addr + (i << 8));
                            req.data =  data + i;
                       // end
                     finish_item(req);
                    end
*/
                       // // read miss x 8 - fill cache 0
                       // for (int i=0; i<8; i++) begin
                       //     dcache_drv[cid][1].rd(.addr(addr + (i << DCACHE_INDEX_WIDTH)));
                       // end





    /*
    // Additional transactions (commented out)
    req = dcache_req_seq_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      addr == 64'h0000000080091000;
      data == 64'hCAFE;
      data_we == 1'b1;
    });
    finish_item(req);

    req = dcache_req_seq_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      addr == 64'h0000000080006000;
      data == 64'hFAAB;
      data_we == 1'b1;
    });
    finish_item(req);
    */

  end
  //finish_event.trigger();  // (commented out event trigger)
endtask



//======================Interference scnerio====================//



class pre_seq extends dcache_sequence; 
  `uvm_object_utils(pre_seq) 
 
  function new(string name = "pre_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 
    start_item(req); 
    req.addr     = 64'h0000000080061000; 
    req.data     = 64'hDEAD; 
    req.data_we  = 1'b1; 
    finish_item(req); 
  endtask 
endclass 


class write_seq extends dcache_sequence; 
  `uvm_object_utils(write_seq) 
 
  function new(string name = "write_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 
    start_item(req); 
    req.addr     = 64'h0000000080061000; 
    req.data     = 64'hF00D; 
    req.data_we  = 1'b1; 
    finish_item(req); 
  endtask 
endclass 

class read_seq extends dcache_sequence; 
  `uvm_object_utils(read_seq) 
 
  function new(string name = "read_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 
    start_item(req); 
    req.addr     = 64'h0000000080061000; 
    req.data_we  = 1'b0; 
    finish_item(req); 
  endtask 
endclass 

class write1_seq extends dcache_sequence; 
  `uvm_object_utils(write1_seq) 
 
  function new(string name = "write1_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 
    start_item(req); 
    req.addr     = 64'h0000000080061000; 
    req.data     = 64'hBEEF; 
    req.data_we  = 1'b1; 
    finish_item(req); 
  endtask 
endclass 


class write2_seq extends dcache_sequence; 
  `uvm_object_utils(write2_seq) 
 
  function new(string name = "write2_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 
    start_item(req); 
    req.addr     = 64'h0000000080061800; 
    req.data     = 64'hFAFA; 
    req.data_we  = 1'b1; 
    finish_item(req); 
  endtask 
endclass 


class write3_seq extends dcache_sequence; 
  `uvm_object_utils(write3_seq) 
 
  function new(string name = "write2_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 
    start_item(req); 
    req.addr     = 64'h0000000080060800; 
    req.data     = 64'hBABA; 
    req.data_we  = 1'b1; 
    finish_item(req); 
  endtask 
endclass 




class scnerio2_write1_seq extends dcache_sequence; 
  `uvm_object_utils(scnerio2_write1_seq) 
 
  function new(string name = "scnerio2_write1_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 

    start_item(req); 
    req.addr     = 64'h0000000080061000; 
    req.data     = 64'hDEAD; 
    req.data_we  = 1'b1; 
    finish_item(req); 

  endtask 
endclass 

class scnerio2_write2_seq extends dcache_sequence; 
  `uvm_object_utils(scnerio2_write2_seq) 
 
  function new(string name = "scnerio2_write2_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 

    start_item(req); 
    req.addr     = 64'h0000000080061800; 
    req.data     = 64'hCAFE; 
    req.data_we  = 1'b1; 
    finish_item(req); 

  endtask 
endclass 

class scnerio2_read_seq extends dcache_sequence; 
  `uvm_object_utils(scnerio2_read_seq) 
 
  function new(string name = "scnerio2_read_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 

    start_item(req); 
    req.addr     = 64'h0000000080061000; 
    req.data_we  = 1'b0; 
    finish_item(req); 

     endtask 
endclass 


class read2_dcache extends dcache_sequence; 
  `uvm_object_utils(read2_dcache) 
 
  function new(string name = "read2_dcache"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 

    start_item(req); 
    req.addr     = 64'h0000000080061800; 
    req.data_we  = 1'b0; 
    finish_item(req); 

  endtask 
endclass 



//======cache_line_read_write_collision=================//


class cache_rwc_w1_seq extends dcache_sequence; 
  `uvm_object_utils(cache_rwc_w1_seq) 
 
  function new(string name = "cache_rwc_w1_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 

    start_item(req); 
    req.addr     = 64'h0000000080060000; 
    req.data     = 64'hBABA; 
    req.data_we  = 1'b1; 
    finish_item(req); 

  endtask 
endclass 



class cache_rwc_w2_seq extends dcache_sequence; 
  `uvm_object_utils(cache_rwc_w2_seq) 
 
  function new(string name = "cache_rwc_w2_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 

    start_item(req); 
    req.addr     = 64'h0000000080060010; 
    req.data_we  = 1'b1; 
    req.data     = 64'hCAFE; 
    finish_item(req); 

  endtask 
endclass 


class cache_rwc_w3_seq extends dcache_sequence; 
  `uvm_object_utils(cache_rwc_w3_seq) 
 
  function new(string name = "cache_rwc_w3_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 

    start_item(req); 
    req.addr     = 64'h0000000080060020; 
    req.data_we  = 1'b1; 
    req.data     = 64'hC0FFE; 
    finish_item(req); 

  endtask 
endclass 




class cache_rwc_w11_seq extends dcache_sequence; 
  `uvm_object_utils(cache_rwc_w11_seq) 
 
  function new(string name = "cache_rwc_w11_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 

    start_item(req); 
    req.addr     = 64'h0000000080060000; 
    req.data     = 64'hD00D; 
    req.data_we  = 1'b1; 
    finish_item(req); 

  endtask 
endclass 



class cache_rwc_r1_seq extends dcache_sequence; 
  `uvm_object_utils(cache_rwc_r1_seq) 
 
  function new(string name = "cache_rwc_r1_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 

    start_item(req); 
    req.addr     = 64'h0000000080060000; 
    req.data_we  = 1'b0; 
    finish_item(req); 

  endtask 
endclass 



class cache_rwc_r2_seq extends dcache_sequence; 
  `uvm_object_utils(cache_rwc_r2_seq) 
 
  function new(string name = "cache_rwc_r2_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 

    start_item(req); 
    req.addr     = 64'h0000000080060010; 
    req.data_we  = 1'b0; 
    finish_item(req); 

  endtask 
endclass 


class cache_rwc_r3_seq extends dcache_sequence; 
  `uvm_object_utils(cache_rwc_r3_seq) 
 
  function new(string name = "cache_rwc_r3_seq"); 
    super.new(name); 
  endfunction 
 
  virtual task body(); 
    dcache_req_seq_item req; 
    req = dcache_req_seq_item::type_id::create("req"); 

    start_item(req); 
    req.addr     = 64'h0000000080060020; 
    req.data_we  = 1'b0; 
    finish_item(req); 

  endtask 
endclass 


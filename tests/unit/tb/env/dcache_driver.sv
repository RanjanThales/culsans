`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;

//class dcache_driver extends uvm_driver#(dcache_req_seq_item, dcache_resp_seq_item);
class dcache_driver extends uvm_driver#(dcache_req_seq_item);
//class dcache_driver #(type REQ = uvm_sequence_item, type RESP = uvm_sequence_item) extends uvm_driver #(REQ, RESP);

   // `uvm_component_param_utils(dcache_driver #(REQ, RESP))
  //  `uvm_component_param_utils(dcache_driver #(dcache_req_seq_item, dcache_resp_seq_item ))
    `uvm_component_utils (dcache_driver)
  
    //uvm_seq_item_pull_port #(dcache_req_seq_item) seq_item_port;
    
    function new(string name = "dcache_driver", uvm_component parent = null);
    super.new(name, parent);
    //seq_item_port = new("seq_item_port", this);
    endfunction

    virtual dcache_intf vif;
    dcache_req_seq_item req;
    dcache_resp_seq_item resp;
    logic verbosity =1;
    int c_agt;
    int p_agt;
string name = "sample";

    //extern task wr();
    //extern task rd ();
    uvm_event            finish_event;
   
    logic kill_req = 0;
        logic kill_armed;
 

    function void build_phase(uvm_phase phase);
    super.build_phase(phase);

if (!uvm_config_db#(uvm_event)::get(this, "", "finish_event", finish_event)) begin
            `uvm_fatal("CONFIG_DB_ERROR", "Unable to get finish_event from config DB");
        end
   

     //if (!uvm_config_db#(int)::get(this, $sformatf("d_drv[%0d][%0d]",c,p), "c_value", c_agt)) begin 
     if (!uvm_config_db#(int)::get(this, "", "c_value", c_agt)) begin 
      `uvm_fatal("NO_CVAR", "Not Getting c_value from config db!"); 
    end
  
    if (!uvm_config_db#(int)::get(this, "", "p_value", p_agt)) begin 
      `uvm_fatal("NO_CVAR", "Not Getting p_value from config db!"); 
    end
 
        if (!uvm_config_db#(virtual dcache_intf)::get(this, "*",$sformatf("dcache_vif_%0d_%0d", c_agt, p_agt),vif)) begin 

                    //`uvm_fatal("NOCFG", $sformatf("No dcache_vif[%0d][%0d] found", c, p)); 
                    `uvm_fatal("NOCFG", $sformatf("No dcache_vif[c_agt][p_agt] found")); 
                end else begin 
                    `uvm_info("DCACHE_CONFIG", $sformatf("---------%s[%0d][%0d]--------------", "DCACHE_INTF", c_agt, p_agt), UVM_NONE); 
                end


    //resp = dcache_resp_seq_item::type_id::create("resp");

    endfunction
  
  task run_phase(uvm_phase phase);

        vif.req.address_tag = $urandom();
        vif.req.address_index = $urandom();
        vif.req.data_wdata = 0;
        vif.req.data_wuser = 0;
        vif.req.data_req = 0;
        vif.req.data_we = 0;
        vif.req.data_be = 8'h0;
        vif.req.data_size = 2'h0;
        vif.req.data_id = 0;
        vif.req.kill_req = 0;

  #18040;    //Need_to_check 
    forever begin
    seq_item_port.get_next_item(req);
// #100;
        `uvm_info("DRV_RK", $sformatf("req.addr=%0h, req.data=%0h", req.addr, req.data), UVM_MEDIUM)

      // Pin-level driving
            // Assume some protocol waits, capture response
      @(posedge vif.clk);
      
      if (req.data_we==1'b1) begin
          
        `uvm_info("data_we", $sformatf("req.addr=%0h, req.data=%0h, req.data=%0h", req.addr, req.data, req.data_we), UVM_MEDIUM)
        wr (.addr (req.addr), .data (req.data)); 
       
        //wr (.addr (req.addr), .data (req.data)); 
    end else begin
        rd (.addr (req.addr));
        //seq_item_port.item_done(resp); // Pass RESP back
    end

        seq_item_port.item_done(req);
    end
  endtask

       // read request
        task automatic rd_resp (
            input logic  [63:0] addr         = '0,
            input logic   [1:0] size         = 2'b11,
            input logic   [7:0] be           = '1,
            input bit           rand_size_be = 0,
            input bit           rand_addr    = 0,
            input int           rand_kill    = 0, // chance of killing request in percentage
            input bit           check_result = 1'b0,
            input logic  [63:0] exp_result   = '0,
            input bit           do_wait      = 1'b0,
            input bit           kill         = 1'b0,
            output logic [63:0] result
        );
            logic [63:0] addr_int;
            logic  [1:0] size_int;
            logic  [7:0] be_int;
            logic        kill_int;
            logic [63:0] bit_mask;

            if (rand_addr) begin
           //     addr_int = get_rand_addr_from_cfg(cfg);
            end else begin
                addr_int = req.addr;
            end

            if (rand_size_be) begin
                int size_bytes;
                size_int = $urandom_range(3);
                size_bytes = 2**size_int;
                be_int = ((2**size_bytes)-1) << $urandom_range(8 - size_bytes);
            end else begin
                be_int = be;
                size_int = size;
            end

            for (int i=0; i<8; i++) begin
                bit_mask[i*8 +:8] = {8{be_int[i]}};
            end

            if (kill) begin
                kill_int = 1'b1;
            end else begin
                kill_int = (rand_kill >= $urandom_range(100,1));
            end

            if (verbosity > 0) begin
            //    $display("%t ns %s: sending read request for address 0x%8h", $time, name, addr_int);
            end

            #0;
            vif.req.data_req      = 1'b1;
            vif.req.data_we       = 1'b0;
            vif.req.data_be       = be_int;
            vif.req.data_size     = size_int;
            vif.req.address_index = addr2index(addr_int);

            do begin
                @(posedge vif.clk);
            end while (!vif.resp.data_gnt);
            $display("printing data_gnt::%0d", vif.resp.data_gnt);

            fork
                // send tag while allowing a new read to start
                begin

                    if (verbosity > 0) begin
                        //$display("%t ns %s: got grant for read address 0x%8h, sending tag 0x%6h", $time, name, addr_int, addr2tag(addr_int));
                    end

                    #0;
                    vif.req.data_req    = 1'b0;

                    #0; // one more zero delay to "win" over an earlier read that sets tag_valid to 0
                    vif.req.tag_valid   = 1'b1;
                    vif.req.address_tag = addr2tag(addr_int);

                    do begin

                        if ((this.kill_req || kill_int) && !check_result) begin // don't kill transaction when we expect a result
                            if (verbosity > 0) begin
                               $display("%t ns %s: TESTING killing read request to address 0x%8h,kill_req :: %0d", $time, name, addr_int, kill_req);
                            end
                            vif.req.kill_req = 1'b1;
                            this.kill_req = 0;
                            kill_int = 0;
                        end
                        @(posedge vif.clk);
                        #0;
                        vif.req.tag_valid = '0;
                        vif.req.kill_req = 1'b0;
                    end while (!vif.resp.data_rvalid);
                        req.data_rvalid = vif.resp.data_rvalid;
                     $display("Reading data from cache addr:: %0h, data:: %0h",req.addr, vif.resp.data_rdata);

                    result = vif.resp.data_rdata;
                   
                    if (verbosity > 0) begin
                        $display("%t ns %s: got rvalid for read address 0x%8h", $time, name, addr_int);
                    end

                    if (check_result) begin
                        a_rd_check : assert ((result & bit_mask) == exp_result) else
                        $error("%s: data mismatch. Expected 0x%16h, got 0x%16h", name, exp_result, result);
                    end

                end

                begin
                    if (do_wait)
                        wait (0); // avoid exiting fork
                end
            join_any
        endtask

        // wrapper to rd_resp without result output mapped
        task automatic rd (
            input logic  [63:0] addr         = '0,
            input logic   [1:0] size         = 2'b11,
            input logic   [7:0] be           = '1,
            input bit           rand_size_be = 0,
            input bit           rand_addr    = 0,
            input int           rand_kill    = 0, // chance of killing request in percentage
            input bit           check_result = 1'b0,
            input logic  [63:0] exp_result   = '0,
            input bit           do_wait      = 1'b0,
            input bit           kill         = 1'b0
        );
            logic [63:0] dummy_result;
            rd_resp (
                .addr         ( addr         ),
                .size         ( size         ),
                .be           ( be           ),
                .rand_size_be ( rand_size_be ),
                .rand_addr    ( rand_addr    ),
                .rand_kill    ( rand_kill    ),
                .check_result ( check_result ),
                .exp_result   ( exp_result   ),
                .do_wait      ( do_wait      ),
                .kill         ( kill         ),
                .result       ( dummy_result )
            );
        endtask


        // write request
        //task automatic dcache_driver::wr (
        task automatic wr (
            input logic [63:0] data         = 0,
            input logic [63:0] addr         = 0,
            input logic  [1:0] size         = 2'b11,
            input logic  [7:0] be           = '1,
            input bit          rand_size_be = 0,
            input bit          rand_data    = 0,
            input bit          rand_addr    = 0
        );
            logic [63:0] addr_int;
            logic [63:0] data_int;
            logic  [1:0] size_int;
            logic  [7:0] be_int;

            logic verbosity=1'b1;

        `uvm_info("data_we", $sformatf(""), UVM_MEDIUM)

            if (rand_addr) begin
                //addr_int = get_rand_addr_from_cfg(cfg);
            end else begin
                addr_int = req.addr;
            end

            if (rand_data) begin
                data_int = {$urandom,$urandom};
            end else begin
                data_int = req.data;
            end

            if (rand_size_be) begin
                int size_bytes;
                size_int = $urandom_range(3);
                size_bytes = 2**size_int;
                be_int = ((2**size_bytes)-1) << $urandom_range(8 - size_bytes);
            end else begin
                be_int = be;
                size_int = size;
            end

            if (verbosity > 0) begin
               // $display("%t ns %s: sending write request for address 0x%8h with data 0x%8h", $time, name, addr_int, data_int);
            end

            #0;
            vif.req.data_req      = 1'b1;
            //vif.req.data_we       = 1'b1;
            vif.req.data_we       = req.data_we;
            vif.req.data_be       = be_int;
            vif.req.data_size     = size_int;
            vif.req.data_wdata    = data_int;
            vif.req.address_index = addr2index(addr_int);
            vif.req.address_tag   = addr2tag(addr_int);
            vif.req.tag_valid     = 1'b1;


       //    do begin
       //        @(posedge vif.clk);
       //    end while (req.data_gnt <= vif.resp.data_gnt);
       //    `uvm_info("DATA_GNT", $sformatf("DATA_GNT_SK data_gnt is HIGH at time %0t: data_gnt = %b", $time, vif.resp.data_gnt), UVM_LOW)


         //   req.data_gnt = vif.resp.data_gnt;

          do begin
              @(posedge vif.clk);
          end while (!vif.resp.data_gnt);

           #0;
           vif.req.data_req  = 1'b0;
           vif.req.data_we   = 1'b0;
           vif.req.tag_valid = 1'b0;

        endtask

endclass
   





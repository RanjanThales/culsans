`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*; 
import tb_std_cache_subsystem_pkg::*; 
import ariane_pkg::*;
   
class dcache_monitor extends uvm_monitor;

    // UVM factory registration
    `uvm_component_utils(dcache_monitor)

    // Ports
    uvm_analysis_port #(dcache_req)  req_ap;
    uvm_analysis_port #(dcache_resp) resp_ap;

        mailbox #(dcache_req)  req_mbox;
        mailbox #(dcache_resp) resp_mbox;

culsans_env_config                c_env_cfg;

    // Virtual interface
   // virtual dcache_intf vif;
    virtual dcache_intf   vif    ;
    // Configurable variables
    string name;
    int verbosity;
    int port_idx;

int c_agt;
    int p_agt;

    // Internal counters
    int rd_req_cnt, rd_kill_cnt, rd_resp_cnt, wr_req_cnt;
    int req_id, resp_id;

    // Constructor
    function new(string name = "dcache_monitor", uvm_component parent = null);
        super.new(name, parent);
            rd_req_cnt = 0;
            rd_kill_cnt = 0;
            rd_resp_cnt = 0;
            wr_req_cnt = 0;
            req_id = 0;
            resp_id = 0;
            this.name = name;

    endfunction

    // Build phase: create ports
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

   if(!uvm_config_db #(culsans_env_config)::get(this, "*", "culsans_env_config", c_env_cfg)) begin
            `uvm_fatal("NO_c_env_cfg", "culsans_env_config not found!");
        end 

 if (!uvm_config_db#(int)::get(this, "", "c_value", c_agt)) begin 
  `uvm_fatal("NO_CVAR", "Not Getting c_value from config db!"); 
end

if (!uvm_config_db#(int)::get(this, "", "p_value", p_agt)) begin 
  `uvm_fatal("NO_CVAR", "Not Getting p_value from config db!"); 
end

    if (!uvm_config_db#(virtual dcache_intf)::get(this, "*",$sformatf("dcache_vif_%0d_%0d", c_agt, p_agt),vif)) begin 
                `uvm_fatal("NOCFG", $sformatf("No dcache_vif[c_agt][p_agt] found")); 
            end else begin 
                `uvm_info("DCACHE_CONFIG_IN_MMON_DSAI", $sformatf("---------%s[%0d][%0d]--------------", "DCACHE_INTF", c_agt, p_agt), UVM_NONE); 
            end
        req_ap  = new("req_ap", this);
        resp_ap = new("resp_ap", this);
    endfunction


 task print_stats;
        //  $display("%s: got %5d read requests, (%4d killed), %5d read responses, %5d write requests", name, rd_req_cnt, rd_kill_cnt, rd_resp_cnt, wr_req_cnt);
 `uvm_info(get_type_name(), $sformatf("%s: %5d read requests (%4d killed), %5d read responses, %5d write requests", name, rd_req_cnt, rd_kill_cnt, rd_resp_cnt, wr_req_cnt), UVM_LOW)

        endtask



  local task automatic mon_rd_req;
            $display("%t ns %s: monitoring read requests", $time, name);
            forever begin
                if (vif.req.data_req && !vif.req.data_we) begin // got read request
                    automatic dcache_req rd_req;

                    while (!vif.resp.data_gnt) begin
                        @(posedge vif.clk);
                    end

                    if (verbosity > 0) begin
                        $display("%t ns %s: got request for read", $time, name);
                    end

                    rd_req = new();
                    rd_req.trans_type    = RD_REQ;
                    rd_req.address_index = vif.req.address_index;
                    rd_req.be            = vif.req.data_be;
                    rd_req.size          = vif.req.data_size;
                    rd_req.port_idx      = port_idx;
                    rd_req.id            = this.req_id;
                    this.rd_req_cnt++;
                    this.req_id++;

                    @(negedge vif.clk);
                    while (!vif.req.tag_valid) begin
                        @(negedge vif.clk);
                    end

                    rd_req.address_tag = vif.req.address_tag;
                    rd_req.set_data_offset();

                    if (vif.req.kill_req) begin
                        if (verbosity > 0) begin
                            $display("%t ns %s: read request killed", $time, name);
                        end
                        this.rd_kill_cnt++;
                    end else begin
                        if (verbosity > 0) begin
                            $display("%t ns %s: got request for read tag 0x%6h, index 0x%3h", $time, name, rd_req.address_tag, rd_req.address_index);
                        end
                        req_mbox.put(rd_req);

                        fork begin
                            while (!vif.resp.data_rvalid) begin
                                assert (!vif.req.kill_req) else $error("%s: Got kill req without rvalid",name);
                                @(posedge vif.clk);
                            end

                            if (vif.req.kill_req) begin
                                if (verbosity > 0) begin
                                    $display("%t ns %s: read request killed", $time, name);
                                end
                                this.rd_kill_cnt++;
                            end

                            if (verbosity > 0) begin
                                $display("%t ns %s: saw read response", $time, name);
                            end
                        end join_none

                    end

                end else begin
                    @(posedge vif.clk);
                end
            end
        endtask

        // get read responses
        local task mon_rd_resp;
            dcache_resp rd_resp;
            $display("%t ns %s monitoring read responses", $time, name);
            forever begin
                if (vif.resp.data_rvalid) begin // got read request
                    rd_resp = new();
                    rd_resp.trans_type = RD_RESP;
                    rd_resp.data = vif.resp.data_rdata;
                    rd_resp.id = this.resp_id;
                    this.rd_resp_cnt++;
                    this.resp_id++;
                    #0; // add zero delay here to make sure read response is repoerted after read request if it gets served immediately
                    if (verbosity > 0) begin
                        $display("%t ns %s got read response with data 0x%8h", $time, name, rd_resp.data);
                    end
                    resp_mbox.put(rd_resp);
                end
                @(posedge vif.clk);
            end
        endtask

        // get write requests
        local task mon_wr_req;
            dcache_req  wr_req;
            dcache_resp wr_resp;
            $display("%t ns %s monitoring write requests", $time, name);
            forever begin
                if (vif.req.data_req && vif.req.data_we) begin // got write request

                    while (!vif.wr_gnt) begin
                        @(posedge vif.clk);
                    end
                    this.wr_req_cnt++;
                    if (verbosity > 0) begin
                        $display("%t ns %s got request for write", $time, name);
                    end

                    wr_req = new();
                    wr_req.trans_type      = WR_REQ;
                    wr_req.address_index = vif.req.address_index;
                    wr_req.data          = vif.req.data_wdata;
                    wr_req.be            = vif.req.data_be;
                    wr_req.size          = vif.req.data_size;
                    wr_req.port_idx      = port_idx;
                    wr_req.id            = this.req_id;
                    wr_req.address_tag   = vif.req.address_tag;
                    wr_req.set_data_offset();

                    this.req_id++;

                    // add one more cycle here to get same timing as read requests
                    @(negedge vif.clk);

                    if (verbosity > 0) begin
                        $display("%t ns %s got request for write tag 0x%6h, index 0x%3h, data 0x%8h", $time, name, wr_req.address_tag, wr_req.address_index, wr_req.data);
                    end
                    req_mbox.put(wr_req);

                    while (!vif.resp.data_gnt) begin
                        @(posedge vif.clk);
                    end
                    wr_resp = new();
                    wr_resp.trans_type = WR_RESP;
                    wr_resp.id = this.resp_id;
                    this.resp_id++;

                    if (verbosity > 0) begin
                        $display("%t ns %s got write response %s", $time, name, wr_resp.print_me());
                    end
                    resp_mbox.put(wr_resp);
                end
                @(posedge vif.clk);
            end
        endtask

 
    // Run phase: spawn tasks
    task monitor();
        fork
            mon_rd_req();
            mon_rd_resp();
            mon_wr_req();
        join_none
    endtask


 endclass


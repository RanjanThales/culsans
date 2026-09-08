  `include "uvm_macros.svh"
  import uvm_pkg::*;
import tb_pkg::*;

import tb_pkg::*;

class mcache_monitor extends uvm_monitor;
    `uvm_component_utils(mcache_monitor)

 // Analysis ports to send transactions to scoreboard or other components
    uvm_analysis_port #(dcache_req_seq_item)  req_ap;
    uvm_analysis_port #(dcache_resp_seq_item) resp_ap;

culsans_env_config                c_env_cfg;

 // Configurable fields
    string name;
    int    verbosity;
    int    port_idx;

    // Internal counters
    int rd_req_cnt;
    int rd_kill_cnt;
    int rd_resp_cnt;
    int wr_req_cnt;
    int req_id;
    int resp_id;

  int c_agt;
    int p_agt;
// virtual dcache_intf vif;

  virtual dcache_intf   vif ;

    
function new(string name = "mcache_monitor", uvm_component parent =null);
super.new(name,parent);
endfunction



function void build_phase(uvm_phase phase);
super.build_phase(phase);


   if(!uvm_config_db #(culsans_env_config)::get(this, "*", "culsans_env_config", c_env_cfg)) begin
            `uvm_fatal("NO_c_env_cfg", "culsans_env_config not found!");
        end 


//         req_ap  = new("req_ap", this);
//        resp_ap = new("resp_ap", this);


 //if (!uvm_config_db#(int)::get(this, $sformatf("d_drv[%0d][%0d]",c,p), "c_value", c_agt)) begin 
 if (!uvm_config_db#(int)::get(this, "", "c_value", c_agt)) begin 
  `uvm_fatal("NO_CVAR", "Not Getting c_value from config db!"); 
end

if (!uvm_config_db#(int)::get(this, "", "p_value", p_agt)) begin 
  `uvm_fatal("NO_CVAR", "Not Getting p_value from config db!"); 
end

    if (!uvm_config_db#(virtual dcache_intf)::get(this, "*",$sformatf("dcache_vif_%0d_%0d", c_agt, p_agt),vif)) begin 
                `uvm_fatal("NOCFG", $sformatf("No dcache_vif[c_agt][p_agt] found")); 
            end else begin 
                `uvm_info("DCACHE_CONFIG_IN_MMON_SAI", $sformatf("---------%s[%0d][%0d]--------------", "DCACHE_INTF", c_agt, p_agt), UVM_NONE); 
            end
endfunction

endclass


`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;
import tb_std_cache_subsystem_pkg::*; 
//`include "ace_cov_monitor.sv"

class dcache_agent extends uvm_agent;

  `uvm_component_utils(dcache_agent)
 
 
int c_var; 
int c;
string dmon_name; 
string mon_name; 
string drv_name; 
string drv_name_v; 
string seqr_name; 
string seqr_name_v; 
  culsans_env_config c_env_cfg;
  
  dcache_driver     d_drv[][];
  mcache_monitor    m_mon[][];
  dcache_sequencer  d_seqr[][];
  dcache_monitor          dcache_mon         [][];
 ace_cov_monitor           cov_mon; //coverage Monitor
 

  function new(string name = "dcache_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction
 
  
  
  
function void build_phase(uvm_phase phase);
    super.build_phase(phase);
 


    cov_mon = ace_cov_monitor::type_id::create("cov_mon", this);

    if (!uvm_config_db#(culsans_env_config)::get(this, "", "culsans_env_config", c_env_cfg)) begin
      `uvm_fatal("NO_ENV_CONFIG", "Not Getting env config db!");
    end
 
if (!uvm_config_db#(int)::get(this, "", "c_var", c_var)) begin 
      `uvm_fatal("NO_CVAR", "Not Getting c_var from config db!"); 
    end
 
    c = c_var  ;
 

             d_drv = new[c_env_cfg.N_C];
             m_mon = new[c_env_cfg.N_C];
             dcache_mon = new[c_env_cfg.N_C];
             d_seqr = new[c_env_cfg.N_C];
                          // Allocate second dimension arrays inside each first dim element
             for (int i = 0; i < c_env_cfg.N_C; i++) begin
                d_drv[i]  = new[c_env_cfg.N_D];
                m_mon[i]  = new[c_env_cfg.N_D];
                dcache_mon[i]  = new[c_env_cfg.N_D];
                d_seqr[i] = new[c_env_cfg.N_D];
             end
    
    for(int p=0; p < c_env_cfg.N_D; p++) begin
        drv_name = $sformatf("d_drv_%0d_%0d", c, p);
        seqr_name = $sformatf("d_seqr_%0d_%0d", c, p);
        mon_name = $sformatf("m_mon_%0d_%0d", c, p);
        dmon_name = $sformatf("dcache_mon_%0d_%0d", c, p);
        
         d_drv[c][p] = dcache_driver::type_id::create(drv_name, this);
         m_mon[c][p] = mcache_monitor::type_id::create(mon_name, this);
         dcache_mon[c][p] = dcache_monitor::type_id::create(dmon_name, this);
         d_seqr[c][p] = dcache_sequencer::type_id::create(seqr_name, this);
        
       if (d_drv[c][p] != null) begin
      `uvm_info(get_name(), $sformatf("Driver [%0d][%0d] driver_created_properly.", c, p), UVM_LOW);
      end else begin
      `uvm_info(get_name(), $sformatf("Driver [%0d][%0d] driver_not_created_properly.", c, p), UVM_LOW);
      end
         
         // d_mon[c][p] = dcache_monitor::type_id::create($sformatf("d_mon[%0d][%0d]", c, p), this);
        //d_seqr[c][p] = dcache_sequencer::type_id::create($sformatf("d_seqr[%0d][%0d]", c, p), this);

        
            //uvm_config_db#(int)::set(this, $sformatf("d_drv[%d][%d]", c,p), "c_p_var", p);
            uvm_config_db#(int)::set(this, drv_name, "c_value", c);
            uvm_config_db#(int)::set(this, drv_name, "p_value", p);


                uvm_config_db#(int)::set(this, mon_name, "c_value", c);
                uvm_config_db#(int)::set(this, mon_name, "p_value", p);

                uvm_config_db#(int)::set(this, dmon_name, "c_value", c);
                uvm_config_db#(int)::set(this, dmon_name, "p_value", p);

            
     end
  
 endfunction



function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  //d_drv_0_0.seq_item_port.connect(d_seqr_0_0.seq_item_export);

for (int c = 0; c < c_env_cfg.N_C; c++) begin
  for (int p = 0; p < c_env_cfg.N_D; p++) begin
      if (d_drv[c][p] != null && d_seqr[c][p] != null) begin
         // if (d_drv[c][p] != null) begin
         // && d_seqr[c][p] != null) begin
      d_drv[c][p].seq_item_port.connect(d_seqr[c][p].seq_item_export);
      `uvm_info(get_name(), $sformatf("Driver [%0d][%0d] seq_item_port connected successfully.", c, p), UVM_LOW);
        end else begin
       `uvm_warning(get_name(), $sformatf("Driver [%0d][%0d] seq_item_port is NOT connected!", c, p));
        end  
end
end
 



endfunction
endclass


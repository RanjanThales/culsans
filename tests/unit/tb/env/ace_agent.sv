
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;
import tb_std_cache_subsystem_pkg::*; 
//`include "ace_cov_monitor.sv"
import tb_pkg::*;

class ace_agent extends uvm_agent;
  `uvm_component_utils(ace_agent)




    parameter  int unsigned  AxiIdWidth    = culsans_pkg::IdWidth; 
    parameter  int unsigned  AxiAddrWidth  = culsans_pkg::AddrWidth; 
    parameter  int unsigned  AxiDataWidth  = culsans_pkg::DataWidth; 
    localparam int unsigned  AxiUserWidth  = culsans_pkg::UserWidth; 

  culsans_env_config c_env_cfg;

// ace_cov_monitor           cov_mon; //coverage Monitor
 ace_driver                ace_drv;
 ace_sequencer             ace_sqr;
 ace_monitor_int           ace_mon;


function new(string name = "ace_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction
 

function void build_phase(uvm_phase phase);
    super.build_phase(phase);


// In build_phase
if (!uvm_config_db#(culsans_env_config)::get(this, "", "culsans_env_config", c_env_cfg)) begin
  `uvm_fatal("NO_ENV_CONFIG", "Failed to get culsans_env_config")
end

  ace_drv = ace_driver::type_id::create("ace_drv", this);
  ace_sqr = ace_sequencer::type_id::create("ace_sqr", this);
  ace_mon = ace_monitor_int::type_id::create("ace_mon", this);



//    cov_mon = ace_cov_monitor::type_id::create("cov_mon", this);
endfunction





function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  ace_drv.seq_item_port.connect(ace_sqr.seq_item_export);
endfunction


endclass

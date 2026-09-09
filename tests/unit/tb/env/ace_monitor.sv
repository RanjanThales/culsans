`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;
import ariane_pkg::*;
import snoop_test::*;
import ace_test::*;
import tb_ace_ccu_pkg::*;
import tb_std_cache_subsystem_pkg::*;
import tb_pkg::*;




class ace_monitor_int extends uvm_monitor;
    `uvm_component_utils(ace_monitor_int)


// ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------
  parameter int unsigned AxiIdWidth   = culsans_pkg::IdWidth;
  parameter int unsigned AxiAddrWidth = culsans_pkg::AddrWidth;
  parameter int unsigned AxiDataWidth = culsans_pkg::DataWidth;

  localparam int unsigned AxiUserWidth = culsans_pkg::UserWidth;
  localparam ariane_cfg_t ArianeCfg    = culsans_pkg::ArianeSocCfg;

  // ---------------------------------------------------------------------------
  // Virtual Interfaces
  // ---------------------------------------------------------------------------
  virtual ACE_BUS_DV #(
    .AXI_ADDR_WIDTH (AxiAddrWidth),
    .AXI_DATA_WIDTH (AxiDataWidth),
    .AXI_ID_WIDTH   (AxiIdWidth),
    .AXI_USER_WIDTH (AxiUserWidth)
  ) vif;



 virtual SNOOP_BUS_DV #( 
        .SNOOP_ADDR_WIDTH (AxiAddrWidth), 
        .SNOOP_DATA_WIDTH (AxiDataWidth) 
    //) snoop_bus_dv   [NB_CORES-1:0];           // Snoop bus driven/monitored per core 
    ) svif[];           // Snoop bus driven/monitored per core 
 

 // ---------------------------------------------------------------------------
  // Variables
  // ---------------------------------------------------------------------------
  int c;
  int ace_var;
 ace_txn_item xtn;
 int k;
int c_agt;
int c_var;

  culsans_env_config c_env_cfg;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  function new(string name = "ace_monitor_int", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  // ---------------------------------------------------------------------------
  // Build Phase
  // ---------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get ace_var from config DB
    if (!uvm_config_db#(int)::get(this, "", "ace_var", c)) begin
      `uvm_fatal("NO_ACE_VAR", "ace_var not found in agent")
    end


//if (!uvm_config_db#(int)::get(this, "", "c_var", c_agt)) begin 
//      `uvm_fatal("NO_CVAR", "Not Getting c_var from config db!"); 
//    end


 
  if (!uvm_config_db#(culsans_env_config)::get(this, "", "culsans_env_config", c_env_cfg)) begin
      `uvm_fatal("NO_ENV_CONFIG", "Not Getting env config db!");
    end




// if (!uvm_config_db#(int)::get(this, "", "c_value", c_agt)) begin 
//      `uvm_fatal("NO_CVAR", "Not Getting c_value from config db in ace_monitor!"); 
//    end



    // Allocate ACE bus interface array
 //   ace_bus_dv = new[c];

    // Get virtual interface for this driver
//    if (!uvm_config_db#(virtual ACE_BUS_DV#(64,64,4,64))::get(this,"",$sformatf("ace_bus_dv_vif_%0d", c), vif)) begin
//      `uvm_fatal("ACE_BUS_DV",$sformatf("Failed to get ace_bus_dv in ACE mONITOR INT for c=%0d", c))
//    end
//    else begin
//      `uvm_info("ACE_BUS_DV_IN_ACE_MONITOR_INT",$sformatf("--------- ACE_BUS_DV[%0d] retrieved successfully ---------", c),UVM_NONE)
//    end




if (!uvm_config_db#(virtual ACE_BUS_DV#(AxiAddrWidth,AxiDataWidth,AxiIdWidth,AxiUserWidth))::get(this, "", $sformatf("ace_bus_dv_vif_%0d", c), vif)) begin
  `uvm_fatal("ACE_BUS_DV",$sformatf("Failed to get ace_bus_dv in ACE Driver for c=%0d", c))
end  else begin
      `uvm_info("ACE_BUS_DV_IN_ACE_MONITOR_INT",$sformatf("--------- ACE_BUS_DV[%0d] retrieved successfully ---------", c),UVM_NONE)
    end


 svif = new[c_env_cfg.N_C];


for (int i = 0; i < c_env_cfg.N_C; i++) begin

 if (!uvm_config_db#(virtual SNOOP_BUS_DV#(64,64))::get(this, "*", $sformatf("snoop_bus_dv_vif_%0d", c), svif[i])) begin 
                `uvm_fatal("SNOOP_BUS_DV", $sformatf("Failed to get snoop_bus_dv for c=%0d", c)); 
end else begin
      `uvm_info("SNOOP_BUS_DV_IN_ACE_MONITOR",$sformatf("--------- SNOOP_BUS_DV[%0d] retrieved successfully ---------", c),UVM_NONE)
    end
end



  endfunction


task run_phase(uvm_phase phase);

    super.run_phase(phase);

            collect_read_data();
endtask





  //--------------------------------------------------------------------------
    // READ TRANSACTION COLLECTION
    //--------------------------------------------------------------------------
    task collect_read_data();
  //      forever begin

        for(int z=0; z<1000; z++) begin
            xtn = ace_txn_item::type_id::create("xtn", this);

   //         do @(posedge vif.clk_i);    
   //         while(!(vif.ar_valid && vif.ar_ready));

        wait(vif.ar_valid && vif.ar_ready);

      xtn.ar_valid    = vif.ar_valid  ;
      xtn.ar_addr     =  vif.ar_addr     ;
      xtn.ar_id       =  vif.ar_id       ;
      xtn.ar_len      =  vif.ar_len      ;
      xtn.ar_size     =  vif.ar_size     ;
      xtn.ar_burst    =  vif.ar_burst    ;
      xtn.ar_valid    =  vif.ar_valid    ;
      xtn.ar_snoop    =  vif.ar_snoop    ;
      xtn.ar_bar      =  vif.ar_bar      ;
      xtn.ar_domain   =  vif.ar_domain   ;
      xtn.r_id        =  vif.r_id        ;
      xtn.r_data      =  vif.r_data      ;
      xtn.r_resp      =  vif.r_resp      ;
      xtn.r_user      = vif.r_user       ;
      xtn.r_valid     = vif.r_valid       ;
      xtn.r_ready     = vif.r_ready       ;
      xtn.r_last      = vif.r_last       ;
    
//for (int k = 0; k < c_agt; k++) begin
    for (int k = 0; k < c_env_cfg.N_C; k++) begin

     print_snoop(k);
 
       xtn.ac_addr      =   svif[k].ac_addr ;
       xtn.ac_prot       =   svif[k].ac_prot ;
       xtn.ac_snoop     =   svif[k].ac_snoop    ;
       xtn.ac_valid     =   svif[k].ac_valid    ;
       xtn.ac_ready     =   svif[k].ac_ready    ;

        xtn.cd_data     =   svif[k].cd_data     ;
        xtn.cd_last     =   svif[k].cd_last     ;
        xtn.cd_valid   =   svif[k].cd_valid     ;
        xtn.cd_ready    =   svif[k].cd_ready    ;
        

        xtn.cr_resp     =   svif[k].cr_resp     ;
        xtn.cr_valid    =   svif[k].cr_valid    ;
        xtn.cr_ready    =   svif[k].cr_ready    ;

        xtn.sprint();

end
 

   //     if(xtn.ar_valid) begin
   //           `uvm_info(get_type_name(), $sformatf("ARADDR=0x%0h, ",  xtn.ar_addr), UVM_MEDIUM)
   //     end 
            
      //  xtn.print(); 
        if(xtn.r_valid) begin
              `uvm_info(get_type_name(), $sformatf("ARADDR=0x%0h, RDATA=0x%0h, RVALID=0x%0h, ",  xtn.ar_addr, xtn.r_data, xtn.r_valid), UVM_MEDIUM)
        end
     //   xtn.print();

        
           end
 


    endtask




task automatic print_snoop(int core);
    if (svif[core] == null) return;

    // AC channel
    if (svif[core].ac_valid && svif[core].ac_ready) begin
      `uvm_info("SNOOP_AC", $sformatf("[CORE %0d] AC addr=0x%0h prot=0x%0h snoop=0x%0h", core, svif[core].ac_addr,svif[core].ac_prot,svif[core].ac_snoop), UVM_MEDIUM)
    end

    // CD channel
    if (svif[core].cd_valid && svif[core].cd_ready) begin
      `uvm_info("SNOOP_CD", $sformatf("[CORE %0d] CD data=0x%0h last=%0b",core,svif[core].cd_data,svif[core].cd_last),UVM_MEDIUM)
    end

    // CR channel
    if (svif[core].cr_valid && svif[core].cr_ready) begin
      `uvm_info("SNOOP_CR",$sformatf("[CORE %0d] CR resp=0x%0h",core,svif[core].cr_resp),UVM_MEDIUM)
    end
  endtask


//cache_rwc_w1_seq

//    req.addr     = 64'h0000000080060000; 
//    req.data     = 64'hBABA_CAFE; 
//    req.data_we  = 1'b1; 



//cache_rwc_w1_seq

//    req.addr     = 64'h0000000080060000; 
//    req.data     = 64'hBABA_CAFE; 
//    req.data_we  = 1'b1; 


endclass














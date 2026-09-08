
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;

// change covergroup name into ace transistion state and add  required type, response and state values only.

covergroup ace_cov_group (virtual ACE_BUS_DV#(64, 64, 4, 64) ace_bus_dv,
                          virtual SNOOP_BUS_DV#(64,64) snoop_bus_dv);
//                          virtual SNOOP_BUS_DV#(64,64) snoop_bus_dv) @(posedge ace_bus_dv.clk_i);
  option.per_instance = 1;

// =============================================================
// ==============      ACE WRITE ADDRESS CHANNEL     ===========
// =============================================================
  cp_AWDOMAIN  : coverpoint ace_bus_dv.aw_domain   {   bins domain_vals[]   = {[0:$]};       }
  cp_AWSNOOP   : coverpoint ace_bus_dv.aw_snoop    {   bins write_snoop[]   = {[0:$]};       }
  cp_AWCACHE   : coverpoint ace_bus_dv.aw_cache    {   bins aw_cache[]      = {[0:$]};       }
  cp_AWBURST   : coverpoint ace_bus_dv.aw_burst    {   bins aw_burst[]      = {[0:$]};       }
 
// =============================================================
// ==============       ACE WRITE DATA CHANNEL      ============
// =============================================================
  cp_WSTRB    : coverpoint ace_bus_dv.w_strb        { bins wstrb[] = {[0:$]};      }
  cp_LAST     : coverpoint ace_bus_dv.w_last        { bins wlast[] = {0,1};        }

// =============================================================
// ==============      ACE WRITE RESPONSE           ============
// =============================================================
  cp_BRESP    : coverpoint ace_bus_dv.b_resp        { bins bresp[] = {[0:$]};      }

// =============================================================
// ==============       ACE READ ADDRESS CHANNEL    ============
// =============================================================
    cp_ARBURST  : coverpoint ace_bus_dv.ar_burst      { bins ar_burst[]  = {[0:$]}; }
    cp_ARCACHE  : coverpoint ace_bus_dv.ar_cache      { bins ar_cache[]  = {[0:$]}; }
   // cp_ARDOMAIN : coverpoint ace_bus_dv.ar_domain     { bins ar_domain[7] = {[0:$]}; }
    cp_ARDOMAIN : coverpoint ace_bus_dv.ar_domain     { bins ar_domain[] = { 2'b00, 2'b01, 2'b10, 2'b11}; }
    cp_ARSNOOP  : coverpoint ace_bus_dv.ar_snoop      { bins ar_snoop[]  = {[0:$]}; }

// =============================================================
// ==============      ACE READ DATA CHANNEL        ============
// =============================================================
    cp_RRESP    : coverpoint ace_bus_dv.r_resp        { bins rresp[] = {[0:$]}; }
    cp_RLAST    : coverpoint ace_bus_dv.r_last        { bins rlast[] = {0,1};   }

// =============================================================
// ==============     SNOOP REQUEST CHANNEL         ============
// =============================================================
    cp_ACSNOOP  : coverpoint snoop_bus_dv.ac_snoop      { bins ac_snoop[]    = {[0:$]};     }
    cp_ACPROT   : coverpoint snoop_bus_dv.ac_prot       { bins ac_prot[]     = {[0:$]};     }
    cp_ACVALID  : coverpoint snoop_bus_dv.ac_valid      { bins ac_valid[2]   = {0,1};       }
    cp_ACREADY  : coverpoint snoop_bus_dv.ac_ready      { bins ac_ready[2] =   {0,1};       }

// =============================================================
// ==============    SNOOP RESPONSE (CR) CHANNEL    ============
// =============================================================
    cp_CRRESP   : coverpoint  snoop_bus_dv.cr_resp     {    bins cr_resp[]   = {[0:$]};   }
    cp_CRVALID  : coverpoint snoop_bus_dv.cr_valid     {    bins cr_valid[2] = {[0:1]};   }
    cp_CRREADY  : coverpoint snoop_bus_dv.cr_ready     {    bins cr_ready[2] = {[0:1]};   }

// =============================================================
// ==============  SNOOP DATA RESPONSE (CD) CHANNEL  ===========
// =============================================================
    cp_CDLAST    : coverpoint snoop_bus_dv.cd_last      { bins cd_last[]  = {0,1};     }
    cp_CDVALID   : coverpoint snoop_bus_dv.cd_valid     { bins cd_valid[] = {0,1};     }
    cp_CDREADY   : coverpoint snoop_bus_dv.cd_ready     { bins cd_ready[] = {0,1};     }

// =============================================================
// Cross coverage 
// =============================================================
    x_write_snoop  : cross cp_AWSNOOP, cp_AWDOMAIN;
    x_read_snoop   : cross cp_ARSNOOP, cp_ARDOMAIN;
    x_req_rsp      : cross cp_ACSNOOP, cp_CRRESP;

/*

  ar_snoop_cp: coverpoint ace_bus_dv.ar_snoop {
    option.auto_bin_max = 16;
    bins read_snoop[] = {[0:15]};
  }
 
  aw_domain_cp: coverpoint ace_bus_dv.aw_domain {
    bins domain_vals[] = {[0:3]};
  }

  ar_domain_cp: coverpoint ace_bus_dv.ar_domain {
    bins domain_vals[] = {[0:3]};
  }

  cr_resp_cp: coverpoint snoop_bus_dv.cr_resp {
    bins cr_resp_vals[] = {[0:15]};
  }

  cr_valid_cp: coverpoint snoop_bus_dv.cr_valid {
    bins cr_valid_vals[] = {[0:1]};
  }

  ar_addr_cp: coverpoint ace_bus_dv.ar_addr {
    bins ar_addr_vals[9] = {64'h80060000, 64'h80061000,
                           64'h80062000, 64'h80063000,
                           64'h80064000, 64'h80065000,
                           64'h80066000, 64'h80067000,
                           64'h80068000 };
  }

 aw_addr_cp: coverpoint ace_bus_dv.aw_addr {
    bins aw_addr_vals[9] = {64'h80060000, 64'h80061000,
                           64'h80062000, 64'h80063000,
                           64'h80064000, 64'h80065000,
                           64'h80066000, 64'h80067000,
                           64'h80068000 };

  }

*/


endgroup


covergroup read_collision_cov_group (virtual ACE_BUS_DV#(64, 64, 4, 64) ace_bus_dv,
                                    virtual SNOOP_BUS_DV#(64,64) snoop_bus_dv) @(posedge ace_bus_dv.clk_i);
  option.per_instance = 1;

  aw_addr_coll_cp: coverpoint ace_bus_dv.aw_addr {
    bins aw_addr_vals[3] = {64'h80060000, 64'h80060010, 64'h80060020};
  }

  ar_addr_coll_cp: coverpoint ace_bus_dv.ar_addr {
    bins ar_addr_vals[3] = {64'h80080000, 64'h80060010, 64'h80060020};
  }

//  data_we_cp: coverpoint ace_bus_dv.data_we {
//    bins data_we_vals[] = {0, 1};
//  }

//  w_data_cp: coverpoint ace_bus_dv.w_data {
//    bins w_data_vals[2] = {64'hBABA, 64'hCAFE};
//  }

endgroup

//ace_transistion_state --- name change
//For Transistions aw_snoop, domain add only required valus

covergroup sample_cov_group (virtual ACE_BUS_DV#(64, 64, 4, 64) ace_bus_dv,
                          virtual SNOOP_BUS_DV#(64,64) snoop_bus_dv) @(posedge ace_bus_dv.clk_i);
  option.per_instance = 1;

  samp_aw_snoop_cp: coverpoint ace_bus_dv.aw_snoop {
    option.auto_bin_max = 8;
    bins write_snoop[] = {[0:7]};
  }

  samp_ar_snoop_cp: coverpoint ace_bus_dv.ar_snoop {
    option.auto_bin_max = 16;
    bins read_snoop[] = {[0:15]};
  }
 
  samp_aw_domain_cp: coverpoint ace_bus_dv.aw_domain {
    bins domain_vals[] = {[0:3]};
  }

  samp_ar_domain_cp: coverpoint ace_bus_dv.ar_domain {
    bins domain_vals[] = {[0:3]};
  }

  samp_cr_resp_cp: coverpoint snoop_bus_dv.cr_resp {
    bins cr_resp_vals[] = {[0:15]};
  }

  

 samp_ar_addr_coll_cp: coverpoint ace_bus_dv.ar_addr {
    bins ar_addr_vals[1] = {64'h80060000};
  }

// samp_aw_addr_coll_cp: coverpoint ace_bus_dv.aw_addr {
//    bins ar_addr_vals[1] = {64'h80060000};
//  }



  samp_ac_addr_cp: coverpoint snoop_bus_dv.ac_addr {
    bins cr_resp_vals[] = {64'h80060000};
  }



 samp_ac_snoop_cp: coverpoint snoop_bus_dv.ac_snoop {
    bins ac_snoop_vals[15] = {[0:15]};
  }


 samp_ac_valid_cp: coverpoint snoop_bus_dv.ac_valid {
    bins ac_valid_vals[2] = {[0:1]};
  }

 samp_ac_ready_cp: coverpoint snoop_bus_dv.ac_ready {
    bins ac_ready_vals[2] = {[0:1]};
  }

  samp_cr_resp: coverpoint snoop_bus_dv.cr_resp {   
    bins cr_resp_all_vals[] = {[0 : 31]}; 
  }


 samp_cr_valid_cp: coverpoint snoop_bus_dv.cr_valid {
    bins cr_valid_vals[2] = {[0:1]};
  }


 samp_cr_ready_cp: coverpoint snoop_bus_dv.cr_ready {
    bins cr_ready_vals[2] = {[0:1]};
  }

endgroup




class ace_cov_monitor extends uvm_monitor;
  `uvm_component_utils(ace_cov_monitor)


  bit enable_cov_A;
  bit enable_cov_B;
  bit enable_cov_C;
  int NB_CORES = 4;

  parameter int unsigned AxiIdWidth   = culsans_pkg::IdWidth;
  parameter int unsigned AxiAddrWidth = culsans_pkg::AddrWidth;
  parameter int unsigned AxiDataWidth = culsans_pkg::DataWidth;
  localparam int unsigned AxiUserWidth = culsans_pkg::UserWidth;

  //-----------------------------------------------------------------
  // Virtual Interface Array (per ACE core)
  //-----------------------------------------------------------------
  virtual ACE_BUS_DV #(
      .AXI_ADDR_WIDTH (AxiAddrWidth),
      .AXI_DATA_WIDTH (AxiDataWidth),
      .AXI_ID_WIDTH   (AxiIdWidth),
      .AXI_USER_WIDTH (AxiUserWidth)
  ) ace_bus_dv[];


virtual SNOOP_BUS_DV #( 
       .SNOOP_ADDR_WIDTH ( AxiAddrWidth ), 
       .SNOOP_DATA_WIDTH ( AxiDataWidth )
  ) snoop_bus_dv[];
 
   culsans_env_config c_env_cfg;

   function new(string name = "ace_cov_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

ace_cov_group               cg_per_core[];
read_collision_cov_group    rd_coll_cg[];
sample_cov_group            samp_cov_cg[];
  //-----------------------------------------------------------------
  // Build Phase 
  //-----------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

// Get enable flags from config_db (default = 0)
    if (!uvm_config_db#(bit)::get(this, "", "enable_cov_A", enable_cov_A))
      enable_cov_A = 0;

    if (!uvm_config_db#(bit)::get(this, "", "enable_cov_B", enable_cov_B))
      enable_cov_B = 0;


 if (!uvm_config_db#(bit)::get(this, "", "enable_cov_C", enable_cov_C))
      enable_cov_C = 0;


    // Get environment config
    if (!uvm_config_db#(culsans_env_config)::get(this, "*", "culsans_env_config", c_env_cfg))
      `uvm_fatal("NO_C_ENV_CFG", "culsans_env_config not found!")

    // Create interface handle array
    ace_bus_dv = new[c_env_cfg.N_C];
    snoop_bus_dv = new[c_env_cfg.N_C];

    // Get ACE interface handles for each core
    for (int c = 0; c < c_env_cfg.N_C; c++) begin
      if (!uvm_config_db#(virtual ACE_BUS_DV#(AxiAddrWidth, AxiDataWidth, AxiIdWidth, AxiUserWidth))::get(this, "*", $sformatf("ace_bus_dv_vif_%0d", c), ace_bus_dv[c])) begin
        `uvm_fatal("ACE_VIF_ERR", $sformatf("Failed to get ace_bus_dv_vif_%0d", c))
      end

     if (!uvm_config_db#(virtual SNOOP_BUS_DV#(AxiAddrWidth, AxiDataWidth))::get(this, "*", $sformatf("snoop_bus_dv_vif_%0d", c), snoop_bus_dv[c])) begin
        `uvm_fatal("SNOOP_VIF_ERR", $sformatf("Failed to get snoop_bus_dv_vif_%0d", c))
      end

    end
  endfunction : build_phase

  //-----------------------------------------------------------------
  // Run Phase — sample coverage
  //-----------------------------------------------------------------


//    task run_phase(uvm_phase phase);  
//      super.run_phase(phase);  
//      
//      // Create covergroup array  
//      cg_per_core = new[c_env_cfg.N_C];  
//      rd_coll_cg  = new[c_env_cfg.N_C];  
//      samp_cov_cg  = new[c_env_cfg.N_C];  
//      
//      // Construct covergroup instances per core  
//      for (int c = 0; c < c_env_cfg.N_C; c++) begin  
//        cg_per_core[c] = new(ace_bus_dv[c], snoop_bus_dv[c]);  
//        rd_coll_cg[c]  = new(ace_bus_dv[c], snoop_bus_dv[c]);  
//        samp_cov_cg[c]  = new(ace_bus_dv[c], snoop_bus_dv[c]);  
//      end  
      
      // Sample continuously  
//     forever begin  
//        for (int c = 0; c < c_env_cfg.N_C; c++) begin  
//          @(posedge ace_bus_dv[c].clk_i); 
//    
//    //    if (ace_bus_dv[c].aw_valid && ace_bus_dv[c].aw_ready) begin
//
//              cg_per_core[c].sample();
//              $display("coverage samplings are cg_per_core[%0d]", c);
//    
//    /*
//          if (enable_cov_A)
//            cg_per_core[c].sample();
//          if (enable_cov_B)
//            rd_coll_cg[c].sample();
//       if (enable_cov_C)
//            samp_cov_cg[c].sample();
//    */
//    //    end
//    
//    //    else if (ace_bus_dv[c].ar_valid && ace_bus_dv[c].ar_ready) begin
//    //     cg_per_core[c].sample();
//    
//    
//    
//    /*    if (enable_cov_A)
//            cg_per_core[c].sample();
//          if (enable_cov_B)
//            rd_coll_cg[c].sample();
//    
//         if (enable_cov_C)
//            samp_cov_cg[c].sample();
//    */
//        end
//        end  
//    //  end 




task run_phase(uvm_phase phase);
  super.run_phase(phase);

  // Create covergroup arrays
  cg_per_core = new[c_env_cfg.N_C];

  // Create covergroup instances
  for (int c = 0; c < c_env_cfg.N_C; c++) begin
    cg_per_core[c] = new(ace_bus_dv[c], snoop_bus_dv[c]);
  end

  // Spawn one thread per core
  fork
    for (int c = 0; c < c_env_cfg.N_C; c++) begin
      automatic int core_id = c;
      fork
        forever begin
          @(posedge ace_bus_dv[core_id].clk_i);
          cg_per_core[core_id].sample();
         // $display("sampling core %0d", core_id);
        end
      join_none
    end
  join_none
endtask


endclass 

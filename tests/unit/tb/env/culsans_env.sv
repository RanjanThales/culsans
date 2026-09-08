`include "uvm_macros.svh" 
import uvm_pkg::*;
import ariane_pkg::*; 
import snoop_test::*; 
import ace_test::*; 
import tb_ace_ccu_pkg::*; 
import tb_std_cache_subsystem_pkg::*; 
import tb_pkg::*;

class culsans_enviroment extends uvm_env;
	`uvm_component_utils(culsans_enviroment)

    parameter  int unsigned  AxiIdWidth    = culsans_pkg::IdWidth; 
    parameter  int unsigned  AxiAddrWidth  = culsans_pkg::AddrWidth; 
    parameter  int unsigned  AxiDataWidth  = culsans_pkg::DataWidth; 
    localparam int unsigned  AxiUserWidth  = culsans_pkg::UserWidth; 
    localparam ariane_cfg_t  ArianeCfg     = culsans_pkg::ArianeSocCfg; 
 
    localparam int unsigned  NUM_WORDS     = 4**10; 
    logic enable_icache_random_gen = 1;
    logic [63:0]   addr, base_addr;            // Generic address variables 
    logic [63:0]   data, base_data;            // Generic data variables 
 
    string         testname;                   // Test name via plusarg 
    
    culsans_env_config                c_env_cfg;
    ace_cov_monitor                  cov_mon; //coverage Monitor
 
        uvm_event finish_event;


    task automatic test_header(string testname, string description=""); 
        `uvm_info("TEST_HEADER", "--------------------------------------------------------------------------", UVM_NONE) 
        `uvm_info("TEST_HEADER", $sformatf("Running test %s", testname), UVM_NONE) 
        `uvm_info("TEST_HEADER", description, UVM_NONE) 
        `uvm_info("TEST_HEADER", "--------------------------------------------------------------------------", UVM_NONE)
       
    endtask 

/////////////////////////////////////////////
    //-------------------------------------------------------------------------- 
    // Monitor, Driver, and Checker Declarations 
    //-------------------------------------------------------------------------- 

        ace_monitor   #(.IW(AxiIdWidth), .AW(AxiAddrWidth), .DW(AxiDataWidth), .UW(AxiUserWidth)) 
        //ace_mon      [NB_CORES-1:0];           // ACE protocol monitor per core 
        ace_mon      [];           // ACE protocol monitor per core 
        
        snoop_monitor #(.AW(AxiAddrWidth), .DW(AxiDataWidth)) 
        //snoop_mon    [NB_CORES-1:0];           // Snoop bus monitor per core 
        snoop_mon    [];           // Snoop bus monitor per core 
        
        ace_ccu_monitor #( 
        .AxiAddrWidth      (AxiAddrWidth               ), 
        .AxiDataWidth      (AxiDataWidth               ), 
        .AxiIdWidthMasters (AxiIdWidth                 ), 
        .AxiIdWidthSlaves  (culsans_pkg::IdWidthToXbar ), 
        .AxiUserWidth      (AxiUserWidth               ), 
        //.NoMasters         (NB_CORES                   ),    //NEED_TO_SEE 
        .NoMasters         (4                   ), 
        .NoSlaves          (1                          ), 
        .TimeTest          (0                          ) 
        ) ccu_mon;                                 // ACE CCU monitor instance 
    //-------------------------------------------------------------------------- 
    // Interface Declarations for Each Core 
    //-------------------------------------------------------------------------- 
    virtual dcache_intf                  dcache_if    [][]; // DCache ports 
    virtual dcache_sram_if               dc_sram_if   [];               // SRAM interface 
    virtual dcache_gnt_if                gnt_if       [];               // Grant interface 
    virtual sram_intf #(8, 64, NUM_WORDS) sram_if     [];               // SRAM itself 
    virtual amo_intf                     amo_if       [];               // Atomic operations 
    virtual icache_intf                  icache_if    [];               // ICache interface 
    virtual dcache_mgmt_intf             mgmt_if      [];               // DCache management 
    virtual clk_rst_intf                 clk_rst_if             ;

    virtual SNOOP_BUS_DV #( 
        .SNOOP_ADDR_WIDTH (AxiAddrWidth), 
        .SNOOP_DATA_WIDTH (AxiDataWidth) 
    //) snoop_bus_dv   [NB_CORES-1:0];           // Snoop bus driven/monitored per core 
    ) snoop_bus_dv   [];           // Snoop bus driven/monitored per core 
 
    virtual ACE_BUS_DV #( 
        .AXI_ADDR_WIDTH (AxiAddrWidth), 
        .AXI_DATA_WIDTH (AxiDataWidth), 
        .AXI_ID_WIDTH   (AxiIdWidth), 
        .AXI_USER_WIDTH (AxiUserWidth) 
    //) ace_bus_dv     [NB_CORES-1:0];           // ACE protocol bus per core 
    ) ace_bus_dv     [];           // ACE protocol bus per core 
     
    virtual AXI_BUS_DV #( 
        .AXI_ADDR_WIDTH (AxiAddrWidth), 
        .AXI_DATA_WIDTH (AxiDataWidth), 
        .AXI_ID_WIDTH   (culsans_pkg::IdWidthToXbar), 
        .AXI_USER_WIDTH (AxiUserWidth) 
    ) axi_bus_dv     [0:0];                     // AXI bus (usually to/from xbar) 
    //) axi_bus_dv     [];                     // AXI bus (usually to/from xbar) 
 
    //-------------------------------------------------------------------------- 
    // Verification Component Instances 
    //-------------------------------------------------------------------------- 
    dcache_driver           dcache_drv         [][]; // DCache drivers 
    dcache_monitor          dcache_mon         [][]; // Monitors 
    dcache_mgmt_driver      dcache_mgmt_drv    [];               // DCache mgmt driver 
    dcache_mgmt_monitor     dcache_mgmt_mon    [];               // DCache mgmt monitor 
    icache_driver           icache_drv         [];               // ICache driver 
    amo_driver              amo_drv            [];               // AMO driver 
    amo_monitor             amo_mon            [];               // AMO monitor


   dcache_agent             d_agt[]                ;   //Dcache Agent 
 
    std_dcache_checker #( 
        //.NB_CORES        (NB_CORES     ),      NEED_TO_SEE 
        .NB_CORES        (4     ), 
        .SRAM_DATA_WIDTH (AxiDataWidth ), 
        .SRAM_NUM_WORDS  (NUM_WORDS    ) 
    ) dcache_chk;                                             // DCache functional checker 
 
    //-------------------------------------------------------------------------- 
    // Scoreboard and Mailbox Declarations 
    //-------------------------------------------------------------------------- 
    std_cache_scoreboard   cache_scbd [];             // Scoreboard per core 
 
    // Data cache mailbox communication per port/per core 
    mailbox #(dcache_req)  dcache_req_mbox       [][]; 
    mailbox #(dcache_resp) dcache_resp_mbox      [][]; 
    mailbox #(dcache_req)  dcache_req_mbox_fwd   []; 
    mailbox #(dcache_resp) dcache_resp_mbox_fwd  []; 
 
    // Atomic memory mailbox communication 
    mailbox #(amo_req)     amo_req_mbox          []; 
    mailbox #(amo_resp)    amo_resp_mbox         []; 
    mailbox #(amo_req)     amo_req_mbox_fwd      []; 
    mailbox #(amo_resp)    amo_resp_mbox_fwd     []; 
 
    mailbox #(dcache_mgmt_trans) mgmt_mbox       []; // DCache mgmt transactions 
 
    // Protocol channel mailboxes per core (ACE and snoop) 
    mailbox aw_mbx []; 
    mailbox w_mbx  []; 
    mailbox b_mbx  []; 
    mailbox ar_mbx []; 
    mailbox r_mbx  []; 
    mailbox ac_mbx []; 
    mailbox cd_mbx []; 
    mailbox cr_mbx []; 
 
    //-------------------------------------------------------------------------- 
    // Control, Utility and Randomization Variables 
    //-------------------------------------------------------------------------- 
    bit enable_mem_check    = 1;                        // Memory check enable 
    bit enable_ccu_mon      = 1;                        // CCU monitor enable/disable 
    bit ccu_mon_end_check   = 0;                        // End-of-test flag 
 
    int timeout             = 500000;                   // Default test timeout 
    int wait_time           = 0;                        // Custom wait time for synchronizations 
    int test_id             = -1;                       // Test ID from plusarg or auto-assignment 
    int rep_cnt;                                        // Repetition count for randomization/loops 
 
 
    //-------------------------------------------------------------------------- 
    // Constructor: Initializes the testclass and event handle 
    
    //-------------------------------------------------------------------------- 
    // UVM build_phase: Environment and interface setup 
    //-------------------------------------------------------------------------- 
    
    
     function new(string name="culsans_enviroment", uvm_component parent=null); 
        super.new(name, parent); 
       // finish_event = new("finish_event"); 
    endfunction 

    
    
    
    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
      


      cov_mon = ace_cov_monitor::type_id::create("cov_mon", this);
 
      // uvm_config_db#(uvm_event)::set(this, "*", "finish_event", finish_event);


        if (!uvm_config_db#(uvm_event)::get(this, "", "finish_event", finish_event)) begin
            `uvm_fatal("CONFIG_DB_ERROR", "Unable to get finish_event from config DB");
        end

 
        if(!uvm_config_db #(virtual clk_rst_intf)::get(this, "*", "clk_rst_if", clk_rst_if)) begin
            `uvm_fatal("NO_CLK_RST_INTF", "CLK_RST_INTF interface not found in config db!");
        end 
  
        if(!uvm_config_db #(culsans_env_config)::get(this, "*", "culsans_env_config", c_env_cfg)) begin
            `uvm_fatal("NO_c_env_cfg", "culsans_env_config not found!");
        end 

        
        //if(c_env_cfg.has_virtual_sequencer)
        //v_sqr = virtual_sequencer::type_id::create("v_sqr",this);
/*
       
        if (!uvm_config_db#(int)::get(null, "*", "NB_CORES", NB_CORES)) begin
            `uvm_fatal("NO_NB_CORES", "Config not found!");
        end
        
        if(!uvm_config_db#(int)::get(null, "*", "DCACHE_PORTS", DCACHE_PORTS)) begin
            `uvm_fatal("NO_DCACHE_PORTS", "Config not found!");
        end
*/


       if (!$value$plusargs("TESTNAME=%s", testname)) begin
            $error("No TESTNAME plusarg given");
            end

        // Fetch AXI bus interface from UVM config DB 
        if (!uvm_config_db #(virtual AXI_BUS_DV #( 
                .AXI_ADDR_WIDTH (AxiAddrWidth), 
                .AXI_DATA_WIDTH (AxiDataWidth), 
                .AXI_ID_WIDTH   (culsans_pkg::IdWidthToXbar), 
                .AXI_USER_WIDTH (AxiUserWidth) 
            ))::get(this, "*", "axi_bus_dv", axi_bus_dv[0])) 
        begin 
            `uvm_fatal("NO_AXI", "AXI interface not found in config db!"); 
        end 
         
        // Register event handle for test finish 
        //uvm_config_db#(uvm_event)::set(this, "*", "finish_event", finish_event); 
 
        // ---------------------------------------------------------------------- 
        // Setup all mailbox, interface, driver, monitor, checker, etc. instances 
        // ---------------------------------------------------------------------- 
       
        
  
  // allocate the dynamic arrays here first
                dcache_if = new[c_env_cfg.N_C];
                
                dcache_drv = new[c_env_cfg.N_C];
                dcache_mon = new[c_env_cfg.N_C];
                ace_mon = new[c_env_cfg.N_C];
                dcache_mgmt_drv = new[c_env_cfg.N_C];
                dcache_mgmt_mon = new[c_env_cfg.N_C];
                icache_drv = new[c_env_cfg.N_C];
                amo_drv = new[c_env_cfg.N_C];
                amo_mon = new[c_env_cfg.N_C];
                cache_scbd = new[c_env_cfg.N_C];
                snoop_mon = new[c_env_cfg.N_C];

                
    //mail_box_moved_to_connect               
                //dcache_req_mbox = new[c_env_cfg.N_C]; //moved_to_connect
                //dcache_resp_mbox = new[c_env_cfg.N_C];
       
        for (int c = 0; c < c_env_cfg.N_C; c++) begin 
        dcache_if[c]       = new[c_env_cfg.N_D];
        dcache_drv[c]      = new[c_env_cfg.N_D];
        dcache_mon[c]      = new[c_env_cfg.N_D];
        
        end
         
        for (int c = 0; c < c_env_cfg.N_C; c++) begin 
            for (int p = 0; p < c_env_cfg.N_D; p++) begin 
 
                // Fetch dcache interface for each core/port 
                if (!uvm_config_db#(virtual dcache_intf)::get(this, "*", $sformatf("dcache_vif_%0d_%0d", c, p), dcache_if[c][p])) begin 
                    `uvm_fatal("NOCFG", $sformatf("No dcache_vif[%0d][%0d] found", c, p)); 
                end else begin 
                    `uvm_info("DCACHE_CONFIG", $sformatf("---------%s[%0d][%0d]--------------", "DCACHE_INTF", c, p), UVM_NONE); 
                end

               if (dcache_if[c][p] == null) begin
                `uvm_fatal("NULLIF", $sformatf("Null dcache interface handle at [%0d][%0d]", c, p));
               end 

                // Construct drivers and monitors for core/port 
                //dcache_drv[c][p] = new(dcache_if[c][p], ArianeCfg, $sformatf("%s[%0d][%0d]", "dcache_driver", c, p)); 
                //dcache_mon[c][p] = new(dcache_if[c][p], p, $sformatf("%s[%0d][%0d]", "dcache_monitor", c, p));
               // dcache_req_mbox [c][p] = new();  //moved_to_connect
               // dcache_resp_mbox [c][p] = new(); //moved_to_connect



            end 
 
           end 

  // allocate the dynamic arrays here first
              dcache_if = new[c_env_cfg.N_C];
              dc_sram_if  = new [c_env_cfg.N_C];               // SRAM interface 
              gnt_if      = new [c_env_cfg.N_C];               // Grant interface 
              sram_if     = new [c_env_cfg.N_C];               // SRAM itself 
              amo_if      = new [c_env_cfg.N_C];               // Atomic operations 
              icache_if   = new [c_env_cfg.N_C];               // ICache interface 
              mgmt_if     = new [c_env_cfg.N_C];               // DCache management
              snoop_bus_dv = new [c_env_cfg.N_C];
              ace_bus_dv =   new [c_env_cfg.N_C];

         d_agt = new[c_env_cfg.N_C];
   
        for (int c = 0; c < c_env_cfg.N_C; c++) begin

         uvm_config_db#(int)::set(this, $sformatf("d_agt[%0d]", c), "c_var", c);

        
        d_agt[c] = dcache_agent::type_id::create($sformatf("d_agt[%0d]", c), this);

           

            if (!uvm_config_db#(virtual dcache_sram_if)::get(this, "*", $sformatf("d_sram_vif_%0d", c), dc_sram_if[c])) 
                `uvm_fatal("NOCFG", $sformatf("No dcache_sram_vif[%0d] found", c)); 
            if (!uvm_config_db#(virtual dcache_gnt_if)::get(this, "*", $sformatf("d_gnt_vif_%0d", c), gnt_if[c])) 
                `uvm_fatal("NOCFG", $sformatf("No dcache_gnt_vif[%0d] found", c)); 
            if (!uvm_config_db#(virtual sram_intf #(8, 64, NUM_WORDS))::get(this, "*", $sformatf("sram_if_vif_%0d", c), sram_if[c])) 
                `uvm_fatal("SRAM_VIF", $sformatf("Failed to get sram_if for c=%0d", c)); 
            if (!uvm_config_db#(virtual amo_intf)::get(this, "*", $sformatf("amo_if_vif_%0d", c), amo_if[c])) 
                `uvm_fatal("AMO_VIF", $sformatf("Failed to get amo_if for c=%0d", c)); 
            if (!uvm_config_db#(virtual icache_intf)::get(this, "*", $sformatf("icache_if_vif_%0d", c), icache_if[c])) 
                `uvm_fatal("ICACHE_VIF", $sformatf("Failed to get icache_if for c=%0d", c)); 
            if (!uvm_config_db#(virtual dcache_mgmt_intf)::get(this, "*", $sformatf("dcache_mgmt_if_vif_%0d", c), mgmt_if[c])) 
                `uvm_fatal("MGMT_VIF", $sformatf("Failed to get dcache_mgmt_if for c=%0d", c)); 
            if (!uvm_config_db#(virtual SNOOP_BUS_DV#(64,64,4,64))::get(this, "*", $sformatf("snoop_bus_dv_vif_%0d", c), snoop_bus_dv[c])) 
                `uvm_fatal("SNOOP_BUS_DV", $sformatf("Failed to get snoop_bus_dv for c=%0d", c)); 
            if (!uvm_config_db#(virtual ACE_BUS_DV#(64,64,4,64))::get(this, "*", $sformatf("ace_bus_dv_vif_%0d", c), ace_bus_dv[c])) 
                `uvm_fatal("ACE_BUS_DV", $sformatf("Failed to get ace_bus_dv for c=%0d", c)); 

            dcache_mgmt_drv[c] = new(mgmt_if[c], $sformatf("%s[%0d]", "dcache_mgmt_driver", c)); 
            icache_drv[c]      = new(icache_if[c], ArianeCfg, $sformatf("%s[%0d]", "icache_driver", c)); 
            amo_drv[c]         = new(amo_if[c], ArianeCfg, $sformatf("%s[%0d]", "amo_driver", c)); 
            dcache_chk         = new(sram_if, dc_sram_if, ArianeCfg, "dcache_checker"); 
            cache_scbd[c]      = new(dc_sram_if[c], gnt_if[c], ArianeCfg, $sformatf("%s[%0d]","dcache_scoreboard",c)); 
            snoop_mon[c]       = new(snoop_bus_dv[c]); 
            amo_mon[c]         = new(amo_if[c], $sformatf("%s[%0d]","amo_monitor",c)); 
            ace_mon[c]         = new(ace_bus_dv[c]);
            dcache_mgmt_mon[c] = new(mgmt_if[c], $sformatf("%s[%0d]","dcache_mgmt_monitor",c));
        end 

            // Bind CCU monitor to verification buses 
            //ccu_mon = new(ace_bus_dv, axi_bus_dv[0], snoop_bus_dv);             //need_to_see 
 
            // Optionally enable/disable CCU monitor from plusarg 
            void'($value$plusargs("ENABLE_CCU_MON=%b", enable_ccu_mon)); 
       endfunction 



function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(get_full_name(), "CONNECT PHASE COMPLETE", UVM_LOW)
    $display("no_of_cores=%d", c_env_cfg.N_C);
    $display("no_of_dcache_port=%d", c_env_cfg.N_D);
    $display("name=%d", c_env_cfg.name);

    dcache_req_mbox = new[c_env_cfg.N_C];
    dcache_resp_mbox = new[c_env_cfg.N_C];
   
    dcache_req_mbox_fwd  = new [c_env_cfg.N_C]; 
    dcache_resp_mbox_fwd = new [c_env_cfg.N_C]; 
    amo_req_mbox         = new [c_env_cfg.N_C]; 
    amo_resp_mbox        = new [c_env_cfg.N_C]; 
    amo_req_mbox_fwd     = new [c_env_cfg.N_C]; 
    amo_resp_mbox_fwd    = new [c_env_cfg.N_C]; 
 
     mgmt_mbox =new[c_env_cfg.N_C]; // DCache mgmt transactions 
     aw_mbx    =new[c_env_cfg.N_C]; 
     w_mbx     =new[c_env_cfg.N_C]; 
     b_mbx     =new[c_env_cfg.N_C]; 
     ar_mbx    =new[c_env_cfg.N_C]; 
     r_mbx     =new[c_env_cfg.N_C]; 
     ac_mbx    =new[c_env_cfg.N_C]; 
     cd_mbx    =new[c_env_cfg.N_C]; 
     cr_mbx    =new[c_env_cfg.N_C]; 

       for (int c = 0; c < c_env_cfg.N_C; c++) begin
        dcache_req_mbox[c] = new[c_env_cfg.N_D];
        dcache_resp_mbox[c]= new[c_env_cfg.N_D];

        for (int p = 0; p < c_env_cfg.N_D; p++) begin
                
                dcache_req_mbox [c][p] = new();
                dcache_resp_mbox [c][p] = new();

                if (d_agt[c].dcache_mon[c][p] == null)
                `uvm_fatal("NULL_MON", $sformatf("dcache_mon[%0d][%0d] is null in connect_phase", c, p));
      
                if (dcache_req_mbox[c][p] == null)
                `uvm_fatal("NULL_MBOX", $sformatf("dcache_req_mbox[%0d][%0d] is null in connect_phase", c, p));
                if (dcache_resp_mbox[c][p] == null)
                `uvm_fatal("NULL_MBOX", $sformatf("dcache_resp_mbox[%0d][%0d] is null in connect_phase", c, p)); 
                d_agt[c].dcache_mon[c][p].req_mbox  = dcache_req_mbox[c][p];
                d_agt[c].dcache_mon[c][p].resp_mbox = dcache_resp_mbox[c][p];
                cache_scbd[c].dcache_req_mbox[p]  = dcache_req_mbox  [c][p];
                cache_scbd[c].dcache_resp_mbox[p] = dcache_resp_mbox [c][p];
        end
        
        // Create per-core mailboxes 
            mgmt_mbox[c]            = new(); 
            amo_req_mbox[c]         = new(); 
            amo_resp_mbox[c]        = new(); 
            amo_req_mbox_fwd[c]     = new(); 
            amo_resp_mbox_fwd[c]    = new(); 
            dcache_req_mbox_fwd[c]  = new(); 
            dcache_resp_mbox_fwd[c] = new(); 
            aw_mbx[c]               = new(); 
            w_mbx[c]                = new(); 
            b_mbx[c]                = new(); 
            ar_mbx[c]               = new(); 
            r_mbx[c]                = new(); 
            ac_mbx[c]               = new(); 
            cd_mbx[c]               = new(); 
            cr_mbx[c]               = new(); 
             
      end

    
    
    for (int c = 0; c < c_env_cfg.N_C; c++) begin
            
            snoop_mon[c].ac_mbx = ac_mbx[c];
            snoop_mon[c].cd_mbx = cd_mbx[c];
            snoop_mon[c].cr_mbx = cr_mbx[c];
            dcache_mgmt_mon[c].mbox = mgmt_mbox[c];
            amo_mon[c].req_mbox  = amo_req_mbox[c];
            amo_mon[c].resp_mbox = amo_resp_mbox[c];
            cache_scbd[c].dcache_req_mbox_fwd   = dcache_req_mbox_fwd   [c];
            cache_scbd[c].dcache_resp_mbox_fwd  = dcache_resp_mbox_fwd  [c];
            cache_scbd[c].amo_req_mbox      = amo_req_mbox      [c]; 
            cache_scbd[c].amo_resp_mbox     = amo_resp_mbox     [c]; 
            cache_scbd[c].amo_req_mbox_fwd  = amo_req_mbox_fwd  [c]; 
            cache_scbd[c].amo_resp_mbox_fwd = amo_resp_mbox_fwd [c]; 
 
            cache_scbd[c].aw_mbx_pre_filt   = aw_mbx            [c]; 
            cache_scbd[c].w_mbx_pre_filt    = w_mbx             [c]; 
            cache_scbd[c].b_mbx_pre_filt    = b_mbx             [c]; 
            cache_scbd[c].ar_mbx_pre_filt   = ar_mbx            [c]; 
            cache_scbd[c].r_mbx_pre_filt    = r_mbx             [c]; 
 
            cache_scbd[c].ac_mbx            = ac_mbx            [c]; 
            cache_scbd[c].cd_mbx            = cd_mbx            [c]; 
            cache_scbd[c].cr_mbx            = cr_mbx            [c]; 
 
            cache_scbd[c].mgmt_mbox         = mgmt_mbox         [c];
            dcache_chk.amo_req_mbox[c]  = amo_req_mbox_fwd  [c]; 
            dcache_chk.amo_resp_mbox[c] = amo_resp_mbox_fwd [c]; 
 
            dcache_chk.dcache_req_mbox[c]  = dcache_req_mbox_fwd  [c]; 
            dcache_chk.dcache_resp_mbox[c] = dcache_resp_mbox_fwd [c];

            ace_mon[c].aw_mbx = aw_mbx [c];
            ace_mon[c].w_mbx  = w_mbx  [c];
            ace_mon[c].b_mbx  = b_mbx  [c];
            ace_mon[c].ar_mbx = ar_mbx [c];
            ace_mon[c].r_mbx  = r_mbx  [c];
end

            void'($value$plusargs("ENABLE_MEM_CHECK=%b", enable_mem_check)); 
            dcache_chk.enable_mem_check = enable_mem_check; 

endfunction


task automatic start_amo_monitor; 
        fork 
            dcache_chk.check_amo_lock(); 
        join_none 
    endtask 
 
    // start all monitors 
task automatic start_monitors;
        fork
            for (int c=0; c < c_env_cfg.N_C; c++) begin : CORE
                fork
                    automatic int core_idx = c;
                    begin
                        for (int p=0; p<=2; p++) begin : PORT
                            fork
                                automatic int port = p;
                                begin
                                    d_agt[core_idx].dcache_mon[core_idx][port].monitor();
                                end
                            join_none
                        end
                    end
                    ace_mon[core_idx].monitor();
                    snoop_mon[core_idx].monitor();
                    amo_mon[core_idx].monitor();
                    dcache_mgmt_mon[core_idx].monitor();
                    cache_scbd[core_idx].run();
                join_none
            end
            if (enable_ccu_mon) begin
                ccu_mon_end_check = 1;
                //ccu_mon.run();    //need_to_see
            end
            dcache_chk.monitor();
        join_none
 endtask
endclass


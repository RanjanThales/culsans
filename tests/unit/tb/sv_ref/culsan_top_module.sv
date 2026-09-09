`include "uvm_macros.svh"
`include "ace/assign.svh" 

import ariane_pkg::*;
import snoop_test::*; 
import ace_test::*;   
import tb_ace_ccu_pkg::*; 
//import tb_std_cache_subsystem_pkg::*; 
import soc_pkg::*;

module culsans_tb_uvm;


    parameter  int unsigned AxiIdWidth       = culsans_pkg::IdWidth;
    parameter  int unsigned AxiAddrWidth     = culsans_pkg::AddrWidth;
    parameter  int unsigned AxiDataWidth     = culsans_pkg::DataWidth;
    localparam int unsigned AxiUserWidth     = culsans_pkg::UserWidth;
    localparam ariane_cfg_t ArianeCfg        = culsans_pkg::ArianeSocCfg;

    localparam time         CLK_PERIOD         = 10ns;
    localparam int unsigned RTC_CLOCK_PERIOD   = 30.517us;
    localparam int unsigned DCACHE_PORTS       = 3;
    localparam int unsigned NB_CORES           = culsans_pkg::NB_CORES;
    localparam int unsigned NUM_WORDS          = 4**10;
    localparam bit          STALL_RANDOM_DELAY = `ifdef TB_AXI_RAND_DELAY  `TB_AXI_RAND_DELAY  `else 1'b1  `endif;
    localparam int unsigned FIXED_AXI_DELAY    = `ifdef TB_AXI_FIXED_DELAY `TB_AXI_FIXED_DELAY `else 0     `endif;
    localparam bit          HAS_LLC            = `ifdef TB_HAS_LLC         `TB_HAS_LLC         `else  1'b1 `endif;
    localparam int unsigned DCACHE_INDEX_DIST = std_cache_pkg::DCACHE_NUM_WORDS * DCACHE_LINE_WIDTH / 8; // Distance between two addresses mapping to the same index

    // The length of cached, shared region is derived from other constants
    localparam int CachedSharedRegionLength =  ArianeCfg.SharedRegionAddrBase[0] + ArianeCfg.SharedRegionLength[0] - ArianeCfg.CachedRegionAddrBase[0];
    initial assert (CachedSharedRegionLength > 0) else $error ("Got negative CachedSharedRegionLength");

    logic                                   clk;
    logic                                   rst_n;
    logic                                   rtc;
    logic [31:0]                            exit_val;

 //--------------------------------------------------------------------------
 // Clock & reset generation
 //--------------------------------------------------------------------------

    initial begin
        clk   = 1'b0;
        rst_n = 1'b0;

        repeat(8)
            #(CLK_PERIOD/2) clk = ~clk;

        rst_n = 1'b1;

        forever begin
            #(CLK_PERIOD/2) clk = ~clk;
        end

    end


    initial begin
        forever begin
            rtc = 1'b0;
            forever begin
                #(RTC_CLOCK_PERIOD/2) rtc = ~rtc;
            end
        end
    end


    //--------------------------------------------------------------------------
    // DUT
    //--------------------------------------------------------------------------
    culsans_top #(
        .InclSimDTM       (1'b0),
        .NUM_WORDS        (NUM_WORDS), // 4Kwords
        .StallRandomInput (STALL_RANDOM_DELAY),
        .StallRandomOutput(STALL_RANDOM_DELAY),
        .HasLLC           (HAS_LLC),
        .FixedDelayInput  (FIXED_AXI_DELAY),
        .FixedDelayOutput (FIXED_AXI_DELAY),
        .BootAddress      (culsans_pkg::DRAMBase + 64'h10_0000)
    ) i_culsans (
        .clk_i  ( clk      ),
        .rtc_i  ( rtc      ),
        .rst_ni ( rst_n    ),
        .exit_o ( exit_val )
    );


    // Interfaces
    amo_intf                amo_if           [NB_CORES]               (clk);
    dcache_intf             dcache_if        [NB_CORES][DCACHE_PORTS] (clk);
    icache_intf             icache_if        [NB_CORES]               (clk);
    dcache_sram_if          dc_sram_if       [NB_CORES]               (clk);
    dcache_gnt_if           gnt_if           [NB_CORES]               (clk);
    dcache_mgmt_intf        mgmt_if          [NB_CORES]               (clk);




    sram_intf #(
        .NUM_WORDS        (NUM_WORDS),
        .DATA_WIDTH       (AxiDataWidth),
        .DCACHE_SET_ASSOC (DCACHE_SET_ASSOC)
    ) sram_if [NB_CORES] ();


 //--------------------------------------------------------------------------
 // AXI/ACE bus interfaces
 //--------------------------------------------------------------------------

    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth               ),
        .AXI_DATA_WIDTH ( AxiDataWidth               ),
        .AXI_ID_WIDTH   ( culsans_pkg::IdWidthToXbar ),
        .AXI_USER_WIDTH ( AxiUserWidth               )
    ) axi_bus [0:0] ();

    AXI_BUS_DV #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth               ),
        .AXI_DATA_WIDTH ( AxiDataWidth               ),
        .AXI_ID_WIDTH   ( culsans_pkg::IdWidthToXbar ),
        .AXI_USER_WIDTH ( AxiUserWidth               )
    ) axi_bus_dv [0:0] (clk);


    ACE_BUS #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth ),
        .AXI_DATA_WIDTH ( AxiDataWidth ),
        .AXI_ID_WIDTH   ( AxiIdWidth   ),
        .AXI_USER_WIDTH ( AxiUserWidth )
    ) ace_bus [NB_CORES-1:0] ();

    ACE_BUS_DV #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth ),
        .AXI_DATA_WIDTH ( AxiDataWidth ),
        .AXI_ID_WIDTH   ( AxiIdWidth   ),
        .AXI_USER_WIDTH ( AxiUserWidth )
    ) ace_bus_dv [NB_CORES-1:0] (clk);


    SNOOP_BUS #(
        .SNOOP_ADDR_WIDTH ( AxiAddrWidth ),
        .SNOOP_DATA_WIDTH ( AxiDataWidth )
    ) snoop_bus [NB_CORES-1:0] ();

    SNOOP_BUS_DV #(
        .SNOOP_ADDR_WIDTH ( AxiAddrWidth ),
        .SNOOP_DATA_WIDTH ( AxiDataWidth )
    ) snoop_bus_dv [NB_CORES-1:0] (clk);


// connect internal signals to interfaces, connect interfaces to dv interfaces
//    `AXI_ASSIGN_MONITOR (axi_bus[0], i_culsans.to_xbar[0])
//    `AXI_ASSIGN_MONITOR (axi_bus_dv[0], axi_bus[0])

   for (genvar core_idx=0; core_idx<NB_CORES; core_idx++) begin
        `ACE_ASSIGN_FROM_REQ    (ace_bus   [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_req_o)
        `ACE_ASSIGN_FROM_RESP   (ace_bus   [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_resp_i)
        `ACE_ASSIGN_MONITOR   (ace_bus_dv   [core_idx], ace_bus   [core_idx])

        `SNOOP_ASSIGN_FROM_REQ  (snoop_bus [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_resp_i)
        `SNOOP_ASSIGN_FROM_RESP (snoop_bus [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_req_o)
        `SNOOP_ASSIGN_MONITOR (snoop_bus_dv [core_idx], snoop_bus [core_idx])
    end


// assign ace_bus_dv[core_idx].req=i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_req_o;


/*
    // AXI/ACE monitors
    ace_monitor #(
        .IW ( AxiIdWidth   ),
        .AW ( AxiAddrWidth ),
        .DW ( AxiDataWidth ),
        .UW ( AxiUserWidth )
    ) ace_mon [NB_CORES-1:0] ;

    snoop_monitor #(
        .AW ( AxiAddrWidth ),
        .DW ( AxiDataWidth )
    ) snoop_mon [NB_CORES-1:0];

    // CCU monitor & scoreboard
    ace_ccu_monitor #(
        .AxiAddrWidth      ( AxiAddrWidth               ),
        .AxiDataWidth      ( AxiDataWidth               ),
        .AxiIdWidthMasters ( AxiIdWidth                 ),
        .AxiIdWidthSlaves  ( culsans_pkg::IdWidthToXbar ),
        .AxiUserWidth      ( AxiUserWidth               ),
        .NoMasters         ( NB_CORES      ),
        .NoSlaves          ( 1                          ),
        .TimeTest          ( 0                          )
    ) ccu_mon;

*/


// assign SRAM IF
        `ifdef USE_XILINX_SRAM
            assign dc_sram_if[core_idx].vld_sram_xilinx  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.i_tc_sram.gen_1_ports.i_xpm_memory_spram.xpm_memory_base_inst.mem;
        `else
            assign dc_sram_if[core_idx].vld_sram  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.i_tc_sram.sram;
        `endif

        assign dc_sram_if[core_idx].vld_req   = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.req_i;
        assign dc_sram_if[core_idx].vld_we    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.we_i;
        assign dc_sram_if[core_idx].vld_index = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.addr_i;
        for (genvar i = 0; i<DCACHE_SET_ASSOC; i++) begin : sram_block
            `ifdef USE_XILINX_SRAM
                assign dc_sram_if[core_idx].tag_sram_xilinx[i]  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.sram_block[i].tag_sram.i_tc_sram.gen_1_ports.i_xpm_memory_spram.xpm_memory_base_inst.mem;
                assign dc_sram_if[core_idx].data_sram_xilinx[i] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.sram_block[i].data_sram.i_tc_sram.gen_1_ports.i_xpm_memory_spram.xpm_memory_base_inst.mem;
            `else
                assign dc_sram_if[core_idx].tag_sram[i]  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.sram_block[i].tag_sram.i_tc_sram.sram;
                assign dc_sram_if[core_idx].data_sram[i] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.sram_block[i].data_sram.i_tc_sram.sram;
            `endif
        end

        assign gnt_if[core_idx].gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[0] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[0];

        assign gnt_if[core_idx].gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[1] &&
            !(|i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.updating_cache);

        assign gnt_if[core_idx].gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[2] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[2];

        assign gnt_if[core_idx].gnt[3] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[3] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[3];

        assign gnt_if[core_idx].gnt[4] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[4] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[4];



        for (genvar p=0; p<5; p++) begin
            assign gnt_if[core_idx].req[p] = |i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.req[p];
        end

        assign gnt_if[core_idx].rd_gnt = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt;

        assign gnt_if[core_idx].snoop_wr_gnt = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[1] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[1];


        assign gnt_if[core_idx].bypass_gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[0];
        assign gnt_if[core_idx].bypass_gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[1];
        assign gnt_if[core_idx].bypass_gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[2];

        assign gnt_if[core_idx].miss_gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[0];
        assign gnt_if[core_idx].miss_gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[1];
        assign gnt_if[core_idx].miss_gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[2];

        // priority encoding of wr_gnt.
        assign gnt_if[core_idx].wr_gnt[0] = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                            (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.bypass);

        assign gnt_if[core_idx].wr_gnt[1] = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                            (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[2].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[2].i_cache_ctrl.miss_req_o.bypass) &&
                                            !(i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.bypass);

        assign gnt_if[core_idx].wr_gnt[2] = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                            (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[3].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[3].i_cache_ctrl.miss_req_o.bypass) &&
                                            !(i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[2].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[2].i_cache_ctrl.miss_req_o.bypass) &&
                                            !(i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.bypass);

        assign gnt_if[core_idx].mshr_match[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.mshr_addr_matches[0];
        assign gnt_if[core_idx].mshr_match[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.mshr_addr_matches[1];
        assign gnt_if[core_idx].mshr_match[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.mshr_index_matches[2];

        assign gnt_if[core_idx].way    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.req_ram;
        assign gnt_if[core_idx].be_vld = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.be_valid_dirty_ram;

        // assign management IF
        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_en_csr_nbdcache  = mgmt_if[core_idx].dcache_enable;
        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_flush_ctrl_cache = mgmt_if[core_idx].dcache_flush;
        assign mgmt_if[core_idx].dcache_flushing  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.flushing;
        assign mgmt_if[core_idx].dcache_flush_ack = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_flush_ack_cache_ctrl;
        assign mgmt_if[core_idx].dcache_miss      = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_miss_cache_perf;
        assign mgmt_if[core_idx].wbuffer_empty    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_commit_wbuffer_empty;

//sk        initial begin : ICACHE_DRV
//sk            icache_drv[core_idx] = new(icache_if[core_idx], ArianeCfg, $sformatf("%s[%0d]","icache_driver",core_idx));
//sk
//sk        end
//sk
//sk        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.icache_dreq_if_cache = icache_if[core_idx].req;
//sk        assign icache_if[core_idx].resp = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.icache_dreq_cache_if;




        for (genvar port=0; port<=2; port++) begin : PORT
            // assign dcache request/response to dcache_if
            assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_ex_cache[port] = dcache_if[core_idx][port].req;
            assign dcache_if[core_idx][port].resp   = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_cache_ex[port];
            assign dcache_if[core_idx][port].wr_gnt = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[port+2] &&
                                                      //i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.start_ack[port+2] &&
                                                      (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[port+1].i_cache_ctrl.state_q == 0); // IDLE
        end



//sk  // force different AXI IDs for testbench purposes
//sk             initial begin : FORCE_AXI_ID
//sk                 automatic logic axi_id_per_port = 0;
//sk                 logic enable_axi_id_per_port;
//sk                 if ($value$plusargs("ENABLE_AXI_ID_PER_PORT=%d", enable_axi_id_per_port)) begin
//sk                     axi_id_per_port = enable_axi_id_per_port;
//sk                 end
//sk 
//sk                 if (axi_id_per_port) begin
//sk                     force i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.req_fsm_miss_id =
//sk                         4'hC + i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.mshr_q.id;
//sk                     // disable assertions checking AXI IDs
//sk                     $assertoff(0,i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.a_axi_data_awid);
//sk                     $assertoff(0,i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.a_axi_data_arid);
//sk                     #0;
//sk                     cache_scbd[core_idx].axi_id_per_port = 1;
//sk                 end
//sk             end




        // assign AMO IF
        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_req = amo_if[core_idx].req;
        assign amo_if[core_idx].resp = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_resp;
        assign amo_if[core_idx].gnt  = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                       (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.busy_i  == 0);




  for (genvar w=0; w<DCACHE_SET_ASSOC; w++) begin
            `ifdef USE_XILINX_SRAM
                assign sram_if[core_idx].data[w][0] = i_culsans.i_sram.i_tc_sram.gen_1_ports.i_xpm_memory_spram.xpm_memory_base_inst.mem[sram_if[core_idx].addr[w]];
                assign sram_if[core_idx].data[w][1] = i_culsans.i_sram.i_tc_sram.gen_1_ports.i_xpm_memory_spram.xpm_memory_base_inst.mem[sram_if[core_idx].addr[w]+1];
            `else
                assign sram_if[core_idx].data[w][0] = i_culsans.i_sram.i_tc_sram.sram[sram_if[core_idx].addr[w]];
                assign sram_if[core_idx].data[w][1] = i_culsans.i_sram.i_tc_sram.sram[sram_if[core_idx].addr[w]+1];
            `endif
        end
end


 // Set virtual interface handles to the config_db
    initial begin : SET_VIFS
        
        for (int c = 0; c < NB_CORES; c++) begin : CORE_VIF_SET
            // Set DCACHE agent VIFs
            for (int p = 0; p < DCACHE_PORTS; p++) begin
                uvm_config_db#(virtual dcache_intf)::set(null, $sformatf("uvm_test_top.env_h.dcache_agent_h[%0d][%0d].*", c, p), "dcache_vif", dcache_if[c][p]);
            end

            uvm_config_db#(virtual ACE_BUS_DV)::set(null, $sformatf("uvm_test_top.env_h.ace_agent_h[%0d].*", c), "ace_vif", ace_bus_dv[c]);
            uvm_config_db#(virtual SNOOP_BUS_DV)::set(null, $sformatf("uvm_test_top.env_h.snoop_agent_h[%0d].*", c), "snoop_vif", snoop_bus_dv[c]);
        end
        uvm_config_db#(virtual AXI_BUS_DV)::set(null, "*", "axi_vif", axi_bus_dv);
        // Run UVM test
        run_test();
    end



    //--------------------------------------------------------------------------
    // Tests
    //--------------------------------------------------------------------------


    class test_run;
    


  task automatic test_header (string testname, string description="");
        $display("--------------------------------------------------------------------------");
        $display("Running test %s", testname);
        $display("%s", description);
        $display("--------------------------------------------------------------------------");
    endtask



    int timeout = 500000; // default
    int wait_time = 0;
    int test_id = -1;
    int rep_cnt;
    // select one core randomly for tests that need one core that behaves differently
    int cid = $urandom_range(NB_CORES-1);
    // select one more core for tests that need two specific cores
    int cid2 = (cid + (NB_CORES/2)) % NB_CORES;


     initial begin : TESTS
        logic [63:0] addr, base_addr;
        logic [63:0] data, base_data;
        static logic enable_icache_random_gen = 0;

    automatic string testname="";
        if (!$value$plusargs("TESTNAME=%s", testname)) begin
            $error("No TESTNAME plusarg given");
        end
   void'($value$plusargs("ENABLE_ICACHE_RANDOM_GEN=%b", enable_icache_random_gen));


fork  
  
            begin  
  
                `WAIT_SIG(clk, rst_n)  
                start_monitors();  
                `WAIT_CYC(clk, 300)  
                `WAIT_CYC(clk, 1500) // wait some more for LLC initialization  
  
                if (enable_icache_random_gen) begin  
                    for (int c=0; c < NB_CORES; c++) begin  
                        icache_drv[c].start_random_req();  
                    end  
                end 

case (testname)   
   
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
                    "read_miss" : begin   
                        test_header(testname, "8 consecutive read misses in the same cache set");   
   
                        addr = ArianeCfg.CachedRegionAddrBase[0];   
   
                        // write to address 0-7 and then some more   
                        for (int i=0; i<16; i++) begin   
                            dcache_drv[cid][2].wr(.addr(addr + (i << DCACHE_INDEX_WIDTH)), .data(i));   
                        end   
   
   
                        // read miss x 8 - fill cache 0   
                        for (int i=0; i<8; i++) begin   
                            dcache_drv[cid][1].rd(.addr(addr + (i << DCACHE_INDEX_WIDTH)));   
                        end   
   
                        `WAIT_CYC(clk, 100)   
                    end   

 "write_collision" : begin   
                        test_header(testname, "Part 1 : Write conflicts to single address");   
   
                        addr = ArianeCfg.CachedRegionAddrBase[0];   
   
                        // make sure data 0 is in cache   
                        for (int c=0; c < NB_CORES; c++) begin   
                            dcache_drv[c][0].rd(.addr(addr));   
                            `WAIT_CYC(clk, 100)   
                        end   
   
                        // simultaneous writes to same address   
                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope   
                            for (int i=0; i<100; i++) begin   
                                for (int c=0; c < NB_CORES; c++) begin   
                                    fork   
                                        automatic int cc = c;   
                                        begin   
                                            if (cc == cid) begin   
                                                dcache_drv[cc][2].wr(.addr(addr), .data(64'hBEEFCAFE0000 + i), .rand_size_be(1));   
                                                `WAIT_CYC(clk, 10)   
                                                dcache_drv[cc][2].wr(.addr(addr), .data(64'hBEEFCAFE0100 + i), .rand_size_be(1));   
                                            end else begin   
                                                dcache_drv[cc][2].wr(.addr(addr), .data(64'hBAADF00D0000 + i), .rand_size_be(1));   
                                                `WAIT_CYC(clk, ((i+cc)%19))   
                                                dcache_drv[cc][2].wr(.addr(addr), .data(64'hDEADABBA0000 + i), .rand_size_be(1));   
                                            end   
                                        end   
                                    join_none   
                                end   
                                wait fork;   
                            end   
                        end join   
   
                        `WAIT_CYC(clk, 100)   

 
 $display("Test done");   
                $display("--------------------------------------------------------------------------------------------------------");   
                for (int c=0; c < NB_CORES; c++) begin   
                    for (int p=0; p<3; p++) begin   
                        dcache_mon[c][p].print_stats();   
                    end   
                end   
                $display("--------------------------------------------------------------------------------------------------------");   
   
   
                $finish();   
   
            end   
   
            //------------------------------------------------------------------   
            // Timeout   
            //------------------------------------------------------------------   
            begin   
                while (timeout > 0) begin   
                    timeout--;   
                    `WAIT_CYC(clk, 1)   
                end   
                $error("Timeout");   
                $finish();   
            end   
   
        join_any   
        disable fork;   
   
    end   


endmodule













            

            //sk uvm_config_db#(virtual amo_intf)::set(null, $sformatf("uvm_test_top.env_h.amo_agent_h[%0d].*", c), "vif", amo_if[c]);
            //sk uvm_config_db#(virtual icache_intf)::set(null, $sformatf("uvm_test_top.env_h.icache_agent_h[%0d].*", c), "vif", icache_if[c]);
            //sk uvm_config_db#(virtual dcache_mgmt_intf)::set(null, $sformatf("uvm_test_top.env_h.dcache_mgmt_agent_h[%0d].*", c), "vif", mgmt_if[c]);

          


`include "uvm_macros.svh"
`include "ace/assign.svh" 
`include "ace/assign.svh"

import ariane_pkg::*;
import snoop_test::*; 
import ace_test::*;   
import tb_ace_ccu_pkg::*; 
import tb_std_cache_subsystem_pkg::*; 
  import tb_pkg::*;
  import uvm_pkg::*;  
  //import soc_pkg::*;
//`include "ace_cov_monitor.sv"
module culsans_tb
    import ariane_pkg::*;
    import snoop_test::*;
    import ace_test::*;
    import tb_ace_ccu_pkg::*;
    //import tb_std_cache_subsystem_pkg::*;
#()();



    `define WAIT_CYC(CLK, N) \
        repeat(N) @(posedge(CLK));


    `define WAIT_SIG(CLK,SIG)    \
        do begin                 \
            @(posedge(CLK));     \
        end while(SIG == 1'b0);

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

    // TB signals
    dcache_req_i_t [NB_CORES][DCACHE_PORTS] dcache_req_ports_i;
    dcache_req_o_t [NB_CORES][DCACHE_PORTS] dcache_req_ports_o;
    logic                                   clk;
    logic                                   rst_n;
    logic                                   rtc;
    logic [31:0]                            exit_val;

    // TB interfaces
    amo_intf                amo_if           [NB_CORES]               (clk);
    dcache_intf             dcache_if        [NB_CORES][DCACHE_PORTS] (clk);
    icache_intf             icache_if        [NB_CORES]               (clk);
    dcache_sram_if          dc_sram_if       [NB_CORES]               (clk);
    dcache_gnt_if           gnt_if           [NB_CORES]               (clk);
    dcache_mgmt_intf        mgmt_if          [NB_CORES]               (clk);
    clk_rst_intf            clk_rst_if                                (clk);
   


    assign clk_rst_if.rst_n         = rst_n         ;
    assign clk_rst_if.rtc           = rtc           ;
    assign clk_rst_if.exit_val      = exit_val      ;
    

   
    
    sram_intf #(
        .NUM_WORDS        (NUM_WORDS),
        .DATA_WIDTH       (AxiDataWidth),
        .DCACHE_SET_ASSOC (DCACHE_SET_ASSOC)
    ) sram_if [NB_CORES] ();

    
   
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

   //-----------------------------------------
   //          Assertions
   //-----------------------------------------
  
/*
    bind culsans_top culsans_multicore_assertions #(
        .N_CORES(culsans_pkg::NB_CORES),
        .N_PORTS(DCACHE_PORTS)
    ) i_assertions (
        .clk(clk),
        .rst_n(rst_n),
        .dcache_if(dcache_if)  
    );
*/

 
//   culsans_multicore_assertions #(
//        .N_CORES(culsans_pkg::NB_CORES),
//        .N_PORTS(DCACHE_PORTS)
//    ) i_assertions (
//        .clk        ( clk      ),
//        .rst_n      ( rst_n    ),
//        .dcache_if  ( dcache_if )
//    );
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
    `AXI_ASSIGN_MONITOR (axi_bus[0], i_culsans.to_xbar[0])
    `AXI_ASSIGN_MONITOR (axi_bus_dv[0], axi_bus[0])

    for (genvar core_idx=0; core_idx<NB_CORES; core_idx++) begin
        `ACE_ASSIGN_FROM_REQ    (ace_bus   [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_req_o)
        `ACE_ASSIGN_FROM_RESP   (ace_bus   [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_resp_i)
        `ACE_ASSIGN_MONITOR   (ace_bus_dv   [core_idx], ace_bus   [core_idx])

        `SNOOP_ASSIGN_FROM_REQ  (snoop_bus [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_resp_i)
        `SNOOP_ASSIGN_FROM_RESP (snoop_bus [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_req_o)
        `SNOOP_ASSIGN_MONITOR (snoop_bus_dv [core_idx], snoop_bus [core_idx])
    end

    for (genvar core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE

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

        // assign Grant IF
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

        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.icache_dreq_if_cache = icache_if[core_idx].req;
        assign icache_if[core_idx].resp = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.icache_dreq_cache_if;


        for (genvar port=0; port<=2; port++) begin : PORT
            // assign dcache request/response to dcache_if
            assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_ex_cache[port] = dcache_if[core_idx][port].req;
            assign dcache_if[core_idx][port].resp   = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_cache_ex[port];
            assign dcache_if[core_idx][port].wr_gnt = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[port+2] &&
                                                      //i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.start_ack[port+2] &&
                                                      (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[port+1].i_cache_ctrl.state_q == 0); // IDLE


            // force different AXI IDs for testbench purposes
            initial begin : FORCE_AXI_ID
                automatic logic axi_id_per_port = 0;
                logic enable_axi_id_per_port;
                if ($value$plusargs("ENABLE_AXI_ID_PER_PORT=%d", enable_axi_id_per_port)) begin
                    axi_id_per_port = enable_axi_id_per_port;
                end

                if (axi_id_per_port) begin
                    force i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.req_fsm_miss_id =
                        4'hC + i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.mshr_q.id;
                    // disable assertions checking AXI IDs
                    $assertoff(0,i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.a_axi_data_awid);
                    $assertoff(0,i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.a_axi_data_arid);
                    #0;
                   // cache_scbd[core_idx].axi_id_per_port = 1;
                end
            end


            //------------------------------------------------------------------
            // check that the read responds match the read requests
            //------------------------------------------------------------------
            int cnt = 0;
            logic check_neg = 1;
            logic check_pos = 1;
            always @ (posedge clk) begin
                if (dcache_if[core_idx][port].req.data_req && !dcache_if[core_idx][port].req.data_we && dcache_if[core_idx][port].resp.data_gnt) begin
                    cnt++;
                end
                if (dcache_if[core_idx][port].resp.data_rvalid) begin
                    cnt--;
                end

                a_rd_resp_neg : assert (!check_neg || cnt >= 0) else begin
                   $error("too many read responds in core %0d, dcache port %0d", core_idx, port);
                    check_neg = 0;
                end

                a_rd_resp_pos : assert (!check_pos || cnt <= 2) else begin
                   $error("too many outstanding read requests in core %0d, dcache port %0d", core_idx, port);
                    check_pos = 0;
                end
            end
            final a_req_resp_match : assert (cnt == 0) else $error("read requests and responds dont match in core %0d, dcache port %0d", core_idx, port);

        end

        // assign AMO IF
        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_req = amo_if[core_idx].req;
        assign amo_if[core_idx].resp = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_resp;
        assign amo_if[core_idx].gnt  = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                       (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.busy_i  == 0);
   


        // assign SRAM IF
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

genvar i,j;
generate
for (i = 0; i < NB_CORES; i++) begin
for (j = 0; j < DCACHE_PORTS; j++) begin

initial begin
 uvm_config_db#(virtual dcache_intf)::set(null,"*",$sformatf("dcache_vif_%0d_%0d", i, j),dcache_if[i][j]);
// uvm_config_db#(virtual dcache_intf)::set(null, $sformatf("culsans_base_test_%0d_%0d", i, j), "dcache_vif", dcache_if[i][j]);
end
end

initial begin


              uvm_config_db#(virtual dcache_mgmt_intf)::set(null, "*", $sformatf("dcache_mgmt_if_vif_%0d", i), mgmt_if[i]);    
              uvm_config_db#(virtual amo_intf)::set(null, "*", $sformatf("amo_if_vif_%0d", i), amo_if[i]);    
              uvm_config_db#(virtual icache_intf)::set(null, "*", $sformatf("icache_if_vif_%0d", i), icache_if[i]);   
              uvm_config_db#(virtual sram_intf #(8, 64, NUM_WORDS))::set(null, "*", $sformatf("sram_if_vif_%0d", i), sram_if[i]);
              uvm_config_db#(virtual ACE_BUS_DV#(64,64,4,64))::set(null, "*", $sformatf("ace_bus_dv_vif_%0d", i), ace_bus_dv[i]);
              uvm_config_db#(virtual SNOOP_BUS_DV#(64,64,4,64))::set(null, "*", $sformatf("snoop_bus_dv_vif_%0d", i), snoop_bus_dv[i]);
              uvm_config_db#(virtual dcache_sram_if)::set(null, "*", $sformatf("d_sram_vif_%0d", i), dc_sram_if[i]);
              uvm_config_db#(virtual dcache_gnt_if)::set(null, "*", $sformatf("d_gnt_vif_%0d", i), gnt_if[i]);
              uvm_config_db#(virtual AXI_BUS_DV#(64, 64, 9, 64))::set(null, "*", "axi_bus_dv", axi_bus_dv[0]);
              uvm_config_db#(virtual clk_rst_intf)::set(null, "*", "clk_rst_if", clk_rst_if);
end

end
endgenerate

initial begin
        
            //run_test("same_cache_line_interference_test");
            run_test();
end

endmodule

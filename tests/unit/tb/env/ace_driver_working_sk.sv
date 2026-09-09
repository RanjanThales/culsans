`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;
import ariane_pkg::*;
import snoop_test::*;
import ace_test::*;
import tb_ace_ccu_pkg::*;
import tb_std_cache_subsystem_pkg::*;
import tb_pkg::*;


class ace_driver extends uvm_driver #(ace_txn_item) ;
  `uvm_component_utils(ace_driver)


 ace_txn_item req;
  // ---------------------------------------------------------------------------
  // Configuration Handles
  // ---------------------------------------------------------------------------
  ace_env_config ace_env_cfg;

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
  //testing ) ace_bus_dv[];
  ) vif;

  // ---------------------------------------------------------------------------
  // Variables
  // ---------------------------------------------------------------------------
  int c;
  int ace_var;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  function new(string name = "ace_driver", uvm_component parent = null);
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

//test    // Get virtual interface for this driver
//test    if (!uvm_config_db#(virtual ACE_BUS_DV#(64,64,4,64))::get(this,"",$sformatf("ace_bus_dv_vif_%0d", c), vif)) begin
//test      `uvm_fatal("ACE_BUS_DV",$sformatf("Failed to get ace_bus_dv in ACE Driver for c=%0d", c))
//test    end
//test    else begin
//test      `uvm_info("ACE_BUS_DV_IN_ACE_DRIVER",$sformatf("--------- ACE_BUS_DV[%0d] retrieved successfully ---------", c),UVM_NONE)
//test    end



if (!uvm_config_db#(virtual ACE_BUS_DV#(AxiAddrWidth,AxiDataWidth,AxiIdWidth,AxiUserWidth))::get(this, "", $sformatf("ace_bus_dv_vif_%0d", c), vif)) begin
  `uvm_fatal("ACE_BUS_DV",$sformatf("Failed to get ace_bus_dv in ACE Driver for c=%0d", c))
end

 





  endfunction

task run_phase(uvm_phase phase); 
      forever begin
            reset();
            #500;
            seq_item_port.get_next_item(req);
            `uvm_info("ACE DRIVER", $sformatf("RECEIVED TRANSACTION: is_write=%0d", req.is_write), UVM_MEDIUM)
              send_to_dut(req);
            seq_item_port.item_done();
       end
endtask
   

task reset();

    @(posedge vif.clk_i);
        vif.aw_id          <= 0;         
        vif.aw_addr        <= 0;
        vif.aw_len         <= 0;
        vif.aw_size        <= 0;
        vif.aw_burst       <= 0;
        vif.aw_lock        <= 0;
        vif.aw_cache       <= 0;
        vif.aw_prot        <= 0;
        vif.aw_qos         <= 0;
        vif.aw_region      <= 0;
        vif.aw_atop        <= 0;
        vif.aw_user        <= 0;
        vif.aw_valid       <= 0;
        vif.aw_snoop       <= 1'bx;
        vif.aw_bar         <= 1'bx;
        vif.aw_domain      <= 1'bx;
        vif.aw_awunique    <= 0;
        vif.w_data         <= 0;
        vif.w_strb         <= 0;
        vif.w_user         <= 0;
        vif.w_valid        <= 0;
        vif.w_last         <= 0;
        vif.b_id           <= 0;        
        vif.b_resp         <= 0;
        vif.b_user         <= 0;
        vif.b_ready        <= 0;



endtask
 
//================================================================//
// SEND TO DUT
//===============================================================//
task send_to_dut(ace_txn_item xtn);
    if(xtn.is_write == 1) begin
        `uvm_info(get_type_name(), "WRITE TRANSACTION STARTS", UVM_MEDIUM)
    fork
        write_addr(xtn);
        write_data(xtn);
       collect_write_response(xtn);
         
    join
    `uvm_info(get_type_name(), "WRITE TRANSACTION ENDS", UVM_MEDIUM)
    end
    // READ TRANSACTION
    else begin
        `uvm_info(get_type_name(), "READ TRANSACTION STARTS", UVM_MEDIUM)
        read_addr(xtn);
        read_data(xtn);
        `uvm_info(get_type_name(), "READ TRANSACTION ENDS", UVM_MEDIUM)
    end
endtask


//***************************************************************************//
// WRITE ADDRESS CHANNEL
//**************************************************************************//
task write_addr(ace_txn_item xtn);
    `uvm_info(get_type_name(), "START OF WRITE ADDRESS CHANNEL", UVM_MEDIUM)
  
// reset();

  if (vif == null) begin
    `uvm_fatal("NULL_VIF", "vif is NULL in write_addr")
  end
 
    @(posedge vif.clk_i); 
    vif.aw_addr         <=      xtn.aw_addr      ;
    vif.aw_id           <=      xtn.aw_id        ;
    vif.aw_len          <=      xtn.aw_len       ;
    vif.aw_size         <=      xtn.aw_size      ;
    vif.aw_burst        <=      xtn.aw_burst     ;
    vif.aw_valid        <=      xtn.aw_valid     ;
    vif.aw_snoop        <=      xtn.aw_snoop     ;
    vif.aw_domain       <=      xtn.aw_domain    ;
    vif.aw_bar          <=      xtn.aw_bar       ;

    #8;
    while (!vif.aw_ready) begin
      @(posedge vif.clk_i);
    #8;
    end
  @(posedge vif.clk_i);

   vif.aw_valid <= 1'b0;

repeat($urandom_range(1,5)) @(posedge vif.clk_i);
    `uvm_info(get_type_name(), "END OF WRITE ADDRESS CHANNEL", UVM_MEDIUM)

endtask

//***************************************************************************//
// WRITE DATA CHANNEL
//**************************************************************************//
task write_data(ace_txn_item xtn);

  `uvm_info(get_type_name(),
            "START OF WRITE DATA CHANNEL",
            UVM_MEDIUM)

  for (int i = 0; i <= xtn.aw_len; i++) begin

    // Drive one beat
    vif.w_valid <= 1'b1;
    vif.w_data  <= xtn.w_data[i];
    vif.w_strb  <= xtn.w_strb;
    vif.w_last  <= (i == xtn.aw_len);

    // Wait until slave is ready
    do begin
      @(posedge vif.clk_i);
    end
    while (vif.w_ready !== 1'b1);

    `uvm_info(get_type_name(),
      $sformatf("WRITE DATA HANDSHAKE DONE : beat=%0d WDATA=0x%0h WLAST=%0b", i, xtn.w_data[i], (i == xtn.aw_len)), UVM_MEDIUM)

  end

  // Deassert after final handshake
  @(posedge vif.clk_i);
  vif.w_valid <= 1'b0;
  vif.w_last  <= 1'b0;

  repeat($urandom_range(1,5))
    @(posedge vif.clk_i);

  `uvm_info(get_type_name(), "END OF WRITE DATA CHANNEL", UVM_MEDIUM)

endtask
//****************************************************************************************//
// WRITE RESPONSE CHANNEL
//***************************************************************************************//:w!

  task collect_write_response(ace_txn_item xtn);
    int timeout = 0;
  
    // Master asserts readiness
    vif.b_ready <= #2 1'b1;
   #8;
    // Wait for slave response
    while (vif.b_valid !== 1) begin
      @(posedge vif.clk_i);
      timeout++;
      if (timeout == 5000) begin
        `uvm_fatal("AXI", "BVALID timeout")
        return;
      end
    end
 

    // Response accepted this cycle
    case (vif.b_resp)
      2'b00: `uvm_info("AXI", "Write OKAY", UVM_LOW)
      2'b01: `uvm_info("AXI", "Write EXOKAY", UVM_LOW)
      2'b10: `uvm_error("AXI", "Write SLVERR")
      2'b11: `uvm_error("AXI", "Write DECERR")
    endcase

    `uvm_info(get_type_name(), "END OF WRITE RESPONSE CHANNEL", UVM_MEDIUM)
  
    // Deassert ready after handshake
    @(posedge vif.clk_i);
    vif.b_ready <= 1'b0;
endtask

task read_addr(ace_txn_item xtn);

   `uvm_info(get_type_name(), "START OF READ ADDRESS CHANNEL", UVM_HIGH)

   @(posedge vif.clk_i);

   vif.Master.ar_addr    <= xtn.ar_addr;
   vif.Master.ar_id      <= xtn.ar_id;
   vif.Master.ar_len     <= xtn.ar_len;
   vif.Master.ar_size    <= xtn.ar_size;
   vif.Master.ar_burst   <= xtn.ar_burst;
   vif.Master.ar_snoop   <= xtn.ar_snoop;
   vif.Master.ar_bar     <= xtn.ar_bar;
   vif.Master.ar_domain  <= xtn.ar_domain;

   vif.Master.ar_valid   <= 1'b1;

   `uvm_info(get_type_name(),
             $sformatf("ARADDR=0x%0h ARBURST=0x%0h", xtn.ar_addr, xtn.ar_burst),  UVM_MEDIUM)

   // Wait for handshake
   while (!(vif.Master.ar_valid && vif.Master.ar_ready)) begin
      @(posedge vif.clk_i);
   end

   @(posedge vif.clk_i);
   vif.Master.ar_valid <= 1'b0;

   `uvm_info(get_type_name(), "END OF READ ADDRESS CHANNEL", UVM_MEDIUM)

endtask


task read_data(ace_txn_item xtn);

   int beat_cnt;

   `uvm_info(get_type_name(), "START OF READ DATA CHANNEL", UVM_MEDIUM)

   beat_cnt = xtn.ar_len + 1;

   vif.r_ready <= 1'b1;

   for (int i = 0; i < beat_cnt; i++) begin

      do begin
         @(posedge vif.clk_i);
      end
      while (!(vif.r_valid && vif.r_ready));

      xtn.r_data[i] = vif.r_data;

      `uvm_info(get_type_name(), $sformatf( "READ DATA HANDSHAKE DONE : beat=%0d RVALID=%0b RREADY=%0b RDATA=0x%0h RRESP=0x%0h RLAST=%0b", 
            i,
            vif.r_valid,
            vif.r_ready,
            vif.r_data,
            vif.r_resp,
            vif.r_last
         ),
         UVM_MEDIUM)

      // Final beat checking
      if ((i == beat_cnt-1) && (vif.r_last !== 1'b1)) begin
         `uvm_error(get_type_name(), "EXPECTED RLAST NOT ASSERTED ON FINAL BEAT")
      end

      // Early RLAST checking
      if ((i != beat_cnt-1) && (vif.r_last === 1'b1)) begin
         `uvm_error(get_type_name(), "RLAST ASSERTED EARLY")
      end

   end

   @(posedge vif.clk_i);

   vif.r_ready <= 1'b0;

   `uvm_info(get_type_name(), "END OF READ DATA CHANNEL", UVM_MEDIUM)

endtask



endclass









class culsans_env extends uvm_env;
    `uvm_component_utils(culsans_env)

    // Agents
    dcache_agent    dcache_agent_h [NB_CORES][DCACHE_PORTS];

    // ACE/AXI/Snoop Agents
    ace_agent       ace_agent_h    [NB_CORES]; 
    snoop_agent     snoop_agent_h  [NB_CORES];
    axi_agent       axi_agent_h;

     function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
       
        // Instantiate Agents
        for (int c = 0; c < NB_CORES; c++) begin 
            for (int p = 0; p < DCACHE_PORTS; p++) begin
                dcache_agent_h[c][p] = dcache_agent::type_id::create($sformatf("dcache_agent[%0d][%0d]", c, p), this);
            end
            ace_agent_h[c] = ace_agent::type_id::create($sformatf("ace_agent_%0d", c), this);
            snoop_agent_h[c] = snoop_agent::type_id::create($sformatf("snoop_agent_%0d", c), this);
        end
        axi_agent_h = axi_agent::type_id::create("axi_agent", this);

    endfunction

 
endclass

class dcache_agent extends uvm_agent;
    `uvm_component_utils(dcache_agent)
 
    dcache_driver    drv;
    dcache_sequencer seqr;
    dcache_monitor   mon;
 
 
    function new(string name, uvm_component parent);
super.new(name, parent);
    endfunction
 
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
            drv=dcache_driver::type_id::create("drv", this);
            seqr=dcache_sequencer::type_id::create("seqr", this);
        mon=dcache_monitor::type_id::create("mon", this);
    endfunction
 
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction
 
endclass

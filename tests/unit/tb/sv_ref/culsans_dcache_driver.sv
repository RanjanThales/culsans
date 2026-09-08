class dcache_driver extends uvm_driver #(dcache_transaction);
    `uvm_component_utils(dcache_driver)
 
    virtual dcache_intf dcache_vif;
 
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
 
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual dcache_intf)::get(this, "", "dcache_vif", vif))
            `uvm_fatal(get_full_name(), "Virtual interface 'vif' not set for dcache_driver");
    endfunction
 
    virtual task run_phase(uvm_phase phase);
        forever begin
            dcache_transaction tr;
            seq_item_port.get_next_item(tr);
            drive_dcache_req(tr);
            seq_item_port.item_done();
        end
    endtask
 
    virtual task drive_dcache_req(dcache_transaction tr);
      
    endtask
 
endclass

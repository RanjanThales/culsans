
module culsans_multicore_assertions #(
  parameter int N_CORES = 4,
  parameter int N_PORTS = 3
)(
  input logic clk,
  input logic rst_n,
  dcache_intf dcache_if [N_CORES][N_PORTS]  
);

generate
  genvar i, p;
  for (i = 0; i < N_CORES; i++) begin
    for (p = 0; p < N_PORTS; p++) begin
      a_write_gnt_delay: assert property (
        @(posedge clk) disable iff (!rst_n)
        (dcache_if[i][p].req.data_req && dcache_if[i][p].req.data_we) |->  ##[1:10] dcache_if[i][p].resp.data_gnt)
     else $error("Core %0d Port %0d: data_gnt not received within 1-7 cycles after write request at time %0t",i, p, $time);
    end
  end
endgenerate

endmodule
 

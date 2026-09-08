 "read_collision" : begin
                        test_header(testname, "Trigger colliding_read in cache controllers");

                        addr = ArianeCfg.CachedRegionAddrBase[0] + $urandom_range(256) * 16;
                        rep_cnt = 400 / NB_CORES;
                        wait_time = 2000;
                        timeout = 1000000;

                        for (int core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE
                            cache_scbd[core_idx].set_cache_msg_timeout(wait_time);
                        end


                        for (int i=0; i < rep_cnt; i++) begin
                            test_id = i;
                            // make sure data is shared in all caches
                            for (int c=0; c < NB_CORES; c++) begin
                                dcache_drv[c][1].rd(.do_wait(1), .addr(addr));
                            end

                            // overwrite data in all but one cache by reading in other data to the same cache entry
                            for (int c=0; c < NB_CORES; c++) begin
                                logic [63:0] laddr;
                                if (c != cid) begin
                                    for (int i=1; i<16; i++) begin
                                        laddr = addr + (i << DCACHE_INDEX_WIDTH);
                                        dcache_drv[c][1].rd(.do_wait(1), .addr(laddr));
                                    end
                                end
                            end

                            fork begin // this fork is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                                for (int c=0; c < NB_CORES; c++) begin
                                    fork
                                        automatic int         cc     = c;
                                        // target one 32 bit word inside the 128 bit cacheline
                                        automatic int         offset = $urandom_range(3);
                                        // be is either 00001111 or 11110000 depending on offset
                                        automatic logic [7:0] be     = 8'b00001111 << 4 * (offset % 2);
                                        begin
                                            `WAIT_CYC(clk, $urandom_range(10))
                                            // write in one core while the others read
                                            if (cc == cid) begin
                                                fork
                                                    begin
                                                        // write the target cacheline
                                                        `WAIT_CYC(clk, 5)
                                                        dcache_drv[cc][2].wr(.addr(addr + (offset*4)), .rand_data(1), .size(2'b10), .be(be));
                                                    end
                                                    begin
                                                        // read some other cacheline - compete withe the write above
                                                        `WAIT_CYC(clk, $urandom_range(10))
                                                        dcache_drv[cc][1].rd(.addr(addr + $urandom_range(2,1024) * 8));
                                                    end
                                                join
                                            end else begin
                                                // read the target cacheline
                                                `WAIT_CYC(clk, 5)
                                                dcache_drv[cc][1].rd(.do_wait(1), .addr(addr + (offset*4)), .size(2'b10), .be(be));
                                            end
                                        end
                                    join_none
                                end
                                wait fork;
                            end join
                        end

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)

                    end



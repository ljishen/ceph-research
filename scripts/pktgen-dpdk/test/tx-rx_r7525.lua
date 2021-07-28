package.path = package.path ..";?.lua;test/?.lua;app/?.lua;"
-- Lua uses '--' as comment to end of line read the
-- manual for more comment options.
require "Pktgen"
-- local seq_table = {			-- entries can be in any order
    -- ["eth_dst_addr"] = "0011:4455:6677",
    -- ["eth_src_addr"] = "0011:1234:5678",
    -- ["ip_dst_addr"] = "10.12.0.1",
    -- ["ip_src_addr"] = "10.12.0.1/16",	-- the 16 is the size of the mask value
    -- ["sport"] = 9,			-- Standard port numbers
    -- ["dport"] = 10,			-- Standard port numbers
    -- ["ethType"] = "ipv4",	-- ipv4|ipv6|vlan
    -- ["ipProto"] = "udp",	-- udp|tcp|icmp
    -- ["vlanid"] = 1,			-- 1 - 4095
    -- ["pktSize"] = 128,		-- 64 - 1518
    -- ["teid"] = 3,
    -- ["cos"] = 5,
    -- ["tos"] = 6
  -- };
-- -- seqTable( seq#, portlist, table );
-- pktgen.seqTable(0, "all", seq_table );
-- pktgen.set("all", "seq_cnt", 1);


pktgen.set_mac("0", "src", "0c:42:a1:a4:8a:7c");
pktgen.set_mac("0", "dst", "0c:42:a1:a4:89:d8");
pktgen.set_ipaddr("0", "src", "10.10.2.1");
pktgen.set_ipaddr("0", "dst", "10.10.2.2");

-- 32 is the largest burst value
--   https://github.com/pktgen/Pktgen-DPDK/blob/pktgen-21.05.0/app/pktgen-constants.h#L23
pktgen.set("all", "burst", 32);
pktgen.set("all", "size", 512);
pktgen.set_proto("all", "tcp");
pktgen.set_type("all", "ipv4");

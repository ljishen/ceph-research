package.path = package.path ..";?.lua;test/?.lua;app/?.lua;"
-- Lua uses '--' as comment to end of line read the
-- manual for more comment options.
require "Pktgen"

local eth_dst_addr = "0c:42:a1:a4:89:a4"
local eth_src_addr = "0c:42:a1:a4:89:a8"
local seq_cnt = 16
local pkt_size = 8192


pktgen.set("0", "seq_cnt", seq_cnt)

local seq_table = {}
for i=0,seq_cnt - 1 do
	seq_table[i] = {
	  ["eth_dst_addr"] = eth_dst_addr,
	  ["eth_src_addr"] = eth_src_addr,
	  ["ip_dst_addr"] = "10.10.1.2",
	  ["ip_src_addr"] = "10.10.1.1",
	  ["sport"] = 12340 + i,
	  ["dport"] = 56780 + i,
	  ["ethType"] = "ipv4",
	  ["ipProto"] = "udp",
	  ["vlanid"] = i,
	  ["pktSize"] = pkt_size,
	  ["gtpu_teid"] = i
	}
	pktgen.seqTable(i, "0", seq_table[i])
end

-- 32 is the largest burst value
--   https://github.com/pktgen/Pktgen-DPDK/blob/pktgen-21.05.0/app/pktgen-constants.h#L23
pktgen.set("0", "burst", 32)

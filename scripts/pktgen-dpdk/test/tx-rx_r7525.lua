package.path = package.path ..";?.lua;test/?.lua;app/?.lua;"
-- Lua uses '--' as comment to end of line read the
-- manual for more comment options.
require "Pktgen"

local eth_dst_addr = "0c:42:a1:a4:89:e0"
local eth_src_addr = "0c:42:a1:a4:89:c8"
local pkt_size = 64

-- 16 is the max number of sequences
-- https://github.com/pktgen/Pktgen-DPDK/blob/dev/app/pktgen-cmds.c#L2881
local seq_cnt = 16
pktgen.set("0", "seq_cnt", seq_cnt)
pktgen.vlan("0", "on");

local seq_table = {}
for i=0,seq_cnt - 1 do
  seq_table[i] = {
    ["eth_dst_addr"] = eth_dst_addr,
    ["eth_src_addr"] = eth_src_addr,
    ["ip_dst_addr"] = "10.10.1." .. (111 + i),
    ["ip_src_addr"] = "10.10.1.222",
    ["dport"] = 12340 + i,
    ["sport"] = 56780 + i,
    ["ethType"] = "ipv4",
    ["ipProto"] = "udp",
    ["vlanid"] = i,
    ["tcp_seq"] = i,
    ["pktSize"] = pkt_size,
    ["gtpu_teid"] = 0
  }
  pktgen.seqTable(i, "0", seq_table[i])
end

-- 128 is the largest burst value
-- https://github.com/pktgen/Pktgen-DPDK/blob/pktgen-22.04.1/app/pktgen-cmds.c#L2990
pktgen.set("0", "burst", 128)

pktgen.start("0")

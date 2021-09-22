package.path = package.path ..";?.lua;test/?.lua;app/?.lua;"
-- Lua uses '--' as comment to end of line read the
-- manual for more comment options.
require "Pktgen"

local eth_dst_addr = "0c:42:a1:a4:89:8c"
local eth_src_addr = "0c:42:a1:a4:8a:58"
local pkt_size = 4096

pktgen.set("all", "seq_cnt", 8);

local seq_table = {}
seq_table[0] = {
  ["eth_dst_addr"] = eth_dst_addr,
  ["eth_src_addr"] = eth_src_addr,
  ["ip_dst_addr"] = "10.10.2.1",
  ["ip_src_addr"] = "10.10.2.2",
  ["sport"] = 1234,
  ["dport"] = 5678,
  ["ethType"] = "ipv4",
  ["ipProto"] = "udp",
  ["vlanid"] = 1,
  ["pktSize"] = pkt_size,
  ["gtpu_teid"] = 0
}
seq_table[1] = {
  ["eth_dst_addr"] = eth_dst_addr,
  ["eth_src_addr"] = eth_src_addr,
  ["ip_dst_addr"] = "10.10.2.1",
  ["ip_src_addr"] = "10.10.2.2",
  ["sport"] = 1234,
  ["dport"] = 5678,
  ["ethType"] = "ipv4",
  ["ipProto"] = "udp",
  ["vlanid"] = 1,
  ["pktSize"] = pkt_size,
  ["gtpu_teid"] = 0
}
seq_table[2] = {
  ["eth_dst_addr"] = eth_dst_addr,
  ["eth_src_addr"] = eth_src_addr,
  ["ip_dst_addr"] = "10.10.2.1",
  ["ip_src_addr"] = "10.10.2.2",
  ["sport"] = 1234,
  ["dport"] = 5678,
  ["ethType"] = "ipv4",
  ["ipProto"] = "udp",
  ["vlanid"] = 1,
  ["pktSize"] = pkt_size,
  ["gtpu_teid"] = 0
}
seq_table[3] = {
  ["eth_dst_addr"] = eth_dst_addr,
  ["eth_src_addr"] = eth_src_addr,
  ["ip_dst_addr"] = "10.10.2.1",
  ["ip_src_addr"] = "10.10.2.2",
  ["sport"] = 1234,
  ["dport"] = 5678,
  ["ethType"] = "ipv4",
  ["ipProto"] = "udp",
  ["vlanid"] = 1,
  ["pktSize"] = pkt_size,
  ["gtpu_teid"] = 0
}
seq_table[4] = {
  ["eth_dst_addr"] = eth_dst_addr,
  ["eth_src_addr"] = eth_src_addr,
  ["ip_dst_addr"] = "10.10.2.1",
  ["ip_src_addr"] = "10.10.2.2",
  ["sport"] = 1234,
  ["dport"] = 5678,
  ["ethType"] = "ipv4",
  ["ipProto"] = "udp",
  ["vlanid"] = 1,
  ["pktSize"] = pkt_size,
  ["gtpu_teid"] = 0
}
seq_table[5] = {
  ["eth_dst_addr"] = eth_dst_addr,
  ["eth_src_addr"] = eth_src_addr,
  ["ip_dst_addr"] = "10.10.2.1",
  ["ip_src_addr"] = "10.10.2.2",
  ["sport"] = 1234,
  ["dport"] = 5678,
  ["ethType"] = "ipv4",
  ["ipProto"] = "udp",
  ["vlanid"] = 1,
  ["pktSize"] = pkt_size,
  ["gtpu_teid"] = 0
}
seq_table[6] = {
  ["eth_dst_addr"] = eth_dst_addr,
  ["eth_src_addr"] = eth_src_addr,
  ["ip_dst_addr"] = "10.10.2.1",
  ["ip_src_addr"] = "10.10.2.2",
  ["sport"] = 1234,
  ["dport"] = 5678,
  ["ethType"] = "ipv4",
  ["ipProto"] = "udp",
  ["vlanid"] = 1,
  ["pktSize"] = pkt_size,
  ["gtpu_teid"] = 0
}
seq_table[7] = {
  ["eth_dst_addr"] = eth_dst_addr,
  ["eth_src_addr"] = eth_src_addr,
  ["ip_dst_addr"] = "10.10.2.1",
  ["ip_src_addr"] = "10.10.2.2",
  ["sport"] = 1234,
  ["dport"] = 5678,
  ["ethType"] = "ipv4",
  ["ipProto"] = "udp",
  ["vlanid"] = 1,
  ["pktSize"] = pkt_size,
  ["gtpu_teid"] = 0
}

pktgen.seqTable(0, "all", seq_table[0]);
pktgen.seqTable(1, "all", seq_table[1]);
pktgen.seqTable(2, "all", seq_table[2]);
pktgen.seqTable(3, "all", seq_table[3]);
pktgen.seqTable(4, "all", seq_table[4]);
pktgen.seqTable(5, "all", seq_table[5]);
pktgen.seqTable(6, "all", seq_table[6]);
pktgen.seqTable(7, "all", seq_table[7]);

-- 32 is the largest burst value
--   https://github.com/pktgen/Pktgen-DPDK/blob/pktgen-21.05.0/app/pktgen-constants.h#L23
pktgen.set("all", "burst", 32);

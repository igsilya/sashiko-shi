# OVS: Security Supplements

- OpenFlow message parsing must validate message length before accessing
  fields; messages come from untrusted controllers or switches
- `ofpbuf` / `dp_packet` hold network data from untrusted sources
- Netlink message parsing (for kernel datapath interaction) must validate
  attribute types and lengths
- OVSDB JSON-RPC input is from potentially untrusted clients

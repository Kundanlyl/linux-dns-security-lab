Architecture

This lab models a small enterprise DNS environment using a parent DNS zone, a delegated child zone, an authoritative internal DNS server, and firewall controls.

Components
Gateway DNS Server

The gateway DNS server is authoritative for the parent zone:

klayal.300.ops

Its main role is to hold the parent zone and delegate the child zone to the internal DNS server.

Gateway IP:

192.168.50.5
Internal DNS Server

The internal DNS server is authoritative for the child zone:

lab.klayal.300.ops

It also hosts the reverse zone:

50.168.192.in-addr.arpa

This server performs authoritative DNS service, DNSSEC signing, recursive DNSSEC validation, and TSIG-secured zone transfers.

DNS server IP:

192.168.50.10
Client/Test Machines

Client machines are used to test DNS resolution, hierarchy delegation, signed DNSSEC records, recursive validation, and resolver behavior.

Example hosts:

ad.lab.klayal.300.ops  - 192.168.50.6
c1.lab.klayal.300.ops  - 192.168.50.15
c2.lab.klayal.300.ops  - 192.168.50.16
c3.lab.klayal.300.ops  - 192.168.50.17
Network Flow

A client querying the child zone follows this path:

Client → Gateway DNS → Child-zone delegation → Internal DNS Server

The gateway provides an NS delegation and glue A record so clients can locate the authoritative server for the child zone.

DNS Roles
gateway.klayal.300.ops
Authoritative for: klayal.300.ops

dns.lab.klayal.300.ops
Authoritative for: lab.klayal.300.ops
Authoritative for: 50.168.192.in-addr.arpa
Recursive DNSSEC validation server
Security Controls

The environment includes several DNS and network security controls:

DNS service limited to expected networks
SSH access restricted to internal hosts
Zone transfers restricted with TSIG keys
DNSSEC signing enabled on authoritative zones
DNSSEC validation enabled on the recursive resolver
nftables firewall rules controlling inbound, outbound, and forwarded traffic

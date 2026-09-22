# Architecture

This lab models a small enterprise DNS environment using a parent DNS zone, a delegated child zone, an authoritative internal DNS server, and firewall controls.

## Components

### Gateway DNS Server

The gateway DNS server is authoritative for the parent zone:

```text
corp.example
```

Its main role is to hold the parent zone and delegate the child zone to the internal DNS server.

Gateway IP:

```text
192.168.50.5
```

### Internal DNS Server

The internal DNS server is authoritative for the child zone:

```text
lab.corp.example
```

It also hosts the reverse zone:

```text
50.168.192.in-addr.arpa
```

This server performs authoritative DNS service, DNSSEC signing, recursive DNSSEC validation, and TSIG-secured zone transfers.

DNS server IP:

```text
192.168.50.10
```

### Client/Test Machines

Client machines are used to test DNS resolution, hierarchy delegation, signed DNSSEC records, recursive validation, and resolver behavior.

Example hosts:

```text
ad.lab.corp.example  - 192.168.50.6
client01.lab.corp.example  - 192.168.50.15
client02.lab.corp.example  - 192.168.50.16
client03.lab.corp.example  - 192.168.50.17
```

## Network Flow

A client querying the child zone follows this path:

```text
Client → Gateway DNS → Child-zone delegation → Internal DNS Server
```

The gateway provides an NS delegation and glue A record so clients can locate the authoritative server for the child zone.

## DNS Roles

```text
gw01.corp.example
Authoritative for: corp.example

dns01.lab.corp.example
Authoritative for: lab.corp.example
Authoritative for: 50.168.192.in-addr.arpa
Recursive DNSSEC validation server
```

## Security Controls

The environment includes several DNS and network security controls:

* DNS service limited to expected networks
* SSH access restricted to internal hosts
* Zone transfers restricted with TSIG keys
* DNSSEC signing enabled on authoritative zones
* DNSSEC validation enabled on the recursive resolver
* nftables firewall rules controlling inbound, outbound, and forwarded traffic


* Child zone records resolve from the internal DNS server
* Reverse zone records resolve from the internal DNS server

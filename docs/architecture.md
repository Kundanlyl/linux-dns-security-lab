# Architecture

This lab models a small enterprise DNS environment using a parent DNS zone, a delegated child zone, an authoritative internal DNS server, and firewall controls.

## Components

### Gateway DNS Server

The gateway DNS server is authoritative for the parent zone:

```text
example.internal
```

Its main role is to hold the parent zone and delegate the child zone to the internal DNS server.

### Internal DNS Server

The internal DNS server is authoritative for the child zone:

```text
lab.example.internal
```

It also hosts the reverse zone:

```text
50.168.192.in-addr.arpa
```

This server performs authoritative DNS service, DNSSEC signing, recursive DNSSEC validation, and TSIG-secured zone transfers.

### Client/Test Machines

Client machines are used to test DNS resolution, hierarchy delegation, signed DNSSEC records, and resolver behavior.

## Example Network

```text
Gateway DNS: 192.168.50.5
Internal DNS: 192.168.50.10
Client 1: 192.168.50.15
Client 2: 192.168.50.16
Client 3: 192.168.50.17
```

## DNS Flow

A client querying the child zone follows this path:

```text
Client → Gateway DNS → Child-zone delegation → Internal DNS Server
```

The gateway provides an NS delegation and glue A record so clients can locate the authoritative server for the child zone.

## Security Controls

The environment includes several DNS and network security controls:

* DNS service limited to expected networks
* SSH access restricted to internal hosts
* Zone transfers restricted with TSIG keys
* DNSSEC signing enabled on authoritative zones
* DNSSEC validation enabled on the recursive resolver
* nftables firewall rules controlling inbound, outbound, and forwarded traffic

# `docs/dns-hierarchy.md`

# DNS Hierarchy

This lab uses a parent DNS zone and a delegated child zone.

## Parent Zone

The gateway DNS server is authoritative for the parent zone:

```text
example.internal
```

The parent zone contains its own SOA and NS records, plus a delegation for the child zone.

Example parent zone records:

```dns
$TTL 86400
@ IN SOA gateway.example.internal. admin.example.internal. (
    2026072201
    604800
    86400
    2419200
    604800 )

@       IN NS   gateway.example.internal.
gateway IN A    192.168.50.5

lab.example.internal.      IN NS dns.lab.example.internal.
dns.lab.example.internal.  IN A  192.168.50.10
```

## Child Zone

The internal DNS server is authoritative for:

```text
lab.example.internal
```

Example child zone records:

```dns
$TTL 86400
@ IN SOA dns.lab.example.internal. admin.lab.example.internal. (
    2026072201
    604800
    86400
    2419200
    604800 )

@       IN NS dns.lab.example.internal.

dns     IN A 192.168.50.10
client1 IN A 192.168.50.15
client2 IN A 192.168.50.16
client3 IN A 192.168.50.17
```

## Glue Records

The parent zone needs a glue record because the delegated nameserver is inside the child zone.

Delegation:

```dns
lab.example.internal. IN NS dns.lab.example.internal.
```

Glue:

```dns
dns.lab.example.internal. IN A 192.168.50.10
```

Without the glue record, a resolver may know which nameserver is responsible for the child zone but not know how to reach it.

## Verification

Example tests:

```bash
dig @192.168.50.5 example.internal SOA
dig @192.168.50.5 lab.example.internal SOA
dig @192.168.50.10 lab.example.internal SOA
```

Expected result:

* Parent zone resolves through the gateway
* Child zone delegation points to the internal DNS server
* Child zone records resolve from the internal DNS server


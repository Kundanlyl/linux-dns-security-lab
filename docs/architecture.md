# `docs/architecture.md`

# Architecture

This lab models a small enterprise DNS environment using a parent DNS zone, a delegated child zone, an authoritative internal DNS server, and firewall controls.

## Components

### Gateway DNS Server

The gateway DNS server is authoritative for the parent zone:

```text
klayal.300.ops
```

Its main role is to hold the parent zone and delegate the child zone to the internal DNS server.

Gateway IP:

```text
192.168.50.5
```

### Internal DNS Server

The internal DNS server is authoritative for the child zone:

```text
lab.klayal.300.ops
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
ad.lab.klayal.300.ops  - 192.168.50.6
c1.lab.klayal.300.ops  - 192.168.50.15
c2.lab.klayal.300.ops  - 192.168.50.16
c3.lab.klayal.300.ops  - 192.168.50.17
```

## Network Flow

A client querying the child zone follows this path:

```text
Client → Gateway DNS → Child-zone delegation → Internal DNS Server
```

The gateway provides an NS delegation and glue A record so clients can locate the authoritative server for the child zone.

## DNS Roles

```text
gateway.klayal.300.ops
Authoritative for: klayal.300.ops

dns.lab.klayal.300.ops
Authoritative for: lab.klayal.300.ops
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

# `docs/dns-hierarchy.md`

# DNS Hierarchy

This lab uses a parent DNS zone and a delegated child zone.

## Parent Zone

The gateway DNS server is authoritative for the parent zone:

```text
klayal.300.ops
```

The parent zone contains its own SOA and NS records, plus a delegation for the child zone.

Example parent zone records:

```dns
$TTL 86400
@ IN SOA gateway.klayal.300.ops. root.klayal.300.ops. (
    2026072201
    604800
    86400
    2419200
    604800 )

@       IN NS   gateway.klayal.300.ops.
gateway IN A    192.168.50.5

lab.klayal.300.ops.      IN NS dns.lab.klayal.300.ops.
dns.lab.klayal.300.ops.  IN A  192.168.50.10
```

## Child Zone

The internal DNS server is authoritative for:

```text
lab.klayal.300.ops
```

Example child zone records:

```dns
$TTL 86400
@ IN SOA dns.lab.klayal.300.ops. root.lab.klayal.300.ops. (
    2026072201
    604800
    86400
    2419200
    604800 )

@   IN NS dns.lab.klayal.300.ops.

dns IN A 192.168.50.10
ad  IN A 192.168.50.6
c1  IN A 192.168.50.15
c2  IN A 192.168.50.16
c3  IN A 192.168.50.17
```

## Reverse Zone

The DNS server also hosts the reverse zone:

```text
50.168.192.in-addr.arpa
```

Example reverse records:

```dns
$TTL 86400
@ IN SOA dns.lab.klayal.300.ops. root.lab.klayal.300.ops. (
    2026072201
    604800
    86400
    2419200
    604800 )

@  IN NS dns.lab.klayal.300.ops.

5  IN PTR gateway.klayal.300.ops.
6  IN PTR ad.lab.klayal.300.ops.
10 IN PTR dns.lab.klayal.300.ops.
15 IN PTR c1.lab.klayal.300.ops.
16 IN PTR c2.lab.klayal.300.ops.
17 IN PTR c3.lab.klayal.300.ops.
```

## Glue Records

The parent zone needs a glue record because the delegated nameserver is inside the child zone.

Delegation:

```dns
lab.klayal.300.ops. IN NS dns.lab.klayal.300.ops.
```

Glue:

```dns
dns.lab.klayal.300.ops. IN A 192.168.50.10
```

Without the glue record, a resolver may know which nameserver is responsible for the child zone but not know how to reach it.

## Verification

Example tests:

```bash
dig @192.168.50.5 klayal.300.ops SOA
dig @192.168.50.5 lab.klayal.300.ops SOA
dig @192.168.50.10 lab.klayal.300.ops SOA
dig @192.168.50.10 c1.lab.klayal.300.ops A
```

Expected result:

* Parent zone resolves through the gateway
* Child zone delegation points to the internal DNS server
* Child zone records resolve from the internal DNS server
* Reverse zone records resolve from the internal DNS server

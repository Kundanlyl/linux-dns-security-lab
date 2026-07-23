# linux-dns-security-lab
# Enterprise DNS and DNSSEC Lab

A Linux infrastructure security project demonstrating BIND9 DNS hierarchy, DNSSEC authoritative signing, recursive DNSSEC validation, TSIG-secured zone transfers, and nftables firewall policy design.

## Overview

This project documents a small enterprise-style DNS environment built with Ubuntu Server and BIND9. The lab simulates a parent DNS zone, a delegated internal child zone, signed authoritative DNS records, secure zone transfers, and firewall rules that restrict DNS and SSH access.

The repository contains sanitized example configurations and documentation. Private keys, generated DNSSEC private material, journal files, signed runtime files, and raw submission outputs are intentionally excluded.

## Goals

The main goals of this project are to:

* Build a delegated DNS hierarchy using a parent zone and child zone
* Configure BIND9 as an authoritative DNS server
* Enable DNSSEC signing for internal authoritative zones
* Configure recursive DNSSEC validation
* Secure zone transfers with TSIG keys
* Use nftables to restrict DNS, SSH, forwarding, and NAT traffic
* Document troubleshooting steps for common DNS and DNSSEC issues

## Technologies Used

* Ubuntu Server
* BIND9 / named
* DNSSEC
* TSIG-secured AXFR
* nftables
* systemd-resolved
* dig
* delv
* rndc
* dnssec-dsfromkey

## Example Architecture

```text
Client VM
   |
   v
Gateway DNS Server
Authoritative for: example.internal
   |
   v
Internal DNS Server
Authoritative for: lab.example.internal
```

Example sanitized network:

```text
Gateway DNS: 192.168.50.5
Internal DNS: 192.168.50.10
Client 1: 192.168.50.15
Client 2: 192.168.50.16
Client 3: 192.168.50.17
```

## Key Features

* Parent-to-child DNS delegation using NS and glue records
* Forward and reverse DNS zone configuration
* DNSSEC signing with `dnssec-policy default`
* Recursive DNSSEC validation using BIND9
* TSIG-secured zone transfers
* Local validation testing with `delv`
* nftables rules for inbound DNS, SSH, forwarding, and NAT
* Verification scripts for DNS hierarchy and DNSSEC testing

## Repository Structure

```text
enterprise-dns-dnssec-lab/
├── README.md
├── docs/
│   ├── architecture.md
│   ├── dns-hierarchy.md
│   ├── dnssec-validation.md
│   └── troubleshooting.md
├── configs/
│   ├── gateway/
│   │   ├── named.conf.options
│   │   ├── named.conf.local
│   │   └── db.parent.example
│   ├── dns/
│   │   ├── named.conf.options
│   │   ├── named.conf.local
│   │   ├── db.lab.example
│   │   └── db.reverse.example
│   └── nftables/
│       ├── gateway.nft
│       ├── dns.nft
│       └── client.nft
├── scripts/
│   ├── verify-dns.sh
│   └── verify-dnssec.sh
└── .gitignore
```

## Configuration Areas

### Gateway DNS

The gateway configuration demonstrates a parent DNS zone with a delegated child zone. The parent zone includes NS delegation and glue records so clients can locate the internal authoritative DNS server.

Relevant files:

```text
configs/gateway/named.conf.options
configs/gateway/named.conf.local
configs/gateway/db.parent.example
```

### Internal DNS Server

The internal DNS server configuration demonstrates authoritative DNS hosting, dynamic-update-compatible zone storage, DNSSEC signing, and TSIG-secured zone transfers.

Relevant files:

```text
configs/dns/named.conf.options
configs/dns/named.conf.local
configs/dns/db.lab.example
configs/dns/db.reverse.example
```

### nftables

The firewall examples restrict inbound DNS and SSH, control forwarding behavior, and demonstrate NAT/masquerading on the gateway.

Relevant files:

```text
configs/nftables/gateway.nft
configs/nftables/dns.nft
configs/nftables/client.nft
```

## Example Verification Commands

DNS hierarchy:

```bash
dig @192.168.50.5 example.internal SOA
dig @192.168.50.5 lab.example.internal SOA
dig @192.168.50.10 lab.example.internal SOA
```

DNSSEC authoritative records:

```bash
dig @192.168.50.10 lab.example.internal DNSKEY +dnssec
dig @192.168.50.10 client1.lab.example.internal A +dnssec
```

Recursive DNSSEC validation:

```bash
dig +tcp +dnssec @192.168.50.10 isc.org
dig @192.168.50.10 www.dnssec-failed.org
```

Expected results include authoritative answers, DNSKEY/RRSIG records for signed zones, the `ad` flag for validated external DNSSEC records, and `SERVFAIL` for intentionally broken DNSSEC domains.

## Security Note

This repository uses sanitized example values. It does not include real private key material, generated runtime files, or raw submission output.

Excluded examples:

```text
*.private
K*.private
K*.key
*.jnl
*.signed
*.signed.jnl
*.state
managed-keys.bind*
rndc.key
update-key.key
primary-secondary1.key
```

## Skills Demonstrated

* Linux server administration
* DNS hierarchy and delegation
* BIND9 authoritative DNS configuration
* DNSSEC signing and validation
* TSIG-secured DNS zone transfers
* nftables firewall policy design
* Infrastructure troubleshooting
* Technical documentation

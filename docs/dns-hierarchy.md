# `docs/dnssec-validation.md`

# DNSSEC Validation

This lab demonstrates both recursive DNSSEC validation and authoritative DNSSEC signing.

## Recursive DNSSEC Validation

The internal DNS server is configured to validate DNSSEC for recursive queries.

Example BIND setting:

```conf
dnssec-validation auto;
```

A positive validation test can be performed with a signed public domain:

```bash
dig +tcp +dnssec @192.168.50.10 isc.org
```

Expected result:

```text
flags: ... ad ...
RRSIG records present
```

The `ad` flag means the resolver validated the response as authenticated data.

## Negative DNSSEC Test

A deliberately broken DNSSEC domain should fail validation:

```bash
dig @192.168.50.10 www.dnssec-failed.org
```

Expected result:

```text
SERVFAIL
```

This confirms that the resolver is not simply ignoring broken DNSSEC signatures.

## Authoritative DNSSEC Signing

The authoritative zones use BIND9 DNSSEC policy-based signing:

```conf
dnssec-policy default;
```

Example zone configuration:

```conf
zone "lab.klayal.300.ops" {
    type primary;
    file "/var/cache/bind/db.lab.klayal.300.ops";
    allow-transfer { key "primary-secondary1"; };
    allow-update { key "update-key"; };
    dnssec-policy default;
};

zone "50.168.192.in-addr.arpa" {
    type primary;
    file "/var/cache/bind/db.50.168.192";
    allow-transfer { key "primary-secondary1"; };
    allow-update { key "update-key"; };
    dnssec-policy default;
};
```

## Signed Record Verification

A signed authoritative zone should return DNSSEC records when queried with `+dnssec`.

Example:

```bash
dig @192.168.50.10 lab.klayal.300.ops DNSKEY +dnssec
dig @192.168.50.10 c1.lab.klayal.300.ops A +dnssec
dig @192.168.50.10 lab.klayal.300.ops SOA +dnssec
```

Expected records:

```text
DNSKEY
RRSIG
NSEC
```

## Zone Status Verification

BIND zone status can be checked with:

```bash
sudo rndc zonestatus lab.klayal.300.ops
sudo rndc zonestatus 50.168.192.in-addr.arpa
```

Expected indicators:

```text
secure: yes
key maintenance: automatic
dynamic: yes
```

## Trust Anchors and Local Validation

Before a full parent-chain DNSSEC configuration exists, a local trust anchor can be used with `delv`.

Example:

```bash
sudo delv @127.0.0.1 -a lab.klayal.300.ops.trust +root=lab.klayal.300.ops SOA lab.klayal.300.ops
```

Expected result:

```text
; fully validated
```

# `docs/troubleshooting.md`

# Troubleshooting

This document lists common issues encountered when configuring BIND9 DNS hierarchy, DNSSEC, TSIG zone transfers, and nftables.

## Localhost DNS Query Fails

Problem:

```bash
dig @127.0.0.1 klayal.300.ops SOA
```

returns:

```text
connection refused
```

Likely cause:

BIND is not listening on loopback.

Fix:

```conf
listen-on { 127.0.0.1; 192.168.50.5; };
```

For the internal DNS server:

```conf
listen-on { 127.0.0.1; 192.168.50.10; };
```

Also confirm loopback is allowed in nftables:

```nft
iif "lo" accept
```

## DNSSEC Records Missing

Problem:

```bash
dig @127.0.0.1 lab.klayal.300.ops DNSKEY +dnssec
```

returns no DNSKEY or RRSIG records.

Likely causes:

* `dnssec-policy default;` is missing from the zone
* Zone file is not in a writable location
* BIND cannot write generated DNSSEC files
* The wrong zone file is being loaded
* The server is returning cached recursive data instead of an authoritative answer

Checks:

```bash
sudo named-checkconf
sudo rndc zonestatus lab.klayal.300.ops
sudo ls -lah /var/cache/bind
dig @127.0.0.1 lab.klayal.300.ops SOA +norecurse
```

Expected zone status includes:

```text
secure: yes
key maintenance: automatic
dynamic: yes
```

Expected query flag for authoritative answers:

```text
aa
```

## AXFR Fails

Problem:

```bash
dig AXFR lab.klayal.300.ops @192.168.50.10
```

returns:

```text
Transfer failed
```

Likely cause:

Zone transfers require TSIG authentication.

Use the correct key:

```bash
sudo dig AXFR lab.klayal.300.ops @192.168.50.10 -k /etc/bind/keys/primary-secondary1.key
```

Reverse zone:

```bash
sudo dig AXFR 50.168.192.in-addr.arpa @192.168.50.10 -k /etc/bind/keys/primary-secondary1.key
```

## Private Domain Returns SERVFAIL

Problem:

An internal/private domain returns `SERVFAIL` when queried through a validating resolver.

Likely cause:

The resolver is trying to validate a private zone that does not have a public DNSSEC chain of trust.

Fix options:

* Disable DNSSEC validation on the test forwarding resolver
* Add a local trust anchor
* Publish the child zone DS record into the parent zone if parent-chain validation is part of the project

## nftables Blocks DNS

Problem:

DNS queries timeout or TCP DNS fails.

Checks:

```bash
sudo nft list ruleset
```

Required rules usually include:

```nft
iif "lo" accept
ct state established,related accept
ip saddr 192.168.50.0/24 udp dport 53 accept
ip saddr 192.168.50.0/24 tcp dport 53 accept
```

DNSSEC and AXFR can require TCP/53, so UDP/53 alone is not enough.

## Hostname Domain Is Blank

Problem:

```bash
hostname -d
```

returns blank.

This can break scripts that calculate the DNS domain from the host’s FQDN.

Fix example:

```bash
sudo hostnamectl set-hostname gateway.klayal.300.ops
```

Then update `/etc/hosts`:

```text
127.0.1.1 gateway.klayal.300.ops gateway
192.168.50.5 gateway.klayal.300.ops gateway
```

Expected:

```bash
hostname -d
```

```text
klayal.300.ops
```


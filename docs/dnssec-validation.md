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


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

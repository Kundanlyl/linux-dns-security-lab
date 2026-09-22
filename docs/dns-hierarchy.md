# DNS Hierarchy

This lab uses a parent DNS zone and a delegated child zone.

## Parent Zone

The gateway DNS server is authoritative for the parent zone:

```text
corp.example
```

The parent zone contains its own SOA and NS records, plus a delegation for the child zone.

Example parent zone records:

```dns
$TTL 86400
@ IN SOA gw01.corp.example. root.corp.example. (
    2026072201
    604800
    86400
    2419200
    604800 )

@       IN NS   gw01.corp.example.
gateway IN A    192.168.50.5

lab.corp.example.      IN NS dns01.lab.corp.example.
dns01.lab.corp.example.  IN A  192.168.50.10
```

## Child Zone

The internal DNS server is authoritative for:

```text
lab.corp.example
```

Example child zone records:

```dns
$TTL 86400
@ IN SOA dns01.lab.corp.example. root.lab.corp.example. (
    2026072201
    604800
    86400
    2419200
    604800 )

@   IN NS dns01.lab.corp.example.

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
@ IN SOA dns01.lab.corp.example. root.lab.corp.example. (
    2026072201
    604800
    86400
    2419200
    604800 )

@  IN NS dns01.lab.corp.example.

5  IN PTR gw01.corp.example.
6  IN PTR ad.lab.corp.example.
10 IN PTR dns01.lab.corp.example.
15 IN PTR client01.lab.corp.example.
16 IN PTR client02.lab.corp.example.
17 IN PTR client03.lab.corp.example.
```

## Glue Records

The parent zone needs a glue record because the delegated nameserver is inside the child zone.

Delegation:

```dns
lab.corp.example. IN NS dns01.lab.corp.example.
```

Glue:

```dns
dns01.lab.corp.example. IN A 192.168.50.10
```

Without the glue record, a resolver may know which nameserver is responsible for the child zone but not know how to reach it.

## Verification

Example tests:

```bash
dig @192.168.50.5 corp.example SOA
dig @192.168.50.5 lab.corp.example SOA
dig @192.168.50.10 lab.corp.example SOA
dig @192.168.50.10 client01.lab.corp.example A
```

Expected result:

* Parent zone resolves through the gateway
* Child zone delegation points to the internal DNS server
* Child zone records resolve from the internal DNS server
* Reverse zone records resolve from the internal DNS server

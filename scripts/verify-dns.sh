#!/usr/bin/env bash

# verify-dns.sh
# Basic DNS hierarchy verification for the Enterprise DNS/DNSSEC lab.
# This script uses sanitized lab IPs and the lab.klayal.300.ops domain.

set -u

PARENT_ZONE="klayal.300.ops"
CHILD_ZONE="lab.klayal.300.ops"
REVERSE_ZONE="50.168.192.in-addr.arpa"

GATEWAY_DNS="192.168.50.5"
INTERNAL_DNS="192.168.50.10"

HOST_RECORD="c1.lab.klayal.300.ops"
REVERSE_RECORD="15.50.168.192.in-addr.arpa"

pass_count=0
fail_count=0

print_header() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "[ERROR] Required command not found: $1"
        echo "Install it with: sudo apt install dnsutils"
        exit 1
    fi
}

run_check() {
    local name="$1"
    local command="$2"
    local expected="$3"

    echo
    echo "[TEST] $name"
    echo "[CMD ] $command"

    output=$(eval "$command" 2>&1)

    if echo "$output" | grep -q "$expected"; then
        echo "[PASS] Found expected result: $expected"
        pass_count=$((pass_count + 1))
    else
        echo "[FAIL] Expected result not found: $expected"
        echo "------ Output ------"
        echo "$output"
        echo "--------------------"
        fail_count=$((fail_count + 1))
    fi
}

check_command dig

print_header "DNS Hierarchy Verification"

run_check \
    "Parent zone SOA from gateway DNS" \
    "dig @$GATEWAY_DNS $PARENT_ZONE SOA +short" \
    "gateway.$PARENT_ZONE"

run_check \
    "Child zone delegation through gateway DNS" \
    "dig @$GATEWAY_DNS $CHILD_ZONE SOA +short" \
    "dns.$CHILD_ZONE"

run_check \
    "Child zone SOA directly from internal DNS" \
    "dig @$INTERNAL_DNS $CHILD_ZONE SOA +short" \
    "dns.$CHILD_ZONE"

run_check \
    "Forward host record from internal DNS" \
    "dig @$INTERNAL_DNS $HOST_RECORD A +short" \
    "192.168.50.15"

run_check \
    "Reverse PTR record from internal DNS" \
    "dig @$INTERNAL_DNS $REVERSE_RECORD PTR +short" \
    "$HOST_RECORD"

print_header "Summary"

echo "Passed: $pass_count"
echo "Failed: $fail_count"

if [ "$fail_count" -eq 0 ]; then
    echo "[SUCCESS] DNS hierarchy verification completed successfully."
    exit 0
else
    echo "[ERROR] Some DNS hierarchy checks failed."
    exit 1
fi

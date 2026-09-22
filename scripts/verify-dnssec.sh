#!/usr/bin/env bash

# verify-dnssec.sh
# DNSSEC verification script for the Enterprise DNS/DNSSEC lab.
# This script checks authoritative DNSSEC records and recursive validation behavior.

set -u

CHILD_ZONE="lab.corp.example"
REVERSE_ZONE="50.168.192.in-addr.arpa"

INTERNAL_DNS="192.168.50.10"

SIGNED_HOST="client01.lab.corp.example"
VALID_PUBLIC_DOMAIN="isc.org"
BROKEN_DNSSEC_DOMAIN="www.dnssec-failed.org"

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

print_header "Authoritative DNSSEC Verification"

run_check \
    "Child zone DNSKEY record exists" \
    "dig @$INTERNAL_DNS $CHILD_ZONE DNSKEY +dnssec" \
    "DNSKEY"

run_check \
    "Child zone returns RRSIG records" \
    "dig @$INTERNAL_DNS $CHILD_ZONE SOA +dnssec" \
    "RRSIG"

run_check \
    "Signed host record returns RRSIG" \
    "dig @$INTERNAL_DNS $SIGNED_HOST A +dnssec" \
    "RRSIG"

run_check \
    "Reverse zone DNSSEC records exist" \
    "dig @$INTERNAL_DNS $REVERSE_ZONE DNSKEY +dnssec" \
    "DNSKEY"

print_header "Recursive DNSSEC Validation"

run_check \
    "Valid public DNSSEC domain returns authenticated data flag" \
    "dig +tcp +dnssec @$INTERNAL_DNS $VALID_PUBLIC_DOMAIN" \
    "ad"

run_check \
    "Broken DNSSEC domain returns SERVFAIL" \
    "dig @$INTERNAL_DNS $BROKEN_DNSSEC_DOMAIN" \
    "SERVFAIL"

print_header "Summary"

echo "Passed: $pass_count"
echo "Failed: $fail_count"

if [ "$fail_count" -eq 0 ]; then
    echo "[SUCCESS] DNSSEC verification completed successfully."
    exit 0
else
    echo "[ERROR] Some DNSSEC checks failed."
    exit 1
fi

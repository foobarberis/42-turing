#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

LOG="test/log.txt"
: > "$LOG"
count=0

fail_case() {
	name=$1
	status=$2
	printf '[e2e] [%02d] FAIL %s\n  command exited with status %s; see %s\n' "$count" "$name" "$status" "$LOG" >&2
	exit 1
}

run_case() {
	json=$1
	input=$2
	name="$json \"$input\""
	count=$((count + 1))
	printf './ft_turing %s "%s"\n' "$json" "$input" >> "$LOG"
	if ./ft_turing "$json" "$input" >> "$LOG" 2>&1; then
		printf 'OK\n\n' >> "$LOG"
		printf '[e2e] [%02d] OK %s\n' "$count" "$name"
	else
		status=$?
		printf 'FAIL (exit %s)\n\n' "$status" >> "$LOG"
		fail_case "$name" "$status"
	fi
}

printf 'e2e\n'

run_case "res/02n.json" ""
run_case "res/02n.json" "0000"
run_case "res/0n1n.json" ""
run_case "res/0n1n.json" "000111"
run_case "res/is_palindrome.json" ""
run_case "res/is_palindrome.json" "1000000001"
run_case "res/unary_add.json" "11+1111="
run_case "res/utm.json" "1.+=|.|ABCDE|A|E|A.A.RA1A1RA+A+RA=B.LB1C=LB+E.LC1C1LC+D1RD1D1RD=E.R|_11+1111="

printf 'SUMMARY: %d OK / 0 FAIL\n' "$count"
printf 'SUMMARY: %d OK / 0 FAIL\n' "$count" >> "$LOG"

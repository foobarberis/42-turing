#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

LOG="test/log.txt"
: > "$LOG"
count=0

run() {
	json=$1
	input=$2
	printf '[e2e] %s "%s"\n' "$json" "$input"
	printf './ft_turing %s "%s"\n' "$json" "$input" >> "$LOG"
	if ./ft_turing "$json" "$input" >> "$LOG" 2>&1; then
		printf 'OK\n\n' >> "$LOG"
		count=$((count + 1))
	else
		printf 'FAIL: %s "%s"\n' "$json" "$input" >&2
		exit 1
	fi
}

run "res/02n.json" "0000"
run "res/0n1n.json" "000111"
run "res/infloop.json" "10"
run "res/is_palindrome.json" "1000000001"
run "res/unary_add.json" "1+1="
run "res/unary-add-min.json" "1+1="
run "res/unary_sub.json" "111-11="
run "res/utm.json" "1.+=|.|ABCDE|A|E|A.A.RA1A1RA+A+RA=B.LB1C=LB+E.LC1C1LC+D1RD1D1RD=E.R|_11+1111="

printf 'OK: %d e2e cases passed\n' "$count"
printf 'OK: %d e2e cases passed\n' "$count" >> "$LOG"

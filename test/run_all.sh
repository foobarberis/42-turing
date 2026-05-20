#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/.."

LOG="test/log.txt"
: > "$LOG"
rm -rf log

count=0
status=0
case_name=
log_file=
last_step_line=
final_line=

fail_case() {
	message=$1
	printf 'FAIL: %s\n\n' "$message" >> "$LOG"
	printf '[e2e] [%02d] FAIL %s\n  %s; see %s\n' "$count" "$case_name" "$message" "$LOG" >&2
	exit 1
}

run_case() {
	case_name=$1
	json=$2
	input=$3
	log_file=$4

	count=$((count + 1))
	rm -f "$log_file"

	cmd=(./ft_turing -l "$log_file" "$json" -- "$input")
	printf '%q ' "${cmd[@]}" >> "$LOG"
	printf '\n' >> "$LOG"
	if "${cmd[@]}" >> "$LOG" 2>&1; then
		status=0
	else
		status=$?
	fi
	printf 'exit: %s\n' "$status" >> "$LOG"
}

assert_status() {
	expected=$1
	[ "$status" -eq "$expected" ] || fail_case "expected exit $expected, got $status"
}

assert_log_created() {
	[ -s "$log_file" ] || fail_case "expected non-empty log file: $log_file"
}

load_trace_tail() {
	last_step_line=$(tail -n 2 "$log_file" | head -n 1)
	final_line=$(tail -n 1 "$log_file")
	printf 'log: %s\n' "$log_file" >> "$LOG"
	printf 'last step: %s\n' "$last_step_line" >> "$LOG"
	printf 'final line: %s\n' "$final_line" >> "$LOG"
}

assert_not_blocked() {
	case "$final_line" in
		*"Blocked at this state"*)
			fail_case "machine blocked instead of halting: $final_line"
			;;
	esac
}

assert_last_step_contains() {
	needle=$1
	case "$last_step_line" in
		*"$needle"*) ;;
		*) fail_case "expected last step to contain $needle, got: $last_step_line" ;;
	esac
}

assert_final_contains() {
	needle=$1
	case "$final_line" in
		*"$needle"*) ;;
		*) fail_case "expected final line to contain $needle, got: $final_line" ;;
	esac
}

assert_trace_case() {
	assert_status 0
	assert_log_created
	load_trace_tail
	assert_not_blocked
	assert_last_step_contains "$1"
	assert_final_contains "$2"
}

assert_blocked_case() {
	assert_status 0
	assert_log_created
	load_trace_tail
	assert_final_contains "$1"
}

pass_case() {
	printf 'OK\n\n' >> "$LOG"
	printf '[e2e] [%02d] OK %s\n' "$count" "$case_name"
}

printf 'e2e\n'

run_case 'blocked machine reports the blocked state' 'test/fixtures/e2e/blocked.json' '0' 'log/blocked_info.log'
assert_blocked_case 'Blocked at this state q0'
pass_case

run_case '02n accepts empty input' 'res/02n.json' '' 'log/02n_info.log'
assert_trace_case '-> (HALT, y, LEFT)' '<.>y'
pass_case

run_case '02n accepts 00' 'res/02n.json' '00' 'log/02n_info.log'
assert_trace_case '(init, .) -> (HALT, y, LEFT)' '<0>y'
pass_case

run_case '02n rejects odd zero count' 'res/02n.json' '0' 'log/02n_info.log'
assert_trace_case '-> (HALT, n, LEFT)' '<0>n'
pass_case

run_case '02n accepts 0000' 'res/02n.json' '0000' 'log/02n_info.log'
assert_trace_case '-> (HALT, y, LEFT)' '<0>y'
pass_case

run_case '02n accepts 000 as valid syntax and rejects it semantically' 'res/02n.json' '000' 'log/02n_info.log'
assert_trace_case '-> (HALT, n, LEFT)' '<0>n'
pass_case

run_case '02n rejects y as malformed external input' 'res/02n.json' 'y' 'log/02n_info.log'
assert_blocked_case 'Blocked at this state INVALID_INPUT'
pass_case

run_case '02n rejects n as malformed external input' 'res/02n.json' 'n' 'log/02n_info.log'
assert_blocked_case 'Blocked at this state INVALID_INPUT'
pass_case

run_case '0n1n accepts empty input' 'res/0n1n.json' '' 'log/0n1n_info.log'
assert_trace_case '-> (HALT, y, LEFT)' '<.>y'
pass_case

run_case '0n1n accepts 01' 'res/0n1n.json' '01' 'log/0n1n_info.log'
assert_trace_case '-> (HALT, y, LEFT)' '<->y'
pass_case

run_case '0n1n accepts 000111' 'res/0n1n.json' '000111' 'log/0n1n_info.log'
assert_trace_case '-> (HALT, y, LEFT)' '<->y'
pass_case

run_case '0n1n rejects 0 as valid syntax but invalid language member' 'res/0n1n.json' '0' 'log/0n1n_info.log'
assert_trace_case '-> (HALT, n, LEFT)' '<->n'
pass_case

run_case '0n1n rejects 10 as valid syntax but invalid language member' 'res/0n1n.json' '10' 'log/0n1n_info.log'
assert_trace_case '-> (HALT, n, LEFT)' '<0>n'
pass_case

run_case '0n1n rejects 00011' 'res/0n1n.json' '00011' 'log/0n1n_info.log'
assert_trace_case '-> (HALT, n, LEFT)' '<->n'
pass_case

run_case '0n1n rejects wrong-order input 001011' 'res/0n1n.json' '001011' 'log/0n1n_info.log'
assert_trace_case '(deny, y) -> (HALT, n, LEFT)' '.--10-<->n'
pass_case

run_case '0n1n rejects y as malformed external input' 'res/0n1n.json' 'y' 'log/0n1n_info.log'
assert_blocked_case 'Blocked at this state INVALID_INPUT'
pass_case

run_case '0n1n rejects n as malformed external input' 'res/0n1n.json' 'n' 'log/0n1n_info.log'
assert_blocked_case 'Blocked at this state INVALID_INPUT'
pass_case

run_case '0n1n rejects - as malformed external input' 'res/0n1n.json' '-' 'log/0n1n_info.log'
assert_blocked_case 'Blocked at this state INVALID_INPUT'
pass_case

run_case 'is_palindrome accepts empty input' 'res/is_palindrome.json' '' 'log/is_palindrome_info.log'
assert_trace_case '-> (HALT, y, LEFT)' '<.>y'
pass_case

run_case 'is_palindrome accepts 0110' 'res/is_palindrome.json' '0110' 'log/is_palindrome_info.log'
assert_trace_case '(init, y) -> (HALT, y, LEFT)' '.---<->y'
pass_case

run_case 'is_palindrome accepts 010' 'res/is_palindrome.json' '010' 'log/is_palindrome_info.log'
assert_trace_case '(is_one, .) -> (HALT, ., LEFT)' '---y'
pass_case

run_case 'is_palindrome accepts 1000000001' 'res/is_palindrome.json' '1000000001' 'log/is_palindrome_info.log'
assert_trace_case '-> (HALT, y, LEFT)' '<->y'
pass_case

run_case 'is_palindrome rejects 01' 'res/is_palindrome.json' '01' 'log/is_palindrome_info.log'
assert_trace_case '(deny, y) -> (HALT, n, LEFT)' '<1>n'
pass_case

run_case 'is_palindrome rejects 10010' 'res/is_palindrome.json' '10010' 'log/is_palindrome_info.log'
assert_trace_case '-> (HALT, n, LEFT)' '<0>n'
pass_case

run_case 'is_palindrome rejects y as malformed external input' 'res/is_palindrome.json' 'y' 'log/is_palindrome_info.log'
assert_blocked_case 'Blocked at this state INVALID_INPUT'
pass_case

run_case 'is_palindrome rejects n as malformed external input' 'res/is_palindrome.json' 'n' 'log/is_palindrome_info.log'
assert_blocked_case 'Blocked at this state INVALID_INPUT'
pass_case

run_case 'is_palindrome rejects - as malformed external input' 'res/is_palindrome.json' '-' 'log/is_palindrome_info.log'
assert_blocked_case 'Blocked at this state INVALID_INPUT'
pass_case

run_case 'unary_add accepts += as empty operands' 'res/unary_add.json' '+=' 'log/unary_add_info.log'
assert_trace_case '(B, +) -> (E, ., LEFT)' '[<.>'
pass_case

run_case 'unary_add accepts 1+= as empty right operand' 'res/unary_add.json' '1+=' 'log/unary_add_info.log'
assert_trace_case '(B, +) -> (E, ., LEFT)' '.<1>'
pass_case

run_case 'unary_add accepts +11= as empty left operand' 'res/unary_add.json' '+11=' 'log/unary_add_info.log'
assert_trace_case '-> (E, ., RIGHT)' '11.<.>'
pass_case

run_case 'unary_add computes 11+1111= to 111111' 'res/unary_add.json' '11+1111=' 'log/unary_add_info.log'
assert_trace_case '-> (E, ., RIGHT)' '111111.<.>'
pass_case

run_case 'unary_add rejects 111 as malformed external input' 'res/unary_add.json' '111' 'log/unary_add_info.log'
assert_blocked_case 'Blocked at this state INVALID_INPUT'
pass_case

run_case 'unary_add rejects 1+11+111= as malformed external input' 'res/unary_add.json' '1+11+111=' 'log/unary_add_info.log'
assert_blocked_case 'Blocked at this state INVALID_INPUT'
pass_case

run_case 'unary_add rejects 1=+1 as malformed external input' 'res/unary_add.json' '1=+1' 'log/unary_add_info.log'
assert_blocked_case 'Blocked at this state INVALID_INPUT'
pass_case

run_case 'unary_add rejects =+ as malformed external input' 'res/unary_add.json' '=+' 'log/unary_add_info.log'
assert_blocked_case 'Blocked at this state INVALID_INPUT'
pass_case

run_case 'unary_add rejects 11+=1 as malformed external input' 'res/unary_add.json' '11+=1' 'log/unary_add_info.log'
assert_blocked_case 'Blocked at this state INVALID_INPUT'
pass_case

run_case 'utm runs encoded unary_add and yields 111111' 'res/utm.json' '1.+=|.|ABCDE|A|E|A.A.RA1A1RA+A+RA=B.LB1C=LB+E.LC1C1LC+D1RD1D1RD=E.R|_11+1111=' 'log/utm_info.log'
assert_trace_case '-> (HALT, E, RIGHT)' '|111111._.]'
pass_case

printf 'SUMMARY: %d OK / 0 FAIL\n' "$count"
printf 'SUMMARY: %d OK / 0 FAIL\n' "$count" >> "$LOG"

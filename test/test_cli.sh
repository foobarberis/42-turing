#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

count=0
status=0
stdout_file=
stderr_file=
case_name=

write_usage() {
	printf '%s\n' \
		'usage: ft_turing [-h] jsonfile input' \
		'' \
		'positional arguments:' \
		'  jsonfile    json description of the machine' \
		'  input       input of the machine' \
		'' \
		'optional arguments:' \
		'  -h, --help  show this help message and exit'
}

usage_file="$tmpdir/usage.txt"
write_usage > "$usage_file"

fail_case() {
	message=$1
	printf '[cli] [%02d] FAIL %s\n  %s\n' "$count" "$case_name" "$message" >&2
	exit 1
}

run_case() {
	case_name=$1
	shift
	count=$((count + 1))
	stdout_file="$tmpdir/$count.stdout"
	stderr_file="$tmpdir/$count.stderr"
	if "$@" >"$stdout_file" 2>"$stderr_file"; then
		status=0
	else
		status=$?
	fi
}

assert_status() {
	expected=$1
	[ "$status" -eq "$expected" ] || fail_case "expected exit $expected, got $status"
}

assert_empty() {
	file=$1
	[ ! -s "$file" ] || fail_case "expected empty file: $file"
}

assert_non_empty() {
	file=$1
	[ -s "$file" ] || fail_case "expected non-empty file: $file"
}

assert_same() {
	expected=$1
	actual=$2
	cmp -s "$expected" "$actual" || fail_case "unexpected output in $actual"
}

assert_contains() {
	needle=$1
	file=$2
	grep -F -- "$needle" "$file" >/dev/null || fail_case "missing output in $file: $needle"
}

pass_case() {
	printf '[cli] [%02d] OK %s\n' "$count" "$case_name"
}

printf 'cli\n'

run_case '--help prints usage to stdout' ./ft_turing --help
assert_status 0
assert_same "$usage_file" "$stdout_file"
assert_empty "$stderr_file"
pass_case

run_case 'wrong arg count prints usage to stderr' ./ft_turing
assert_status 1
assert_empty "$stdout_file"
assert_same "$usage_file" "$stderr_file"
pass_case

rm -rf log
run_case 'valid run is quiet and creates a log file' ./ft_turing res/unary_add.json 11+1111=
assert_status 0
assert_empty "$stdout_file"
assert_empty "$stderr_file"
assert_non_empty 'log/unary_add_info.log'
pass_case

run_case 'missing json path returns parse error' ./ft_turing test/fixtures/parse/missing.json 101
assert_status 1
assert_empty "$stdout_file"
assert_contains 'Parse error: test/fixtures/parse/missing.json:' "$stderr_file"
assert_contains 'No such file or directory' "$stderr_file"
pass_case

run_case 'malformed json returns parse error' ./ft_turing test/fixtures/parse/bad_syntax.json 101
assert_status 1
assert_empty "$stdout_file"
assert_contains 'Parse error: test/fixtures/parse/bad_syntax.json:' "$stderr_file"
assert_contains 'Unexpected end of input' "$stderr_file"
pass_case

run_case 'invalid machine returns validation error' ./ft_turing test/fixtures/validate/invalid_initial.json 0
assert_status 1
assert_empty "$stdout_file"
assert_contains 'Validation error: test/fixtures/validate/invalid_initial.json: initial must be in states' "$stderr_file"
pass_case

run_case 'invalid input symbol returns validation error' ./ft_turing res/0n1n.json 00112
assert_status 1
assert_empty "$stdout_file"
assert_contains 'Validation error: input: input symbols must be in alphabet' "$stderr_file"
pass_case

run_case 'blank in input returns validation error' ./ft_turing res/unary_add.json 11.11=
assert_status 1
assert_empty "$stdout_file"
assert_contains 'Validation error: input: input must not contain blank' "$stderr_file"
pass_case

printf 'SUMMARY: %d OK / 0 FAIL\n\n' "$count"

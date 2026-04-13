#!/bin/bash

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## Unit tests for msgcollector input validation and security.

set -o errexit
set -o nounset
set -o errtrace
set -o pipefail

PASS=0
FAIL=0
ERRORS=""

pass() {
  printf '%s\n' "$0: PASS: $1"
  PASS=$(( PASS + 1 ))
}

fail() {
  printf '%s\n' "$0: FAIL: $1" >&2
  FAIL=$(( FAIL + 1 ))
  ERRORS="${ERRORS}  FAIL: $1"$'\n'
}

## Source dependencies.
source /usr/libexec/helper-scripts/strings.bsh
source /usr/libexec/msgcollector/check

## --------------------------------------------------------------------------
printf '%s\n' "$0: === check() function tests ==="
## --------------------------------------------------------------------------

## check() should accept valid alphanumeric identifiers.
test_check_valid_simple() {
  local result
  result=0
  check "systemcheck" || result=$?
  if [ "${result}" = "0" ]; then
    pass "check accepts 'systemcheck'"
  else
    fail "check rejects 'systemcheck'"
  fi
}

test_check_valid_with_dashes() {
  local result
  result=0
  check "2b3916d6-3b3f-4490-bc85-b97da494a55d" || result=$?
  if [ "${result}" = "0" ]; then
    pass "check accepts UUID with dashes"
  else
    fail "check rejects UUID with dashes"
  fi
}

test_check_valid_with_underscores() {
  local result
  result=0
  check "my_identifier_123" || result=$?
  if [ "${result}" = "0" ]; then
    pass "check accepts underscores"
  else
    fail "check rejects underscores"
  fi
}

## check() should reject path traversal attempts.
test_check_reject_path_traversal() {
  local result
  result=0
  ## check() calls exit 1 on failure, run in subshell.
  (check "../../etc/passwd" 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects path traversal '../../etc/passwd'"
  else
    fail "check accepts path traversal '../../etc/passwd'"
  fi
}

test_check_reject_slash() {
  local result
  result=0
  (check "foo/bar" 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects slash 'foo/bar'"
  else
    fail "check accepts slash 'foo/bar'"
  fi
}

test_check_reject_empty() {
  local result
  result=0
  (check "" 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects empty string"
  else
    fail "check accepts empty string"
  fi
}

test_check_reject_spaces() {
  local result
  result=0
  (check "has spaces" 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects spaces"
  else
    fail "check accepts spaces"
  fi
}

test_check_reject_dots() {
  local result
  result=0
  (check "two..dots" 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects dots"
  else
    fail "check accepts dots"
  fi
}

test_check_reject_semicolon() {
  local result
  result=0
  (check "foo;bar" 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects semicolon injection"
  else
    fail "check accepts semicolon injection"
  fi
}

test_check_reject_dollar() {
  local result
  result=0
  (check '$(whoami)' 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects command substitution"
  else
    fail "check accepts command substitution"
  fi
}

test_check_reject_backtick() {
  local result
  result=0
  (check '`whoami`' 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects backtick injection"
  else
    fail "check accepts backtick injection"
  fi
}

test_check_reject_newline() {
  local result
  result=0
  (check $'line1\nline2' 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects newline"
  else
    fail "check accepts newline"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === is_whole_number() tests ==="
## --------------------------------------------------------------------------

test_is_whole_number_valid() {
  if is_whole_number "42"; then
    pass "is_whole_number accepts '42'"
  else
    fail "is_whole_number rejects '42'"
  fi
}

test_is_whole_number_zero() {
  if is_whole_number "0"; then
    pass "is_whole_number accepts '0'"
  else
    fail "is_whole_number rejects '0'"
  fi
}

test_is_whole_number_100() {
  if is_whole_number "100"; then
    pass "is_whole_number accepts '100'"
  else
    fail "is_whole_number rejects '100'"
  fi
}

test_is_whole_number_reject_negative() {
  if ! is_whole_number "-1"; then
    pass "is_whole_number rejects '-1'"
  else
    fail "is_whole_number accepts '-1'"
  fi
}

test_is_whole_number_reject_float() {
  if ! is_whole_number "3.14"; then
    pass "is_whole_number rejects '3.14'"
  else
    fail "is_whole_number accepts '3.14'"
  fi
}

test_is_whole_number_reject_alpha() {
  if ! is_whole_number "abc"; then
    pass "is_whole_number rejects 'abc'"
  else
    fail "is_whole_number accepts 'abc'"
  fi
}

test_is_whole_number_reject_empty() {
  if ! is_whole_number ""; then
    pass "is_whole_number rejects empty string"
  else
    fail "is_whole_number accepts empty string"
  fi
}

test_is_whole_number_reject_injection() {
  if ! is_whole_number '$(whoami)'; then
    pass "is_whole_number rejects command substitution"
  else
    fail "is_whole_number accepts command substitution"
  fi
}

test_is_whole_number_reject_spaces() {
  if ! is_whole_number "4 2"; then
    pass "is_whole_number rejects '4 2'"
  else
    fail "is_whole_number accepts '4 2'"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === check_is_alpha_numeric() tests ==="
## --------------------------------------------------------------------------

test_alpha_numeric_valid() {
  local testvar
  testvar="validName123"
  if check_is_alpha_numeric "testvar" 2>/dev/null; then
    pass "check_is_alpha_numeric accepts 'validName123'"
  else
    fail "check_is_alpha_numeric rejects 'validName123'"
  fi
}

test_alpha_numeric_reject_slash() {
  local testvar
  testvar="../../etc"
  if ! check_is_alpha_numeric "testvar" 2>/dev/null; then
    pass "check_is_alpha_numeric rejects '../../etc'"
  else
    fail "check_is_alpha_numeric accepts '../../etc'"
  fi
}

test_alpha_numeric_reject_empty() {
  local testvar
  testvar=""
  if ! check_is_alpha_numeric "testvar" 2>/dev/null; then
    pass "check_is_alpha_numeric rejects empty"
  else
    fail "check_is_alpha_numeric accepts empty"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === validate_safe_filename() tests ==="
## --------------------------------------------------------------------------

test_safe_filename_valid() {
  local testvar
  testvar="systemcheck_messagex_done"
  if validate_safe_filename "testvar" 2>/dev/null; then
    pass "validate_safe_filename accepts 'systemcheck_messagex_done'"
  else
    fail "validate_safe_filename rejects 'systemcheck_messagex_done'"
  fi
}

test_safe_filename_reject_dotdot() {
  local testvar
  testvar=".."
  if ! validate_safe_filename "testvar" 2>/dev/null; then
    pass "validate_safe_filename rejects '..'"
  else
    fail "validate_safe_filename accepts '..'"
  fi
}

test_safe_filename_reject_slash() {
  local testvar
  testvar="foo/bar"
  if ! validate_safe_filename "testvar" 2>/dev/null; then
    pass "validate_safe_filename rejects 'foo/bar'"
  else
    fail "validate_safe_filename accepts 'foo/bar'"
  fi
}

test_safe_filename_reject_leading_dash() {
  local testvar
  testvar="-rf"
  if ! validate_safe_filename "testvar" 2>/dev/null; then
    pass "validate_safe_filename rejects leading dash '-rf'"
  else
    fail "validate_safe_filename accepts leading dash '-rf'"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === msgcollector argument parsing tests ==="
## --------------------------------------------------------------------------

test_msgcollector_reject_bad_identifier() {
  local result
  result=0
  /usr/libexec/msgcollector/msgcollector \
    --identifier "../../tmp/evil" \
    --messagecli --typecli info --message "test" 2>/dev/null || result=$?
  if [ "${result}" != "0" ]; then
    pass "msgcollector rejects path traversal in --identifier"
  else
    fail "msgcollector accepts path traversal in --identifier"
  fi
}

test_msgcollector_reject_empty_identifier() {
  local result
  result=0
  /usr/libexec/msgcollector/msgcollector \
    --identifier "" \
    --messagecli --typecli info --message "test" 2>/dev/null || result=$?
  if [ "${result}" != "0" ]; then
    pass "msgcollector rejects empty --identifier"
  else
    fail "msgcollector accepts empty --identifier"
  fi
}

test_msgcollector_reject_bad_progressbaridx() {
  local result
  result=0
  /usr/libexec/msgcollector/msgcollector \
    --identifier "test" \
    --progressx "50" \
    --progressbaridx "../evil" 2>/dev/null || result=$?
  if [ "${result}" != "0" ]; then
    pass "msgcollector rejects path traversal in --progressbaridx"
  else
    fail "msgcollector accepts path traversal in --progressbaridx"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === msgprogress validation tests ==="
## --------------------------------------------------------------------------

test_msgprogress_reject_non_numeric_progress() {
  local result
  result=0
  /usr/libexec/msgcollector/msgprogress \
    --identifier "test" \
    --progressbaridx "testidx" \
    --progress '$(whoami)' 2>/dev/null || result=$?
  if [ "${result}" != "0" ]; then
    pass "msgprogress rejects non-numeric --progress"
  else
    fail "msgprogress accepts non-numeric --progress"
  fi
}

test_msgprogress_reject_bad_identifier() {
  local result
  result=0
  /usr/libexec/msgcollector/msgprogress \
    --identifier "../evil" \
    --progressbaridx "testidx" \
    --progress "50" 2>/dev/null || result=$?
  if [ "${result}" != "0" ]; then
    pass "msgprogress rejects bad --identifier"
  else
    fail "msgprogress accepts bad --identifier"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === pv_wrapper numeric validation tests ==="
## --------------------------------------------------------------------------

test_pv_wrapper_filters_non_numeric() {
  local output
  ## Feed mixed numeric and non-numeric lines. The eval'd commands just printf $percent.
  ## Non-numeric lines should be silently skipped.
  output="$(printf '%s\n' "50" '$(whoami)' "75" "abc" "100" | \
    pv_echo_command='printf "%s\n" "$percent"' \
    pv_wrapper_command='true' \
    /usr/libexec/msgcollector/pv_wrapper 2>/dev/null)"
  local expected
  expected="$(printf '%s\n' "50" "75" "100")"
  if [ "${output}" = "${expected}" ]; then
    pass "pv_wrapper filters non-numeric input lines"
  else
    fail "pv_wrapper did not filter correctly. Got: '${output}'"
  fi
}

test_pv_wrapper_reject_injection() {
  local output
  ## Injection attempt via stdin should be filtered out.
  output="$(printf '%s\n' '; echo HACKED' '$(echo HACKED)' '`echo HACKED`' | \
    pv_echo_command='printf "%s\n" "$percent"' \
    pv_wrapper_command='true' \
    /usr/libexec/msgcollector/pv_wrapper 2>/dev/null)" || true
  if printf '%s\n' "${output}" | grep "HACKED" &>/dev/null; then
    fail "pv_wrapper allowed injection through stdin"
  else
    pass "pv_wrapper blocks injection through stdin"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === alert icon allowlist tests ==="
## --------------------------------------------------------------------------

test_alert_icon_allowlist() {
  ## Verify the allowlist is present in the source code.
  if grep "allowed_icons.*Information.*Warning.*Critical" \
    usr/libexec/msgcollector/alert &>/dev/null; then
    pass "alert has icon allowlist"
  else
    fail "alert missing icon allowlist"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === Run all tests ==="
## --------------------------------------------------------------------------

test_check_valid_simple
test_check_valid_with_dashes
test_check_valid_with_underscores
test_check_reject_path_traversal
test_check_reject_slash
test_check_reject_empty
test_check_reject_spaces
test_check_reject_dots
test_check_reject_semicolon
test_check_reject_dollar
test_check_reject_backtick
test_check_reject_newline

test_is_whole_number_valid
test_is_whole_number_zero
test_is_whole_number_100
test_is_whole_number_reject_negative
test_is_whole_number_reject_float
test_is_whole_number_reject_alpha
test_is_whole_number_reject_empty
test_is_whole_number_reject_injection
test_is_whole_number_reject_spaces

test_alpha_numeric_valid
test_alpha_numeric_reject_slash
test_alpha_numeric_reject_empty

test_safe_filename_valid
test_safe_filename_reject_dotdot
test_safe_filename_reject_slash
test_safe_filename_reject_leading_dash

test_msgcollector_reject_bad_identifier
test_msgcollector_reject_empty_identifier
test_msgcollector_reject_bad_progressbaridx

test_msgprogress_reject_non_numeric_progress
test_msgprogress_reject_bad_identifier

test_pv_wrapper_filters_non_numeric
test_pv_wrapper_reject_injection

test_alert_icon_allowlist

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: =============================="
printf '%s\n' "$0: Results: ${PASS} passed, ${FAIL} failed"
printf '%s\n' "$0: =============================="

if [ "${FAIL}" != "0" ]; then
  printf '%s\n' ""
  printf '%s\n' "$0: Failures:"
  printf '%s\n' "${ERRORS}"
  exit 1
fi

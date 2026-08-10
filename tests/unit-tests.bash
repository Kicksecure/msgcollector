#!/bin/bash

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## Unit tests for msgcollector input validation and security.
##
## The tests below feed deliberately literal injection payloads ('$(whoami)',
## backtick and '; echo HACKED') to the validators to prove they are rejected,
## so the single-quoted non-expansions are intentional (SC2016) and a literal
## 'echo' inside a payload string is not a command (R-034).
# shellcheck disable=SC2016
## style-ok: allow-echo

set -o errexit
set -o nounset
set -o errtrace
set -o pipefail
shopt -s inherit_errexit
shopt -s shift_verbose

if ! [ "${CI:-}" = "true" ]; then
  printf '%s\n' "$0: These tests are only supposed to run on CI." >&2
  exit 1
fi

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
printf '%s\n' "$0: === msgcollector_check() function tests ==="
## --------------------------------------------------------------------------

## check() should accept valid alphanumeric identifiers.
test_check_valid_simple() {
  local result
  result=0
  msgcollector_check "systemcheck" || result=$?
  if [ "${result}" = "0" ]; then
    pass "check accepts 'systemcheck'"
  else
    fail "check rejects 'systemcheck'"
  fi
}

test_check_valid_with_dashes() {
  local result
  result=0
  msgcollector_check "2b3916d6-3b3f-4490-bc85-b97da494a55d" || result=$?
  if [ "${result}" = "0" ]; then
    pass "check accepts UUID with dashes"
  else
    fail "check rejects UUID with dashes"
  fi
}

test_check_valid_with_underscores() {
  local result
  result=0
  msgcollector_check "my_identifier_123" || result=$?
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
  (msgcollector_check "../../etc/passwd" 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects path traversal '../../etc/passwd'"
  else
    fail "check accepts path traversal '../../etc/passwd'"
  fi
}

test_check_reject_slash() {
  local result
  result=0
  (msgcollector_check "foo/bar" 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects slash 'foo/bar'"
  else
    fail "check accepts slash 'foo/bar'"
  fi
}

test_check_reject_empty() {
  local result
  result=0
  (msgcollector_check "" 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects empty string"
  else
    fail "check accepts empty string"
  fi
}

test_check_reject_spaces() {
  local result
  result=0
  (msgcollector_check "has spaces" 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects spaces"
  else
    fail "check accepts spaces"
  fi
}

test_check_reject_dots() {
  local result
  result=0
  (msgcollector_check "two..dots" 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects dots"
  else
    fail "check accepts dots"
  fi
}

test_check_reject_semicolon() {
  local result
  result=0
  (msgcollector_check "foo;bar" 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects semicolon injection"
  else
    fail "check accepts semicolon injection"
  fi
}

test_check_reject_dollar() {
  local result
  result=0
  (msgcollector_check '$(whoami)' 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects command substitution"
  else
    fail "check accepts command substitution"
  fi
}

test_check_reject_backtick() {
  local result
  result=0
  (msgcollector_check '`whoami`' 2>/dev/null) || result=$?
  if [ "${result}" != "0" ]; then
    pass "check rejects backtick injection"
  else
    fail "check accepts backtick injection"
  fi
}

test_check_reject_newline() {
  local result
  result=0
  (msgcollector_check $'line1\nline2' 2>/dev/null) || result=$?
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
printf '%s\n' "$0: === source-based: msgcollector pure functions (#33) ==="
## --------------------------------------------------------------------------

## msgcollector is source-able (main() + BASH_SOURCE guard), so its pure
## functions can be driven directly instead of shelling out through the CLI.
MSGCOLLECTOR_SCRIPT="/usr/libexec/msgcollector/msgcollector"

run_sourced() {
  ## Run $1 (shell code) in a clean child shell with msgcollector sourced:
  ## functions defined, main() NOT run. Color globals are forced empty so the
  ## color-disabled path is deterministic (and pretty_type_*'s bare ${green}
  ## references are defined). $2, if given, is exposed to the snippet as ${ARG}.
  MSGC="${MSGCOLLECTOR_SCRIPT}" ARG="${2:-}" bash -c '
    source "${MSGC}" </dev/null >/dev/null 2>&1 || true
    green="" yellow="" red="" reset="" bold=""
    '"$1"'
  ' 2>/dev/null
}

test_src_links_footnote() {
  local out
  out="$(run_sourced 'cli_links_to_footnotes "${ARG}"' \
    'See <a href="https://example.com">here</a>.')"
  if printf '%s' "${out}" | grep -Fq 'here[1]' \
     && printf '%s' "${out}" | grep -Fq 'Links:' \
     && printf '%s' "${out}" | grep -Fq '[1] https://example.com'; then
    pass "cli_links_to_footnotes: distinct link text becomes a footnote"
  else
    fail "cli_links_to_footnotes: footnote form wrong (got '${out}')"
  fi
}

test_src_links_bare_url() {
  local out
  out="$(run_sourced 'cli_links_to_footnotes "${ARG}"' \
    'Go <a href="https://example.com">https://example.com</a> now')"
  if printf '%s' "${out}" | grep -Fq 'https://example.com' \
     && ! printf '%s' "${out}" | grep -Fq '[1]'; then
    pass "cli_links_to_footnotes: link text equal to URL stays a bare URL"
  else
    fail "cli_links_to_footnotes: bare-URL case wrong (got '${out}')"
  fi
}

test_src_links_plain_unchanged() {
  local out
  out="$(run_sourced 'cli_links_to_footnotes "${ARG}"' 'no links here')"
  if [ "${out}" = 'no links here' ]; then
    pass "cli_links_to_footnotes: a message with no link is unchanged"
  else
    fail "cli_links_to_footnotes: plain message altered (got '${out}')"
  fi
}

test_src_translate_color_disabled() {
  local out
  out="$(run_sourced 'cli_translate_gui_markup "${ARG}"' \
    '<font color="green">X</font>')"
  if [ "${out}" = 'X' ]; then
    pass "cli_translate_gui_markup: color tags removed when color disabled"
  else
    fail "cli_translate_gui_markup: color-disabled output wrong (got '${out}')"
  fi
}

test_src_translate_br_newline() {
  local out
  out="$(run_sourced 'cli_translate_gui_markup "${ARG}"' 'A<br>B')"
  if [ "${out}" = $'A\nB' ]; then
    pass "cli_translate_gui_markup: <br> becomes a real newline"
  else
    fail "cli_translate_gui_markup: <br> not translated (got '${out}')"
  fi
}

test_src_pretty_type_cli() {
  local info_out error_out
  info_out="$(run_sourced 'pretty_type_cli info; printf "%s" "${p_type}"')"
  error_out="$(run_sourced 'pretty_type_cli error; printf "%s" "${p_type}"')"
  if [ "${info_out}" = 'INFO' ] && printf '%s' "${error_out}" | grep -Fq 'ERROR'; then
    pass "pretty_type_cli: info/error produce INFO/ERROR labels"
  else
    fail "pretty_type_cli: labels wrong (info='${info_out}' error='${error_out}')"
  fi
}

test_src_pretty_type_x() {
  ## pretty_type_x rewrites a <p>-prefixed message with a typed span; a message
  ## not starting with <p>, and an unknown type, are left unchanged.
  local info_out warn_out plain_out
  info_out="$(run_sourced 'message="<p>hello"; pretty_type_x info; printf "%s" "${message}"')"
  warn_out="$(run_sourced 'message="<p>hello"; pretty_type_x warning; printf "%s" "${message}"')"
  plain_out="$(run_sourced 'message="plain no p"; pretty_type_x error; printf "%s" "${message}"')"
  if printf '%s' "${info_out}" | grep -Fq 'INFO' \
     && printf '%s' "${warn_out}" | grep -Fq 'WARNING' \
     && [ "${plain_out}" = 'plain no p' ]; then
    pass "pretty_type_x: <p> messages get typed spans; non-<p> unchanged"
  else
    fail "pretty_type_x: wrong (info='${info_out}' warn='${warn_out}' plain='${plain_out}')"
  fi
}

test_src_translate_color_enabled() {
  ## With color enabled, <font color="..."> becomes the terminal color code.
  ## A plain sentinel stands in for the ANSI code: the str_replace path is the
  ## same, and it keeps the assertion free of escape bytes.
  local out
  out="$(run_sourced 'green="[[G]]"; reset="[[R]]"; cli_translate_gui_markup "${ARG}"' \
    '<font color="green">X</font>')"
  if [ "${out}" = '[[G]]X[[R]]' ]; then
    pass "cli_translate_gui_markup: color tags become the color codes when enabled"
  else
    fail "cli_translate_gui_markup: color-enabled output wrong (got '${out}')"
  fi
}

test_src_error_handler_unset_parentpid() {
  ## Regression: error_handler must not itself abort under nounset when
  ## parentpid is empty. ps_p_parentpid is only assigned when parentpid is a
  ## real PID; with the empty default it stays '', so the diagnostic block that
  ## prints ${ps_p_parentpid} must find it defined. On the buggy code the msg
  ## assembly aborts with 'ps_p_parentpid: unbound variable' before the
  ## 'No panic' banner is ever printed.
  local out
  out="$(MSGC="${MSGCOLLECTOR_SCRIPT}" bash -c '
    source "${MSGC}" </dev/null >/dev/null 2>&1 || true
    parentpid=""
    error_handler
  ' 2>&1 || true)"
  if printf '%s' "${out}" | grep -Fq 'No panic' \
     && ! printf '%s' "${out}" | grep -Fq 'unbound variable'; then
    pass "error_handler: empty parentpid does not trip nounset"
  else
    fail "error_handler: nounset abort on empty parentpid (got '${out}')"
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

test_src_links_footnote
test_src_links_bare_url
test_src_links_plain_unchanged
test_src_translate_color_disabled
test_src_translate_color_enabled
test_src_translate_br_newline
test_src_pretty_type_cli
test_src_pretty_type_x
test_src_error_handler_unset_parentpid

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

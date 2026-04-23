#!/bin/bash

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## Integration tests for msgcollector message collection pipeline.

set -o errexit
set -o nounset
set -o errtrace
set -o pipefail

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

## Determine the run directory the same way msgcollector does.
source /usr/libexec/msgcollector/msgcollector_shared
folder_init
## Now ${msgcollector_run_dir} is set (e.g., /run/user/<uid>/msgcollector or mktemp fallback).

MSGCOLLECTOR="/usr/libexec/msgcollector/msgcollector"

## --------------------------------------------------------------------------
printf '%s\n' "$0: === Message collection pipeline tests ==="
## --------------------------------------------------------------------------

test_collect_messagecli() {
  ${MSGCOLLECTOR} \
    --identifier "unittest" \
    --messagecli --typecli info --message "Hello CLI" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/unittest_messagecli"
  if [ -f "${file}" ]; then
    local content
    content="$(cat -- "${file}")"
    if printf '%s\n' "${content}" | grep "Hello CLI" &>/dev/null; then
      pass "messagecli: message file created with correct content"
    else
      fail "messagecli: message file content mismatch: '${content}'"
    fi
  else
    fail "messagecli: message file not created"
  fi
}

test_collect_messagecli_type() {
  ## Type file should be created.
  local file
  file="${msgcollector_run_dir}/unittest_typecli"
  if [ -f "${file}" ]; then
    local type_content
    type_content="$(cat -- "${file}")"
    if [ "${type_content}" = "info" ]; then
      pass "messagecli: type file has correct value 'info'"
    else
      fail "messagecli: type file has wrong value: '${type_content}'"
    fi
  else
    fail "messagecli: type file not created"
  fi
}

test_collect_messagex() {
  ${MSGCOLLECTOR} \
    --identifier "unittest" \
    --messagex --typex warning --message "<p>Hello GUI</p>" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/unittest_messagex"
  if [ -f "${file}" ]; then
    local content
    content="$(cat -- "${file}")"
    if printf '%s\n' "${content}" | grep "Hello GUI" &>/dev/null; then
      pass "messagex: message file created with HTML content"
    else
      fail "messagex: message file content mismatch: '${content}'"
    fi
  else
    fail "messagex: message file not created"
  fi
}

test_collect_messagex_type() {
  local file
  file="${msgcollector_run_dir}/unittest_typex"
  if [ -f "${file}" ]; then
    local type_content
    type_content="$(cat -- "${file}")"
    if [ "${type_content}" = "warning" ]; then
      pass "messagex: type file has correct value 'warning'"
    else
      fail "messagex: type file has wrong value: '${type_content}'"
    fi
  else
    fail "messagex: type file not created"
  fi
}

test_collect_titlex() {
  ${MSGCOLLECTOR} \
    --identifier "unittest" \
    --titlex "Test Title" \
    --messagex --typex info --message "<p>test</p>" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/unittest_titlex"
  if [ -f "${file}" ]; then
    pass "titlex: title file created"
  else
    fail "titlex: title file not created"
  fi
}

test_collect_icon() {
  ${MSGCOLLECTOR} \
    --identifier "unittest" \
    --icon "/usr/share/icons/test.png" \
    --messagex --typex info --message "<p>test</p>" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/unittest_icon"
  if [ -f "${file}" ]; then
    pass "icon: icon file created"
  else
    fail "icon: icon file not created"
  fi
}

test_collect_done_marker() {
  ${MSGCOLLECTOR} \
    --identifier "unittest" \
    --done \
    --messagecli --typecli info --message "Done test" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/unittest_messagecli_done"
  if [ -f "${file}" ]; then
    pass "done: done marker file created"
  else
    fail "done: done marker file not created"
  fi
}

test_collect_passivepopupqueuex() {
  ${MSGCOLLECTOR} \
    --identifier "unittest" \
    --passivepopupqueuex \
    --passivepopupqueuextitle "Popup Title" \
    --message "Popup message" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/unittest_passivepopupqueuex"
  if [ -f "${file}" ]; then
    pass "passivepopupqueuex: message file created"
  else
    fail "passivepopupqueuex: message file not created"
  fi
  local title_file
  title_file="${msgcollector_run_dir}/unittest_passivepopupqueuextitle"
  if [ -f "${title_file}" ]; then
    pass "passivepopupqueuex: title file created"
  else
    fail "passivepopupqueuex: title file not created"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === Type escalation tests ==="
## --------------------------------------------------------------------------

test_type_escalation_info_to_warning() {
  ## Clean state.
  ${MSGCOLLECTOR} --identifier "escalation" --forget 2>/dev/null || true
  ## First message: info.
  ${MSGCOLLECTOR} \
    --identifier "escalation" \
    --messagecli --typecli info --message "info msg" 2>/dev/null || true
  ## Second message: warning (should upgrade).
  ${MSGCOLLECTOR} \
    --identifier "escalation" \
    --messagecli --typecli warning --message "warn msg" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/escalation_typecli"
  if [ -f "${file}" ]; then
    local type_content
    type_content="$(cat -- "${file}")"
    if [ "${type_content}" = "warning" ]; then
      pass "type escalation: info -> warning works"
    else
      fail "type escalation: expected 'warning', got '${type_content}'"
    fi
  else
    fail "type escalation: type file not created"
  fi
}

test_type_escalation_warning_to_error() {
  ## Continue from previous state (warning).
  ${MSGCOLLECTOR} \
    --identifier "escalation" \
    --messagecli --typecli error --message "error msg" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/escalation_typecli"
  if [ -f "${file}" ]; then
    local type_content
    type_content="$(cat -- "${file}")"
    if [ "${type_content}" = "error" ]; then
      pass "type escalation: warning -> error works"
    else
      fail "type escalation: expected 'error', got '${type_content}'"
    fi
  else
    fail "type escalation: type file not created"
  fi
}

test_type_no_downgrade() {
  ## Error should not downgrade to info.
  ${MSGCOLLECTOR} \
    --identifier "escalation" \
    --messagecli --typecli info --message "info again" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/escalation_typecli"
  if [ -f "${file}" ]; then
    local type_content
    type_content="$(cat -- "${file}")"
    if [ "${type_content}" = "error" ]; then
      pass "type escalation: error does not downgrade to info"
    else
      fail "type escalation: expected 'error' (no downgrade), got '${type_content}'"
    fi
  else
    fail "type escalation: type file not created"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === Forget (cleanup) tests ==="
## --------------------------------------------------------------------------

test_forget() {
  ## Create some files.
  ${MSGCOLLECTOR} \
    --identifier "forgettest" \
    --messagecli --typecli info --message "will be forgotten" 2>/dev/null || true
  ## Verify file exists.
  local file
  file="${msgcollector_run_dir}/forgettest_messagecli"
  if [ ! -f "${file}" ]; then
    fail "forget: prerequisite file not created"
    return 0
  fi
  ## Forget.
  ${MSGCOLLECTOR} --identifier "forgettest" --forget 2>/dev/null || true
  if [ ! -f "${file}" ]; then
    pass "forget: messagecli file cleaned up"
  else
    fail "forget: messagecli file still exists after forget"
  fi
}

test_forget_type() {
  local file
  file="${msgcollector_run_dir}/forgettest_typecli"
  if [ ! -f "${file}" ]; then
    pass "forget: typecli file cleaned up"
  else
    fail "forget: typecli file still exists after forget"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === Status query tests ==="
## --------------------------------------------------------------------------

test_status_exists() {
  ## Create a message.
  ${MSGCOLLECTOR} \
    --identifier "statustest" \
    --messagecli --typecli info --message "status test" 2>/dev/null || true
  ## Query status.
  local result
  result=0
  ${MSGCOLLECTOR} \
    --identifier "statustest" \
    --status --messagecli 2>/dev/null || result=$?
  if [ "${result}" = "0" ]; then
    pass "status: returns 0 for existing message"
  else
    fail "status: returns ${result} for existing message"
  fi
}

test_status_not_exists() {
  local result
  result=0
  ${MSGCOLLECTOR} \
    --identifier "nonexistent" \
    --status --messagecli 2>/dev/null || result=$?
  if [ "${result}" != "0" ]; then
    pass "status: returns non-zero for non-existing message"
  else
    fail "status: returns 0 for non-existing message"
  fi
}

test_status_typex() {
  ${MSGCOLLECTOR} \
    --identifier "statustest" \
    --messagex --typex error --message "<p>error</p>" 2>/dev/null || true
  local type_output
  type_output="$(${MSGCOLLECTOR} \
    --identifier "statustest" \
    --status --typexstatus 2>/dev/null)" || true
  if [ "${type_output}" = "error" ]; then
    pass "status --typexstatus: returns 'error'"
  else
    fail "status --typexstatus: expected 'error', got '${type_output}'"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === waitmessagecli tests ==="
## --------------------------------------------------------------------------

test_waitmessagecli() {
  ${MSGCOLLECTOR} --identifier "waitcli" --forget 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "waitcli" \
    --waitmessagecli --typecli info --message "Please wait..." 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/waitcli_waitmessagecli"
  if [ -f "${file}" ]; then
    local content
    content="$(cat -- "${file}")"
    if printf '%s\n' "${content}" | grep "Please wait" &>/dev/null; then
      pass "waitmessagecli: message file created with content"
    else
      fail "waitmessagecli: content mismatch: '${content}'"
    fi
  else
    fail "waitmessagecli: message file not created"
  fi
}

test_waitmessagecli_done() {
  ${MSGCOLLECTOR} \
    --identifier "waitcli" \
    --done \
    --waitmessagecli --typecli info --message "Wait done" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/waitcli_waitmessagecli_done"
  if [ -f "${file}" ]; then
    pass "waitmessagecli: done marker created"
  else
    fail "waitmessagecli: done marker not created"
  fi
}

test_forgetwaitcli() {
  ## forgetwaitcli should only clean waitmessagecli files, not others.
  ${MSGCOLLECTOR} \
    --identifier "waitcli" \
    --messagecli --typecli info --message "regular msg" 2>/dev/null || true
  ${MSGCOLLECTOR} --identifier "waitcli" --forgetwaitcli 2>/dev/null || true
  local wait_file
  wait_file="${msgcollector_run_dir}/waitcli_waitmessagecli"
  local regular_file
  regular_file="${msgcollector_run_dir}/waitcli_messagecli"
  if [ ! -f "${wait_file}" ]; then
    pass "forgetwaitcli: waitmessagecli file cleaned"
  else
    fail "forgetwaitcli: waitmessagecli file still exists"
  fi
  if [ -f "${regular_file}" ]; then
    pass "forgetwaitcli: regular messagecli file preserved"
  else
    fail "forgetwaitcli: regular messagecli file was deleted (should be preserved)"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === onlyecho mode tests ==="
## --------------------------------------------------------------------------

test_onlyecho_no_file() {
  ${MSGCOLLECTOR} --identifier "echotest" --forget 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "echotest" \
    --onlyecho \
    --messagecli --typecli info --message "echo only" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/echotest_messagecli"
  if [ ! -f "${file}" ]; then
    pass "onlyecho: no message file created"
  else
    fail "onlyecho: message file was created (should not be)"
    safe-rm --force -- "${file}"
  fi
}

test_onlyecho_no_type_file() {
  local file
  file="${msgcollector_run_dir}/echotest_typecli"
  if [ ! -f "${file}" ]; then
    pass "onlyecho: no type file created"
  else
    fail "onlyecho: type file was created (should not be)"
    safe-rm --force -- "${file}"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === Message append tests ==="
## --------------------------------------------------------------------------

test_append_multiple_messages() {
  ${MSGCOLLECTOR} --identifier "appendtest" --forget 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "appendtest" \
    --messagecli --typecli info --message "first" 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "appendtest" \
    --messagecli --typecli info --message "second" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/appendtest_messagecli"
  if [ -f "${file}" ]; then
    local content
    content="$(cat -- "${file}")"
    if printf '%s\n' "${content}" | grep "first" &>/dev/null && \
       printf '%s\n' "${content}" | grep "second" &>/dev/null; then
      pass "append: both messages present in file"
    else
      fail "append: expected both messages, got: '${content}'"
    fi
  else
    fail "append: message file not created"
  fi
}

test_append_messagex_multiple() {
  ${MSGCOLLECTOR} --identifier "appendtest" --forget 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "appendtest" \
    --messagex --typex info --message "<p>first html</p>" 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "appendtest" \
    --messagex --typex info --message "<p>second html</p>" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/appendtest_messagex"
  if [ -f "${file}" ]; then
    local content
    content="$(cat -- "${file}")"
    if printf '%s\n' "${content}" | grep "first html" &>/dev/null && \
       printf '%s\n' "${content}" | grep "second html" &>/dev/null; then
      pass "append: both HTML messages present in messagex file"
    else
      fail "append: expected both HTML messages, got: '${content}'"
    fi
  else
    fail "append: messagex file not created"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === parentpid and parenttty tests ==="
## --------------------------------------------------------------------------

test_parentpid_default() {
  ## When no --parentpid is given, it defaults to "0000000000".
  ## This is not written to a file in the identifier-only path, so we test
  ## that msgcollector still works without --parentpid.
  ${MSGCOLLECTOR} --identifier "pidtest" --forget 2>/dev/null || true
  local result
  result=0
  ${MSGCOLLECTOR} \
    --identifier "pidtest" \
    --messagecli --typecli info --message "no parentpid" 2>/dev/null || result=$?
  if [ "${result}" = "0" ]; then
    pass "parentpid: works without --parentpid"
  else
    fail "parentpid: fails without --parentpid (exit ${result})"
  fi
}

test_parenttty() {
  ${MSGCOLLECTOR} --identifier "ttytest" --forget 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "ttytest" \
    --parenttty "/dev/tty1" \
    --messagecli --typecli info --message "tty test" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/ttytest_parenttty"
  if [ -f "${file}" ]; then
    local content
    content="$(cat -- "${file}")"
    if [ "${content}" = "/dev/tty1" ]; then
      pass "parenttty: file contains correct TTY path"
    else
      fail "parenttty: expected '/dev/tty1', got '${content}'"
    fi
  else
    fail "parenttty: parenttty file not created"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === forceactive flag tests ==="
## --------------------------------------------------------------------------

test_forceactive() {
  ${MSGCOLLECTOR} --identifier "forcetest" --forget 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "forcetest" \
    --forceactive \
    --messagex --typex info --message "<p>force</p>" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/forcetest_forceactive"
  if [ -f "${file}" ]; then
    pass "forceactive: flag file created"
  else
    fail "forceactive: flag file not created"
  fi
}

test_forceactive_cleaned_by_forget() {
  ${MSGCOLLECTOR} --identifier "forcetest" --forget 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/forcetest_forceactive"
  if [ ! -f "${file}" ]; then
    pass "forceactive: flag file cleaned by forget"
  else
    fail "forceactive: flag file not cleaned by forget"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === Type escalation for typex (GUI) ==="
## --------------------------------------------------------------------------

test_typex_escalation_info_to_error() {
  ${MSGCOLLECTOR} --identifier "typexesc" --forget 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "typexesc" \
    --messagex --typex info --message "<p>info</p>" 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "typexesc" \
    --messagex --typex error --message "<p>error</p>" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/typexesc_typex"
  if [ -f "${file}" ]; then
    local type_content
    type_content="$(cat -- "${file}")"
    if [ "${type_content}" = "error" ]; then
      pass "typex escalation: info -> error works"
    else
      fail "typex escalation: expected 'error', got '${type_content}'"
    fi
  else
    fail "typex escalation: typex file not created"
  fi
}

test_typex_no_downgrade() {
  ${MSGCOLLECTOR} \
    --identifier "typexesc" \
    --messagex --typex info --message "<p>info again</p>" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/typexesc_typex"
  if [ -f "${file}" ]; then
    local type_content
    type_content="$(cat -- "${file}")"
    if [ "${type_content}" = "error" ]; then
      pass "typex escalation: error does not downgrade to info"
    else
      fail "typex escalation: expected 'error' (no downgrade), got '${type_content}'"
    fi
  else
    fail "typex escalation: typex file not created"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === Status query: --typeclistatus ==="
## --------------------------------------------------------------------------

test_status_typecli() {
  ${MSGCOLLECTOR} --identifier "clipstattest" --forget 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "clipstattest" \
    --messagecli --typecli warning --message "warn msg" 2>/dev/null || true
  local type_output
  type_output="$(${MSGCOLLECTOR} \
    --identifier "clipstattest" \
    --status --typeclistatus 2>/dev/null)" || true
  if [ "${type_output}" = "warning" ]; then
    pass "status --typeclistatus: returns 'warning'"
  else
    fail "status --typeclistatus: expected 'warning', got '${type_output}'"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === Passivepopupqueuex with done marker ==="
## --------------------------------------------------------------------------

test_passivepopupqueuex_done() {
  ${MSGCOLLECTOR} --identifier "popupdone" --forget 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "popupdone" \
    --done \
    --passivepopupqueuex \
    --passivepopupqueuextitle "Popup" \
    --message "done popup" 2>/dev/null || true
  local done_file
  done_file="${msgcollector_run_dir}/popupdone_passivepopupqueuex_done"
  if [ -f "${done_file}" ]; then
    pass "passivepopupqueuex: done marker file created"
  else
    fail "passivepopupqueuex: done marker file not created"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === Forget cleans all file types ==="
## --------------------------------------------------------------------------

test_forget_comprehensive() {
  ${MSGCOLLECTOR} --identifier "forgetall" --forget 2>/dev/null || true
  ## Create various file types.
  ${MSGCOLLECTOR} \
    --identifier "forgetall" \
    --icon "/test/icon.png" \
    --titlex "Title" \
    --forceactive \
    --parenttty "/dev/tty1" \
    --done \
    --messagex --typex error --message "<p>everything</p>" 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "forgetall" \
    --messagecli --typecli error --message "everything cli" 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "forgetall" \
    --passivepopupqueuex \
    --passivepopupqueuextitle "PassiveTitle" \
    --done \
    --message "passive msg" 2>/dev/null || true
  ## Forget.
  ${MSGCOLLECTOR} --identifier "forgetall" --forget 2>/dev/null || true
  ## Check that key files are gone.
  local all_clean
  all_clean=true
  local suffix
  for suffix in icon titlex typex typecli messagex messagecli \
                messagex_done messagecli_done forceactive parenttty \
                passivepopupqueuex passivepopupqueuex_done passivepopupqueuextitle; do
    if [ -f "${msgcollector_run_dir}/forgetall_${suffix}" ]; then
      fail "forget comprehensive: file forgetall_${suffix} still exists"
      all_clean=false
    fi
  done
  if [ "${all_clean}" = "true" ]; then
    pass "forget comprehensive: all files cleaned"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === pretty_type_x HTML formatting ==="
## --------------------------------------------------------------------------

test_pretty_type_x_info() {
  ${MSGCOLLECTOR} --identifier "prettytest" --forget 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "prettytest" \
    --messagex --typex info --message "<p>info message</p>" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/prettytest_messagex"
  if [ -f "${file}" ]; then
    local content
    content="$(cat -- "${file}")"
    if printf '%s\n' "${content}" | grep "color:#008000.*INFO" &>/dev/null; then
      pass "pretty_type_x: info type has green INFO prefix"
    else
      fail "pretty_type_x: info type missing green INFO prefix"
    fi
  else
    fail "pretty_type_x: messagex file not created"
  fi
}

test_pretty_type_x_error() {
  ${MSGCOLLECTOR} --identifier "prettytest" --forget 2>/dev/null || true
  ${MSGCOLLECTOR} \
    --identifier "prettytest" \
    --messagex --typex error --message "<p>error message</p>" 2>/dev/null || true
  local file
  file="${msgcollector_run_dir}/prettytest_messagex"
  if [ -f "${file}" ]; then
    local content
    content="$(cat -- "${file}")"
    if printf '%s\n' "${content}" | grep "ERROR" &>/dev/null; then
      pass "pretty_type_x: error type has ERROR prefix"
    else
      fail "pretty_type_x: error type missing ERROR prefix"
    fi
  else
    fail "pretty_type_x: messagex file not created"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === br_add (Python line-break conversion) ==="
## --------------------------------------------------------------------------

test_br_add() {
  if [ -x /usr/libexec/msgcollector/br_add ]; then
    local output
    output="$(/usr/libexec/msgcollector/br_add $'line1\nline2\nline3')"
    if printf '%s\n' "${output}" | grep '<br />' &>/dev/null; then
      pass "br_add: inserts <br /> tags"
    else
      fail "br_add: expected <br /> tags, got: '${output}'"
    fi
  else
    fail "br_add: missing"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === Python script argument parsing ==="
## --------------------------------------------------------------------------

test_msgdispatcher_dispatch_x_argparse() {
  ## Test that the argument parser rejects invalid message types.
  local result
  result=0
  /usr/libexec/msgcollector/msgdispatcher_dispatch_x "invalid_type" "title" "msg" "0" 2>/dev/null || result=$?
  if [ "${result}" != "0" ]; then
    pass "msgdispatcher_dispatch_x: rejects invalid message_type"
  else
    fail "msgdispatcher_dispatch_x: accepts invalid message_type"
  fi
}

test_generic_gui_message_argparse() {
  local result
  result=0
  /usr/libexec/msgcollector/generic_gui_message "invalid_type" "title" "msg" "" "ok" 2>/dev/null || result=$?
  if [ "${result}" != "0" ]; then
    pass "generic_gui_message: rejects invalid message_type"
  else
    fail "generic_gui_message: accepts invalid message_type"
  fi
}

test_generic_gui_message_argparse_button() {
  local result
  result=0
  /usr/libexec/msgcollector/generic_gui_message "info" "title" "msg" "" "invalid_button" 2>/dev/null || result=$?
  if [ "${result}" != "0" ]; then
    pass "generic_gui_message: rejects invalid button_type"
  else
    fail "generic_gui_message: accepts invalid button_type"
  fi
}

test_one_time_popup_argparse_missing() {
  local result
  result=0
  /usr/libexec/msgcollector/one-time-popup 2>/dev/null || result=$?
  if [ "${result}" != "0" ]; then
    pass "one-time-popup: exits non-zero with missing args"
  else
    fail "one-time-popup: exits zero with missing args"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === msgprogress with valid progress values ==="
## --------------------------------------------------------------------------

test_msgprogress_valid_progress() {
  ## msgprogress should accept valid numeric progress and create a progresstxt file.
  local result
  result=0
  /usr/libexec/msgcollector/msgprogress \
    --identifier "progtest" \
    --progressbaridx "testidx" \
    --progress "50" 2>/dev/null || result=$?
  if [ "${result}" = "0" ]; then
    pass "msgprogress: accepts valid progress value '50'"
  else
    fail "msgprogress: rejects valid progress value '50' (exit ${result})"
  fi
  local txt_file
  txt_file="${msgcollector_run_dir}/progtest_testidx_progresstxt"
  if [ -f "${txt_file}" ]; then
    local content
    content="$(cat -- "${txt_file}")"
    if [ "${content}" = "50" ]; then
      pass "msgprogress: progresstxt file contains '50'"
    else
      fail "msgprogress: progresstxt expected '50', got '${content}'"
    fi
  else
    fail "msgprogress: progresstxt file not created"
  fi
}

test_msgprogress_progress_zero() {
  local result
  result=0
  /usr/libexec/msgcollector/msgprogress \
    --identifier "progtest" \
    --progressbaridx "testidx2" \
    --progress "0" 2>/dev/null || result=$?
  if [ "${result}" = "0" ]; then
    pass "msgprogress: accepts progress value '0'"
  else
    fail "msgprogress: rejects progress value '0' (exit ${result})"
  fi
}

test_msgprogress_progress_100() {
  local result
  result=0
  /usr/libexec/msgcollector/msgprogress \
    --identifier "progtest" \
    --progressbaridx "testidx3" \
    --progress "100" 2>/dev/null || result=$?
  if [ "${result}" = "0" ]; then
    pass "msgprogress: accepts progress value '100'"
  else
    fail "msgprogress: rejects progress value '100' (exit ${result})"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === pv_wrapper normal operation ==="
## --------------------------------------------------------------------------

test_pv_wrapper_passthrough() {
  ## Valid numeric values should be passed through to $percent and eval'd commands.
  local output
  output="$(printf '%s\n' "10" "20" "30" | \
    pv_echo_command='printf "progress=%s\n" "$percent"' \
    pv_wrapper_command='true' \
    /usr/libexec/msgcollector/pv_wrapper 2>/dev/null)"
  if printf '%s\n' "${output}" | grep "progress=10" &>/dev/null && \
     printf '%s\n' "${output}" | grep "progress=20" &>/dev/null && \
     printf '%s\n' "${output}" | grep "progress=30" &>/dev/null; then
    pass "pv_wrapper: passes through numeric values correctly"
  else
    fail "pv_wrapper: output mismatch, got: '${output}'"
  fi
}

test_pv_wrapper_single_value() {
  local output
  output="$(printf '%s\n' "100" | \
    pv_echo_command='printf "%s\n" "$percent"' \
    pv_wrapper_command='true' \
    /usr/libexec/msgcollector/pv_wrapper 2>/dev/null)"
  if [ "${output}" = "100" ]; then
    pass "pv_wrapper: handles single value '100'"
  else
    fail "pv_wrapper: expected '100', got '${output}'"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === Unknown option handling ==="
## --------------------------------------------------------------------------

test_unknown_option() {
  local result
  result=0
  ${MSGCOLLECTOR} \
    --identifier "test" \
    --nonexistentoption 2>/dev/null || result=$?
  if [ "${result}" != "0" ]; then
    pass "msgcollector: exits non-zero on unknown option"
  else
    fail "msgcollector: exits zero on unknown option"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === Security: path traversal blocked end-to-end ==="
## --------------------------------------------------------------------------

test_no_file_outside_run_dir() {
  local evil_path
  evil_path="/tmp/msgcollector-test-evil-$$"
  safe-rm --force -- "${evil_path}" 2>/dev/null || true
  ## Attempt path traversal. Should fail validation.
  ${MSGCOLLECTOR} \
    --identifier "../../../../../../tmp/msgcollector-test-evil-$$" \
    --messagecli --typecli info --message "evil" 2>/dev/null || true
  if [ -f "${evil_path}" ] || [ -f "${evil_path}_messagecli" ]; then
    safe-rm --force -- "${evil_path}" "${evil_path}_messagecli" 2>/dev/null || true
    fail "path traversal: file created outside run directory!"
  else
    pass "path traversal: no file created outside run directory"
  fi
}

## --------------------------------------------------------------------------
printf '%s\n' ""
printf '%s\n' "$0: === Run all tests ==="
## --------------------------------------------------------------------------

test_collect_messagecli
test_collect_messagecli_type
test_collect_messagex
test_collect_messagex_type
test_collect_titlex
test_collect_icon
test_collect_done_marker
test_collect_passivepopupqueuex

test_type_escalation_info_to_warning
test_type_escalation_warning_to_error
test_type_no_downgrade

test_forget
test_forget_type

test_status_exists
test_status_not_exists
test_status_typex

test_waitmessagecli
test_waitmessagecli_done
test_forgetwaitcli

test_onlyecho_no_file
test_onlyecho_no_type_file

test_append_multiple_messages
test_append_messagex_multiple

test_parentpid_default
test_parenttty

test_forceactive
test_forceactive_cleaned_by_forget

test_typex_escalation_info_to_error
test_typex_no_downgrade

test_status_typecli

test_passivepopupqueuex_done

test_forget_comprehensive

test_pretty_type_x_info
test_pretty_type_x_error

test_br_add

test_msgdispatcher_dispatch_x_argparse
test_generic_gui_message_argparse
test_generic_gui_message_argparse_button
test_one_time_popup_argparse_missing

test_msgprogress_valid_progress
test_msgprogress_progress_zero
test_msgprogress_progress_100

test_pv_wrapper_passthrough
test_pv_wrapper_single_value

test_unknown_option

test_no_file_outside_run_dir

## Clean up test identifiers.
for id in unittest escalation statustest waitcli echotest appendtest \
          pidtest ttytest forcetest typexesc clipstattest popupdone \
          forgetall prettytest progtest; do
  ${MSGCOLLECTOR} --identifier "${id}" --forget 2>/dev/null || true
done

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

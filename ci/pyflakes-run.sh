#!/bin/bash

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## AI-Assisted

## CI helper: run pyflakes across the project's installable Python
## scripts under usr/libexec/msgcollector/ (the <name>.py files).

set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
shopt -s inherit_errexit
shopt -s shift_verbose

## Refuse outside CI unless ALLOW_LOCAL=true is set explicitly (matches
## derivative-maker/ci/lint-*), so the sanctioned local runner can override.
if [ "${CI:-}" != "true" ] && [ "${ALLOW_LOCAL:-}" != "true" ]; then
   printf '%s\n' \
      'error: run under CI=true, or set ALLOW_LOCAL=true to run locally.' >&2
   exit 1
fi

readonly files=(usr/libexec/msgcollector/*.py)

exit_code=0
for file_name in "${files[@]}"; do
   printf '%s\n' "Checking: ${file_name}"
   pyflakes "${file_name}" || exit_code=1
done

exit "${exit_code}"

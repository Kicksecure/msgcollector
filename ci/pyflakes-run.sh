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

## TODO: Should ALLOW_LOCAL also be checked here?
if [ "${CI:-}" != "true" ]; then
   printf '%s\n' \
      'error: this script must run with CI=true (GitHub Actions or equivalent).' >&2
   exit 1
fi

readonly files=(usr/libexec/msgcollector/*.py)

exit_code=0
for file_name in "${files[@]}"; do
   printf '%s\n' "Checking: ${file_name}"
   pyflakes "${file_name}" || exit_code=1
done

exit "${exit_code}"

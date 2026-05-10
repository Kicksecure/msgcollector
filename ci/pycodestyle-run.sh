#!/bin/bash

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## AI-Assisted

## CI helper: run pycodestyle across the project's installable
## Python scripts. Mirrors the file list in pyflakes-run.sh.
##
## Ignored checks:
## - E501: project uses long descriptive argparse help strings.
## - W503/W504: conflicting rules for line breaks around operators.
## - E266: project-wide convention to use '##' for block comments
##   in both bash and Python (all 18 usr/libexec/msgcollector/
##   files use '##').

set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
shopt -s inherit_errexit
shopt -s shift_verbose

if [ "${CI:-}" != "true" ]; then
   printf '%s\n' \
      'error: this script must run with CI=true (GitHub Actions or equivalent).' >&2
   exit 1
fi

readonly files=(
   usr/libexec/msgcollector/alert
   usr/libexec/msgcollector/generic_gui_message
   usr/libexec/msgcollector/msgdispatcher_dispatch_x
   usr/libexec/msgcollector/one-time-popup
   usr/libexec/msgcollector/tb_updater_gui
   usr/libexec/msgcollector/br_add
)

exit_code=0
for file in "${files[@]}"; do
   printf '%s\n' "Checking: ${file}"
   pycodestyle --max-line-length=120 \
      --ignore=E501,W503,W504,E266 \
      -- "${file}" || exit_code=1
done

exit "${exit_code}"

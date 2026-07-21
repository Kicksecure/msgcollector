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
   pycodestyle --max-line-length=120 \
      --ignore=E501,W503,W504,E266 \
      -- "${file_name}" || exit_code=1
done

exit "${exit_code}"

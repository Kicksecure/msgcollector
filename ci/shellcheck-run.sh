#!/bin/bash

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## AI-Assisted

## CI helper: run shellcheck across the project's bash and sh
## scripts. Discovers shell scripts by shebang (the source tree
## ships Debian libexec-style executables with no extension), not
## by file extension.
##
## Exclusions:
## - SC1091/SC1090: external sourced files not followed.
## - SC2034: variables consumed by sourcing libs via indirection
##   (e.g. check_is_alpha_numeric reads ${!varname}).
## - SC2154: variables set by sourced helper libraries
##   (strings.bsh, msgcollector_shared, ...).
## - SC2086: intentional word-splitting in pv_wrapper eval and a
##   handful of callers that export multi-word commands.

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

exit_code=0
while IFS= read -r -d '' file; do
   read -r first_line < "${file}" || continue
   case "${first_line}" in
      *'/bin/bash'* | *'/bin/sh'*)
         printf '%s\n' "Checking: ${file}"
         shellcheck --shell=bash \
            --exclude=SC1091,SC1090,SC2034,SC2154,SC2086 \
            --severity=warning \
            -- "${file}" || exit_code=1
         ;;
   esac
done < <(find usr/libexec/msgcollector etc/profile.d -type f -print0 2>/dev/null)

exit "${exit_code}"

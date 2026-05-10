#!/bin/bash

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## AI-Assisted

## Pre-scan source-tree prep for tools that discover Python sources by
## the '.py' extension (CodeQL Python extractor, bandit, etc.).
##
## msgcollector's installable Python scripts live at
## usr/libexec/msgcollector/ with no extension (Debian convention for
## libexec). Neither CodeQL nor bandit will find them as-is.
##
## Walk the tracked file list, identify shebang-declared Python
## scripts, and create same-directory '<name>.py' symlinks so static
## analyzers see them under their conventional name. Symlinks use
## basename targets so they resolve regardless of where the tree is
## later moved.

set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
shopt -s inherit_errexit
shopt -s shift_verbose

repo_root="$(git rev-parse --show-toplevel)"
cd -- "${repo_root}"

linked=0
skipped=0
while IFS= read -r script; do
  ## Skip files that already have an extension.
  case "${script}" in
    *.*) continue ;;
  esac

  ## Read first line; bail if it isn't a python shebang.
  read -r first_line < "${script}" || continue
  case "${first_line}" in
    '#!'*python*) ;;
    *) continue ;;
  esac

  link="${script}.py"
  if [ -e "${link}" ] && [ ! -L "${link}" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  target="$(basename -- "${script}")"
  ln -s -n -f -- "${target}" "${link}"
  linked=$((linked + 1))
done < <(git ls-files)

printf '%s\n' "python-prepare: linked=${linked} skipped=${skipped}"

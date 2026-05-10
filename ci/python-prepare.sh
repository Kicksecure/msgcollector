#!/bin/bash

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## AI-Assisted

## Pre-scan source-tree prep for tools that discover Python sources by
## the '.py' extension (CodeQL Python extractor, bandit, etc.).
##
## msgcollector's installable Python scripts live at
## usr/libexec/msgcollector/ with no extension (Debian convention for
## libexec). Walk the tracked file list, identify shebang-declared
## Python scripts, and create same-directory '<name>.py' symlinks so
## static analyzers see them under their conventional name. Symlinks
## use basename targets so they resolve regardless of where the tree
## is later moved.

set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
shopt -s inherit_errexit
shopt -s shift_verbose

cd -- "$(git rev-parse --show-toplevel)"

linked=0
while IFS= read -r script; do
  ## Skip already-extensioned files (the .py symlinks created on a
  ## prior run match the shebang grep too).
  case "${script}" in
    *.*)
      continue
      ;;
  esac
  link="${script}.py"
  if [ -e "${link}" ] && [ ! -L "${link}" ]; then
    continue
  fi
  ln --symbolic --no-dereference --force -- \
    "$(basename -- "${script}")" "${link}"
  linked=$((linked + 1))
done < <(git grep -lE '^#!.*python' || true)

printf '%s\n' "python-prepare: linked=${linked}"

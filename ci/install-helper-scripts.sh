#!/bin/bash

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## AI-Assisted

## CI helper: install helper-scripts directly via cp, bypassing
## genmkfile to keep build-time dependencies minimal. The
## msgcollector test jobs only need helper-scripts' runtime libs
## and a handful of bin tools; the full genmkfile flow is heavier
## than necessary here.
##
## Resolves the clone source from GITHUB_REPOSITORY_OWNER (set by
## the GitHub Actions runner) - so the script clones
## org-ai-assisted/helper-scripts when run from
## org-ai-assisted/msgcollector, Kicksecure/helper-scripts when run
## from Kicksecure/msgcollector, etc. Hard error if the owner does
## not host its own helper-scripts fork - no implicit upstream
## fallback (an org choosing to host its own CI must explicitly
## fork helper-scripts; a silent cross-org clone would be a
## supply-chain footgun).

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

if [ -z "${GITHUB_REPOSITORY_OWNER:-}" ]; then
   printf '%s\n' \
      'error: GITHUB_REPOSITORY_OWNER is not set (expected GitHub Actions runner env).' >&2
   exit 1
fi

readonly clone_dir='/tmp/helper-scripts'
readonly upstream_url="https://github.com/${GITHUB_REPOSITORY_OWNER}/helper-scripts.git"

git clone --depth=1 --no-tags --branch=master -- "${upstream_url}" "${clone_dir}"

sudo --non-interactive cp --recursive --no-target-directory -- \
   "${clone_dir}/usr/libexec/helper-scripts" /usr/libexec/helper-scripts
sudo --non-interactive cp --recursive -- \
   "${clone_dir}/usr/lib/python3/dist-packages/." \
   /usr/lib/python3/dist-packages/

for tool in stecho stcat unicode-show sanitize-string strip-markup; do
   src="${clone_dir}/usr/bin/${tool}"
   if [ -f "${src}" ]; then
      sudo --non-interactive cp -- "${src}" "/usr/bin/${tool}"
   fi
done

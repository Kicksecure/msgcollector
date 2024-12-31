#!/bin/sh

## Copyright (C) 2012 - 2025 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## /etc/profile.d/40_msgdispatcher.sh

if [ ! "$XDG_SESSION_TYPE" = "tty" ]; then
   true "$0: INFO: Skip because this is not running in tty."
   return 0
   exit 0
fi

## Do this only in /dev/tty1.
if [ ! "$(tty)" = "/dev/tty1" ]; then
   true "$0: INFO: Skip, because not running in /dev/tty1."
   return 0
   exit 0
fi

true "$0: INFO: Continue, because running in /dev/tty1."

## Running in /dev/tty1.
/usr/libexec/msgcollector/msgdispatcher_profile_d

## End of /etc/profile.d/40_msgdispatcher.sh

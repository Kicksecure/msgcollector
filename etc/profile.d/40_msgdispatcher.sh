#!/bin/bash

## Copyright (C) 2012 - 2021 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## /etc/profile.d/40_msgdispatcher.sh

if [ ! "$(tty)" = "/dev/tty1" ]; then
   return 0
else
   /usr/libexec/msgcollector/msgdispatcher_profile_d
fi

## End of /etc/profile.d/40_msgdispatcher.sh

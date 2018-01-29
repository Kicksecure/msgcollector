#!/bin/bash

## Copyright (C) 2012 - 2018 Patrick Schleizer <adrelanos@riseup.net>
## See the file COPYING for copying conditions.

## /etc/profile.d/40_msgdispatcher.sh

if [ ! "$(tty)" = "/dev/tty1" ]; then
   return 0
else
   /usr/lib/msgcollector/msgdispatcher_profile_d
fi

## End of /etc/profile.d/40_msgdispatcher.sh

#!/bin/sh
base=$(echo $(dirname $(dirname $(readlink -f $0))))
liquidsoap "$base/etc/liquidsoap.liq"
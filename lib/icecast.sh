#!/bin/sh
base=$(echo $(dirname $(dirname $(readlink -f $0))))
icecast2 -c "$base/etc/icecast.xml"
#!/bin/sh
test "$USER" = "liquidsoap" || { USER=liquidsoap sudo -u liquidsoap $0; return; }
export RADIO=/var/radio
export USER=liquidsoap
export HOME=/var/radio
export PATH=$PATH:$RADIO/node_modules/.bin
export PATH=$PATH:$RADIO/bin
cd /var/radio
fizsh

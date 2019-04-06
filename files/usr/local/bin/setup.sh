#!/bin/sh

set -eu

release=${1:-edge}
echo "http://dl-cdn.alpinelinux.org/alpine/$release/main" > /etc/apk/repositories

apk -U upgrade -a
apk add alpine-sdk lua-aports pigz
rm -rf /var/cache/apk/*

# use buildozer for building
adduser -D buildozer
adduser buildozer abuild
adduser buildozer wheel

# default distfiles location
install -d -g abuild -m 775 /var/cache/distfiles

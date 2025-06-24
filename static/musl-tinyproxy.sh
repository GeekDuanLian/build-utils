#!/bin/bash
set -eo pipefail
echoerr () { echo "${@}" >&2; }; die () { local r="${?}"; echoerr "${@}"; exit "${r}"; }
trap 'echoerr -e "${0}: \e[0;91mExit with Error Code ${?} at Line ${LINENO}\e[0m"' ERR

# https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/main/tinyproxy/APKBUILD

# var
pkgver=('1.11.2' 'd7cdc3aa273881ca1bd3027ff83d1fa3d3f40424a3f665ea906a3de059df2795455b65aeebde0f75ae5cacf9bba57219bc0c468808a9a75278e93f8d7913bac5')

# pkg
apk add build-base

# src
cd "$( mktemp -d )"
wget -O- "https://github.com/tinyproxy/tinyproxy/releases/download/$pkgver/tinyproxy-$pkgver.tar.gz" |
    tee >(tar -xz --strip 1) | sha512sum -c <(echo "${pkgver[1]} -")

# build
./configure LDFLAGS=-static \
    --enable-upstream \
    --disable-debug \
    --disable-xtinyproxy \
    --disable-filter \
    --disable-reverse \
    --disable-transparent \
    --disable-manpage_support
make

# done
for i in src/tinyproxy; do
    strip -v --strip-all "${i}"
    mv -v "${i}" /release/
done

#!/bin/bash
set -eo pipefail
echoerr () { echo "${@}" >&2; }; die () { local r="${?}"; echoerr "${@}"; exit "${r}"; }
trap 'echoerr -e "${0}: \e[0;91mExit with Error Code ${?} at Line ${LINENO}\e[0m"' ERR

# https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/main/openssh/APKBUILD

# var
pkgver=('10.0_p1' '2daa1fcf95793b23810142077e68ddfabdf3732b207ef4f033a027f72d733d0e9bcdb6f757e7f3a5934b972de05bfaae3baae381cfc7a400cd8ab4d4e277a0ed')

# pkg
apk add build-base \
    zlib-dev zlib-static

# src
cd "$( mktemp -d )"
wget -O- "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${pkgver%_*}${pkgver#*_}.tar.gz" |
    tee >(tar -xz --strip 1) | sha512sum -c <(echo "${pkgver[1]} -")

# build
./configure CFLAGS=-static LDFLAGS=-static \
    --without-openssl
make sftp-server

# done
for i in sftp-server; do
    strip -v --strip-all "${i}"
    mv -v "${i}" /release/
done

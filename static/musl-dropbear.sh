#!/bin/bash
set -eo pipefail
echoerr () { echo "${@}" >&2; }; die () { local r="${?}"; echoerr "${@}"; exit "${r}"; }
trap 'echoerr -e "${0}: \e[0;91mExit with Error Code ${?} at Line ${LINENO}\e[0m"' ERR

# https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/main/dropbear/APKBUILD

# var
pkgver=('2025.88' '71194f4792287b9e56e07cfa9a3e97d23b7fda82c858e0219d0d54aee48e77892997330ad1af5654a738b970965a92a79468bbf5c8ba0358b046fd053dfc87ed')

# pkg
apk add build-base \
    zlib-dev zlib-static

# src
cd "$( mktemp -d )"
wget -O- "https://matt.ucc.asn.au/dropbear/releases/dropbear-${pkgver}.tar.bz2" |
    tee >(tar -xj --strip 1) | sha512sum -c <(echo "${pkgver[1]} -")

# cfg
# https://github.com/mkj/dropbear/blob/master/src/default_options.h
cat >localoptions.h <<EOF
// sftp-server path
#define SFTPSERVER_PATH "/home/${ALLOWED_USER:?}/.bin/sftp-server"

// verbose if needed
#define DEBUG_TRACE 5

// not need motd
#define DO_MOTD 0

// no agent forwarding
#define DROPBEAR_SVR_AGENTFWD 0

// not use inetd
#define INETD_MODE 0

// only aes128
#define DROPBEAR_AES128 1
#define DROPBEAR_AES256 0
#define DROPBEAR_3DES 0
#define DROPBEAR_CHACHA20POLY1305 0

// only sha256
#define DROPBEAR_SHA1_HMAC 0
#define DROPBEAR_SHA2_256_HMAC 1
#define DROPBEAR_SHA2_512_HMAC 0
#define DROPBEAR_SHA1_96_HMAC 0

// only ed25519
#define DROPBEAR_RSA 0
#define DROPBEAR_RSA_SHA1 0
#define DROPBEAR_ECDSA 0
#define DROPBEAR_ED25519 1
#define DROPBEAR_SK_KEYS 0

// only curve25519
#define DROPBEAR_DH_GROUP14_SHA1 0
#define DROPBEAR_DH_GROUP14_SHA256 0
#define DROPBEAR_DH_GROUP16 0
#define DROPBEAR_CURVE25519 1
#define DROPBEAR_SNTRUP761 0
#define DROPBEAR_MLKEM768 0
#define DROPBEAR_ECDH 1
#define DROPBEAR_DH_GROUP1 0
EOF

# nopass
sed -i- '148 s|$| strcmp(ses.authstate.pw_name, "'"${ALLOWED_USER:?}"'") \&\&|' src/svr-auth.c

# build
./configure --enable-static \
    --disable-lastlog \
    --disable-utmp --disable-utmpx \
    --disable-wtmp --disable-wtmpx \
    --disable-pututline --disable-pututxline
make strip PROGRAMS=dropbear

# done
for i in dropbear; do
    strip -v --strip-all "${i}"
    mv -v "${i}" /release/
done

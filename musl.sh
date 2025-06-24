#!/bin/bash
set -eo pipefail
echoerr () { echo "${@}" >&2; }; die () { local r="${?}"; echoerr "${@}"; exit "${r}"; }
trap 'echoerr -e "${0}: \e[0;91mExit with Error Code ${?} at Line ${LINENO}\e[0m"' ERR

# pkg
pkg=(bash curl less grep diffutils htop broot btop micro traceroute rsync netcat-openbsd)
bin=(bash curl less grep diff      htop broot btop micro traceroute rsync nc)
interpreter_path="/home/${ALLOWED_USER:?}/.bin"

# patchelf
command -v patchelf &>/dev/null || apk add patchelf

# arch
: "${arch:?}"
cd /release

# apk index
index="$(mktemp -d)"
mkdir -p "${index}"/etc/apk
ln -s /usr/share/apk/keys/"${arch}" "${index}"/etc/apk/keys
cat >"${index}"/etc/apk/repositories <<'EOF'
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
EOF

# apk
apk add --initdb --arch "${arch}" --root "${index}" --no-script "${pkg[@]}"

# func
find_in_index () {
    local i path=() args=()
    IFS=':' read -ra path <<<"${1}"
    path=("${path[@]/#/"${index}/"}")
    shift
    for i in "${@}"; do args+=(-or -name "${i}"); done
    find "${path[@]}" "${args[@]:1}"
}

# bin
find_in_index bin:usr/bin "${bin[@]}" | xargs cp -uLt ./
patchelf --set-interpreter "${interpreter_path}"/libc.musl-"${arch}".so.1 --set-rpath '$ORIGIN/lib' "${bin[@]}"

# lib from bin
mapfile -t lib < <( patchelf --print-needed ./* | sort | uniq )
mkdir lib
find_in_index lib:usr/lib "${lib[@]}" | xargs cp -uLt lib/
# lib from lib
for _ in 1 2; do # check twice
    mapfile -t lib < <( patchelf --print-needed lib/* | sort | uniq )
    find_in_index lib:usr/lib "${lib[@]}" | xargs cp -uLt lib/
done
# chmod
mv lib/libc.musl-"${arch}".so.1 ./
chmod 644 lib/*

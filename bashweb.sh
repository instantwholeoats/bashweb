#!/bin/bash

trap exit INT
SCRIPTDIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
MO_URL="https://raw.githubusercontent.com/tests-always-included/mo/31ff19e9543354907dee833981bfd7ab3d036910/mo"
MO_SHA256="2ced83493e63194f5ffc84fa82817c6c664b635e46de06d66d56bcacc019cda5"

download_and_verify() {
  local url=$1
  local output=$2
  local expected=$3
  curl --fail --location --proto '=https' --tlsv1.2 --output "$output" "$url"
  printf '%s  %s\n' "$expected" "$output" | shasum -a 256 -c -
}

case $1 in

############################
## Install Dependencies
############################
  install)
    echo "Install dependencies..."
    mkdir -p "${SCRIPTDIR}/vendor/mo"
    pushd "${SCRIPTDIR}/vendor/mo" >/dev/null
    if [ ! -e "./mo" ]; then
      download_and_verify "$MO_URL" ./mo "$MO_SHA256"
      chmod 755 ./mo
    fi
    popd >/dev/null
    mkdir -p "${SCRIPTDIR}/log" "${SCRIPTDIR}/db"
    echo "Install finished!"
    ;;

############################
## Start Server
############################
  start)
    cat <<EOF
🐠 bashweb server 🐠

press ctrl+c to quit
listening ${BIND_ADDRESS:-127.0.0.1}:${PORT:-8080}...
EOF

    while :
    do
      exec python3 "${SCRIPTDIR}/server.py" --bind "${BIND_ADDRESS:-127.0.0.1}" --port "${PORT:-8080}"
    done
    ;;

############################
## HELP
############################
  *)
    cat <<EOF
🐠 bashweb server usage 🐠
install dependencies:
  $ ./bashweb.sh install
start server:
  $ ./bashweb.sh start
EOF
    ;;
esac

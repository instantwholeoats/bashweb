#!/bin/bash

declare -a ROUTE_METHODS
declare -a ROUTE_PATHS
declare -a ROUTE_CONTROLLERS

route() {
  local method
  method=$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')
  local path=$2
  local controller=$3
  if ! [[ "$method" =~ ^(GET|POST|PUT)$ ]] ||
    ! [[ "$path" =~ ^/[A-Za-z0-9._/-]*$ ]] ||
    ! [[ "$controller" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] ||
    ! declare -F "$controller" >/dev/null; then
    return 1
  fi
  local index=${#ROUTE_METHODS[@]}
  ROUTE_METHODS[$index]=$method
  ROUTE_PATHS[$index]=$path
  ROUTE_CONTROLLERS[$index]=$controller
}

call_controller() {
  local method=$1
  local path=$2
  local index
  for ((index = 0; index < ${#ROUTE_METHODS[@]}; index++)); do
    if [ "${ROUTE_METHODS[$index]}" = "$method" ] && [ "${ROUTE_PATHS[$index]}" = "$path" ]; then
      "${ROUTE_CONTROLLERS[$index]}"
      return
    fi
  done
  response 404 404
}

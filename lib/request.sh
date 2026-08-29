#!/bin/bash

url_decode() {
  local encoded=${1//+/ }
  local decoded=""
  local character hex byte
  local index=0

  while [ "$index" -lt "${#encoded}" ]; do
    character=${encoded:$index:1}
    if [ "$character" = '%' ]; then
      hex=${encoded:$((index + 1)):2}
      if ! [[ "$hex" =~ ^[0-9A-Fa-f]{2}$ ]] || [[ "$hex" =~ ^(0[0-9A-Fa-f]|1[0-9A-Fa-f]|7[Ff])$ ]]; then
        return 1
      fi
      printf -v byte '%b' "\\x${hex}"
      decoded="${decoded}${byte}"
      index=$((index + 3))
    else
      decoded="${decoded}${character}"
      index=$((index + 1))
    fi
  done
  REPLY=$decoded
}

parse_form_body() {
  local body=$1
  local pair key encoded_value value variable_name
  local old_ifs=$IFS
  IFS='&'

  for pair in $body; do
    key=${pair%%=*}
    encoded_value=${pair#*=}
    if ! [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]{0,63}$ ]]; then
      IFS=$old_ifs
      return 1
    fi
    url_decode "$encoded_value" || {
      IFS=$old_ifs
      return 1
    }
    value=$REPLY
    variable_name="REQUEST_${key}"
    printf -v "$variable_name" '%s' "$value"
  done

  IFS=$old_ifs
}

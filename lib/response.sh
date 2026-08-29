#!/bin/bash

html_escape() {
  local value=$1
  local result=""
  local character
  local index
  for ((index = 0; index < ${#value}; index++)); do
    character=${value:$index:1}
    case "$character" in
      '&') result="${result}&amp;" ;;
      '<') result="${result}&lt;" ;;
      '>') result="${result}&gt;" ;;
      '"') result="${result}&quot;" ;;
      "'") result="${result}&#39;" ;;
      *) result="${result}${character}" ;;
    esac
  done
  REPLY=$result
}

response() {
  RESPONSE_CODE=${1:-200}
  add_response_code_description
  local layout=${2:-${FUNCNAME[1]}}
  if ! [[ "$layout" =~ ^[A-Za-z0-9_-]+$ ]] || [ ! -f "${APPROOT}/view/${layout}.mustache" ]; then
    RESPONSE_CODE=404
    add_response_code_description
    layout=404
  fi
  RESPONSE_BODY=$(mo "${APPROOT}/view/${layout}.mustache")
  CONTENT_TYPE="text/html"
}

add_response_code_description() {
  case "$RESPONSE_CODE" in
    200) RESPONSE_CODE_DESCRIPTION=OK ;;
    400) RESPONSE_CODE_DESCRIPTION='Bad Request' ;;
    404) RESPONSE_CODE_DESCRIPTION='Not Found' ;;
    405) RESPONSE_CODE_DESCRIPTION='Method Not Allowed' ;;
    413) RESPONSE_CODE_DESCRIPTION='Payload Too Large' ;;
    *) RESPONSE_CODE=500; RESPONSE_CODE_DESCRIPTION='Internal Server Error' ;;
  esac
}

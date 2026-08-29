#!/bin/bash

html_escape() {
  local value=$1
  value=${value//&/&amp;}
  value=${value//</&lt;}
  value=${value//>/&gt;}
  value=${value//\"/&quot;}
  value=${value//\'/&#39;}
  REPLY=$value
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

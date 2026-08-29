#!/bin/bash
declare -r SESSION_ID=$RANDOM
declare -r APPROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${APPROOT}/config.sh"
source "${APPROOT}/lib/index.sh"
source "${APPROOT}/vendor/mo/mo"

# load controllers
while IFS= read -r SCRIPT; do
  source "$SCRIPT"
done < <(find "${APPROOT}/controller" -type f -name '*.sh' -print)

source "${APPROOT}/route.sh"

# parse HTTP request
declare INPUT HTTP_VERSION REQUEST_TARGET
IFS=' ' read -r HTTP_METHOD REQUEST_TARGET HTTP_VERSION
HTTP_METHOD=$(printf '%s' "$HTTP_METHOD" | tr '[:lower:]' '[:upper:]')
REQUEST_PATH=${REQUEST_TARGET%%\?*}
declare -r SAFE_PATH_PATTERN='^/[^[:cntrl:] ]*$'

if ! [[ "$HTTP_METHOD" =~ ^(GET|POST|PUT)$ ]] || ! [[ "$REQUEST_PATH" =~ $SAFE_PATH_PATTERN ]]; then
  RESPONSE_CODE=400
  add_response_code_description
fi

log debug "$HTTP_METHOD $REQUEST_TARGET $HTTP_VERSION"
while :
do
  IFS= read -r INPUT
  INPUT=${INPUT%$'\r'}
  if [ -z "$INPUT" ]; then
    break
  fi
  declare HEADER_KEY=${INPUT%%:*}
  HEADER_KEY=$(printf '%s' "$HEADER_KEY" | tr '[:upper:]' '[:lower:]')
  declare HEADER_VALUE=${INPUT#*:}
  HEADER_VALUE=${HEADER_VALUE# }
  if [ "${HEADER_KEY}" = "content-type" ]; then
    REQUEST_CONTENT_TYPE=$HEADER_VALUE
  fi
  if [ "${HEADER_KEY}" = "content-length" ]; then
    REQUEST_CONTENT_LENGTH=$HEADER_VALUE
  fi
  log debug "$HEADER_KEY: $HEADER_VALUE"
done

if [ -z "${RESPONSE_CODE:-}" ] && { [ "$HTTP_METHOD" = POST ] || [ "$HTTP_METHOD" = PUT ]; }; then
  if ! [[ "${REQUEST_CONTENT_LENGTH:-}" =~ ^[0-9]+$ ]]; then
    RESPONSE_CODE=400
    add_response_code_description
  elif [ "$REQUEST_CONTENT_LENGTH" -gt 1048576 ]; then
    RESPONSE_CODE=413
    add_response_code_description
  elif [ "${REQUEST_CONTENT_TYPE:-}" = "application/x-www-form-urlencoded" ]; then
    IFS= read -r -n "$REQUEST_CONTENT_LENGTH" INPUT
    if ! parse_form_body "$INPUT"; then
      RESPONSE_CODE=400
      add_response_code_description
    fi
  else
    RESPONSE_CODE=400
    add_response_code_description
  fi
fi

log info "Request received: ${HTTP_METHOD} ${REQUEST_PATH}"

# routing
if [ -z "${RESPONSE_CODE:-}" ] && [ "${HTTP_METHOD}" = "GET" ]; then
  static_file_loader "$REQUEST_PATH"
fi
if [ -z "${RESPONSE_CODE:-}" ]; then
  call_controller "$HTTP_METHOD" "$REQUEST_PATH"
fi

# send response
printf 'HTTP/1.0 %s %s\r\n' "$RESPONSE_CODE" "$RESPONSE_CODE_DESCRIPTION"
printf 'Content-Type: %s\r\n' "${CONTENT_TYPE:-text/plain}"
printf 'X-Content-Type-Options: nosniff\r\n'
printf 'Content-Security-Policy: default-src '\''self'\''; base-uri '\''none'\''; frame-ancestors '\''none'\''\r\n'
printf '\r\n'
if [ -n "${RESPONSE_FILE:-}" ]; then
  cat "$RESPONSE_FILE"
else
  printf '%s' "${RESPONSE_BODY:-}"
fi
log info "Responsed ${RESPONSE_CODE} ${RESPONSE_CODE_DESCRIPTION}"

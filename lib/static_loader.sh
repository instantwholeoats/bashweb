#!/bin/bash

declare -r MIME_TYPE_JPG="image/jpeg"
declare -r MIME_TYPE_PNG="image/png"
declare -r MIME_TYPE_ICO="image/x-icon"
declare -r MIME_TYPE_TXT="text/plain"
declare -r MIME_TYPE_HTML="text/html"

static_file_loader() {
  local request_path=$1
  local segment candidate extension
  IFS='/' read -r -a segments <<< "$request_path"
  for segment in "${segments[@]}"; do
    [ "$segment" = '..' ] && return
  done
  candidate="${APPROOT}/static${request_path}"
  [ -f "$candidate" ] || return
  RESPONSE_FILE=$candidate
  extension=$(printf '%s' "${candidate##*.}" | tr '[:lower:]' '[:upper:]')
  case "$extension" in
    JPG|JPEG) CONTENT_TYPE=$MIME_TYPE_JPG ;;
    PNG) CONTENT_TYPE=$MIME_TYPE_PNG ;;
    ICO) CONTENT_TYPE=$MIME_TYPE_ICO ;;
    HTML|HTM) CONTENT_TYPE=$MIME_TYPE_HTML ;;
    *) CONTENT_TYPE=$MIME_TYPE_TXT ;;
  esac
  RESPONSE_CODE=200
  add_response_code_description
}

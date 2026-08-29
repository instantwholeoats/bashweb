#!/bin/bash

declare -r LOGLEVEL_DEBUG_DEBUG=true
declare -r LOGLEVEL_DEBUG_INFO=true
declare -r LOGLEVEL_DEBUG_WARN=true
declare -r LOGLEVEL_DEBUG_ERROR=true
declare -r LOGLEVEL_INFO_DEBUG=false
declare -r LOGLEVEL_INFO_INFO=true
declare -r LOGLEVEL_INFO_WARN=true
declare -r LOGLEVEL_INFO_ERROR=true
declare -r LOGLEVEL_WARN_DEBUG=false
declare -r LOGLEVEL_WARN_INFO=false
declare -r LOGLEVEL_WARN_WARN=true
declare -r LOGLEVEL_WARN_ERROR=true
declare -r LOGLEVEL_ERROR_DEBUG=false
declare -r LOGLEVEL_ERROR_INFO=false
declare -r LOGLEVEL_ERROR_WARN=false
declare -r LOGLEVEL_ERROR_ERROR=true

declare -r LOGFILE=${APPROOT}/log/log.txt

log() {
  local type
  type=$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')
  shift
  local configured requested
  case "$LOGLEVEL" in DEBUG) configured=0 ;; INFO) configured=1 ;; WARN) configured=2 ;; *) configured=3 ;; esac
  case "$type" in DEBUG) requested=0 ;; INFO) requested=1 ;; WARN) requested=2 ;; ERROR) requested=3 ;; *) return 1 ;; esac
  if [ "$requested" -ge "$configured" ]; then
    printf '%s SESSION:%s [%s] %s\n' "$(date -u '+%Y/%m/%dT%H:%M:%SZ')" "$SESSION_ID" "$type" "$*" >> "$LOGFILE"
  fi
}

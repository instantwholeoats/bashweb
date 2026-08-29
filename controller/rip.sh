#!/bin/bash

rip_show() {
  declare -r IFS_SAVE=$IFS
  declare -a LIST
  IFS=$'\n'
  declare COUNT=0
  for LINE in $(cat "${APPROOT}/db/rip"); do
    html_escape "$LINE"
    LIST[$COUNT]=$REPLY
    COUNT=$((COUNT+1))
  done
  IFS=${IFS_SAVE}
  response
}

rip_create() {
  printf '%s\n' "${REQUEST_name}" >> "${APPROOT}/db/rip"
  html_escape "${REQUEST_name}"
  declare -r NAME=$REPLY
  response
}

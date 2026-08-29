#!/bin/bash
set -e

ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
APPROOT=$ROOT

source "${ROOT}/lib/request.sh"
source "${ROOT}/lib/router.sh"
source "${ROOT}/lib/response.sh"
source "${ROOT}/lib/static_loader.sh"

mo() {
  cat "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

safe_controller() {
  response 200 main_show
}

route GET /safe safe_controller
call_controller GET /safe
[ "$RESPONSE_CODE" = 200 ] || fail 'registered route did not run'

RESPONSE_CODE=
call_controller GET '/$(touch /tmp/bashweb-injection)'
[ "$RESPONSE_CODE" = 404 ] || fail 'unknown route did not return 404'
[ ! -e /tmp/bashweb-injection ] || fail 'route input executed as shell code'

parse_form_body 'name=hello+world&message=safe%20value'
[ "$REQUEST_name" = 'hello world' ] || fail 'form plus decoding failed'
[ "$REQUEST_message" = 'safe value' ] || fail 'form percent decoding failed'

if parse_form_body 'bad%5Bkey%5D=value'; then
  fail 'unsafe form key was accepted'
fi
if parse_form_body 'name=line%0Abreak'; then
  fail 'control character was accepted'
fi

html_escape 'A&B <test> "quote"'
[ "$REPLY" = 'A&amp;B &lt;test&gt; &quot;quote&quot;' ] || fail 'HTML escaping failed'

unset RESPONSE_FILE RESPONSE_CODE
static_file_loader /hello.html
[ "$RESPONSE_CODE" = 200 ] || fail 'known static file was not found'
[ "$CONTENT_TYPE" = text/html ] || fail 'static MIME type was incorrect'

unset RESPONSE_FILE RESPONSE_CODE
static_file_loader /../README.md
[ -z "${RESPONSE_FILE:-}" ] || fail 'path traversal escaped static root'

printf 'security tests: pass\n'

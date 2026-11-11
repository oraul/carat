#!/bin/sh
# Publishes a change's pull request with exactly the gated title and body:
# the session's pull request tool appended a footer naming the session to
# every pull request it created, a revision the edit history keeps after
# the body is set back. This script runs the pr-body gate on
# build/pipeline/CHANGE.body.md and scans the title before any call, then
# creates the pull request through GitHub's REST API with curl (head the
# run state's branch, base main), or, when the run state already records a
# number, sets that pull request's title and body; it reads the live title
# and body back and refuses unless they equal the title and the file byte
# for byte. The session's proxy authenticates calls to the API host, so no
# token is read or stored here. The number is recorded in the run state
# (pr) as soon as the pull request exists, so a rerun updates it instead of
# creating another, and printed last.
#
# Usage: sh tools/publish_pr.sh CHANGE TITLE...
#   The words of TITLE are joined by single spaces. Exits 0 with the number
#   on its last line; 1 on a refused gate, a failed call, or a live text
#   unlike the gated one (the difference is reported); 2 on bad usage.
set -u

here=$(cd "$(dirname "$0")" && pwd)
# The API base is assembled so this file holds no address.
API="https:/""/api.github.com"

die() {
  echo "publish_pr: $1" >&2
  exit 1
}

[ $# -ge 2 ] || { echo "usage: sh tools/publish_pr.sh CHANGE TITLE..." >&2; exit 2; }
change=$1
shift
case "$change" in
  [a-z0-9]*) ;;
  *) echo "publish_pr: not a change name: $change" >&2; exit 2 ;;
esac
case "$change" in *[!a-z0-9-]*) echo "publish_pr: not a change name: $change" >&2; exit 2 ;; esac
title=$*
body=build/pipeline/$change.body.md

# The gates, before any call.
[ -n "$title" ] || die "refused: an empty title"
out=$(sh "$here/gates.sh" pr-body "$body" 2>&1) || { printf '%s\n' "$out" >&2; die "refused: the body $body fails the pr-body gate; nothing was published"; }
out=$(printf '%s\n' "$title" | sh "$here/scan_text.sh" --where title 2>&1) || { printf '%s\n' "$out" >&2; die "refused: the title fails the scan; nothing was published"; }
[ -z "$out" ] || { printf '%s\n' "$out" >&2; die "refused: the title fails the scan; nothing was published"; }

repo=$(sh "$here/run_state.sh" get "$change" repo 2>/dev/null) || true
branch=$(sh "$here/run_state.sh" get "$change" branch 2>/dev/null) || true
number=$(sh "$here/run_state.sh" get "$change" pr 2>/dev/null) || true
echo "$repo" | grep -Eq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' || die "no repository in the run state of $change"
echo "$branch" | grep -Eq '^[a-z]+/[a-z0-9-]+$' || die "no branch in the run state of $change"
echo "$number" | grep -Eq '^[0-9]+$' || number=""

tmp=$(mktemp -d "${TMPDIR:-/tmp}/publish-pr.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

# call METHOD PATH STATUS [DATA]: the response in $tmp/response; fails
# unless the HTTP status is STATUS.
call() {
  set -- "$1" "$2" "$3" "${4:-}"
  if [ -n "$4" ]; then
    code=$(curl -sS -X "$1" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Content-Type: application/json" --data-binary "@$4" -o "$tmp/response" -w '%{http_code}' "$API/$2") || die "$1 $2 failed"
  else
    code=$(curl -sS -X "$1" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" \
      -o "$tmp/response" -w '%{http_code}' "$API/$2") || die "$1 $2 failed"
  fi
  [ "$code" = "$3" ] || die "$1 $2 answered $code: $(jq -r '.message // empty' "$tmp/response" 2>/dev/null)"
}

if [ -z "$number" ]; then
  jq -n --arg title "$title" --arg head "$branch" --rawfile body "$body" \
    '{title: $title, head: $head, base: "main", body: $body}' > "$tmp/request" || die "cannot build the request"
  call POST "repos/$repo/pulls" 201 "$tmp/request"
  number=$(jq -r '.number' "$tmp/response")
  echo "$number" | grep -Eq '^[0-9]+$' || die "the created pull request has no number"
  sh "$here/run_state.sh" set "$change" pr "$number" > /dev/null || die "cannot record pull request $number in the run state"
else
  jq -n --arg title "$title" --rawfile body "$body" '{title: $title, body: $body}' > "$tmp/request" || die "cannot build the request"
  call PATCH "repos/$repo/pulls/$number" 200 "$tmp/request"
fi

# The live text, read back.
call GET "repos/$repo/pulls/$number" 200
jq -j '.title' "$tmp/response" > "$tmp/title"
jq -j '.body // ""' "$tmp/response" > "$tmp/body"
printf '%s' "$title" > "$tmp/want"
if ! cmp -s "$tmp/want" "$tmp/title"; then
  printf 'live title: %s\n' "$(cat "$tmp/title")" >&2
  die "refused: the live title of pull request $number differs from the gated title; stop the run"
fi
if ! cmp -s "$body" "$tmp/body"; then
  diff "$body" "$tmp/body" | sed 's/^/  /' >&2
  die "refused: the live body of pull request $number differs from $body; stop the run"
fi
echo "publish_pr: pull request $number holds the gated title and body"
echo "$number"

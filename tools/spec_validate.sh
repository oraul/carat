#!/bin/sh
# make spec-validate: strict OpenSpec validation of every change and spec,
# then of each active change as its archive would leave the specs. The
# change is archived in a copy of openspec/ under build/spec-preview/ and
# the copy validated strictly, so a spec that only the archive's merge makes
# invalid (a modified requirement over OpenSpec's length limit, which the
# change's own validation does not check) fails before the reviews, not at
# the package step. The real openspec/ is never written; a failed preview
# is kept for reading. A symbolic link under openspec/, which cp -R keeps
# and the preview's archive would write through to a file outside the
# copy, fails the run before any validation.
#
# Usage: sh tools/spec_validate.sh (from the top of the work tree)
# Environment: OPENSPEC_CMD, the command to run (npx of OpenSpec at the
# exact version OPENSPEC_PACKAGE of the Makefile pins when unset, never a
# tag the registry moves; the tools test sets a stub).
set -u

export OPENSPEC_TELEMETRY=0
openspec=${OPENSPEC_CMD:-npx -y @fission-ai/openspec@2.1.1}
preview=$(pwd)/build/spec-preview
failed=0

links=$(find openspec -type l | sort | tr '\n' ' ')
if [ -n "$links" ]; then
  echo "spec-validate: openspec/ holds the symbolic link(s) ${links% }, through which the preview's archive would write outside build/spec-preview; remove them"
  exit 1
fi
$openspec validate --all --strict --no-interactive || failed=1
for dir in openspec/changes/*/; do
  name=$(basename "$dir")
  [ -d "$dir" ] && [ "$name" != archive ] || continue
  rm -rf "$preview"
  mkdir -p "$preview"
  cp -R openspec "$preview/openspec"
  set -- archive "$name" -y
  ! grep -q -E '^skip_specs:[[:space:]]*true' "$dir.openspec.yaml" 2>/dev/null || set -- "$@" --skip-specs
  if (cd "$preview" && $openspec "$@" > archive.log 2>&1 &&
    $openspec validate --all --strict --no-interactive); then
    echo "spec-validate: $name as archived passes strict validation"
  else
    cat "$preview/archive.log"
    echo "spec-validate: the specs that archiving $name leaves fail strict validation; the preview is in build/spec-preview"
    failed=1
  fi
done
exit $failed

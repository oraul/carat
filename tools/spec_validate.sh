#!/bin/sh
# make spec-validate: strict OpenSpec validation of every change and spec,
# then of each active change as its archive would leave the specs. The
# change is archived in a copy of openspec/ under build/spec-preview/ and
# the copy validated strictly, so a spec that only the archive's merge makes
# invalid (a modified requirement over OpenSpec's length limit, which the
# change's own validation does not check) fails before the reviews, not at
# the package step. The real openspec/ is never written; a failed preview
# is kept for reading.
#
# Usage: sh tools/spec_validate.sh (from the top of the work tree)
# Environment: OPENSPEC_CMD, the command to run (npx of
# @fission-ai/openspec@latest when unset; the tools test sets a stub).
set -u

export OPENSPEC_TELEMETRY=0
openspec=${OPENSPEC_CMD:-npx -y @fission-ai/openspec@latest}
preview=$(pwd)/build/spec-preview
failed=0

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

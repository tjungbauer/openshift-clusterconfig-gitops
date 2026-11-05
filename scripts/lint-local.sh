#!/usr/bin/env bash
#
# Runs the same checks as the job lint-test in .github/workflows/linting.yml, before a push.
# Unlike the job, it does not stop at the first error and prints a summary at the end.
#
# Usage:
#   ./scripts/lint-local.sh                 check all charts
#   ./scripts/lint-local.sh --changed       only charts changed compared to origin/main
#   ./scripts/lint-local.sh components/idp  check the given chart folders
#
# Requires helm and yamllint. Both are in the image used by the job:
#   podman run --rm -v "$PWD":/work:Z -w /work \
#     quay.io/tjungbau/linter-image:v1.0.2 ./scripts/lint-local.sh

set -u
cd "$(git rev-parse --show-toplevel)" || exit 1

for tool in helm yamllint; do
  command -v "$tool" >/dev/null || { echo "$tool not found in PATH"; exit 1; }
done

# Prints the folder of the nearest Chart.yaml for a given file.
chart_of() {
  dir=$(dirname "$1")
  while [ "$dir" != "." ] && [ "$dir" != "/" ]; do
    if [ -f "$dir/Chart.yaml" ]; then echo "./$dir"; return; fi
    dir=$(dirname "$dir")
  done
}

if [ "${1:-}" = "--changed" ]; then
  charts=$( { git diff --name-only origin/main; git ls-files --others --exclude-standard; } \
    | while read -r file; do chart_of "$file"; done | sort -u )
elif [ "$#" -gt 0 ]; then
  charts=$(for dir in "$@"; do echo "./${dir#./}"; done)
else
  charts=$(find . -name Chart.yaml -not -path './.git/*' -not -path '*/charts/*' -exec dirname {} \; | sort)
fi

failed=""
count=0
for helm_dir in $charts; do
  count=$((count + 1))
  echo "##### $helm_dir"
  values=""
  add_val_files=$(find "$helm_dir" -type f -name in-cluster-values.yaml)
  [ -n "$add_val_files" ] && values="-f $add_val_files"

  helm dep up "$helm_dir" >/dev/null || failed="$failed $helm_dir"
  # A missing chart icon is only an info message, it is hidden here.
  # shellcheck disable=SC2086
  output=$(helm lint --strict $values "$helm_dir" 2>&1) || failed="$failed $helm_dir"
  echo "$output" | grep -v 'icon is recommended'
done

echo "##### yamllint"
yaml_failed=0
# shellcheck disable=SC2046
yamllint -f standard -c .yamllint.yaml $(find . -type f -name '*values.yaml' -not -path './.git/*') || yaml_failed=1

echo
echo "Charts checked: $count"
for helm_dir in $failed; do echo "FAILED: $helm_dir"; done
[ "$yaml_failed" -eq 1 ] && echo "FAILED: yamllint"
if [ -n "$failed" ] || [ "$yaml_failed" -eq 1 ]; then exit 1; fi
echo "All checks passed"

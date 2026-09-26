#!/usr/bin/env bash
#
# push-submodules.sh — one-shot publish of submodule changes + the parent pointer.
#
# The repo nests two submodules (`frontend`, `backend`) inside this root repo.
# Publishing a change normally means the "two-commit dance":
#   1. commit + push inside the submodule
#   2. `git add <submodule>` + commit + push in the root (bumps the pointer)
# Doing it by hand is easy to get wrong (push the submodule but forget the
# pointer, or vice versa). This script does both, per submodule that has work.
#
# Usage:
#   scripts/push-submodules.sh -m "feat: ..."            # commit + push everything pending
#   scripts/push-submodules.sh -m "feat: ..." frontend   # only the frontend submodule
#   scripts/push-submodules.sh -m "feat: ..." --dry-run  # show what would happen
#
# Notes:
#   - The same -m message is used for the submodule commit and the root bump.
#   - Submodules with nothing to commit but with unpushed commits are still pushed.
#   - The root bump commit is only made when a pointer actually changed.

set -euo pipefail

# ---- locate the root repo (dir containing .gitmodules) ----------------------
find_root() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  while [[ "$dir" != "/" ]]; do
    [[ -f "$dir/.gitmodules" ]] && { echo "$dir"; return 0; }
    dir="$(dirname "$dir")"
  done
  echo "error: no .gitmodules found in any parent directory" >&2
  return 1
}

ROOT="$(find_root)"
cd "$ROOT"

MESSAGE=""
DRY_RUN=0
TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message) MESSAGE="${2:-}"; shift 2 ;;
    --dry-run)    DRY_RUN=1; shift ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    -*) echo "error: unknown option '$1'" >&2; exit 2 ;;
    *)  TARGETS+=("$1"); shift ;;
  esac
done

if [[ -z "$MESSAGE" ]]; then
  echo "error: a commit message is required (-m \"...\")" >&2
  exit 2
fi

# ---- resolve which submodules to process ------------------------------------
all_submodules() {
  git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}'
}

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  mapfile -t SUBMODULES < <(all_submodules)
else
  SUBMODULES=()
  for t in "${TARGETS[@]}"; do
    if ! all_submodules | grep -qx "$t"; then
      echo "error: '$t' is not a submodule name (choices: $(all_submodules | paste -sd, -))" >&2
      exit 2
    fi
    SUBMODULES+=("$t")
  done
fi

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

branch_of() { git -C "$1" rev-parse --abbrev-ref HEAD; }

pointer_changed=0
changed_subs=()

# ---- per submodule: commit + push -------------------------------------------
for sub in "${SUBMODULES[@]}"; do
  echo "==> $sub"
  branch="$(branch_of "$sub")"

  if [[ -n "$(git -C "$sub" status --porcelain)" ]]; then
    echo "    committing staged + unstaged changes"
    run git -C "$sub" add -A
    run git -C "$sub" commit -m "$MESSAGE"
  else
    echo "    no uncommitted changes"
  fi

  # Push if the branch has unpushed commits (compares against its upstream if set).
  if git -C "$sub" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    ahead="$(git -C "$sub" rev-list --count '@{u}..HEAD')"
    if [[ "$ahead" -gt 0 ]]; then
      echo "    pushing $ahead commit(s) to $branch"
      run git -C "$sub" push origin "$branch"
    else
      echo "    nothing to push"
    fi
  else
    echo "    no upstream set — pushing $branch to origin"
    run git -C "$sub" push -u origin "$branch"
  fi

  # Record whether the root pointer will move. In a real run the commit above
  # has already advanced HEAD; in dry-run we predict it from pending changes.
  recorded="$(git ls-tree HEAD "$sub" | awk '{print $3}')"
  if [[ $DRY_RUN -eq 1 && -n "$(git -C "$sub" status --porcelain)" ]]; then
    pointer_changed=1
    changed_subs+=("$sub")
  else
    actual="$(git -C "$sub" rev-parse HEAD)"
    if [[ "$recorded" != "$actual" ]]; then
      pointer_changed=1
      changed_subs+=("$sub")
    fi
  fi
done

# ---- root: bump the pointer(s) and push -------------------------------------
echo "==> root"
if [[ $pointer_changed -eq 0 ]]; then
  echo "    submodule pointer(s) unchanged — nothing to bump"
  exit 0
fi

echo "    bumping submodule pointer(s): ${changed_subs[*]}"
run git add "${changed_subs[@]}"
run git commit -m "$MESSAGE"

root_branch="$(branch_of .)"
if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  run git push origin "$root_branch"
else
  run git push -u origin "$root_branch"
fi

echo "done."

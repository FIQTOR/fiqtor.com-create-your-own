#!/usr/bin/env bash
#
# check-submodule-pointers.sh — verify the root's submodule pointers match each
# submodule's remote.
#
# Publishing in this repo is a "two-commit dance": commit inside the submodule,
# push it, then bump the pointer in the root. Two things can go wrong, and
# neither shows up in the submodule's own CI:
#
#   BROKEN — the pointer records a commit that was never pushed. Anyone who
#            clones the root gets a gitlink they cannot fetch.
#   STALE  — the submodule's remote branch has moved past the pointer. The
#            change is live but the root still points at the old commit.
#
# This script reads each gitlink from the root tree and talks to the submodule
# remotes directly, so the submodules do NOT need to be checked out.
#
# Usage:
#   scripts/check-submodule-pointers.sh              # all submodules
#   scripts/check-submodule-pointers.sh backend      # only named ones
#   scripts/check-submodule-pointers.sh --quiet      # failures only
#
# Exit: 0 = every pointer is current and reachable, 1 = at least one problem.

set -euo pipefail

QUIET=0
TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -q|--quiet) QUIET=1; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "error: unknown option '$1'" >&2; exit 2 ;;
    *) TARGETS+=("$1"); shift ;;
  esac
done

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

log() { [[ $QUIET -eq 1 ]] || echo "$*"; }
fail() { echo "  ✗ $*" >&2; }

# ---- helpers ----------------------------------------------------------------
name_to_path() { git config -f .gitmodules "$1.path"; }
name_to_url()  { git config -f .gitmodules "$1.url"; }

submodule_names() {
  git config -f .gitmodules --get-regexp '^submodule\..*\.path$' \
    | awk '{print $1}' \
    | sed 's/\.path$//'
}

remote_default_branch() {
  local url="$1"
  git ls-remote --symref "$url" HEAD 2>/dev/null \
    | awk '/^ref:/ { sub("refs/heads/", "", $2); print $2; exit }'
}

# verify_pointer <recorded-sha> <url> <default-branch>
#   0 = current    1 = broken (not reachable)    2 = stale (remote moved on)
#   3 = could not verify. On 2, prints the remote tip to stdout.
verify_pointer() {
  local recorded="$1" url="$2" default_branch="$3"
  local tmp tip
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064  # expand $tmp now, so the trap still fires if the var moves
  trap "rm -rf '$tmp'" RETURN

  git init --bare -q "$tmp" 2>/dev/null || return 3
  git -C "$tmp" remote add origin "$url" 2>/dev/null || return 3
  git -C "$tmp" fetch -q origin '+refs/heads/*:refs/remotes/origin/*' 2>/dev/null || return 3

  tip="$(git -C "$tmp" rev-parse --verify -q "refs/remotes/origin/$default_branch" || true)"
  [[ -n "$tip" ]] || return 3

  git -C "$tmp" merge-base --is-ancestor "$recorded" "$tip" 2>/dev/null || return 1

  if [[ "$recorded" != "$tip" ]]; then
    printf '%s' "$tip"
    return 2
  fi
  return 0
}

# ---- resolve which submodules to check --------------------------------------
names=()
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  mapfile -t names < <(submodule_names)
else
  for t in "${TARGETS[@]}"; do
    names+=("submodule.$t")
  done
fi

if [[ ${#names[@]} -eq 0 ]]; then
  echo "error: no submodules found in .gitmodules" >&2
  exit 2
fi

log "Checking submodule pointers in $ROOT"

problems=0

for name in "${names[@]}"; do
  label="${name#submodule.}"
  path="$(name_to_path "$name")"
  url="$(name_to_url "$name")"

  if [[ -z "$path" || -z "$url" ]]; then
    fail "$label: missing path or url in .gitmodules"
    problems=$((problems + 1))
    continue
  fi

  recorded="$(git ls-tree HEAD "$path" | awk '{print $3}')"
  if [[ -z "$recorded" ]]; then
    fail "$label: no gitlink recorded in root HEAD for '$path'"
    problems=$((problems + 1))
    continue
  fi

  default_branch="$(remote_default_branch "$url" || true)"
  if [[ -z "$default_branch" ]]; then
    fail "$label: could not determine the default branch of $url"
    problems=$((problems + 1))
    continue
  fi

  status=0
  tip="$(verify_pointer "$recorded" "$url" "$default_branch")" || status=$?

  case "$status" in
    0)
      log "  ✓ $label: ${recorded:0:7} (origin/$default_branch)"
      ;;
    1)
      fail "$label: BROKEN — pointer ${recorded:0:7} is not reachable from origin/$default_branch"
      fail "        the submodule commit was never pushed"
      problems=$((problems + 1))
      ;;
    2)
      fail "$label: STALE — pointer ${recorded:0:7} is behind origin/$default_branch (${tip:0:7})"
      fail "        run scripts/push-submodules.sh to bump the pointer"
      problems=$((problems + 1))
      ;;
    *)
      fail "$label: could not verify $url (network or missing branch '$default_branch')"
      problems=$((problems + 1))
      ;;
  esac
done

if [[ $problems -gt 0 ]]; then
  echo "✗ $problems submodule pointer problem(s) found" >&2
  exit 1
fi

log "✓ all submodule pointers are current and reachable"

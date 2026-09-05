#!/usr/bin/env bash
#
# 3-cleanup-dev.sh -- undo whatever 2-publish-dev.sh left behind, and retire
# previews that are no longer wanted.
#
#     previews/3-cleanup-dev.sh                    # local reset: stale profiles + report
#     previews/3-cleanup-dev.sh --outputs          # ...and delete _book-dev/
#     previews/3-cleanup-dev.sh --clone            # ...and delete the staging clone
#     previews/3-cleanup-dev.sh --all              # everything local
#     previews/3-cleanup-dev.sh --list             # list published previews
#     previews/3-cleanup-dev.sh --unpublish pr-123 # remove one preview from the site
#     previews/3-cleanup-dev.sh --prune-root       # delete non-preview debris from the site root
#
#
# WHEN YOU NEED THIS
# ------------------
# 2-publish-dev.sh has an EXIT trap that removes its temporary profile on Ctrl-C
# or a failed render, so ordinary interruptions clean up after themselves. What
# the trap cannot catch is a `kill -9`, a closed terminal, or a crash -- and
# those can leave three kinds of debris:
#
#   * a stale _quarto-dev-<slug>.yml profile in the project root
#   * a partially written _book-dev/<slug>/ output directory
#   * a staging clone holding a half-finished sync, or a commit that was made
#     but never pushed
#
# Only the first genuinely matters, and only mildly: a leftover profile is inert
# unless something sets QUARTO_PROFILE to its name, so it cannot affect a normal
# `quarto render` or `quarto publish gh-pages`. The other two heal themselves,
# because 2-publish-dev.sh re-renders the output directory and resets the clone
# hard onto the remote before it does anything else. This script exists so you
# do not have to remember any of that.
#
# WHAT IT WILL NEVER TOUCH
# ------------------------
#   * _book/ and the production CNAME -- production output is not this script's
#     business.
#   * _freeze/ -- a dev render can update it, and it is tracked by git, but
#     those results are real computation. This script reports the change and
#     leaves the decision to you.
#   * .quarto/ -- cached search and crossref indices, not interrupt debris.
#     Deleting them only makes the next render slower.
#
# ---------------------------------------------------------------------------

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=dev-site-lib.sh
source "$script_dir/dev-site-lib.sh"

project_root="$(dev_project_root)"
cd "$project_root"

# ---------------------------------------------------------------------------
# Parse arguments. Default (no flags) is the conservative option: remove stale
# profiles and report on everything else without deleting it.
# ---------------------------------------------------------------------------
do_outputs=false     # delete $DEV_OUT_ROOT
do_clone=false       # delete $DEV_CLONE_DIR
do_list=false        # list published previews and exit
do_prune_root=false  # delete non-preview debris from the staging root
unpublish_slug=""    # remove this preview from the staging site

while (( $# > 0 )); do
  case "$1" in
    --outputs)    do_outputs=true ;;
    --clone)      do_clone=true ;;
    --all)        do_outputs=true; do_clone=true ;;
    --list)       do_list=true ;;
    --prune-root) do_prune_root=true ;;
    --unpublish)
      # Needs a value, and `set -u` would abort unhelpfully on a bare --unpublish.
      if (( $# < 2 )); then
        echo "3-cleanup-dev.sh: --unpublish needs a slug" >&2
        exit 1
      fi
      unpublish_slug="$(dev_slugify "$2")"
      shift
      ;;
    -h|--help)
      # Print this file's own header comment as the help text.
      sed -n '2,/^# ----/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "3-cleanup-dev.sh: unknown option '$1' (try --help)" >&2
      exit 1
      ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# --prune-root: delete anything at the staging root that is neither a known root
# file nor a marked preview, then push.
#
# The situation this repairs: someone runs `quarto publish gh-pages` in this
# repository. That command wipes the published branch (`git rm -r .` in the
# provider's worktree helper) and unpacks a whole rendered book at the root, so
# the previews vanish and chapters/, site_libs/, search.json and friends appear
# in their place. Re-publishing the previews restores them but leaves the book's
# files behind; this clears them out.
# ---------------------------------------------------------------------------
if [[ $do_prune_root == true ]]; then
  dev_refresh_clone
  dev_check_domain

  # Built with a read loop rather than `mapfile`, which is bash 4+; macOS still
  # ships bash 3.2 and that is what /usr/bin/env bash resolves to here.
  strays=()
  while IFS= read -r name; do
    if [[ -n $name ]]; then strays+=("$name"); fi
  done < <(dev_list_root_strays)

  if (( ${#strays[@]} == 0 )); then
    echo "==> staging root is clean, nothing to prune"
  else
    echo "==> removing ${#strays[@]} non-preview item(s) from the staging root:"
    prune_root_in_clone() {
      local n
      for n in "${strays[@]}"; do
        rm -rf "$DEV_CLONE_DIR/$n"
      done
      dev_write_root_files
    }
    for name in "${strays[@]}"; do
      echo "      $name"
    done
    prune_root_in_clone
    dev_commit_and_push "prune non-preview files from the staging root" prune_root_in_clone
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# --list: show what is currently published. Needs an up-to-date clone to be
# truthful, so refresh first.
# ---------------------------------------------------------------------------
if [[ $do_list == true ]]; then
  dev_refresh_clone
  echo ""
  echo "Previews on $DEV_BASE_URL/ :"
  found=false
  while IFS= read -r name; do
    [[ -n $name ]] || continue
    found=true
    printf '  %-24s %s/%s/\n' "$name" "$DEV_BASE_URL" "$name"
  done < <(dev_list_previews)
  [[ $found == false ]] && echo "  (none)"
  exit 0
fi

# ---------------------------------------------------------------------------
# --unpublish: drop one preview from the staging site.
#
# This is the counterpart to publishing per-PR previews: without it, every
# experiment ever pushed stays live forever. The root index is rewritten in the
# same commit so it never links to a preview that is gone.
# ---------------------------------------------------------------------------
if [[ -n $unpublish_slug ]]; then
  dev_refresh_clone

  # Retiring a preview also rewrites the staging root, CNAME included, so the
  # same accidental-domain-change guard applies here as in 2-publish-dev.sh.
  dev_check_domain

  if [[ ! -d $DEV_CLONE_DIR/$unpublish_slug ]]; then
    echo "3-cleanup-dev.sh: no preview named '$unpublish_slug' is published" >&2
    echo "  (previews/3-cleanup-dev.sh --list shows the ones that are)" >&2
    exit 1
  fi

  echo "==> removing preview '$unpublish_slug' from the staging site"

  # Wrapped so dev_commit_and_push can re-run it if the push is rejected: the
  # retry re-fetches and resets the clone, which would otherwise undo this.
  remove_preview_from_clone() {
    rm -rf "$DEV_CLONE_DIR/$unpublish_slug"
    dev_write_root_files
  }
  remove_preview_from_clone
  dev_commit_and_push "remove dev preview: $unpublish_slug" remove_preview_from_clone
  echo "==> $DEV_BASE_URL/$unpublish_slug/ will 404 once Pages rebuilds"

  # Also drop that preview's local render output, since it is now meaningless.
  rm -rf "$DEV_OUT_ROOT/$unpublish_slug"
  exit 0
fi

# ---------------------------------------------------------------------------
# Local reset. Everything below is about this working copy, not the staging site.
# ---------------------------------------------------------------------------
echo "==> local cleanup in $project_root"

# 1. Stale per-preview profiles. `nullglob` makes the glob expand to nothing
#    when there are no matches, instead of to the literal pattern.
shopt -s nullglob
stale_profiles=( "_quarto-${DEV_PROFILE_PREFIX}"*.yml )
shopt -u nullglob

if (( ${#stale_profiles[@]} > 0 )); then
  for f in "${stale_profiles[@]}"; do
    echo "    removing stale profile $f"
    rm -f "$f"
  done
else
  echo "    no stale dev profiles"
fi

# 2. Dev render output. Off by default: re-rendering a large book is expensive,
#    and a stale output directory is harmless because the next publish
#    re-renders into it anyway.
if [[ $do_outputs == true ]]; then
  if [[ -d $DEV_OUT_ROOT ]]; then
    echo "    removing $DEV_OUT_ROOT/"
    rm -rf "$DEV_OUT_ROOT"
  else
    echo "    no $DEV_OUT_ROOT/ to remove"
  fi
elif [[ -d $DEV_OUT_ROOT ]]; then
  echo "    keeping $DEV_OUT_ROOT/ (--outputs removes it)"
fi

# 3. Staging clone. Also off by default: deleting it costs a full re-clone on
#    the next publish. Worth doing if it has somehow got into a bad state.
if [[ $do_clone == true ]]; then
  if [[ -d $DEV_CLONE_DIR ]]; then
    echo "    removing staging clone $DEV_CLONE_DIR"
    rm -rf "$DEV_CLONE_DIR"
  else
    echo "    no staging clone to remove"
  fi
elif [[ -d $DEV_CLONE_DIR ]]; then
  # Report anything unpushed, which is the one state that a plain re-run of
  # 2-publish-dev.sh will silently discard when it resets onto the remote.
  if git -C "$DEV_CLONE_DIR" rev-parse --verify --quiet HEAD >/dev/null 2>&1; then
    unpushed="$(git -C "$DEV_CLONE_DIR" log --oneline "@{upstream}..HEAD" 2>/dev/null | wc -l | tr -d ' ')"
    if [[ $unpushed != "0" ]]; then
      echo "    note: staging clone has $unpushed unpushed commit(s);"
      echo "          the next previews/2-publish-dev.sh will discard them"
    fi
  fi
  echo "    keeping staging clone $DEV_CLONE_DIR (--clone removes it)"
fi

# 4. Stale git worktrees. Not created by these scripts, but `quarto publish
#    gh-pages` builds one under .quarto/ and can leave it registered if it was
#    interrupted. Pruning is unconditional because it is already a no-op when
#    nothing is stale: it only drops registrations whose directory is gone.
git worktree prune

# 5. Report tracked-file changes rather than reverting them, since a dev render
#    legitimately updates _freeze/.
if ! git diff --quiet -- _freeze 2>/dev/null; then
  echo ""
  echo "    _freeze/ has uncommitted changes from a render."
  echo "    These are real computed results -- commit them, or discard with:"
  echo "        git checkout -- _freeze"
fi

echo "==> done"

#!/usr/bin/env bash
#
# 2-publish-dev.sh -- publish a *dev preview* of this book to the staging site.
#
# Each preview gets its own subdirectory of the staging site, so any number of
# them can coexist: one per branch, one per PR, one per experiment.
#
#     previews/2-publish-dev.sh pr-123       ->  https://dev.aml4td.org/pr-123/
#     previews/2-publish-dev.sh cls-linear   ->  https://dev.aml4td.org/cls-linear/
#     previews/2-publish-dev.sh              ->  slug derived from the current branch
#
# Retire one with:  previews/3-cleanup-dev.sh --unpublish pr-123
# List them with:   previews/3-cleanup-dev.sh --list
#
#
# WHY THIS EXISTS INSTEAD OF `quarto publish gh-pages`
# ----------------------------------------------------
# `quarto publish gh-pages` always pushes to the *origin* remote's *gh-pages*
# branch. Both are hardcoded, with no --remote/--branch flag. Production
# (aml4td.org) owns that slot already, and GitHub Pages serves exactly one site
# per repository, so previews have to live somewhere else. This script renders
# with Quarto and then does the push itself, with plain git, aimed at a separate
# staging repository.
#
# Note that `quarto publish gh-pages` *wipes* the branch before writing: its
# worktree helper runs `git rm -r .` first. That is fine for production, but it
# is also why previews can never share a branch with it -- a production publish
# would delete them. Within a preview directory this script does the equivalent
# itself, with an rsync --delete scoped to that one subdirectory.
#
#
# WHAT IT TOUCHES  (3-cleanup-dev.sh can undo all of it)
# ----------------------------------------------------
#   1. Writes a temporary Quarto profile, _quarto-dev-<slug>.yml, in the project
#      root. A profile is the only way to override site-url and
#      google-analytics for one build: `--metadata-file` does not reach
#      project-level config, it only lands in *format* metadata, so it cannot
#      set book.site-url. The EXIT trap below removes the file even on Ctrl-C or
#      a failed render.
#   2. Renders into _book-dev/<slug>/ (git-ignored). Production's _book/ is
#      never touched, so this is safe to run with a production build in place.
#   3. Maintains a persistent clone of the staging repo at $DEV_CLONE_DIR,
#      outside this repository.
#
#   NOT undone, on purpose: rendering may update the *tracked* _freeze/
#   directory. That is normal Quarto behaviour and reverting it would throw away
#   real computation, so `git status` may show changes after a dev build.
#
#
# ONE-TIME SETUP  (already done for aml4td/dev; see previews/README.md)
# --------------
#   gh repo create aml4td/dev --public     # must be org-owned: the DNS CNAME
#                                          # targets aml4td.github.io
#   previews/2-publish-dev.sh <slug>       # creates gh-pages; GitHub enables
#                                          # Pages automatically when it appears
#   # DNS: CNAME dev.aml4td.org -> aml4td.github.io
#
# ---------------------------------------------------------------------------

# -e            stop at the first failing command, so a broken render is never
#               published.
# -u            an unset variable is an error, which catches config typos.
# -o pipefail   a failure anywhere in a pipeline fails the whole pipeline.
set -euo pipefail

# Load shared configuration and helpers from next to this script, so it works
# regardless of the directory it is invoked from.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=dev-site-lib.sh
source "$script_dir/dev-site-lib.sh"

# Refuse to run inside the staging repository, which holds no book. Cheap, and
# catches a genuinely easy mix-up now that these scripts are committed and
# therefore travel to any checkout they are copied into.
dev_check_not_staging_repo

# Quarto resolves _quarto.yml and profile files relative to the project root,
# so work from there throughout.
project_root="$(dev_project_root)"
cd "$project_root"

# ---------------------------------------------------------------------------
# Work out the slug: this preview's subdirectory name and URL path segment.
# ---------------------------------------------------------------------------
branch="$(git rev-parse --abbrev-ref HEAD)"
short_sha="$(git rev-parse --short HEAD)"

# An explicit argument wins; otherwise name the preview after the branch.
raw_slug="${1:-$branch}"
slug="$(dev_slugify "$raw_slug")"

if [[ -z $slug ]]; then
  echo "2-publish-dev.sh: could not derive a usable slug from '$raw_slug'" >&2
  exit 1
fi

# Derived names. profile_name is what goes in QUARTO_PROFILE; profile_file is
# the file Quarto then looks for.
profile_name="${DEV_PROFILE_PREFIX}${slug}"
profile_file="_quarto-${profile_name}.yml"
out_dir="$DEV_OUT_ROOT/$slug"
preview_url="$DEV_BASE_URL/$slug/"

# ---------------------------------------------------------------------------
# Cleanup trap: runs on normal exit, on error (via set -e), and on Ctrl-C, so
# the generated profile never outlives the run.
#
# $? is captured first because the commands inside the trap would overwrite it;
# `return $rc` then preserves the script's real exit status.
# ---------------------------------------------------------------------------
cleanup() {
  local rc=$?
  # Note whether the profile actually existed, so the failure message below does
  # not claim to have cleaned up a file that was never written -- the guards in
  # steps 1 and 2 can fail before the profile is generated.
  local had_profile=false
  [[ -f $project_root/$profile_file ]] && had_profile=true
  rm -f "$project_root/$profile_file"
  if (( rc != 0 )); then
    echo ""
    echo "2-publish-dev.sh: failed (exit $rc) -- nothing was pushed."
    if [[ $had_profile == true ]]; then
      echo "  Removed the temporary profile $profile_file."
    fi
    echo "  For a fuller reset (stale profiles, output dirs, staging clone):"
    echo "      previews/3-cleanup-dev.sh --all"
  fi
  return $rc
}
trap cleanup EXIT INT TERM

echo "==> preview '$slug' from branch '$branch' ($short_sha)"
echo "    URL: $preview_url"

# ---------------------------------------------------------------------------
# Step 1. Put the staging clone into a pristine mirror of the remote branch,
# cloning it on first use. (See dev_refresh_clone for why it also runs
# `git clean` -- that is what makes a previously interrupted run harmless.)
#
# This runs before the render, not after, so that a misconfiguration or an
# unreachable remote fails in seconds rather than after a full book build.
# ---------------------------------------------------------------------------
dev_refresh_clone

# ---------------------------------------------------------------------------
# Step 2. Refuse to repoint the staging site's custom domain by accident.
# The committed defaults are correct for this repository, so this is a backstop
# rather than a routine trap -- it matters when DEV_DOMAIN is overridden by hand.
# See dev_check_domain for why a wrong value is worth refusing outright.
# ---------------------------------------------------------------------------
dev_check_domain

# ---------------------------------------------------------------------------
# Step 3. Generate this preview's temporary Quarto profile.
#
# site-url          each preview sits at its own path, and site-url is what
#                   feeds sitemap.xml plus the canonical and og:url tags.
#                   `quarto publish` only fixes site-url up automatically when
#                   *it* runs the render, so with a separate render step
#                   nothing else sets it.
# google-analytics  the empty string switches analytics off: it is falsy in
#                   Quarto's analytics check, so no gtag snippet is emitted.
#                   `null` or `false` would fail schema validation instead of
#                   disabling it.
#
# CNAME cannot be handled here. Profile `resources:` lists are *concatenated*
# with the base config's rather than replacing them, so the production CNAME
# ships no matter what this file says; step 5 deletes it from the output.
# ---------------------------------------------------------------------------
#
# The profile also carries the draft banner, appended by dev_banner_yaml. Note
# that the include keys *append* to any include-before-body/-in-header in the
# base config rather than replacing them, so an existing include keeps working.
# ---------------------------------------------------------------------------
cat > "$profile_file" <<YAML
# Generated by 2-publish-dev.sh for the '$slug' preview. Safe to delete.
book:
  site-url: $preview_url
  google-analytics: ""
YAML
dev_banner_yaml "$branch" "$short_sha" >> "$profile_file"

# ---------------------------------------------------------------------------
# Step 4. Render. The profile supplies the dev metadata; --output-dir keeps the
# build out of production's _book/. Committed _freeze/ results are reused, so
# this is normally far faster than a cold render.
# ---------------------------------------------------------------------------
echo "==> rendering with profile '$profile_name' into $out_dir/"
QUARTO_PROFILE="$profile_name" quarto render --output-dir "$out_dir"

# ---------------------------------------------------------------------------
# Step 5. Fix up the rendered output.
#
# Dropping CNAME matters: it contains "aml4td.org", and a CNAME naming the
# production domain inside the staging repository would make that repo try to
# claim aml4td.org, breaking one of the two sites. The staging site's own CNAME
# is written once at the branch root, by dev_write_root_files in step 7.
# ---------------------------------------------------------------------------
rm -f "$out_dir/CNAME"

# ---------------------------------------------------------------------------
# Step 6. Copy this preview into its own subdirectory of the staging branch.
#
# --delete is scoped to $slug/, so stale files from a deleted chapter go away
# while every *other* preview is left untouched.
# ---------------------------------------------------------------------------
# Wrapped in a function so dev_commit_and_push can re-run it if the push is
# rejected: recovering from that means re-syncing onto the new remote tip, and
# dev_refresh_clone resets the working tree, which would otherwise discard this.
# Cheap to repeat -- the render output is already on disk, so no re-render.
sync_preview_into_clone() {
  echo "==> syncing $out_dir/ -> $DEV_BRANCH:$slug/"
  mkdir -p "$DEV_CLONE_DIR/$slug"
  rsync -a --delete --exclude '.git' "$out_dir/" "$DEV_CLONE_DIR/$slug/"

  # Mark the directory as a preview, and record which branch and commit it came
  # from so the index can report it. Written *after* the rsync, because --delete
  # would otherwise remove it as a file absent from the render output. This is
  # what lets the index and the pruning logic tell a real preview from a
  # directory that something else dropped at the staging root.
  dev_write_preview_meta "$slug" "$branch" "$short_sha"

  # The staging root: .nojekyll, CNAME, robots.txt and the preview index.
  dev_write_root_files
}

# ---------------------------------------------------------------------------
# Step 7. Sync, refresh the staging root, then commit and push.
# ---------------------------------------------------------------------------
sync_preview_into_clone
dev_commit_and_push "dev preview: $slug from $branch@$short_sha" sync_preview_into_clone

echo ""
echo "==> published: $preview_url"
echo "    GitHub Pages usually needs a minute, and caches aggressively -- a"
echo "    hard refresh may be required to see changes."

# ---------------------------------------------------------------------------
# Step 8. Report if the render dirtied _freeze/.
#
# _freeze/ is tracked in this repository, and `freeze: auto` re-executes a chunk
# whenever its source changes -- so previewing a branch that edits code rewrites
# frozen results in the working tree. Prose-only branches never trigger this.
#
# It matters most when previewing someone else's PR: the freeze updates land on
# *their* branch, and you have to decide whether they belong in the PR. Nothing
# is reverted here, because those are real computed results; this only makes sure
# the change is never a surprise discovered later.
# ---------------------------------------------------------------------------
freeze_changes="$(git status --porcelain -- _freeze 2>/dev/null || true)"
if [[ -n $freeze_changes ]]; then
  echo ""
  echo "    NOTE: this render updated _freeze/ ($(printf '%s\n' "$freeze_changes" | wc -l | tr -d ' ') file(s))."
  echo "    Those are real computed results, left in place deliberately:"
  printf '%s\n' "$freeze_changes" | sed 's/^/      /' | head -8
  if (( $(printf '%s\n' "$freeze_changes" | wc -l) > 8 )); then
    echo "      ... (see: git status --short -- _freeze)"
  fi
  echo "    Commit them onto '$branch' if they belong there, or discard with:"
  echo "        git checkout -- _freeze && git clean -fd _freeze"
fi

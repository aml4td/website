#!/usr/bin/env bash
#
# dev-site-lib.sh -- shared configuration and helpers for the dev preview
# scripts. Sourced by 2-publish-dev.sh and 3-cleanup-dev.sh; not meant to be run
# directly.
#
# Everything that both scripts need to agree on lives here, so that a change to
# (say) the staging remote or the slug rules can't leave the publisher and the
# cleaner with different ideas about where things are.
#
# ---------------------------------------------------------------------------
# Configuration. Every value can be overridden from the environment:
#
#     DEV_DOMAIN= previews/2-publish-dev.sh pr-9     # use aml4td.github.io/dev instead
#     DEV_REMOTE=git@github.com:me/scratch.git previews/2-publish-dev.sh
# ---------------------------------------------------------------------------

# Staging repository that hosts the previews. This is NOT the book's origin --
# GitHub Pages serves one site per repo, and origin's gh-pages is production.
# HTTPS rather than SSH, to match this machine's setup (no SSH key registered
# with GitHub; pushes authenticate through the osxkeychain credential helper).
DEV_REMOTE="${DEV_REMOTE:-https://github.com/aml4td/dev.git}"

# Custom domain for the staging site. Set to empty to serve from the default
# github.io address instead (DEV_BASE_URL then falls back to match).
#
# NOTE the "-" instead of ":-": that form substitutes the default only when the
# variable is *unset*, so an explicitly empty DEV_DOMAIN is honoured. With ":-"
# a deliberate `DEV_DOMAIN= previews/2-publish-dev.sh` would silently fall back to the
# default domain and write a CNAME claiming it -- which is exactly the sort of
# accidental domain claim this script is otherwise careful to avoid.
DEV_DOMAIN="${DEV_DOMAIN-dev.aml4td.org}"

# Public root of the staging site; each preview hangs off this. No trailing slash.
DEV_BASE_URL="${DEV_BASE_URL:-https://${DEV_DOMAIN:-aml4td.github.io/dev}}"

# Branch that GitHub Pages serves in the staging repository.
DEV_BRANCH="${DEV_BRANCH:-gh-pages}"

# Persistent working clone of the staging repo. Deliberately outside the project
# (and outside $TMPDIR, which macOS prunes) so that pushes stay incremental
# rather than re-uploading the entire site every run.
DEV_CLONE_DIR="${DEV_CLONE_DIR:-$HOME/.cache/aml4td-dev-pages}"

# Parent directory for dev render output. Add /_book-dev/ to .gitignore.
DEV_OUT_ROOT="${DEV_OUT_ROOT:-_book-dev}"

# The published book. Only used for the "read the published book instead" link in
# the draft banner and on the preview index, so that nobody mistakes a preview
# for production or cites a preview URL.
DEV_PROD_URL="${DEV_PROD_URL:-https://aml4td.org}"

# Human-readable name for the published book, used in the same links.
DEV_PROD_NAME="${DEV_PROD_NAME:-aml4td.org}"

# Prefix for the temporary per-preview Quarto profiles. A profile named
# "dev-pr-123" is read by Quarto from the file "_quarto-dev-pr-123.yml".
DEV_PROFILE_PREFIX="${DEV_PROFILE_PREFIX:-dev-}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# dev_project_root
#   Absolute path to the top of the book repository, so either script can be
#   run from any subdirectory.
dev_project_root() {
  git rev-parse --show-toplevel
}

# dev_slugify <text>
#   Turn arbitrary text (usually a branch name) into something safe to use as
#   both a directory name and a URL path segment: lowercase, with every run of
#   characters outside [a-z0-9._-] collapsed to a single dash, and no leading or
#   trailing dashes/dots.
#
#   This is what maps a branch like "feature/Fix Typos" to "feature-fix-typos".
#   It is also a safety check: it defuses path traversal such as "../.." before
#   the value is ever used to build a path.
dev_slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9._-]\{1,\}/-/g' -e 's/^[-.]\{1,\}//' -e 's/[-.]\{1,\}$//'
}

# dev_refresh_clone
#   Bring $DEV_CLONE_DIR to a pristine mirror of the staging branch, cloning it
#   first if necessary.
#
#   The `git clean -fdx` is the important part for interrupt safety: `reset
#   --hard` only restores *tracked* files, so an rsync that died halfway leaves
#   stray untracked files behind, and a later `git add -A` would happily commit
#   them. Cleaning first guarantees every run starts from exactly what the
#   remote has.
dev_refresh_clone() {
  # Probe the remote first, so "cannot reach GitHub" is never mistaken for
  # "the staging branch does not exist yet". Those need opposite responses, and
  # the clone below cannot tell them apart on its own: a DNS blip or a dropped
  # VPN would look like a brand-new staging repo, and the script would start
  # building one from scratch instead of stopping.
  local remote_heads
  if ! remote_heads="$(git ls-remote --heads "$DEV_REMOTE" 2>&1)"; then
    cat >&2 <<MSG

Could not reach the staging repository. Nothing was changed.

  remote:  $DEV_REMOTE
  git said: $(printf '%s' "$remote_heads" | tail -1)

If that is a DNS or network error it is usually transient -- check the
connection and run the same command again. If it is an authentication error,
confirm you can reach the repo with:

    git ls-remote $DEV_REMOTE

MSG
    exit 1
  fi

  if [[ -d $DEV_CLONE_DIR/.git ]]; then
    echo "==> refreshing staging clone at $DEV_CLONE_DIR"
    git -C "$DEV_CLONE_DIR" fetch --quiet origin "$DEV_BRANCH"
    git -C "$DEV_CLONE_DIR" reset --quiet --hard FETCH_HEAD
    git -C "$DEV_CLONE_DIR" clean --quiet -fdx
  elif printf '%s' "$remote_heads" | grep -q "refs/heads/$DEV_BRANCH\$"; then
    echo "==> cloning staging repo into $DEV_CLONE_DIR"
    mkdir -p "$(dirname "$DEV_CLONE_DIR")"
    git clone --quiet --single-branch --branch "$DEV_BRANCH" \
      "$DEV_REMOTE" "$DEV_CLONE_DIR"
  else
    # Reachable, but the branch genuinely does not exist: a brand-new staging
    # repo. Start it locally; the first push publishes it.
    echo "==> no '$DEV_BRANCH' branch on the remote yet -- creating it"
    mkdir -p "$(dirname "$DEV_CLONE_DIR")"
    git init --quiet "$DEV_CLONE_DIR"
    git -C "$DEV_CLONE_DIR" checkout --quiet -b "$DEV_BRANCH"
    git -C "$DEV_CLONE_DIR" remote add origin "$DEV_REMOTE"
  fi
}

# dev_check_domain
#   Refuse to repoint the staging site's custom domain by accident.
#
#   The CNAME file at the root of the staging branch is what tells GitHub Pages
#   which host to serve, and setting it *locks that domain to this repository*
#   until it is released. So an incorrect DEV_DOMAIN does two kinds of damage at
#   once: it takes the staging site offline, and it squats a hostname that then
#   cannot be used by the repository that should own it.
#
#   The defaults at the top of this file are correct for this repository, so the
#   realistic way to trip this is an explicit DEV_DOMAIN override -- pointing at
#   a test domain, or copying these scripts into another project. It is not a
#   hypothetical risk: during development a wrong default wrote a CNAME claiming
#   dev.aml4td.org into a throwaway repository, caught only because Pages had not
#   been enabled there yet.
#
#   Adding a domain where there was none is allowed: that is the normal
#   first-time setup path. Only a *change* is blocked, and only until the caller
#   says it is deliberate.
#
#   Must be called after dev_refresh_clone, so the CNAME being compared is the
#   one actually published rather than a local leftover.
dev_check_domain() {
  local existing=""
  if [[ -f $DEV_CLONE_DIR/CNAME ]]; then
    existing="$(tr -d '[:space:]' < "$DEV_CLONE_DIR/CNAME")"
  fi

  # Nothing published yet, or already correct: nothing to do.
  if [[ -z $existing ]]; then
    [[ -n $DEV_DOMAIN ]] && echo "==> setting custom domain '$DEV_DOMAIN' (none was published before)"
    return 0
  fi
  [[ $existing == "$DEV_DOMAIN" ]] && return 0

  if [[ ${DEV_ALLOW_DOMAIN_CHANGE:-0} == 1 ]]; then
    echo "==> WARNING: changing the staging domain from '$existing' to '${DEV_DOMAIN:-<none>}'"
    return 0
  fi

  cat >&2 <<MSG

2-publish-dev.sh: refusing to change the staging site's custom domain.

  currently published:  $existing
  this run would set:   ${DEV_DOMAIN:-<nothing: the CNAME would be deleted>}
  remote:               $DEV_REMOTE

Setting a CNAME locks that domain to this repository, and clearing it takes the
site offline, so a mismatch is far more often a misconfiguration than an intent.
The usual cause is a DEV_DOMAIN override left over in the shell, or these
scripts having been copied into a project with a different staging site.

Check DEV_DOMAIN, or if the change really is intended:

    DEV_ALLOW_DOMAIN_CHANGE=1 previews/2-publish-dev.sh ...

MSG
  exit 1
}

# Marker file dropped inside every published preview directory.
#
# Previews are identified by this marker rather than by "is a directory at the
# staging root", because that assumption is not safe. If anything else ever
# writes to the staging branch -- most easily `quarto publish gh-pages`, which
# dumps a whole rendered book at the root -- then directories like chapters/ and
# site_libs/ appear alongside the real previews, and a directory-based listing
# advertises them as previews on the index page.
#
# The file also carries this preview's metadata, as `key=value` lines, so the
# index page can report which branch and commit each preview was built from.
# Deliberately not JSON: `key=value` is readable by bash 3.2 (what macOS ships)
# with no jq or python dependency, and none of the values can contain a newline.
DEV_MARKER=".dev-preview"

# dev_write_preview_meta <slug> <branch> <sha>
#   Write the marker file, with metadata, into a freshly synced preview.
#
#   Must run *after* the rsync: --delete would otherwise remove the marker, since
#   it is not part of the render output.
dev_write_preview_meta() {
  local slug="$1" branch="$2" sha="$3"
  cat > "$DEV_CLONE_DIR/$slug/$DEV_MARKER" <<META
slug=$slug
branch=$branch
sha=$sha
published=$(date -u '+%Y-%m-%d %H:%M UTC')
epoch=$(date '+%s')
META
}

# dev_read_meta <slug> <key>
#   Echo one metadata value, or nothing if absent. Tolerates an old-style empty
#   marker from before metadata existed, so a stale preview lists as "unknown"
#   rather than breaking the index.
dev_read_meta() {
  local slug="$1" key="$2" file="$DEV_CLONE_DIR/$1/$DEV_MARKER" k v
  [[ -f $file ]] || return 0
  while IFS='=' read -r k v; do
    if [[ $k == "$key" ]]; then printf '%s' "$v"; return 0; fi
  done < "$file"
}

# dev_banner_yaml <branch> <sha>
#   Emit the YAML that injects the draft banner into every page of a preview.
#   Written to stdout for the caller to append to the generated profile.
#
#   Why the banner exists: a preview is a pixel-perfect copy of the published
#   book. A coauthor sent a deep link has no other way to tell they are reading a
#   draft, and a preview URL that escapes into a citation is worse still. The bar
#   is sticky so it stays visible for someone who lands mid-chapter and scrolls.
#
#   Quarto's `text:` form is used rather than pointing at a file, so there is no
#   transient HTML file to write, reference and clean up. It also puts the CSS in
#   <head> where it belongs: `include-before-body` lands inside
#   <main class="content">, and a <style> element is not valid there.
#
#   Verified placement: the div is inserted directly into
#   main#quarto-document-content, above the title block, so `position: sticky`
#   pins it to the top of the viewport without competing with the docked sidebar.
dev_banner_yaml() {
  local branch="$1" sha="$2"
  cat <<YAML
format:
  html:
    include-in-header:
      - text: |
          <style>
          .dev-preview-banner {
            position: sticky; top: 0; z-index: 500;
            display: flex; flex-wrap: wrap; gap: 0.35rem 1.1rem; align-items: baseline;
            margin: 0 0 1.5rem; padding: 0.55rem 0.9rem;
            background: #fdf3d8; border: 1px solid #e3c874; border-radius: 4px;
            color: #4a3708; font-size: 0.85rem; line-height: 1.35;
          }
          .dev-preview-banner strong {
            color: #8a5a00; text-transform: uppercase; letter-spacing: 0.03em;
          }
          .dev-preview-banner code {
            background: #f6e6bd; color: #4a3708; padding: 0 0.25em; font-size: 0.95em;
          }
          .dev-preview-banner a { color: #7a4a00; text-decoration: underline; }
          @media print { .dev-preview-banner { display: none; } }
          </style>
    include-before-body:
      - text: |
          <div class="dev-preview-banner">
            <strong>Draft preview</strong>
            <span>branch <code>$branch</code> at <code>$sha</code></span>
            <span>Not the published book &mdash;
              <a href="$DEV_PROD_URL">read $DEV_PROD_NAME</a></span>
            <span><a href="$DEV_BASE_URL/">all previews</a></span>
          </div>
YAML
}

# dev_list_previews
#   Names of the previews currently published, i.e. every top-level directory
#   holding a $DEV_MARKER file.
dev_list_previews() {
  local dir name
  for dir in "$DEV_CLONE_DIR"/*/; do
    [[ -d $dir ]] || continue                 # no matches -> the glob itself
    name="$(basename "$dir")"
    [[ $name == ".git" ]] && continue
    [[ -f $dir$DEV_MARKER ]] || continue      # not a preview: skip it
    printf '%s\n' "$name"
  done
}

# Files that legitimately live at the root of the staging branch. Everything
# else up there is either a preview directory or debris.
DEV_ROOT_FILES=(".git" ".nojekyll" "CNAME" "robots.txt" "index.html")

# dev_list_root_strays
#   Top-level entries that are neither a known root file nor a marked preview.
#
#   In practice these arrive one way: someone ran `quarto publish gh-pages` in
#   this repository, which wipes the branch and unpacks a whole rendered book at
#   the root (chapters/, site_libs/, search.json, sitemap.xml, .DS_Store...).
dev_list_root_strays() {
  local path name keep known
  for path in "$DEV_CLONE_DIR"/* "$DEV_CLONE_DIR"/.[!.]*; do
    [[ -e $path ]] || continue                # unmatched glob
    name="$(basename "$path")"

    # Note the `if` rather than `$known && continue`: under `set -e` a bare
    # false-valued command as a statement would abort the whole script.
    known=false
    for keep in "${DEV_ROOT_FILES[@]}"; do
      if [[ $name == "$keep" ]]; then known=true; break; fi
    done
    if [[ $known == true ]]; then continue; fi

    # A directory carrying the marker is a real preview, so leave it be.
    if [[ -d $path && -f $path/$DEV_MARKER ]]; then continue; fi

    printf '%s\n' "$name"
  done
}

# dev_write_root_files
#   (Re)write the files that belong at the root of the staging site. Called
#   after any change to the set of previews -- by 2-publish-dev.sh when adding
#   one, and by 3-cleanup-dev.sh when retiring one -- so the index never points
#   at a preview that is no longer there.
dev_write_root_files() {
  # .nojekyll stops GitHub Pages from running Jekyll, which would otherwise
  # hide every directory whose name starts with an underscore.
  touch "$DEV_CLONE_DIR/.nojekyll"

  # Claim the staging domain, or drop a stale CNAME if DEV_DOMAIN was cleared.
  #
  # Note this is the *staging* domain. The book's own CNAME (aml4td.org) is
  # listed under `resources:` in _quarto.yml and so gets copied into every
  # render; 2-publish-dev.sh deletes it from the output before syncing, because a
  # CNAME naming the production domain in this repo would make it try to claim
  # aml4td.org and break one of the two sites.
  if [[ -n $DEV_DOMAIN ]]; then
    printf '%s\n' "$DEV_DOMAIN" > "$DEV_CLONE_DIR/CNAME"
  else
    rm -f "$DEV_CLONE_DIR/CNAME"
  fi

  # Keep previews out of search results: they are drafts of a site that already
  # ranks, so indexing them invites duplicate-content competition with
  # aml4td.org. Only the root robots.txt is honoured by crawlers, so the
  # per-preview ones Quarto generates alongside each sitemap are harmless.
  printf 'User-agent: *\nDisallow: /\n' > "$DEV_CLONE_DIR/robots.txt"

  dev_write_index
}

# dev_write_index
#   Generate the landing page listing every published preview.
#
#   A bare list of slugs is not enough in practice: the useful question is not
#   "does a preview called X exist" but "is X still current, and what is in it".
#   So each row reports the branch and commit it was built from and when it was
#   published, read from the per-preview metadata marker.
#
#   Rows are ordered newest first. Previews published before metadata existed
#   show as "unknown" rather than breaking the page.
dev_write_index() {
  local name rows="" epoch branch sha published

  # Build sortable lines first: epoch first field so `sort -rn` puts the newest
  # at the top. Tab-separated, since no field can contain a tab.
  while IFS= read -r name; do
    [[ -n $name ]] || continue
    epoch="$(dev_read_meta "$name" epoch)"
    branch="$(dev_read_meta "$name" branch)"
    sha="$(dev_read_meta "$name" sha)"
    published="$(dev_read_meta "$name" published)"
    rows+="${epoch:-0}	$name	${branch:-unknown}	${sha:-unknown}	${published:-unknown}
"
  done < <(dev_list_previews)

  {
    cat <<'HTML'
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>Draft previews</title>
<style>
  :root { color-scheme: light; }
  body {
    max-width: 54rem; margin: 3rem auto 4rem; padding: 0 1.25rem;
    font: 16px/1.55 "Libre Franklin", system-ui, -apple-system, sans-serif;
    color: #1f2328; background: #fff;
  }
  h1 { font-size: 1.6rem; margin: 0 0 0.35rem; }
  .lede { color: #57606a; margin: 0 0 2rem; }
  .lede a { color: #0969da; }
  table { border-collapse: collapse; width: 100%; font-size: 0.92rem; }
  th, td { text-align: left; padding: 0.6rem 0.7rem; border-bottom: 1px solid #d8dee4; vertical-align: baseline; }
  th { font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.04em; color: #57606a; border-bottom-width: 2px; }
  tbody tr:hover { background: #f6f8fa; }
  td.slug a { font-weight: 600; color: #0969da; text-decoration: none; }
  td.slug a:hover { text-decoration: underline; }
  code { font: 0.9em ui-monospace, SFMono-Regular, Menlo, monospace; background: #f0f3f6; padding: 0.1em 0.35em; border-radius: 3px; }
  .when { color: #57606a; white-space: nowrap; }
  .empty { color: #57606a; font-style: italic; padding: 2rem 0; }
  footer { margin-top: 2.5rem; padding-top: 1rem; border-top: 1px solid #d8dee4; color: #57606a; font-size: 0.85rem; }
</style>
<h1>Draft previews</h1>
HTML
    printf '<p class="lede">Work-in-progress builds, one per branch. These are <strong>not</strong> the published book &mdash; read <a href="%s">%s</a> for that. Not indexed by search engines.</p>\n' \
      "$DEV_PROD_URL" "$DEV_PROD_NAME"

    if [[ -z $rows ]]; then
      echo '<p class="empty">No previews are published right now.</p>'
    else
      echo '<table>'
      echo '  <thead><tr><th>Preview</th><th>Branch</th><th>Commit</th><th>Published</th></tr></thead>'
      echo '  <tbody>'
      # `sort -rn` on the epoch column; -k1,1 keeps it comparing only that field.
      printf '%s' "$rows" | sort -t'	' -k1,1 -rn | while IFS='	' read -r epoch name branch sha published; do
        [[ -n $name ]] || continue
        printf '    <tr><td class="slug"><a href="%s/">%s</a></td><td><code>%s</code></td><td><code>%s</code></td><td class="when">%s</td></tr>\n' \
          "$name" "$name" "$branch" "$sha" "$published"
      done
      echo '  </tbody>'
      echo '</table>'
    fi

    printf '<footer>Index rebuilt %s. Previews are published and retired with the dev-preview scripts.</footer>\n' \
      "$(date -u '+%Y-%m-%d %H:%M UTC')"
    echo '</html>'
  } > "$DEV_CLONE_DIR/index.html"
}

# dev_commit_and_push <message> [prepare_fn]
#   Stage everything in the staging clone and push, treating "nothing changed"
#   as success rather than failure.
#
#   The push is deliberately NOT forced. dev_refresh_clone already reset the
#   clone onto the remote tip, so normally this is a fast-forward -- and a
#   force-push would silently discard a preview somebody else published in the
#   meantime, which is exactly the accident worth not automating.
#
#   But a rejection is a genuine possibility once more than one person publishes:
#   a render takes minutes, and anyone who pushes during that window moves the
#   tip. Losing a finished render to that would be miserable, so on rejection
#   this re-syncs onto the new tip and tries once more.
#
#   `prepare_fn` is the caller's function that puts its own changes into the
#   clone (rsync a preview in, delete one, prune the root). It has to be re-run
#   after the re-fetch because dev_refresh_clone resets the working tree, which
#   would otherwise throw those changes away. A rebase is deliberately avoided:
#   both sides regenerate index.html, so it would conflict every time, whereas
#   re-running prepare_fn regenerates it correctly from the merged tree.
dev_commit_and_push() {
  local message="$1" prepare_fn="${2:-}" attempt

  for attempt in 1 2; do
    git -C "$DEV_CLONE_DIR" add -A

    if git -C "$DEV_CLONE_DIR" diff --cached --quiet; then
      echo "==> no changes to publish"
      return 0
    fi

    git -C "$DEV_CLONE_DIR" commit --quiet -m "$message"
    echo "==> pushing to $DEV_REMOTE ($DEV_BRANCH)"
    if git -C "$DEV_CLONE_DIR" push --quiet --set-upstream origin "$DEV_BRANCH" 2>/dev/null; then
      return 0
    fi

    if (( attempt == 2 )) || [[ -z $prepare_fn ]]; then
      echo "" >&2
      echo "Push to $DEV_BRANCH was rejected." >&2
      echo "  Someone else published while this run was working. Re-run the same" >&2
      echo "  command -- the render is cached, so it will be quick." >&2
      return 1
    fi

    echo "==> push rejected (someone else published meanwhile); re-syncing and retrying"
    dev_refresh_clone
    "$prepare_fn"
  done
}

# dev_check_not_staging_repo
#   Refuse to publish from inside the staging repository itself.
#
#   The staging repo holds no book, so a render there would either fail or
#   publish nonsense. It is an easy mistake to make because a clone of it is a
#   perfectly reasonable thing to have sitting next to the book -- and the
#   scripts, being committed, travel to wherever they are copied.
dev_check_not_staging_repo() {
  local origin norm_origin norm_remote
  origin="$(git remote get-url origin 2>/dev/null || true)"
  [[ -n $origin ]] || return 0

  # Compare loosely: SSH and HTTPS forms of the same repo should match, and a
  # trailing .git or / should not matter.
  norm_origin="$(printf '%s' "$origin" | sed -e 's|^git@github.com:|https://github.com/|' -e 's|\.git$||' -e 's|/$||')"
  norm_remote="$(printf '%s' "$DEV_REMOTE" | sed -e 's|^git@github.com:|https://github.com/|' -e 's|\.git$||' -e 's|/$||')"

  if [[ $norm_origin == "$norm_remote" ]]; then
    cat >&2 <<MSG

This looks like the staging repository, not the book.

  origin:       $origin
  DEV_REMOTE:   $DEV_REMOTE

Previews are published *from* the book's repository *to* the staging repository.
Run this from the book checkout instead.

MSG
    exit 1
  fi
}

# Retired dev previews: table and link to main site

(On approval, copy to `plans/2026-11-04-{hhmm}-retired-preview-table.md` in the repo, per CLAUDE.md naming. Plan mode only allows writing here.)

## Overview

PR #131 added `previews/` scripts that publish branch/PR previews to `aml4td/dev` (served at dev.aml4td.org). `3-cleanup-dev.sh --unpublish <slug>` currently deletes the preview and leaves no trace. Goal: when a preview is removed, (1) keep a record so the index page shows a table of retired previews, and (2) let the user attach a link to the related page on the main site (aml4td.org).

## Checklist

- [x] `dev-site-lib.sh`: add `DEV_RETIRED_DIR=".retired"`, add it to `DEV_ROOT_FILES` (so `--prune-root` doesn't delete it)
- [x] `dev-site-lib.sh`: add `dev_write_retired_meta <slug> <link>` — writes `.retired/<slug>` as `key=value` (slug, branch, sha, published, retired date + epoch, link). Branch/sha/published are copied from the preview's `.dev-preview` marker via `dev_read_meta` BEFORE the directory is removed
- [x] `dev_read_retired_meta` and `dev_list_retired` helpers, mirroring `dev_read_meta` / `dev_list_previews`
- [x] `dev_write_index`: add a second "Retired previews" table (Preview, Branch, Retired, Main site link) after the active table, newest retired first; omit the section when empty. Link cell is an `<a>` if a link exists, otherwise an em dash. Slug is plain text (no href — it 404s)
- [x] HTML-escape link/branch values written into the index (link is user-supplied); validate link starts with `http://` or `https://`, and reject whitespace
- [x] `3-cleanup-dev.sh --unpublish`: add optional `--link <url>`; record retired metadata in the same commit and inside `remove_preview_from_clone` so the push-retry path re-applies it. Update header comment/`--help`
- [x] `2-publish-dev.sh`: when a slug is (re)published, delete any `.retired/<slug>` entry so it can't be both active and retired
- [x] `--list`: also print retired previews (with link) under the active ones
- [x] Optional small helper: `3-cleanup-dev.sh --set-link <slug> <url>` to add/fix a link on an already-retired entry (avoids needing to re-publish to fix a typo)
- [x] `previews/README.md`: document `--link`, the retired table, and `.retired/`
- [x] Update the existing plan `plans/2026-08-18-1755-dev-preview-sites.md` with a short follow-up section
- [x] Redirect stub at `<slug>/index.html` (meta refresh to the link, else the index), marked `.dev-retired`; `--prune-root` recognises it; `--unpublish` on an already-retired slug errors; `--set-link` refreshes the stub

## Details

- Storage lives in the staging repo (`.retired/<slug>`, one file per slug) rather than a single list file: parallel unpublishes by different people don't conflict, and it matches the existing per-preview `.dev-preview` marker pattern (bash 3.2-friendly `key=value`, no jq).
- Previously retired previews (removed before this change) have no record; they just won't appear. Could be backfilled by hand with `--set-link`-style entry if wanted.
- The link is supplied at unpublish time, not at publish time, since the main-site page often exists only once the PR is merged.
- Per CLAUDE.md: no inline `if` inside expressions in any new shell code; use temp variables.
- Nothing is committed/pushed to the book repo without explicit permission. Testing must not push to the real `aml4td/dev`.

## Critical files

- `previews/dev-site-lib.sh` (helpers, `dev_write_index`, `DEV_ROOT_FILES`)
- `previews/3-cleanup-dev.sh` (`--unpublish`, `--list`, arg parsing)
- `previews/2-publish-dev.sh` (clear stale retired record)
- `previews/README.md`

## Verification

Use a local bare repo as the staging remote (as in the original testing): `DEV_REMOTE=/path/to/bare.git DEV_DOMAIN= DEV_CLONE_DIR=$scratch/clone`.

1. Create a fake preview dir with a `.dev-preview` marker, push; unpublish with `--link https://aml4td.org/chapters/foo.html`; confirm directory gone, `.retired/<slug>` exists, `index.html` has both tables and the link.
2. Unpublish without `--link`: row shows em dash.
3. Bad link (`javascript:...`, with spaces) is rejected before anything is changed.
4. `--prune-root` leaves `.retired/` alone.
5. Re-publishing a retired slug removes it from the retired table.
6. `--list` shows retired entries; `bash -n` and `shellcheck` (if installed) pass on all scripts.

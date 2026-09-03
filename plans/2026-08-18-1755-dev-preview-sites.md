# Dev preview sites for the book

## Overview

Publish dev/staging versions of the book to alternate URLs, so work on a branch or PR can be reviewed as a rendered site without touching production (<https://aml4td.org>, served from `origin/gh-pages` with the `CNAME` in this repo).

Chosen approach: a **separate staging repository**, with each preview in its own subdirectory of that repo's `gh-pages` branch. Any number of previews coexist:

    previews/2-publish-dev.sh pr-123       ->  https://dev.aml4td.org/pr-123/
    previews/2-publish-dev.sh cls-linear   ->  https://dev.aml4td.org/cls-linear/
    previews/2-publish-dev.sh              ->  slug from the current branch name

The production workflow (`quarto render` then `quarto publish gh-pages --no-render`) is unchanged and unaffected.

## Work items

### Implementation (done)

- [x] Confirm GitHub Pages serves one site per repo, forcing a separate host or repo
- [x] Confirm `quarto publish gh-pages` hardcodes `origin` + `gh-pages` (no flags to redirect it)
- [x] Verify Quarto profiles can override `site-url` and disable `google-analytics`
- [x] Verify profiles cannot remove `CNAME` from `resources` (arrays concatenate)
- [x] Verify `--metadata-file` cannot set project-level `book.site-url`
- [x] Verify per-slug hyphenated profile names + `--output-dir` work together
- [x] `dev-site-lib.sh` — shared config, slug sanitiser, clone/root-file/push helpers
- [x] `2-publish-dev.sh` — render + publish one preview, with an EXIT/INT/TERM trap
- [x] `3-cleanup-dev.sh` — reset local debris; `--list`, `--unpublish`, `--all`
- [x] `.gitignore`: `/_book-dev/`, `/_quarto-dev-*.yml`
- [x] Test end-to-end against a local bare repo standing in for the staging remote

### Testbed validation (done)

Throwaway mirror at `~/content/dev-preview-testbed`, pushed to <https://github.com/topepo/dev-preview-testbed>, acting as its own staging target. Mirrors the real book's `book` project type, `chapters/` subdirectory with parts, production `site-url`, `google-analytics`, `resources: [CNAME]`, `freeze: auto` with committed `_freeze/`, and a themed HTML format. Config lives in a gitignored-by-intent `testbed-env.sh`, so the three scripts stay byte-identical to the copies here.

- [x] Production-style render matches the real book (CNAME shipped, GA on, production sitemap)
- [x] Preview render: no CNAME, 0 `gtag` hits, preview `site-url`, figures and nested chapter paths intact
- [x] `_freeze/` reused across a dev render (0 changed files — R chunk not re-executed)
- [x] Pages auto-enabled on `gh-pages` push; verified `source: gh-pages /`, `https_enforced: true`
- [x] Live: root index, preview pages, nested chapter, figure PNG, `robots.txt` all 200
- [x] Two previews from different branches coexist with different content
- [x] Branch-derived slug: `feature/Fix-Typos` -> `feature-fix-typos`
- [x] `--list` and `--unpublish` verified live: retired preview 404s, the other survives, index drops it

### Bugs found and fixed during testbed validation

1. **`DEV_DOMAIN=` was ignored, causing an accidental domain claim.** `DEV_DOMAIN="${DEV_DOMAIN:-dev.aml4td.org}"` used `:-`, which substitutes the default for an *empty* value as well as an unset one. So the documented `DEV_DOMAIN= previews/2-publish-dev.sh` idiom fell back to `dev.aml4td.org` and wrote a root `CNAME` claiming it — from a throwaway repo. Caught before Pages was enabled, so `cname` stayed `null` and no claim registered. Fixed by using `${DEV_DOMAIN-dev.aml4td.org}` (no colon).
2. **Default `DEV_REMOTE` used SSH, which does not work on this machine.** `ssh -T git@github.com` gives "Permission denied (publickey)"; pushes go over HTTPS through the osxkeychain helper. Default changed to the HTTPS URL, which also matches `aml4td/website`'s own origin.
3. **`quarto publish gh-pages` in the staging repo wiped every preview.** Max ran it against the testbed, which doubles as its own staging target. It deleted both preview trees (28 files removed, 22 "renamed" as `main/x` became `x`) and unpacked the whole rendered book at the staging root, after which the index generator listed `chapters/` and `site_libs/` as previews. Three fixes: previews are now identified by a `.dev-preview` marker file rather than by being a directory; `3-cleanup-dev.sh --prune-root` removes non-preview debris from the staging root; and the README documents the repair. The root cause is specific to the testbed's single-repo shortcut — in the real setup, `gh-pages` in this repo *is* production, so running the production publish here is correct and cannot touch `aml4td/dev`.
4. **`mapfile` is bash 4+.** macOS `/usr/bin/env bash` is 3.2, so the pruning loop uses `while IFS= read -r` instead. Also avoided `$flag && continue` as a bare statement, which aborts under `set -e` when the flag is false.

### Hardening added after the incidents

- `dev_check_domain` refuses to change the staging site's custom domain (the `CNAME` at the branch root), because setting one locks that domain to the repository. Override with `DEV_ALLOW_DOMAIN_CHANGE=1`. Verified: mismatch blocked, override proceeds, first-time set allowed with a notice.
- The clone refresh and domain check moved *before* the render, so a misconfiguration fails in seconds instead of after a full book build.
- `1-setup-dev-site.sh` — read-only checker for remote, branch, Pages config, custom domain, DNS (apex A records vs subdomain CNAME), HTTPS and serving, printing the exact command or DNS record for anything missing.
- `previews/README.md` — high-level usage, why each piece exists, and recovery procedures.
- Scripts renamed to a running order: `1-setup-dev-site.sh`, `2-publish-dev.sh`, `3-cleanup-dev.sh`, plus the sourced-only `dev-site-lib.sh` (left unnumbered because it is never run).

### Interface work (done 2026-08-26)

Built and verified on the testbed (`warm-bread-coffin.org`) before pointing coauthors at `dev.aml4td.org`.

- [x] Per-preview metadata: `.dev-preview` marker now carries `slug`, `branch`, `sha`, `published`, `epoch` as `key=value` (bash 3.2 readable, no jq/python dependency). Doubles as the existing preview marker.
- [x] Preview index rebuilt as a table — preview, branch, commit, published — sorted newest first, with a lede pointing at the published book. Previews predating metadata degrade to `unknown` instead of breaking the page.
- [x] Draft banner on every preview page: sticky bar with branch, commit, a link to the published book and a link to the index; hidden in print.
- [x] Banner injected via the generated profile's inline `text:` form, so no transient HTML file exists to write, reference or clean up.
- [x] Verified `include-before-body` places the div directly inside `main#quarto-document-content` (so `position: sticky` works without fighting the docked sidebar), and moved the CSS to `include-in-header` because `<style>` is not valid inside `<main>`.
- [x] Confirmed both include keys append to, rather than replace, any base-config includes. The real book currently uses neither.

Not yet done: nobody has looked at the banner in a browser. The Chrome extension was declined, so appearance is verified structurally only.

### Real staging site (done 2026-08-26)

- [x] `aml4td/dev` created (public, `main` holds a CC BY-NC-SA license file)
- [x] DNS `CNAME dev.aml4td.org -> aml4td.github.io` — propagated before it was needed
- [x] Pages auto-enabled on the first `gh-pages` push; `source: gh-pages /`
- [x] Certificate approved ~20s after the domain was set; `https_enforced` set via the API; HTTP 301s to HTTPS
- [x] Verified production `aml4td.org` unaffected throughout
- [x] Config lives in `aml4td-dev-env.sh`, separate from the testbed's `testbed-env.sh`

Note: the DNS CNAME targets `aml4td.github.io`, so the staging repo **must** be owned by the `aml4td` org. A repo under a personal account cannot serve `dev.aml4td.org`.

### Remaining (needs Max)

- [x] Custom-domain test on `warm-bread-coffin.org` (apex at Hover). Four GitHub Pages apex A records added (apex cannot use a CNAME); `www` CNAME to `topepo.github.io`. Certificate approved ~20s after the domain was set, HTTPS at the edge ~20s later, `https_enforced` then set via the API. Verified live: apex + both previews + nested chapters + figures 200, `www` 301s to apex, HTTP 301s to HTTPS, the old `topepo.github.io` URL 301s to the custom domain, `robots.txt` disallows all, 0 `gtag` hits, per-preview `sitemap.xml` on the new host, and `/<slug>/CNAME` 404s (production CNAME correctly stripped). Root `CNAME` survives later publishes.
- [ ] Create the real staging repo: `gh repo create aml4td/dev --public`
- [ ] Enable Pages on it (or just push once — GitHub auto-enables on a `gh-pages` push)
- [ ] Add DNS `CNAME dev.aml4td.org -> aml4td.github.io` for the real staging site
- [ ] First real run: `previews/2-publish-dev.sh` on a feature branch, then check the preview loads
- [ ] Commit the three scripts + `.gitignore` change

## Design notes

### Why not `quarto publish gh-pages` for previews

`quarto publish gh-pages` pushes to `origin`'s `gh-pages` branch; both are hardcoded in the provider, with no `--remote`/`--branch` option. Production owns that slot, and GitHub Pages serves one site per repository.

`quarto publish gh-pages` wipes the published branch before writing: its `withWorktree` helper runs `git rm -r .` (`gh-pages.ts:430-435`). That is fine for production — no stale files accumulate there, contrary to an earlier note in this plan — but it means previews can never share a branch with production.

Within a preview subdirectory the scripts do the equivalent themselves, via `rsync --delete` scoped to that one directory, so a deleted chapter disappears without disturbing any other preview.

### How the per-preview config is injected

Verified with Quarto 1.9.36:

| Mechanism | Result |
|---|---|
| Profile `book.site-url` | works — sitemap, canonical, `og:url` follow |
| Profile `google-analytics: ""` | works — empty string is falsy, so no `gtag` is emitted. `null`/`false` fail schema validation |
| Profile `resources: []` to drop `CNAME` | **fails** — profile arrays are concatenated with the base config's, never replaced |
| `--metadata-file` for `book.site-url` | **fails** — only reaches *format* metadata, not project config |
| `--output-dir` | works |
| Top-level `profile:` key in `_quarto.yml` | required spelling; `project: profile:` fails validation |

So `site-url`/GA come from a generated profile file, the output directory comes from a flag, and `CNAME` is deleted from the render output before syncing. That last one matters: a `CNAME` naming `aml4td.org` inside the staging repo would make it try to claim the production domain and break one of the two sites.

`_quarto.yml` needs **no changes** — a dev profile is inert unless `QUARTO_PROFILE` names it, so `quarto render` and `quarto publish gh-pages` behave exactly as before.

### Interrupt safety

`2-publish-dev.sh` traps `EXIT INT TERM` and deletes its generated profile, so Ctrl-C and failed renders clean up after themselves. A `kill -9` can still leave three things behind, and all three are handled:

1. stale `_quarto-dev-<slug>.yml` — inert (nothing sets `QUARTO_PROFILE` to it); removed by `3-cleanup-dev.sh`
2. partial `_book-dev/<slug>/` — overwritten by the next render
3. dirty staging clone, possibly with an unpushed commit — the next run does `fetch` + `reset --hard` + **`git clean -fdx`**. The clean is the essential part: `reset --hard` restores only tracked files, so a half-finished `rsync` would otherwise leave untracked junk for `git add -A` to commit.

Tested by planting exactly that debris (including an unpushed junk commit) and confirming none of it reached the remote.

`_freeze/` is deliberately **not** reverted. A dev render can update it, it is tracked, and those are real computed results — `3-cleanup-dev.sh` reports the change and leaves the call to Max.

### Rejected alternatives

- **Netlify / Cloudflare Pages branch aliases** — least friction, unlimited preview URLs, but adds a vendor. Still the best fallback if the GitHub route becomes annoying.
- **`dev/` subdirectory of production's own `gh-pages`** — **impossible**, not merely undesirable. An early reading of the provider (the `copy` + `git add -Af .` at `gh-pages.ts:240-248`) suggested the publish was additive and would leave a `dev/` subtree alone. It is not: `withWorktree` runs `git rm -r .` first (`gh-pages.ts:430-435`, commented "remove files in existing site, i.e. start clean"), so every production publish deletes anything else on the branch. Proven live — see incident 3 below.
- **Quarto Pub** — fine for throwaway one-off shares, not a durable staging site.
- **Temporarily editing `_quarto.yml` and restoring it in a trap** — an interrupted run leaves a mutated tracked config, risking a committed dev `site-url` or a production publish with dev settings. Profiles achieve the same thing with no window of inconsistency.

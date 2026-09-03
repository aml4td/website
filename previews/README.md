# Dev previews

Publish a work-in-progress version of the book to <https://dev.aml4td.org> so a branch can be reviewed as a real rendered site. Each preview lives in its own subdirectory, several can be live at once, and none of them touch production.

Production is unchanged and unaffected. It is still:

```sh
quarto render
quarto publish gh-pages --no-render     # -> https://aml4td.org
```

## Quick reference

Every command runs from the **project root**. There is nothing to source or configure — the committed defaults already point at `aml4td/dev` and `dev.aml4td.org`.

```sh
previews/2-publish-dev.sh svm-review     # create or update a preview
previews/2-publish-dev.sh                # ...named after the current branch
previews/3-cleanup-dev.sh --list         # what is published right now
previews/3-cleanup-dev.sh --unpublish svm-review    # retire one
previews/1-setup-dev-site.sh             # health check when something looks wrong
```

| File | What it is |
|---|---|
| `1-setup-dev-site.sh` | Read-only checker: repo, branch, Pages, domain, DNS, HTTPS, serving. Prints the exact fix for anything missing. |
| `2-publish-dev.sh` | The everyday command. Renders the current branch and publishes it as one preview. |
| `3-cleanup-dev.sh` | Retire previews, list them, repair the staging site, clear local debris. |
| `dev-site-lib.sh` | Shared config and helpers. Sourced by the others, never run directly. |

---

## Create a new preview

```sh
git checkout svm-cls-linear
previews/2-publish-dev.sh svm-review
```

Result: <https://dev.aml4td.org/svm-review/>

**The slug is both the URL path and the directory name.** Pass it explicitly when you want a stable link to send someone; omit it and the current branch name is used.

```sh
previews/2-publish-dev.sh                # slug = current branch, sanitised
previews/2-publish-dev.sh pr-123         # slug = pr-123
```

Slugs are lowercased with anything outside `[a-z0-9._-]` collapsed to a dash, so `feature/Fix-Typos` becomes `feature-fix-typos`. That also defuses path tricks before the value is used to build a path.

Choosing a slug is worth a moment's thought. A branch-named preview follows that branch forever, which is usually right for your own work. An explicitly named one (`svm-review`, `kjell-ch12`) gives a link whose meaning does not change even if the branch is later renamed.

| Option | Effect |
|---|---|
| `[slug]` | Positional argument. Defaults to the current branch name. |
| `DEV_ALLOW_DOMAIN_CHANGE=1` | Only needed when deliberately repointing the staging domain. See below. |

Two behaviours to know. It renders the **working tree**, so uncommitted edits show up in the preview — but the commit recorded in the banner is the last commit, so a preview of uncommitted work is labelled with the previous sha. And to preview someone else's PR: `gh pr checkout 123 && previews/2-publish-dev.sh pr-123`.

Measured on the real book: about **2 minutes** to publish, another **30 seconds** before Pages serves it. A render that reuses `_freeze` entirely takes about 1m30s.

---

## Update an existing preview

Same command, same slug:

```sh
previews/2-publish-dev.sh svm-review
```

The preview is **replaced in place**. Nothing accumulates — no second directory, no duplicate row on the index, no `svm-review-2`. Anyone holding the link sees the new build once Pages rebuilds, without needing a new URL.

What updating does:

- **Removes stale files.** The sync is `rsync --delete` scoped to that one subdirectory, so a deleted chapter's page disappears from the preview.
- **Leaves other previews alone.** Only the slug you name changes.
- **Updates the index row rather than adding one** — branch, commit and timestamp for that slug are rewritten.
- **May change `_freeze/`.** If the branch altered R code, the render re-executes it and rewrites tracked files under `_freeze/`. The script prints exactly which, and leaves them alone, because they are real computed results. Commit them onto the branch if they belong there, or `git checkout -- _freeze && git clean -fd _freeze`.

One quirk: republishing the *same commit* still produces a commit on the staging branch. Quarto emits HTML attributes in a non-deterministic order, so two renders of identical sources differ by a few dozen lines of reordered attributes. Harmless — but it means the "no changes to publish" message essentially never appears for this book.

If a reviewer needs a URL that stays **frozen** while they read, publish a second slug instead of updating the one you sent them.

---

## Remove a preview

```sh
previews/3-cleanup-dev.sh --unpublish svm-review
```

The directory is deleted from the staging site, the index is rewritten in the same commit so it never links to something gone, and that preview's local output under `_book-dev/` is removed too. The URL 404s once Pages rebuilds, usually within 30 seconds.

| Option | Effect |
|---|---|
| `--unpublish <slug>` | Retire one preview. Errors if no preview by that name is published. |
| `--list` | Show what is published, if you are unsure of the slug. |

Worth doing when a branch merges or an experiment is abandoned: previews are not free (see Capacity), and a stale preview that still looks like the book is a hazard. There is no bulk remove — removing several means running it several times, deliberately.

---

## See what is published

```sh
previews/3-cleanup-dev.sh --list
```

```
Previews on https://dev.aml4td.org/ :
  svm-review               https://dev.aml4td.org/svm-review/
  svm-cls-linear           https://dev.aml4td.org/svm-cls-linear/
```

The same information, plus branch and commit, is on the site itself at <https://dev.aml4td.org/>. That page is regenerated on every publish and is `noindex`.

---

## Check the setup

```sh
previews/1-setup-dev-site.sh
```

Read-only: it never creates a repo, changes DNS, or pushes. It checks, in dependency order, config coherence, that the staging repo exists and is reachable, that the staging branch exists, Pages configuration, the custom domain against `DEV_DOMAIN`, DNS records (an apex needs four A records, a subdomain needs a CNAME), HTTPS enforcement, and whether the site actually serves. For anything missing it prints the exact `gh` command or DNS record.

Run it first on a new machine, and any time the staging site misbehaves.

---

## Clear local debris

The publisher cleans up after itself on Ctrl-C or a failed render. A hard kill can leave a stale profile, which is inert but untidy.

| Option | Effect |
|---|---|
| *(none)* | Remove stale `_quarto-dev-*.yml` profiles; report on everything else without deleting. Safe default. |
| `--outputs` | Also delete `_book-dev/`. Costs a full re-render next time. |
| `--clone` | Also delete the staging clone. Costs a full re-clone next time. |
| `--all` | Both of the above. |
| `--prune-root` | Repair the staging site: delete anything at its root that is neither a preview nor a known root file. |
| `-h`, `--help` | Print usage. |

Nothing here touches production's `_book/`, and `_freeze/` is only ever reported on, never reverted.

---

## Capacity

Each preview is a **complete, independent copy of the book**. That is what lets it stand alone, and what makes it cost something.

| | |
|---|---|
| One rendered site | 184 MB, of which 140 MB is the shinylive runtime |
| GitHub Pages limit | 1 GB per site |
| Practical maximum | about **5 previews** live at once |
| Local disk per preview | ~368 MB (once in `_book-dev/<slug>/`, once in the staging clone) |

The staging **repository** is far cheaper than that arithmetic suggests, because git stores identical files once: two full previews plus three republishes left it at 140.6 MB total. The 1 GB ceiling applies to the *served* site, not the repo.

If the staging repo's history ever gets unwieldy it is disposable — squash `gh-pages` to a single commit, or delete and recreate the repo. That is the main reason previews live in `aml4td/dev` rather than here.

---

## Configuration

The defaults at the top of `dev-site-lib.sh` are correct for this repository, so normal use needs no configuration at all. Everything is an environment variable, so a different staging site can be targeted inline without editing anything:

```sh
DEV_REMOTE=https://github.com/me/scratch.git DEV_DOMAIN=preview.example.org previews/2-publish-dev.sh
```

| Variable | Default | Meaning |
|---|---|---|
| `DEV_REMOTE` | `https://github.com/aml4td/dev.git` | Staging repository. **Not** this book's origin. |
| `DEV_DOMAIN` | `dev.aml4td.org` | Custom domain. Empty serves from the `github.io` address. |
| `DEV_BASE_URL` | `https://$DEV_DOMAIN` | Public root of the staging site. |
| `DEV_BRANCH` | `gh-pages` | Branch Pages serves in the staging repo. |
| `DEV_CLONE_DIR` | `~/.cache/aml4td-dev-pages` | Working clone, kept outside the project so pushes stay incremental. |
| `DEV_OUT_ROOT` | `_book-dev` | Where dev renders go. Git-ignored. |
| `DEV_PROD_URL` | `https://aml4td.org` | Link target in the banner and on the index. |
| `DEV_PROD_NAME` | `aml4td.org` | Link text for the same. |
| `DEV_ALLOW_DOMAIN_CHANGE` | `0` | Set to `1` to permit changing the staging domain. |

Do not point `DEV_CLONE_DIR` at a checkout you work in. The publisher runs `git reset --hard` and `git clean -fdx` on it before every run — that is what makes an interrupted publish recoverable, and what would destroy uncommitted work.

---

## What a preview looks like

Every page carries a sticky bar at the top of the content column: **Draft preview**, the branch and commit it was built from, a link to the published book, and a link to the preview index. It is hidden when printing.

This matters because a preview is otherwise a pixel-perfect copy of the published book. Someone sent a deep link has no other way to tell they are reading a draft, and a preview URL that leaks into a citation is worse.

Previews also carry `robots.txt` with `Disallow: /` and have Google Analytics switched off, so they neither compete with production in search results nor pollute the analytics property. They remain **publicly readable** by anyone with the link — this is not access control.

---

## Things that will go wrong

### "Refusing to change the staging site's custom domain"

Something set `DEV_DOMAIN` to a value other than the published one — usually a stale override left in the shell from targeting a test site, or these scripts copied into another project. Check with `echo $DEV_DOMAIN`; `unset DEV_DOMAIN` restores the committed default.

The guard exists because the `CNAME` file at the staging root is what tells Pages which host to serve, and **setting it locks that domain to that repository** until released. A wrong value both breaks the staging site and squats a hostname the right repo can then no longer use. If the change really is intended:

```sh
DEV_ALLOW_DOMAIN_CHANGE=1 previews/2-publish-dev.sh <slug>
```

### Previews vanished, or `chapters/` appears as a preview

Someone ran `quarto publish gh-pages` inside the **staging** repo. That wipes the branch it publishes to and unpacks a whole rendered book at the root, deleting every preview.

```sh
previews/3-cleanup-dev.sh --prune-root      # clear the book files from the root
previews/2-publish-dev.sh <slug>            # re-publish each preview still wanted
```

This cannot happen from *this* repository, where `gh-pages` is production and that command is the correct thing to run.

### The preview looks stale

Pages caches hard — hard-refresh first. If it is still wrong, check the push landed with `--list`, and compare the commit in the banner against what you expect.

### "This looks like the staging repository, not the book"

You are in a checkout of `aml4td/dev` rather than `aml4td/website`. Previews are published *from* the book *to* the staging repo. Run it from the book checkout.

### "Push to gh-pages was rejected"

Someone else published while your render was running. The script already retries once automatically after re-syncing; this message means the retry also lost the race. Re-run the same command — the render is cached, so it takes seconds.

### "Could not reach the staging repository"

A network or DNS failure, usually transient. Nothing was changed, so just run the same command again. If it persists, check `git ls-remote https://github.com/aml4td/dev.git` — the message quotes git's own error, which distinguishes a name-resolution problem from an authentication one.

### An interrupted publish

The publisher traps `EXIT`, `INT` and `TERM`, so Ctrl-C and failed renders clean up after themselves. A `kill -9` can leave a stale `_quarto-dev-<slug>.yml` (inert — nothing sets `QUARTO_PROFILE` to it), a partial `_book-dev/<slug>/` (overwritten next render), or a dirty staging clone (reset and cleaned before the next run). `previews/3-cleanup-dev.sh` tidies all of it.

---

## Why this exists instead of `quarto publish`

`quarto publish gh-pages` always pushes to *origin's* `gh-pages` branch — both hardcoded, with no flag to redirect them. Production owns that slot, and Pages serves exactly one site per repository, so previews need a different repo.

It also **wipes the branch before writing** (`git rm -r .` in its worktree helper), so previews could never share a branch with production even as a subdirectory: every production publish would delete them.

Per-preview settings come from a generated Quarto profile, because that is the only mechanism reaching project-level config — `--metadata-file` lands only in *format* metadata and cannot set `book.site-url`. The profile sets `site-url`, blanks `google-analytics`, and carries the banner. `_quarto.yml` needs no changes at all: a profile is inert unless `QUARTO_PROFILE` names it.

One thing a profile cannot do is remove `CNAME` from `resources:` — profile arrays are concatenated with the base config's, never replaced — so the production `CNAME` is deleted from the render output instead. Without that, the staging repo would try to claim `aml4td.org`.

---

## Setting up a new staging site

1. Create the repo in the **`aml4td` org**: `gh repo create aml4td/dev --public`. It must be org-owned, because the DNS CNAME targets `aml4td.github.io`; a personal repo cannot serve `dev.aml4td.org`.
2. Publish once. That creates `gh-pages`, and GitHub enables Pages automatically when the branch appears.
3. Add DNS. A subdomain needs one `CNAME` to `aml4td.github.io.`; an apex domain needs four `A` records to `185.199.108–111.153`, because a zone apex cannot be a CNAME.
4. Publish again, so the root `CNAME` file is written.
5. Run `previews/1-setup-dev-site.sh` and fix anything flagged. The certificate arrives within a few minutes; HTTPS enforcement is last.

Worth doing eventually: verify `aml4td.org` at the org level (Settings → Pages → "Verify a domain") so no repo outside the org can claim `*.aml4td.org`.

---

## Notes

- The scripts target **bash 3.2**, what macOS ships. No `jq` or `python3` dependency.
- Preview metadata lives in a `.dev-preview` file inside each preview directory, as `key=value`. It doubles as the marker identifying a directory as a preview, so stray directories are never advertised on the index.
- Concurrent publishes are handled: the push is never forced, and a rejection triggers one automatic re-sync-and-retry rather than overwriting whatever landed first.
- Design decisions, rejected alternatives and the full validation record are in `plans/2026-08-18-1755-dev-preview-sites.md`.

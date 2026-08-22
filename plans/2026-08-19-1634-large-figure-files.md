# Shrink the oversized SVG figures

Issue: https://github.com/aml4td/website/issues/127

## Overview

The rendered book is **342 MB**, of which **181 MB is SVG figures** across 145
files. A handful of dense plots dominate: five figures in
`chapters/cls-neural-nets.qmd` account for 101 MB on their own, and two of them
are 32.8 MB each.

Cause: `R/_common.R:196` sets `dev = 'svg'` for all HTML output, which resolves
to `grDevices::svg()` (cairo), not `svglite`. Cairo SVG emits one `<path>` per
drawn mark *and* one per text glyph, so plots with tens of thousands of marks
balloon while simple line charts stay small. Measured:

| figure | raw | gzipped | `<path>` count |
|---|---|---|---|
| `fig-sgd` | 32.8 MB | 2.7 MB | 160,167 |
| `fig-schedulers` | 32.8 MB | 2.7 MB | 160,159 |
| `fig-ames-missing` | 14.0 MB | 0.95 MB | 68,324 |
| `stationary` | 8.0 MB | 0.73 MB | 40,112 |
| `fig-cal-curves` | 4.4 MB | 0.22 MB | 23,265 |

For comparison, the 18 PNG files in the book total 2.3 MB.

Why it matters:

1. **Repository size is the sharpest cost.** `_freeze/` is tracked in git (only
   `_book/`, `_site/`, `_cache/`, `figures/` are ignored). `_freeze` is 186 MB
   with 125 tracked SVGs, and `.git` is **2.3 GB**. Every re-render commits a
   fresh ~33 MB blob per big figure, and `gh-pages` lives in the same repo.
2. GitHub Pages caps a published site at 1 GB; production is at 342 MB.
3. Dev previews each need a full second copy of the site.
4. Bandwidth is a smaller problem than it first appears: Pages gzips SVG on the
   wire and these compress ~12x, so `cls-neural-nets.html` transfers roughly
   9 MB of figures, not 105 MB. Points 1-3 are the real motivation.

Two distinct size mechanisms, both fixed by the same change:

- **Dense `geom_tile` grids.** `stationary`, `fig-schedulers` and `fig-sgd` all
  draw the 200x200 `loss_grid` from `R/setup_2D_GD.R:40-52` via
  `base_sgd_plot()` (`R/setup_2D_GD.R:84-112`); the latter two facet it 4x for
  ~160,000 rects each. Also `fig-nnet-ex-layer-1`/`-2` (100x100 grid over 8 and
  6 panels) and `fig-split-interactions` (2 x 100x100).
- **Per-observation layers.** `geom_rug` (the four `cls-metrics` calibration
  figures, `fig-nb-probs`, the three `numeric-predictors` figures,
  `fig-ames-splitting`), dense `geom_point` (`longitude-residuals-lab`,
  `fig-lin-reg-interactions`, `fig-ames-lot-living-area`), 1,000-profile PDP
  `geom_line` (`fig-longitude-pdp`, `fig-ensemble-pdp`), and `geom_step` ROC
  curves with one vertex per unique prediction (`fig-forest-logistic-diag`,
  `fig-forest-cart-diag`).

## Decision: extend the existing `ragg_png` convention

Add `#| dev: "ragg_png"` to the offending chunk headers. **This is already the
house pattern**, used in ten chunks: `chapters/whole-game.qmd` (six figures),
`chapters/cls-linear.qmd:113` (`fig-cls-boundaries`), `chapters/embeddings.qmd`
(`fig-mds-example`, plus two chunks using bare `dev: png`).

Why this over the alternatives:

- **No new dependency.** `ragg` 1.5.2 is already in `DESCRIPTION` `Imports`.
  `ggrastr` is not installed, and rasterising individual layers would mean
  hand-editing inside 22 plots' layer stacks for a marginal gain on the two
  figures that have delicate text.
- **No `dpi:` needed.** The existing `ragg_png` chunks set none; Quarto's
  default `fig-dpi: 96` times knitr's `fig.retina: 2` gives 192 effective dpi.
  `fig-delivery-hist` renders 1728x816 px in 48 KB with crisp type.
- **No PDF target to degrade.** `_quarto.yml` declares only `format: html`; the
  `is_tex` branch at `R/_common.R:201-213` is unreachable today.
- **Transparency survives.** `dev.args = list(bg = "transparent")`
  (`R/_common.R:197`) is honoured by `ragg::agg_png`, and the existing
  `ragg_png` figures already rely on it. Moot anyway: the site ships a single
  light theme and `thm_dk` is used in zero chapters.
- **Nothing post-processes SVG.** `h2rgb()` (`R/_themes.R:14`,
  `R/_themes_ggplot.R:16`), commented "a helper for postprocessing svg files",
  has no callers. `includes/aml4td.scss` references SVG only for icon URLs.

Rejected:

- Switching `R/_common.R:196` globally. It would rasterise ~120 small figures
  where SVG is cheaper and sharper, and would invalidate all 27 `_freeze`
  entries, forcing a full-book re-render (the `embeddings` knitr cache alone is
  4.7 GB).
- Shrinking `R/setup_2D_GD.R:40-41` from 200 to 100 grid points. It would fix
  three figures in one edit, but it changes the stationary-point coordinates
  quoted in inline text at `chapters/cls-neural-nets.qmd:504` -- changing the
  book's content to solve a file-size problem.
- `geom_raster()` for `geom_tile()`, which cairo embeds as a single `<image>`
  and so keeps text vector. Elegant, but it only helps the six tile-based
  figures and would leave two mechanisms in the codebase. Worth revisiting only
  if raster type turns out to bother us.

## Work items

Scope: every generated figure at or above 1 MB -- 22 figures across 9 chapters,
~160 MB of SVG.

- [x] Decide the approach (per-figure `#| dev: "ragg_png"`)
- [x] `chapters/cls-neural-nets.qmd` -- `fig-nnet-ex-layer-1`,
      `fig-nnet-ex-layer-2`, `stationary`, `fig-schedulers`, `fig-sgd` (101.5 MB)
- [x] `chapters/missing-data.qmd` -- `fig-ames-missing` (14.0 MB)
- [x] `chapters/cls-metrics.qmd` -- `fig-cal-break-curves`, `fig-cal-curves`,
      `fig-re-cal-curves`, `fig-recal-iso-curves` (16.9 MB)
- [x] `chapters/cls-linear.qmd` -- `fig-forest-logistic-diag`,
      `longitude-residuals-lab`, `fig-longitude-pdp` (8.0 MB)
- [x] `chapters/cls-trees.qmd` -- `fig-split-interactions`,
      `fig-forest-cart-diag` (5.8 MB)
- [x] `chapters/numeric-predictors.qmd` -- `fig-ames-lot-area`,
      `fig-standardization`, `fig-ames-lot-living-area` (4.9 MB)
- [x] `chapters/interactions-nonlinear.qmd` -- `fig-lin-reg-interactions`,
      `fig-ensemble-pdp` (4.7 MB)
- [x] `chapters/cls-nonlinear.qmd` -- `fig-nb-probs` (2.8 MB)
- [x] `chapters/initial-data-splitting.qmd` -- `fig-ames-splitting` (1.5 MB)
- [x] Re-render each touched chapter
- [x] Remove the stale `_freeze/chapters/*/figure-html/*.svg` left behind by the
      device switch
- [x] Confirm the regenerated PNGs read well at publication size. All 22 were
      inspected individually. Both figures flagged as text-sensitive pass at the
      default 192 dpi with no change needed: the `geom_label_repel`
      "under-estimated"/"over-estimated" callouts in `fig-cal-break-curves` are
      sharp, and every variable-importance label in `fig-forest-cart-diag` (down
      to "annual minimum temperature") is legible. No `dpi:` overrides were
      required anywhere.
- [x] Re-measure `_book` and `_freeze`, record below
- [x] Open a PR referencing #127 -- https://github.com/aml4td/website/pull/128

## Deferred

- **`chapters/reg-metrics.qmd` / `fig-mars-cal-plot` (4.2 MB).** That file does
  not exist on `main` or on this branch -- it lives only on `reg-metrics-data`
  (added in `b92c9e5`) and is not in the `_quarto.yml` chapter list. The copy in
  `_book` is a stale render. Give it the same treatment when that branch merges.
- **`premade/anime_barley_pca.gif` (3.8 MB)** is a checked-in static asset, not
  generated, so no chunk option affects it.
- **`chapters/embeddings.qmd:436, 1173`** use bare `#| dev: png` rather than
  `"ragg_png"`. Normalising them is cosmetic and would trigger a re-render of
  the most expensive chapter in the book, so it is left alone.

## Traps found while planning

- `chapters/cls-linear.qmd` -- the `map-residuals-lab` chunk sits in the *same*
  `::: {#fig-longitude-residuals}` div as `longitude-residuals-lab` but is a
  `leaflet()` htmlwidget. It must not get a `dev:` option.
- `stationary` and `longitude-residuals-lab` take their captions from
  surrounding `:::` divs, so they have no `fig-cap` and no `fig-` prefix. That
  is intentional.
- `fig-ames-splitting` sets no `fig-width`/`out-width`, so it inherits the
  global `fig.width = 10` (`R/_common.R:193`).
- `fig-nnet-ex-layer-2` reuses the `relu_layer` object built inside the
  `fig-nnet-ex-layer-1` chunk, so the chapter must be rendered whole.
- `numeric-predictors` and `initial-data-splitting` have no populated knitr
  cache and re-execute fully. Their splits load from `RData/`, so results should
  be stable, but the rendered diff needs a check for inline numeric drift.

## Possible follow-ups

- **`dev = "svglite"` globally.** `svglite` 2.2.2 is already installed as a
  transitive dependency and emits real `<text>` plus terser markup instead of
  cairo's per-glyph paths, which would shrink the ~60 MB spread across the ~120
  remaining SVGs *while keeping them vector*. But it shifts font metrics (so
  layouts can move), does not support every cairo feature, and invalidates all
  27 `_freeze` entries.
- **Reclaiming `.git` is *not* a figure problem.** Git is append-only, so
  deleting these SVGs does not shrink `.git` -- earlier commits still reference
  the blobs. But measuring the pack shows figures were never the bulk of it. Of
  2.11 GB of blob data: `RData/*.RData` + `*.Rdata` is **1.47 GB (70%, 306
  blobs)**, `.tgz` 221 MB, `.data` 122 MB, `.gz` 103 MB, `.gif` 54 MB, and
  **every `.svg` ever committed is 46 MB (2%, 419 blobs)** -- the 22 figures
  converted here are only 21.3 MB across 37 historical versions, since git
  compresses text SVG ~12x and deltas successive re-renders well.

  The cost driver is `RData/`: gzip-compressed R serializations that git can
  neither compress nor delta, so each re-save stores a full fresh copy
  (`forest_logistic_set_res.Rdata` alone is 6 versions x ~34.5 MB = 207 MB;
  `forested_obl_set_res.RData` is 8 x ~18 MB = 144 MB). A `git filter-repo`
  pass aimed at figures would reclaim ~2%; aimed at `RData/` it would reclaim
  ~1.4 GB, but those files are load-bearing inputs at HEAD (212 MB in the
  working tree), so that needs its own issue and a real plan.

  What this change *does* fix is the growth rate: re-rendering a chapter no
  longer appends tens of MB of figure blobs per pass. It is also why the
  `RData/` rewrites were left out of this commit -- adding ~37 MB of
  undeltifiable blobs is exactly the pattern that accumulated the 1.47 GB.

## Results

| | before | after |
|---|---|---|
| `_book` | 342 MB | **184 MB** |
| `_freeze` (tracked in git) | 186 MB | **28 MB** |
| SVG in `_book` | 181 MB / 145 files | 26 MB / 121 files |
| PNG in `_book` | 2.3 MB / 18 files | 5.2 MB / 40 files |

The 22 converted figures went from **160 MB to 2.6 MB**. Nothing at or above
1 MB remains in `_book` apart from the two known exclusions: the stale
`reg-metrics` render (4.2 MB, not on this branch) and
`premade/anime_barley_pca.gif` (3.8 MB, a checked-in asset).

| figure | before | after |
|---|---|---|
| `fig-sgd` | 32.8 MB | 144 KB |
| `fig-schedulers` | 32.8 MB | 145 KB |
| `fig-nnet-ex-layer-1` | 16.0 MB | 114 KB |
| `fig-ames-missing` | 14.0 MB | 72 KB |
| `fig-nnet-ex-layer-2` | 11.9 MB | 81 KB |
| `stationary` | 8.0 MB | 124 KB |
| `fig-cal-curves` | 4.4 MB | 83 KB |
| `fig-re-cal-curves` | 4.4 MB | 83 KB |
| `fig-recal-iso-curves` | 4.2 MB | 87 KB |
| `fig-split-interactions` | 4.2 MB | 63 KB |
| `longitude-residuals-lab` | 4.0 MB | 383 KB |
| `fig-cal-break-curves` | 3.9 MB | 77 KB |
| `fig-nb-probs` | 2.8 MB | 84 KB |
| `fig-ensemble-pdp` | 2.5 MB | 180 KB |
| `fig-ames-lot-area` | 2.4 MB | 88 KB |
| `fig-longitude-pdp` | 2.2 MB | 512 KB |
| `fig-lin-reg-interactions` | 2.2 MB | 163 KB |
| `fig-forest-logistic-diag` | 1.8 MB | 81 KB |
| `fig-forest-cart-diag` | 1.6 MB | 111 KB |
| `fig-ames-splitting` | 1.5 MB | 88 KB |
| `fig-standardization` | 1.3 MB | 48 KB |
| `fig-ames-lot-living-area` | 1.2 MB | 152 KB |

## Verification notes

- **No text or numeric drift.** The rendered markdown in each chapter's
  `_freeze/.../execute-results/html.json` was diffed against `HEAD`. Every
  change is either a `.svg` -> `.png` figure path or a `gt`/Reactable table's
  regenerated random CSS id. One genuine prose change appeared in `cls-metrics`
  ("zero meaning chance agreement" -> "zero meaning no agreement"): that edit
  landed in `3f657ea` (typos and fixes, #125) but its `_freeze` was never
  re-rendered, so this work brings the frozen output back in sync with the
  committed source.
- **`fig-ames-missing` fidelity check.** This figure packs 2,930 properties into
  ~1,500 px, so the old SVG was rasterised at matched width and a magnified crop
  compared against the new PNG. Every missingness stripe is in the same place;
  the only difference is that `ragg` renders them at full saturation where cairo
  washed them out. No information lost, so no dpi increase was needed.
- **`fig-ensemble-pdp` legend clipping.** Panel (d)'s collected legend clips
  "Sun" at the right edge. Comparing against a raster of the old SVG confirms
  this is pre-existing and not caused by the device change.
- **Reference integrity.** All 85 figure references across the nine touched
  chapters resolve to files that exist, and the `leaflet` htmlwidget in
  `cls-linear` is untouched.

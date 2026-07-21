# nemitheasura.github.io

Personal and academic website for **Natalia Gumińska, PhD** — RNA biology,
nanopore direct RNA sequencing, and research software. Built with
[Quarto](https://quarto.org), deployed to GitHub Pages by GitHub Actions.

No CDN, no analytics, no tracker, no web fonts. The site is static HTML and CSS
plus about 90 lines of vanilla JavaScript for a scroll reveal, an image lightbox
and a year stamp.

---

## Quick start

```bash
quarto preview          # live-reloading dev server on http://localhost:4200
quarto render           # one-off build into _site/
```

Quarto 1.5 or newer is the only requirement. There are no executable code cells,
so R and Python are **not** needed to build the site.

If Quarto is not on `PATH` but RStudio is installed, it ships a copy:

```powershell
& "C:\Program Files\RStudio\resources\app\bin\quarto\bin\quarto.exe" preview
```

## Project structure

```
.
├── _quarto.yml                    site config: navigation, theme, SEO
├── _variables.yml                 name, email, social URLs; use {{< var key >}}
├── index.qmd                      Home
├── about.qmd                      Biography, education, grants, awards
├── software.qmd                   Projects and technical case studies
├── stack.qmd                      Technology stack with proficiency levels
├── side-quests.qmd                Hobby projects and experiments
├── contact.qmd                    Contact links
├── 404.qmd
├── publications/
│   ├── index.qmd                  Filterable listing + conference talks
│   ├── publications.yml           THE PUBLICATION DATA — edit this
│   └── references.bib             optional BibTeX source
├── illustrations/index.qmd        Gallery with lightbox
├── cv/
│   ├── index.qmd                  Web CV
│   └── cv.qmd                     Print CV → Natalia-Guminska-CV.pdf (Typst)
├── styles/
│   ├── theme-light.scss           light palette tokens
│   ├── theme-dark.scss            dark palette tokens
│   └── custom.scss                all component rules, theme-agnostic
├── assets/
│   ├── head.html                  SEO meta + JSON-LD Person record
│   ├── scripts.html               reveal observer, lightbox, year stamp
│   └── img/                       favicon, logo, portrait, OG, gallery
├── scripts/
│   ├── make-placeholders.sh       regenerate placeholder artwork
│   └── generate-publications.R    references.bib → publications.yml
└── .github/workflows/publish.yml
```

## Before this goes live

The site builds and looks finished, but the following are placeholders.

- [ ] **Replace `assets/img/profile.svg`** with a real portrait
      (`profile.jpg` is fine — update the `src` in `index.qmd`).
- [ ] **Export `assets/img/og-image.png` at 1200×630.** `assets/head.html`
      points at the PNG; only the SVG exists, and social platforms will not
      render an SVG preview card.
- [ ] **Fill in `publications/publications.yml`.** Six real entries are there;
      the CV claims 17. There is one clearly marked placeholder entry to
      replace or delete. Several entries are missing DOIs.
- [ ] **Fix the conference talk titles** in `publications/index.qmd`. They were
      reconstructed from the award list and are almost certainly not the
      submitted titles.
- [ ] **Check the proficiency levels on `stack.qmd`.** They are my best guess
      from your CV and project history, not your self-assessment. Each row has a
      `--level: N` between 1 and 5.
- [ ] **Replace the gallery images** in `assets/img/illustrations/`.
- [ ] **Verify the three case studies in `software.qmd`.** They are written from
      what the codebase implies. If any detail is wrong, it is wrong in the most
      visible place on the site.

## Editing

**Personal details.** `_variables.yml` holds name, email and social URLs;
reference them anywhere as `{{< var email >}}`. Navigation and site URL live in
`_quarto.yml`. The JSON-LD block in `assets/head.html` duplicates some of this
and must be updated by hand — Quarto variables do not expand inside included
HTML partials.

**Publications.** Append to `publications/publications.yml`:

```yaml
- title: "Paper title"
  author: "Gumińska N., et al."
  date: "2025-01-01"           # only the year is shown; sorts within a year
  journal: "Nature"
  doi: "10.1038/..."
  path: "https://doi.org/10.1038/..."
  categories: [First author, Journal article, Nanopore, "poly(A)"]
  description: "One plain-language sentence."
```

Categories drive the filter chips. Keep the vocabulary small and reuse existing
terms; every new term adds a chip. Note that `poly(A)` must be quoted in YAML.

If you prefer to maintain BibTeX, keep `references.bib` current and run
`Rscript scripts/generate-publications.R --dry-run`, then without the flag.
It needs `RefManageR` and `yaml`, and **it overwrites hand-written
`description` fields** — BibTeX has nowhere to store them.

**Colours.** Every colour is a token in `styles/theme-light.scss` and
`styles/theme-dark.scss`. `custom.scss` contains no hex values at all, only
`var()` references, so changing `--accent` in both token files re-skins the
whole site and dark mode stays consistent by construction.

**Images.** Regenerate placeholders with `bash scripts/make-placeholders.sh`.
Keep the filenames; the pages reference them directly.

**Gallery.** Each item in `illustrations/index.qmd` is an `<a data-lightbox>`
wrapping an `<img>` and a `<figcaption>`. `href` is the full-size image, `src`
the thumbnail. Always set `width` and `height` so the layout does not shift
while images load, and write `alt` text that describes the image rather than
repeating the title.

**Stack page.** Each row carries `style="--level: N"` where N is 1–5. The bar
and the `aria-label` are independent — **change both together**, or screen
reader users get the old number.

**Adding a page.** Create `newpage.qmd` with a `title` in the front matter, then
add it to `website.navbar.left` in `_quarto.yml`.

**CV PDF.** `cv/cv.qmd` renders to `cv/Natalia-Guminska-CV.pdf` via Quarto's
bundled Typst engine — no LaTeX. To publish a hand-made PDF instead, put it in
`cv/` under that filename and delete `cv/cv.qmd`. The web CV (`cv/index.qmd`)
and the print CV duplicate content deliberately: they need different pacing.
**They will drift.** Update both.

## Deploying

1. Push to a GitHub repository. For a **user site**, name the repo
   `nemitheasura.github.io`. For a **project site**, set `site-url` in
   `_quarto.yml` to `https://nemitheasura.github.io/<repo>`, update the sitemap
   URL in `robots.txt`, and prefix the root-absolute links in `404.qmd` with
   `/<repo>`.
2. Repository → Settings → Pages → Build and deployment → Source =
   **GitHub Actions**.
3. Push to `main`. `.github/workflows/publish.yml` renders and deploys.

The Quarto version in the workflow is pinned. Bump it deliberately rather than
using `release`, so a Quarto update cannot change the site without a commit.

## Design notes

The palette descends from the [ninetails](https://lrb-iimcb.github.io/ninetails/)
documentation site (`#2C7BB6`), pushed cooler and deeper. Amber (`--signal`) is
reserved: it marks the one thing on a page that differs from everything around
it, which is what a non-adenosine residue is in a poly(A) tail.

The hero carries the site's one piece of ornament — an SVG nanopore current
trace with a flat poly(A) plateau and a single amber excursion. It draws itself
once on load and then holds. Everything else is deliberately quiet.

Typography uses the system font stack with a monospace utility face for labels,
years, tags and status badges. No web font means no render-blocking request and
no third-party origin. The trade-off is that display type looks slightly
different across platforms; if that matters more than the request, self-host a
variable font in `assets/fonts/` and add a `@font-face` block plus a
`--font-body` override in `custom.scss`.

## Accessibility

Keyboard focus is visible everywhere (`:focus-visible`, 2px accent outline).
The lightbox moves focus to its close button on open, restores it on close, and
closes on Escape or backdrop click. All animation is suppressed under
`prefers-reduced-motion: reduce`, and `.reveal` content is visible without
JavaScript via a `<noscript>` rule. Proficiency meters carry `role="img"` and an
explicit `aria-label`, because a coloured bar is not readable otherwise.

Not yet verified: colour contrast in dark mode against WCAG AA for the muted
`--ink-3` text, and screen reader behaviour on the publication listing filters,
which are Quarto's markup rather than mine.

## Licence

Code MIT (`LICENSE`). Content and artwork © 2026 Natalia Gumińska, all rights
reserved (`LICENSE-CONTENT.md`).

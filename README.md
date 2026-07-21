# nemitheasura.github.io

Personal and academic website for **Natalia Gumińska, PhD**: RNA biology,
nanopore direct RNA sequencing, and research software. Built with
[Quarto](https://quarto.org), deployed to GitHub Pages by GitHub Actions.

No CDN, no analytics, no tracker. Fonts are self-hosted. The site is static HTML and CSS
plus about 90 lines of vanilla JavaScript for a scroll reveal, an image lightbox
and a year stamp.

---

## Quick start

```bash
Rscript scripts/fetch-fonts.R    # once: downloads Open Sans into assets/fonts/
quarto preview                   # live-reloading server on http://localhost:4200
quarto render                    # one-off build into _site/
```

Quarto 1.5 or newer is the only hard requirement. There are no executable code
cells, so R and Python are **not** needed to build the site. R is used only by
the two optional helper scripts.

If Quarto is not on `PATH` but RStudio is installed, it ships a copy:

```powershell
& "C:\Program Files\RStudio\resources\app\bin\quarto\bin\quarto.exe" preview
```

The font step is optional. Without it the build still succeeds and text falls
back to the system stack; run it when you want the site to match the ninetails
docs exactly.

## Project structure

```
.
├── _quarto.yml                    site config: navigation, theme, SEO
├── _variables.yml                 name, email, social URLs; use {{< var key >}}
├── index.qmd                      Home
├── about.qmd                      Biography, education, grants, awards
├── software.qmd                   Projects and packages
├── stack.qmd                      Technology stack, grouped tag lists
├── side-quests.qmd                Hobby projects and interests
├── contact.qmd                    Contact links
├── 404.qmd
├── publications/
│   ├── index.qmd                  Filterable listing + conference talks
│   ├── publications.yml           THE PUBLICATION DATA, edit this
│   └── references.bib             optional BibTeX source
├── illustrations/index.qmd        Gallery with lightbox
├── styles/
│   ├── theme-light.scss           light palette tokens
│   ├── theme-dark.scss            dark palette tokens
│   └── custom.scss                all component rules, theme-agnostic
├── assets/
│   ├── head.html                  SEO meta, JSON-LD, @font-face rules
│   ├── scripts.html               reveal observer, lightbox, year stamp
│   └── img/                       favicon, logo, portrait, OG, gallery
├── scripts/
│   ├── fetch-fonts.R              download Open Sans into assets/fonts/
│   ├── make-placeholders.sh       regenerate placeholder artwork
│   └── generate-publications.R    references.bib → publications.yml
└── .github/workflows/publish.yml
```

## Before this goes live

The site builds and looks finished, but the following are placeholders.

- [ ] **Run `Rscript scripts/fetch-fonts.R` and commit `assets/fonts/`.**
      Without this the live site falls back to the system font stack, silently.

- [ ] **Replace `assets/img/profile.svg`** with a real portrait
      (`profile.jpg` is fine; update the `src` in `index.qmd`).
- [ ] **Export `assets/img/og-image.png` at 1200×630.** `assets/head.html`
      points at the PNG; only the SVG exists, and social platforms will not
      render an SVG preview card.
- [ ] **Replace the gallery images** in `assets/img/illustrations/`. The
      DEGRONOPEDIA section on that page describes the identity work but shows
      nothing; add screenshots or the mark once the lab agrees.

## Editing

**Personal details.** `_variables.yml` holds name, email and social URLs;
reference them anywhere as `{{< var email >}}`. Navigation and site URL live in
`_quarto.yml`. The JSON-LD block in `assets/head.html` duplicates some of this
and must be updated by hand, because Quarto variables do not expand inside
included HTML partials.

**Publications.** Append to `publications/publications.yml`:

```yaml
- title: "Paper title"
  author: "Gumińska N., et al."
  date: "2025-01-01"           # sorts within a year
  year: "2025"                 # selects which year section it appears under
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
`description` fields**, because BibTeX has nowhere to store them.

**Page descriptions.** Every page has a `description` in its front matter. It
feeds the meta description, the Open Graph tags and the sitemap, and it is
hidden on the page itself by a rule in `custom.scss` section 12, because Quarto
otherwise prints it under the title where it restates the heading. Edit it for
search results, not for readers. If you would rather not have the metadata at
all, delete the front matter key and the CSS rule together.

**Publications are grouped by year.** There is one listing per year in the front
matter of `publications/index.qmd`, each selecting on the `year` field, plus a
matching `### <year>` heading and an empty `::: {#papers-<year>} :::` div in the
body. That is what puts the years in the table of contents.

Adding a paper to an existing year needs nothing but a new entry in
`publications.yml` (with both `date` and `year`). Adding a paper in a NEW year
needs three things: the entry, a listing block, and a heading plus div. Miss any
one and the paper silently will not appear.

The search, sort and filter controls are gone, because seven copies of them
would be worse than none. So is the RSS feed, which needs a single listing.

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
and the `aria-label` are independent, so **change both together** or screen
reader users get the old number.

**Adding a page.** Create `newpage.qmd` with a `title` in the front matter, then
add it to `website.navbar.left` in `_quarto.yml`.

**No CV page.** It duplicated About almost line for line, so it was removed.
About carries employment, education, grants, awards, teaching and service;
Publications carries the list. If you later want a downloadable PDF, add it as a
resource and link it from About rather than rebuilding the page.

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

The hero is a two-column layout: introduction and portrait. There is no
decorative graphic; the only ornament on the site is the hairline that runs from
the end of each `h2` to the right margin.

### Typography

The body face is **Open Sans**, matching the ninetails documentation site
(pkgdown on Bootswatch Yeti, which loads Open Sans from Google Fonts). Here it
is self-hosted from `assets/fonts/` rather than fetched from a CDN: embedding
Google Fonts sends every visitor's IP to Google, which a German court found
breaches the GDPR (LG Munich I, 3 O 17493/20), and a same-origin font avoids an
extra DNS lookup, TLS handshake and chained request before text paints.

`scripts/fetch-fonts.R` downloads four woff2 files: roman and italic, latin and
latin-ext. **latin-ext is not optional.** It carries ń, ł, ą, ę, ś, ź and ż, so
without it "Gumińska", "Koźminski" and "Poznań" change typeface mid-word.

**Commit `assets/fonts/` once you have generated it.** The GitHub Actions
workflow builds from a clean checkout with no R installed, so uncommitted fonts
are simply absent from the deployed site. Because the fallback stack is silent,
local preview will look right while the live site does not.

Headings sit at weight 640, which the variable font covers. Open Sans is used
throughout, including labels, tags, buttons and status badges; monospace is
reserved for code. If you would rather skip self-hosting, `assets/head.html`
documents the one-line Google Fonts swap.

Font files are declared with root-absolute paths (`/assets/fonts/…`), which is
correct for a **user site**. On a project site they need a `/<repo>` prefix or
they 404 silently.

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

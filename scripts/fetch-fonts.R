#!/usr/bin/env Rscript
# ===========================================================================
# Download the Open Sans woff2 subsets that assets/head.html expects.
#
#   Rscript scripts/fetch-fonts.R              # download into assets/fonts/
#   Rscript scripts/fetch-fonts.R --dry-run    # show what it would fetch
#   Rscript scripts/fetch-fonts.R --force      # re-download existing files
#
# Run once, from the project root. Base R only, no packages: R is on this
# machine because of RStudio, so this works where a shell script would need
# Git Bash and a PowerShell script would not run on the CI runner.
#
# Why a script rather than committing four .woff2 files to begin with: Google
# periodically reissues these subsets, and a script makes the provenance of
# the bytes obvious. But DO commit what it downloads. The GitHub Actions
# workflow builds from a clean checkout with no R and no network access to
# Google, so uncommitted fonts simply are not on the deployed site.
#
# Open Sans is licensed under the SIL Open Font License 1.1, which permits
# redistribution. Hosting the files yourself is allowed.
# ===========================================================================

args     <- commandArgs(trailingOnly = TRUE)
dry_run  <- "--dry-run" %in% args
force    <- "--force"   %in% args

# --- Resolve the project root from the script's own location ---------------
# sys.frame()$ofile is NULL under Rscript, so parse the --file= argument that
# Rscript always passes. Falls back to the working directory when sourced
# interactively, where getwd() is normally the project root anyway.
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
root <- if (length(file_arg) > 0) {
  dirname(dirname(base::normalizePath(sub("^--file=", "", file_arg[1]))))
} else {
  base::getwd()
}

font_dir <- file.path(root, "assets", "fonts")

# --- What we need ----------------------------------------------------------
# Google serves one file per (style, unicode-range) pair. The two subsets are
# latin and latin-ext; latin-ext is required for Polish diacritics. Filenames
# here are stable and chosen by us, because Google's own filenames carry a
# content hash that changes whenever they reissue the font, which would break
# the hard-coded src paths in assets/head.html.
wanted <- data.frame(
  style  = c("normal", "normal", "italic", "italic"),
  subset = c("latin", "latin-ext", "latin", "latin-ext"),
  file   = c("open-sans-latin.woff2",
             "open-sans-latin-ext.woff2",
             "open-sans-latin-italic.woff2",
             "open-sans-latin-ext-italic.woff2"),
  stringsAsFactors = FALSE
)

# The variable-font request: weights 300-800, roman and italic. This must stay
# in step with the `font-weight: 300 800` ranges declared in assets/head.html.
css_url <- paste0(
  "https://fonts.googleapis.com/css2",
  "?family=Open+Sans:ital,wght@0,300..800;1,300..800&display=swap"
)

# Google content-negotiates on User-Agent: an old or unknown UA gets TTF, a
# modern one gets woff2. Without this header the script silently downloads
# files three times larger that the @font-face `format("woff2")` will reject.
ua <- paste(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
  "AppleWebKit/537.36 (KHTML, like Gecko)",
  "Chrome/120.0.0.0 Safari/537.36"
)

# `headers` is only honoured by some download methods. On Windows the default
# can resolve to "wininet", which silently ignores it. Google then sees an
# unknown client, serves TTF, and the woff2-only @font-face rules reject the
# result with no error anywhere. Force libcurl, which is bundled with R on
# every platform since 4.0 and does respect headers.
dl <- function(url, dest) {
  utils::download.file(
    url, dest, quiet = TRUE, mode = "wb", method = "libcurl",
    headers = c("User-Agent" = ua)
  )
}

message("Fetching the Open Sans stylesheet from Google Fonts ...")

css <- tryCatch(
  {
    tmp <- base::tempfile(fileext = ".css")
    dl(css_url, tmp)
    out <- base::readLines(tmp, warn = FALSE)
    base::unlink(tmp)
    base::paste(out, collapse = "\n")
  },
  error = function(e) {
    stop(
      "Could not reach fonts.googleapis.com: ", conditionMessage(e), "\n",
      "  If you are offline or behind a proxy, download the four files by\n",
      "  hand from https://fonts.google.com/specimen/Open+Sans and save them\n",
      "  into assets/fonts/ under the names listed in assets/head.html.\n",
      "  The site builds and renders fine without them; only the typeface\n",
      "  differs.",
      call. = FALSE
    )
  }
)

# Google writes a `/* latin-ext */` style comment immediately before each
# block, so after splitting on @font-face that comment is the TAIL of the
# previous element. Read the subset name from the end of the preceding chunk.
all_blocks <- base::strsplit(css, "@font-face", fixed = TRUE)[[1]]

if (!base::any(base::grepl("src:", all_blocks, fixed = TRUE))) {
  stop("The response contained no @font-face blocks. Google may have changed ",
       "the API, or a proxy returned an error page.", call. = FALSE)
}

parsed <- do.call(rbind, lapply(seq_along(all_blocks), function(i) {
  b <- all_blocks[i]
  # i == 1 is the preamble before the first @font-face and never has a src:,
  # but guard the lookback anyway so a leading block cannot subscript [0].
  if (i == 1L || !base::grepl("src:", b, fixed = TRUE)) return(NULL)
  prev <- all_blocks[i - 1L]
  label <- base::regmatches(
    prev, base::regexpr("/\\*[^*]*\\*/[[:space:]]*$", prev)
  )
  url <- base::regmatches(b, base::regexpr("https://[^)[:space:]]+\\.woff2", b))
  if (length(url) == 0L) return(NULL)
  # Strip the comment delimiters and surrounding whitespace. Note that "\\s"
  # is not a character class inside a bracket expression in R's default (TRE)
  # engine, so use an explicit character set plus trimws instead.
  subset <- if (length(label)) {
    base::trimws(base::gsub("[/*]", "", label))
  } else {
    ""
  }
  data.frame(
    subset = subset,
    style  = if (base::grepl("font-style:[[:space:]]*italic", b)) "italic" else "normal",
    url    = url,
    stringsAsFactors = FALSE
  )
}))

if (is.null(parsed)) {
  stop("Found @font-face blocks but no woff2 URLs. Check the User-Agent ",
       "header in this script.", call. = FALSE)
}

# --- Download --------------------------------------------------------------
if (!dry_run && !base::dir.exists(font_dir)) {
  base::dir.create(font_dir, recursive = TRUE)
}

n_ok <- 0L
missing <- character(0)

for (i in seq_len(nrow(wanted))) {
  target <- wanted[i, ]
  hit <- parsed[parsed$subset == target$subset & parsed$style == target$style, ]

  if (nrow(hit) == 0L) {
    missing <- c(missing, paste0(target$style, "/", target$subset))
    next
  }

  dest <- file.path(font_dir, target$file)

  if (base::file.exists(dest) && !force) {
    message("  skip     ", target$file, "  (exists; --force to replace)")
    n_ok <- n_ok + 1L
    next
  }

  if (dry_run) {
    message("  would fetch  ", target$file, "  <- ", hit$url[1])
    next
  }

  dl(hit$url[1], dest)

  # A woff2 file starts with the ASCII signature "wOF2". If content
  # negotiation went wrong we would get a TTF (signature 0x00010000) or an
  # HTML error page, either of which the @font-face format("woff2") rule
  # rejects at render time with nothing logged. Catch it here instead.
  sig <- base::readBin(dest, what = "raw", n = 4L)
  if (!identical(sig, base::as.raw(c(0x77, 0x4F, 0x46, 0x32)))) {
    base::unlink(dest)
    stop("Downloaded ", target$file, " is not a woff2 file (signature ",
         base::paste(sig, collapse = " "), "). The User-Agent header was ",
         "probably not sent; check that method = \"libcurl\" is available ",
         "via capabilities(\"libcurl\").", call. = FALSE)
  }

  size_kb <- base::round(base::file.size(dest) / 1024, 1)
  message("  saved    ", target$file, "  (", size_kb, " kB)")
  n_ok <- n_ok + 1L
}

if (length(missing) > 0L) {
  warning("No match in the Google response for: ",
          base::paste(missing, collapse = ", "),
          ". Those glyphs will fall back to the system font.",
          call. = FALSE)
}

if (dry_run) {
  message("\nDry run: nothing written.")
} else {
  message("\n", n_ok, " of ", nrow(wanted), " files in ",
          base::normalizePath(font_dir, mustWork = FALSE))
  message("Run `quarto render` (or restart `quarto preview`) to pick them up.")
}

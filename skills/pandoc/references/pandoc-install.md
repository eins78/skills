# Pandoc Installation

## macOS

### Homebrew (recommended)

```bash
brew install pandoc
```

### For PDF output

LaTeX is required by default. Options:

```bash
# Full TeX Live (large, ~6.9GB, everything included)
brew install --cask mactex

# TeX Live without GUI apps (~300MB smaller)
brew install --cask mactex-no-gui

# Minimal: tectonic (downloads packages on demand)
brew install tectonic

# Non-LaTeX alternative: weasyprint (CSS-based PDF)
pip install weasyprint

# Non-LaTeX alternative: typst (lightweight)
brew install typst
```

## Linux (Debian/Ubuntu)

```bash
apt-get install pandoc

# For PDF output
apt-get install texlive-latex-recommended texlive-fonts-recommended

# For Unicode/custom fonts in PDF
apt-get install texlive-xetex
```

## Linux (Other)

Download the latest release from GitHub:

```bash
# Example for x86_64
curl -L https://github.com/jgm/pandoc/releases/latest/download/pandoc-VERS-linux-amd64.tar.gz | tar xz
sudo mv pandoc-VERS/bin/pandoc /usr/local/bin/
```

Replace `VERS` with the actual version number from https://github.com/jgm/pandoc/releases.

## Docker

```bash
# Core (no LaTeX)
docker run --rm -v "$(pwd):/data" pandoc/core input.md -o output.html

# With LaTeX for PDF output
docker run --rm -v "$(pwd):/data" pandoc/latex input.md -o output.pdf

# With extra packages
docker run --rm -v "$(pwd):/data" pandoc/extra input.md -o output.pdf
```

## Verify Installation

```bash
pandoc --version
pandoc --list-input-formats | wc -l    # ~51 formats
pandoc --list-output-formats | wc -l   # ~75 formats
```

## PDF Engine Comparison

| Engine | Install | Pros | Cons |
|--------|---------|------|------|
| `pdflatex` | texlive/mactex | Fast, standard | No Unicode fonts |
| `xelatex` | texlive/mactex | Unicode, system fonts | Slower than pdflatex |
| `lualatex` | texlive/mactex | Unicode, Lua scripting | Slowest LaTeX engine |
| `tectonic` | `brew install tectonic` | Auto-downloads packages | Fewer packages than full TeX Live |
| `latexmk` | texlive/mactex | Handles multiple passes | Wrapper, needs a LaTeX engine |
| `typst` | `brew install typst` | Fast, no LaTeX needed | Newer, less ecosystem |
| `weasyprint` | `pip install weasyprint` | CSS-based styling | Limited math support |
| `prince` | Commercial | Highest quality HTML→PDF | Paid license |
| `wkhtmltopdf` | `brew install wkhtmltopdf` | WebKit-based | Deprecated, limited |

#!/usr/bin/env bash
# Idempotent repository bootstrap for the sos-state-tx-elections R environment.
# The base image already provides R plus a curated set of analysis and
# R-package-development packages. This step layers in any project-specific
# dependencies once the repo declares them, and (re)generates roxygen docs so
# the project's functions are usable as a standard R package (https://r-pkgs.org/).
set -euo pipefail

cd "$(dirname "$0")/.."

# renv.lock (if present) pins the exact project library and takes precedence.
if [ -f renv.lock ]; then
    echo "renv.lock found -> restoring project library with renv."
    Rscript -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv"); renv::restore(prompt = FALSE)'
fi

# When the repo is structured as a standard R package, install its declared
# dependencies, regenerate roxygen documentation, and install the package
# itself so its functions are importable by scripts and tests.
if [ -f DESCRIPTION ]; then
    echo "DESCRIPTION found -> installing deps, documenting (roxygen), and installing the package."
    Rscript -e '
      if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
      remotes::install_deps(dependencies = TRUE, upgrade = "never")
      if (requireNamespace("roxygen2", quietly = TRUE)) roxygen2::roxygenise()
      remotes::install_local(".", force = TRUE, dependencies = FALSE, upgrade = "never")
    '
elif [ ! -f renv.lock ]; then
    echo "No renv.lock or DESCRIPTION present; using the base R toolchain from the image."
fi

echo "R install step complete. R version:"
Rscript -e 'cat(R.version.string, "\n")'

#!/usr/bin/env bash
# Idempotent repository bootstrap for the sos-state-tx-elections R environment.
# The base image already provides R plus a curated set of tabular-analysis packages.
# This step layers in any project-specific dependencies once the repo declares them.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -f renv.lock ]; then
    echo "renv.lock found -> restoring project library with renv."
    Rscript -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv"); renv::restore(prompt = FALSE)'
elif [ -f DESCRIPTION ]; then
    echo "DESCRIPTION found -> installing declared package dependencies."
    Rscript -e 'if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes"); remotes::install_deps(dependencies = TRUE, upgrade = "never")'
else
    echo "No renv.lock or DESCRIPTION present; using the base R toolchain from the image."
fi

echo "R install step complete. R version:"
Rscript -e 'cat(R.version.string, "\n")'

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Etc/UTC

# Base OS packages, build tooling, and document rendering (pandoc for R Markdown / Quarto-style reports).
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gnupg \
        locales \
        make \
        build-essential \
        pandoc \
        sudo \
    && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Install R and configure r2u so that install.packages() resolves to fast CRAN binaries via apt/bspm.
# See https://eddelbuettel.github.io/r2u/
RUN gpg --homedir /tmp --no-default-keyring \
        --keyring /usr/share/keyrings/r2u.gpg \
        --keyserver keyserver.ubuntu.com \
        --recv-keys A1489FE2AB99A21A 67C2D66C4B1D4339 51716619E084DAB9 \
    && printf 'Types: deb\nURIs: https://r2u.stat.illinois.edu/ubuntu\nSuites: noble\nComponents: main\nArchitectures: amd64 arm64\nSigned-By: /usr/share/keyrings/r2u.gpg\n' \
        > /etc/apt/sources.list.d/r2u.sources \
    && printf 'Types: deb\nURIs: https://cloud.r-project.org/bin/linux/ubuntu\nSuites: noble-cran40/\nComponents:\nArchitectures: amd64 arm64\nSigned-By: /usr/share/keyrings/r2u.gpg\n' \
        > /etc/apt/sources.list.d/cran.sources \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends r-base-core \
    && printf 'Package: *\nPin: release o=CRAN-Apt Project\nPin: release l=CRAN-Apt Packages\nPin-Priority: 700\n' \
        > /etc/apt/preferences.d/99cranapt \
    && apt-get install -y --no-install-recommends python3-dbus python3-gi python3-apt \
    && Rscript -e 'install.packages("bspm")' \
    && printf 'suppressMessages(bspm::enable())\noptions(bspm.version.check=FALSE)\noptions(bspm.sudo=TRUE)\n' >> /etc/R/Rprofile.site \
    && rm -rf /var/lib/apt/lists/*

# Curated base packages for the precinct-level Texas returns database:
#  - tidyverse + data.table + janitor: ingest/clean SoS returns
#  - arrow: parquet storage and querying the "database" tables via the arrow
#    dplyr backend (preferred over a SQL engine for this project)
#  - dataverse: pull the CAGE reference dataset from Harvard Dataverse for name/format alignment + validation
#  - httr2 + rvest: fetch/scrape returns from sos.state.tx.us
#  - here/fs/glue/scales: project paths, file ops, formatting
#  - knitr/rmarkdown: reproducible reports
#  - devtools/roxygen2/usethis/testthat/pkgdown/covr: standard R package
#    development workflow (https://r-pkgs.org/) with roxygen documentation
# Installed as fast apt binaries through bspm; kept in the image so they live in the base snapshot.
RUN Rscript -e 'install.packages(c( \
        "tidyverse", "data.table", "janitor", "here", "fs", \
        "arrow", "dataverse", \
        "httr2", "rvest", "scales", "glue", \
        "knitr", "rmarkdown", "renv", "remotes", \
        "devtools", "roxygen2", "usethis", "testthat", "pkgdown", "covr" \
    ))' \
    && rm -rf /var/lib/apt/lists/*

# Ensure an "ubuntu" user (uid 1000) exists with passwordless sudo to match the Cloud Agent runtime user.
RUN if ! id ubuntu >/dev/null 2>&1; then useradd -m -s /bin/bash -u 1000 ubuntu; fi \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu

# Let the (non-root) ubuntu user install project/source packages into the R
# site-library without sudo. Combined with bspm.sudo above, `install.packages()`
# and `remotes::install_local()` work in the install step, which runs as ubuntu.
RUN mkdir -p /usr/local/lib/R/site-library \
    && chown -R ubuntu:ubuntu /usr/local/lib/R/site-library

USER ubuntu
WORKDIR /home/ubuntu

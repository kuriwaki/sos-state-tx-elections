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
    && printf 'suppressMessages(bspm::enable())\noptions(bspm.version.check=FALSE)\n' >> /etc/R/Rprofile.site \
    && rm -rf /var/lib/apt/lists/*

# Curated base packages for tabular election-data analysis and reporting.
# Installed as fast apt binaries through bspm; kept in the image so they live in the base snapshot.
RUN Rscript -e 'install.packages(c( \
        "tidyverse", "data.table", "janitor", "here", "arrow", \
        "scales", "glue", "knitr", "rmarkdown", "renv", "remotes" \
    ))' \
    && rm -rf /var/lib/apt/lists/*

# Ensure an "ubuntu" user (uid 1000) exists with passwordless sudo to match the Cloud Agent runtime user.
RUN if ! id ubuntu >/dev/null 2>&1; then useradd -m -s /bin/bash -u 1000 ubuntu; fi \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu

USER ubuntu
WORKDIR /home/ubuntu

FROM rocker/r-ver:4.4.2

LABEL description="R 4.4.2 + ProFound (asgr/ProFound) for HPC use via Apptainer/Singularity"

ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential gfortran cmake git pkg-config \
        libcurl4-openssl-dev libssl-dev libxml2-dev \
        libfftw3-dev libcfitsio-dev libgsl-dev wcslib-dev \
        libpng-dev libtiff-dev libjpeg-dev \
        libx11-dev libcairo2-dev libxt-dev \
        libfontconfig1-dev libfreetype6-dev libharfbuzz-dev libfribidi-dev \
        zlib1g-dev libbz2-dev liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

RUN Rscript -e 'options(Ncpus = 4); install.packages(c("remotes", "Rcpp", "data.table", "FITSio", "imager", "magicaxis", "celestial", "png"))'

# ProFound's GitHub-only dependencies (Highlander, LaplacesDemon, ...) are looked up via the
# GitHub API, which rate-limits anonymous requests from shared build machines. The workflow
# passes a token in as a build secret (never stored in the image) so the lookups succeed.
RUN --mount=type=secret,id=github_pat \
    if [ -f /run/secrets/github_pat ]; then export GITHUB_PAT="$(cat /run/secrets/github_pat)"; fi; \
    Rscript -e 'options(Ncpus = 4); remotes::install_github("asgr/ProFound", dependencies = TRUE, upgrade = "never")'

# Fail the build if ProFound didn't install properly
RUN Rscript -e 'library(ProFound); cat("ProFound", as.character(packageVersion("ProFound")), "OK\n")'

WORKDIR /work
CMD ["R"]

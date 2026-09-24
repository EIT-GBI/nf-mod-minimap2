FROM mambaorg/micromamba:1.5.8

USER root

# procps for `ps`: Nextflow's task wrapper shells out to it to collect metrics,
# and without it every task dies with
#   Command 'ps' required by nextflow to collect task metrics cannot be found
# The micromamba base is debian-slim and does not carry it. apt, not
# conda-forge::procps-ng, because Nextflow parses real procps output.
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


ARG MINIMAP2_VERSION=2.28
ARG SAMTOOLS_VERSION=1.20

RUN micromamba install -y -n base -c bioconda -c conda-forge \
        minimap2=${MINIMAP2_VERSION} \
        samtools=${SAMTOOLS_VERSION} \
    && micromamba clean --all --yes

ENV PATH=/opt/conda/bin:${PATH}

CMD ["minimap2"]

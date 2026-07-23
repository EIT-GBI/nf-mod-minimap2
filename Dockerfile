FROM mambaorg/micromamba:1.5.8

USER root

ARG MINIMAP2_VERSION=2.28
ARG SAMTOOLS_VERSION=1.20

RUN micromamba install -y -n base -c bioconda -c conda-forge \
        minimap2=${MINIMAP2_VERSION} \
        samtools=${SAMTOOLS_VERSION} \
    && micromamba clean --all --yes

ENV PATH=/opt/conda/bin:${PATH}

CMD ["minimap2"]

# ![nibscbioinformatics/viralevo](docs/images/nibscbioinformatics-viralevo_logo.png)

**Characterisation of viral genomes, intra-host diversity and viral evolution across samples**.

[![GitHub Actions CI Status](https://github.com/nibscbioinformatics/viralevo/workflows/nf-core%20CI/badge.svg)](https://github.com/nibscbioinformatics/viralevo/actions)
[![GitHub Actions Linting Status](https://github.com/nibscbioinformatics/viralevo/workflows/nf-core%20linting/badge.svg)](https://github.com/nibscbioinformatics/viralevo/actions)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A519.10.0-brightgreen.svg)](https://www.nextflow.io/)

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg)](http://bioconda.github.io/)
[![Docker](https://img.shields.io/docker/automated/nibscbioinformatics/viralevo.svg)](https://hub.docker.com/r/nibscbioinformatics/viralevo)

![Singularity Conversion](https://github.com/nibscbioinformatics/viralevo/workflows/Singularity%20Conversion/badge.svg)

![Docker Finishing](https://github.com/nibscbioinformatics/viralevo/workflows/Docker%20Build%20&%20Push%20-%20Finishing/badge.svg)

![Docker Reporting](https://github.com/nibscbioinformatics/viralevo/workflows/Docker%20Build%20&%20Push%20-%20Reporting/badge.svg)


## Introduction

The ViralEvo pipeline is designed to characterise viral samples, and particularly SARS-CoV-2, from short read sequencing data.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker containers making installation trivial and results highly reproducible.

## Quick Start

i. Install [`nextflow`](https://nf-co.re/usage/installation)

ii. Install either [`Docker`](https://docs.docker.com/engine/installation/) or [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) for full pipeline reproducibility (please only use [`Conda`](https://conda.io/miniconda.html) as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))

iii. Download the pipeline and test it on a minimal dataset with a single command

```bash
nextflow run nibscbioinformatics/viralevo -profile test,nibsc --outdir /output/folder
```

iv. Start running your own analysis!

```bash
nextflow run nibscbioinformatics/viralevo -profile nibsc --outdir /output/folder --tools all --genome SARS-CoV-2 --input /path/to/sampleinfo.tsv
```

See [usage docs](docs/usage.md) for all of the available options when running the pipeline.

## Documentation

The nibscbioinformatics/viralevo pipeline comes with documentation about the pipeline, found in the `docs/` directory:

1. [Installation](https://nf-co.re/usage/installation)
2. Pipeline configuration
    * [Local installation](https://nf-co.re/usage/local_installation)
    * [Adding your own system config](https://nf-co.re/usage/adding_own_config)
    * [Reference genomes](https://nf-co.re/usage/reference_genomes)
3. [Running the pipeline](docs/usage.md)
4. [Output and how to interpret the results](docs/output.md)
5. [Troubleshooting](https://nf-co.re/usage/troubleshooting)

<!-- TODO nf-core: Add a brief overview of what the pipeline does and how it works -->

## Credits

nibscbioinformatics/viralevo was originally written by Francesco Lescai and Thomas Bleazard.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on [Slack](https://nfcore.slack.com/channels/viralevo) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citation

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi. -->
<!-- If you use  nibscbioinformatics/viralevo for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).  
> ReadCube: [Full Access Link](https://rdcu.be/b1GjZ)

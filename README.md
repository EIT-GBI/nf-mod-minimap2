# nf-mod-minimap2

Nextflow module for [minimap2](https://github.com/lh3/minimap2) (long-read
alignment). Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-minimap2:v0.0.0`

Built for `linux/amd64` and `linux/arm64`.

## Processes

| Process | Path | Inputs | Emits |
| --- | --- | --- | --- |
| `MINIMAP2_ALIGN` | `align/main.nf` | `tuple val(meta), path(reads)`, `tuple path(fasta), path(fai)` | `bam` |

`MINIMAP2_ALIGN` emits `tuple val(meta), path(bam), path(bai)` — it sorts and
indexes in the same task, so the index is part of the output rather than a
separate `SAMTOOLS_INDEX` step.

It reads two fields off `meta`:

| Field | Used for |
| --- | --- |
| `meta.preset` | `-x`, e.g. `map-ont` or `map-hifi` |
| `meta.platform` | the `PL` field of the `@RG` header |

minimap2 cannot read BAM. To align an unaligned BAM, convert it first and keep
the modified-base tags alive across the round trip:

```groovy
process {
    withName: SAMTOOLS_FASTQ { ext.args = '-T MM,ML' }   // carry tags out of the uBAM
    withName: MINIMAP2_ALIGN { ext.args = '-y' }         // carry them into the BAM
}
```

Without both flags the `MM`/`ML` tags are silently lost, and any downstream
methylation step sees nothing.

## Publishing

This process does **not** publish its own outputs. Publishing is the consuming
pipeline's job. This keeps the module reusable across pipelines that want
different result layouts.

## Tool arguments

Flags are passed through `task.ext.args` rather than read from pipeline
`params`, so the module never depends on a particular pipeline's parameter
names:

```groovy
process {
    withName: MINIMAP2_ALIGN {
        ext.args = '-y --MD'
    }
}
```

A prebuilt `.mmi` index may be passed in place of the FASTA. Note that an
`.mmi` records the `-k`/`-w` it was built with and **overrides** whatever the
preset would have used, so an index built for `map-ont` silently changes the
parameters when used with HiFi reads.

## Use as submodule

Pin to a release tag rather than a branch, so pipeline runs stay reproducible:

```bash
git submodule add https://github.com/EIT-GBI/nf-mod-minimap2.git modules/minimap2
git -C modules/minimap2 checkout v0.0.0
```

Then include the module's container config from your `nextflow.config`. Nextflow
does not read a submodule's config on its own, so without this line the
process has no image:

```groovy
includeConfig 'modules/minimap2/conf/module.config'
```

`conf/module.config` pins the image to the version built from this same commit,
and carries no `manifest {}` block, so it will not overwrite your pipeline's
own manifest. Override it in your pipeline with a `withName` selector if needed.

And include the process:

```groovy
include { MINIMAP2_ALIGN } from './modules/minimap2/align/main.nf'
```

## Requirements

Nextflow 26.04.4 or newer.

## Releasing

Merging a PR to `main` with exactly one `bump:patch`, `bump:minor` or
`bump:major` label bumps `manifest.version` in `nextflow.config`, tags the
release and publishes the container image.

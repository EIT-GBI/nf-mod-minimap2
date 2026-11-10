# nf-mod-minimap2


Nextflow module for minimap2. Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-minimap2:v0.0.0`

## Processes

- `MINIMAP` — TODO: describe inputs/outputs

## Use as submodule
```bash
git submodule add https://github.com/eit-gbi/nf-mod-minimap2.git modules/minimap2  
```

Then in your pipeline:
```
include { MINIMAP } from './modules/minimap2/main.nf'
```

## Pinning

Pipelines pin a release rather than tracking `main`:

```bash
git -C modules/minimap2 checkout v0.0.0
```

and pick up the matching image with `includeConfig 'modules/minimap2/conf/module.config'`.

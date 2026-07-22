# nf-mod-minimap


Nextflow module for minimap. Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-minimap:latest`

## Processes

- `MINIMAP` — TODO: describe inputs/outputs

## Use as submodule
```bash
git submodule add https://github.com/eit-gbi/nf-mod-minimap.git modules/minimap
```

Then in your pipeline:
```
include { MINIMAP } from './modules/minimap/main.nf'
```

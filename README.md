# nf-mod-minimap


Nextflow module for minimap2. Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-minimap2:latest`

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

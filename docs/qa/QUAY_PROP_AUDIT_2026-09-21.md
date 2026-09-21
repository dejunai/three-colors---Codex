# Quay prop production audit — 2026-09-21

Branch: `feature/district-textures`  
Scope: five root-level Meshy remeshes supplied for the Phase One waterfront

## Verdict

All five assets are suitable for the waterfront pass. Their silhouettes, construction, weathering, and restrained color belong to the same working-quay vocabulary. The untouched source exports are retained at the root of `archive/`. Game-ready copies live in `assets/models/waterfront/` and are produced by `tools/modeling/optimize_quay_props.py`.

| Asset | Triangles | Original GLB | Optimized GLB | Intended use |
|---|---:|---:|---:|---|
| Boat frame | 20,281 | 30.3 MB | 2.2 MB | Repair-yard landmark or unfinished hull |
| Cargo cluster | 15,041 | 30.6 MB | 2.0 MB | One combined crates, barrels, and rope dressing group |
| Dock crane | 10,897 | 29.4 MB | 1.7 MB | Quay silhouette and vertical landmark |
| Dock shed | 42,890 | 29.1 MB | 3.7 MB | Single hero building with visible open interior |
| Fishing boat | 19,267 | 29.2 MB | 2.2 MB | Primary moored vessel and waterfront centerpiece |

Each Meshy source carried a 4K base-color map and a 4K metallic/roughness map. The optimized copies cap both maps at 2K JPEG, preserve their material response, use stable names, contain one placement mesh, and move the origin to the bottom center. Visual comparison found no material loss that matters at the Chapter One camera distance or through its film treatment.

## Placement constraints

- The exports are normalized presentation models rather than real-world-scale assets. Their final Godot scale must be established against Walter and the existing quay footprint during placement.
- Use simple purpose-built collision proxies. Do not generate concave mesh collision from the render geometry.
- The dock shed is the expensive asset and should appear once in the initial waterfront composition. Its 42.9K triangles are acceptable as a hero structure, but it is not a repeatable building kit.
- The cargo asset is intentionally one cluster. Individual crates, barrels, and rope cannot be rearranged without a later separation pass.
- The boat frame is small-boat construction, not the offshore whaling station and not a commitment about Chapter Two's island architecture.

The pale wood values are compatible with the current Chapter One treatment. Final placement lighting should provide darker wet contact areas and stronger separation from fog rather than repainting the assets before they are seen in the live waterfront.

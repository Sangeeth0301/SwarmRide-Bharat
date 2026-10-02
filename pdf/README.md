# Pitch and results-preview tooling

This folder builds the two investor PDFs and holds the **expected-results preview study**.

| File | Builds / does |
|---|---|
| `build_pitch.py` | The 6-page investor pitch (`../SwarmRide_Bharat_Pitch.pdf`): HTML pages with real photos, hand-drawn style diagrams and the end-to-end architecture, printed to PDF with headless Microsoft Edge |
| `pages_v2.py` | Page templates used by `build_pitch.py` (real-bogie photo pages, train overview) |
| `pitch.html` | The generated pitch HTML (intermediate) |
| `sim_preview.py` | **Preview simulation**: a simplified half-coach model in Python that estimates the results SwarmRide should reach. Writes `results/*.png` and `results/summary.json` |
| `build_results.py` | The 4-page *Simulation Results Preview* (`../SwarmRide_Simulation_Results_Preview.pdf`) from `results/` |
| `results_preview.html` | The generated results HTML (intermediate) |
| `build_readme_assets.py` | README visuals: banner `images/hero.jpg` and the annotated bogie `images/casnub_annotated.jpg` |
| `photos/` | Real photographs of Indian rolling stock; see `photos/CREDITS.md` |

## Rebuild

```bash
python pdf/sim_preview.py      # needs numpy, scipy, matplotlib
python pdf/build_results.py    # needs Microsoft Edge (headless print to PDF)
python pdf/build_pitch.py
python pdf/build_readme_assets.py   # needs Pillow
```

## Expected results (preview study)

Crowded coach, poor track, 160 km/h. Simplified Python model with assumed parameters. **These are targets, not measured results.** They will be replaced by the MATLAB/Simulink results of Stages 2 and 3.

| Measure | Today's oil damper | Fixed-load harvester (research approach) | SwarmRide (preview) |
|---|---|---|---|
| Body RMS acceleration | 0.165 m/s² | 0.224 m/s² (worse ride) | **0.125 m/s² (−24%)** |
| Sperling ride index Wz | 1.82 | 2.06 | **1.65** |
| Max stroke | 13.4 mm | – | 12.0 mm |
| Single-bump peak | 0.098 m/s² | – | **0.082 m/s² (−17%)** |
| Harvested power per bogie | 0 W | about 45 W | about 10–15 W at Kₑ = 200 V·s/m (up to about 40 W at Kₑ = 300) |

**Reading it:** a plain harvester makes more power but makes the ride worse. SwarmRide makes less power but improves the ride, and the power covers the bogie's own electronics and sensors (about 5–20 W).

| Figure | Shows |
|---|---|
| `r1_bump.png` | Body response to a single dip: today vs SwarmRide |
| `r2_trace.png` | Body acceleration on poor track |
| `r3_psd.png` | Vibration spectrum: where the energy is removed |
| `r4_loads.png` | Ride and power at empty, half and crowded loads |
| `r5_zeta.png` | Damping ratio vs load: fixed damper vs load-adaptive |
| `r6_pareto.png` | Comfort vs harvested power trade-off |
| `r7_power.png` | Harvested power vs speed and track quality |
| `r8_soc.png` | Power-bank state of charge over a journey |

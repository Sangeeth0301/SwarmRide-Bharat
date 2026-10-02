# Changelog

## Simulation Stage 1b: today's Indian trains
- Train library for LHB, Vande Bharat, ICF and BOXN with sourced and assumed parameters (`functions/sr_trains.m`)
- Spring models per vehicle: air spring (stiffens with load), coil spring (constant), Casnub two-stage nest
- Casnub friction-wedge damper model
- Four live scopes and real-time playback in the Simulink model
- Baseline study (`scripts/check_stage1b.m`): modes, damping ratio, sag, ride, heat wasted per bogie
- Stage 1 report (`SwarmRide_Sim/Stage1.md`) and model guide (`SwarmRide_Sim/MODEL_GUIDE.md`)

## Simulation Stage 1: test rig
- Half-coach 4-DOF vertical model (`functions/sr_eom.m`), sensors (`functions/sr_measure.m`)
- Vertical track irregularity generator: good, poor and single-bump tracks (`functions/sr_track.m`)
- State-space model and Sperling ride index for checks
- Simulink model generated from code (`scripts/build_stage1.m`)
- Verification: hand-calculated bounce frequency and Simulink vs state-space agreement (0.003%)

## Results preview
- Python preview simulation of expected results (`pdf/sim_preview.py`)
- Simulation Results Preview PDF

## Concept and pitch
- Investor pitch, Indian Railways edition (Markdown, Word, PDF)
- Technical project document and complete understanding guide
- System overview and rollout roadmap diagrams
- Six-page investor PDF with real rolling-stock photographs and the end-to-end architecture
- Whitepaper

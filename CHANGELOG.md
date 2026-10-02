# Changelog

## Simulation Stage 2: smart damper and power chain
- Electromagnetic smart damper: Faraday/Lorentz machine, H-bridge current control (current sets damping), current loop, passive part (oil, friction, inertance)
- Damper design library: A direct-drive linear, B hybrid, C geared rotary, sized per vehicle for zeta = 0.25 at full load
- Fail-safe relay with a resistor sized to give today's damping
- Average models of the active rectifier and DC-DC converter
- Power bank per bogie: 10 F supercapacitor + 120 Wh LiFePO4 with a rule-based energy supervisor; 8 W bogie loads
- Verification: same ride as today (1.2% of peak), damping law (0.09%), energy balance (< 0.001%), fail-safe (0.00%)
- Results for 4 vehicles x 3 designs x 2 settings on poor and good track; Stage 2 report and figures
- Shared Simulink builders; Stage 1 re-run unchanged

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

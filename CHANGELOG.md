# Changelog

## Simulation Stage 3: SwarmRide controllers
- LPV (load-scheduled) LQR with Train Brain preview, designed at five loads per vehicle and cached (`functions/sr_controller_design.m`)
- Stage 3 model: Train Brain (rail around the train), SwarmRide Controller (100 Hz feedback + preview, semi-active conversion with passivity and efficiency limits, command smoothing)
- Head to head: today's damper, fixed harvester, LPV, LPV + preview; 4 vehicles x 3 loads; good and poor track; short dip and track settlement; comfort-vs-power sweeps with a damping floor
- Results: better ride at every load, 15-17% on crowded LHB / Vande Bharat coaches and 23% on a loaded wagon, body vibration about 40% lower, 33-38 W per coach bogie
- Fixed: the controller's stroke weight had reused the name of the train start position (P.s0); Stage 3 rerun on the same rail as today's damper, with a guard test
- Stage 3 checks in the verification suite; Stage 3 report

## Audit and track fix
- Verification suite (`scripts/run_all_checks.m`) and `VERIFICATION.md`
- Rail generator corrected (sines on the harmonics of a 2 km period); all results regenerated
- PDF builders wait for Edge to finish; document link checker

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

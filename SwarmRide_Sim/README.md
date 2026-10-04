# SwarmRide_Sim: MATLAB/Simulink simulation

Simulation of SwarmRide Bharat, built stage by stage. Every stage keeps the same coach, the same rail and the same speed, and changes **only the damper**, so every comparison is fair.

**Requires:** MATLAB R2024b with Simulink, Control System Toolbox, Simscape and Simscape Electrical.

## Quick start

```matlab
sr_setup                                              % paths + opens models/SR_Stage4.slx (stage = 1, 2 or 3 for earlier models)
trainType = 'LHB';                                    % LHB | VB | ICF | BOXN | GENERIC
v_kmh = 160;  mload_t = 12;  trackType = 'poor';      % speed, load [t], track: good | poor | bump | settlement
designType = 'C';  ctrlMode = 'C3';  t_fault = Inf;   % damper design, controller (C0..C4), test fault
act_window_s = 1;  wheel_runout = 0;                  % Stage 4: push window around known bad spots, wheel defect [m]
% press Run: live scopes open and the 30 s run plays in real time
```

Batch checks (results written to `results/`):

```matlab
run('scripts/check_stage1.m')     % physics and wiring checks
run('scripts/check_stage1b.m')    % baseline of today's Indian trains
run('scripts/check_stage2.m')     % smart damper and power chain: checks + full study
run('scripts/check_stage3.m')     % controllers: checks + head-to-head study
run('scripts/check_stage4.m')     % active push, full-day journeys, health sensing
run('scripts/export_dashboard.m') % write ../dashboard/data.js for the investor dashboard
run('scripts/check_bench.m')      % bench prototype: sizing, bench model, predicted T1-T9, margins, exports
run('scripts/regenerate_all.m')   % rebuild every model, result and report (about 1 hour)
run('scripts/run_all_checks.m')   % full verification suite -> results/verification_report.txt
```

## Folder layout

| Folder / file | Contents |
|---|---|
| `sr_setup.m` | Session setup |
| `functions/` | Physics (`sr_eom`), sensors (`sr_measure`), track (`sr_track`), state-space model (`sr_linear_model`), ride index (`sr_sperling`), train library (`sr_trains`), damper sizing (`sr_damper_design`), energy balance (`sr_energy_balance`), controller design (`sr_controller_design`), bank step and full-day journey (`sr_bank_step`, `sr_journey`), hot-axle model (`sr_hot_axle`) |
| `builders/` | Shared Simulink block builders: track, coach, scopes, logs, MATLAB Function blocks |
| `tests/` | Verification tests run by `scripts/run_all_checks.m` |
| `scripts/` | Parameters (`sr_params`, `sr_params_stage3`, `sr_params_stage4`), model builders (`build_stage1..4`), checks (`check_stage1`, `check_stage1b`, `check_stage2`, `check_stage3`, `check_stage4`), figures (`plot_*`), `export_dashboard`, `regenerate_all`, `run_all_checks` |
| `models/` | Generated Simulink models `SR_Stage1.slx`, `SR_Stage2.slx`, `SR_Stage3.slx`, `SR_Stage4.slx`, `SR_Bench.slx` (one damper on a test rig) |
| `results/` | Figures, reports, scope captures |
| `Stage1.md` | **Stage 1 report**: objective, every block, parameters, flow and results |
| `Stage2.md` | **Stage 2 report**: smart damper, power chain, designs A/B/C, verification and results |
| `Stage3.md` | **Stage 3 report**: LPV and preview controllers, head-to-head results |
| `Stage4.md` | **Stage 4 report**: active push, full-day power bank, hot axle and wheel defect |
| `Stage5_Bench.md` | **Stage 5 report**: the bench-prototype model, predicted bench results, hardware margins, firmware |
| `MODEL_GUIDE.md` | Block-by-block reference and parameter sources |
| `VERIFICATION.md` | What is proven, how, the open issues, and what is not verified |

## Stages

| Stage | Content | Status |
|---|---|---|
| 1 | Test rig: track, 4-DOF half-coach, passive damper, verification | Done |
| 1b | Today's Indian trains (LHB, Vande Bharat, ICF, BOXN), live scopes, baseline | Done |
| 2 | Electromagnetic smart damper (designs A/B/C), rectifier, DC-DC, power bank, fail-safe | Done |
| 3 | Controllers: fixed harvester, LPV load-adaptive, LPV + Train Brain preview | Done |
| 4 | Active push at known bad spots (C4), full-day journeys, self-powered health sensing, investor dashboard | Done |
| 5 | Bench prototype: hardware sizing, bench model (`SR_Bench`), C firmware, rig drive files, test plan | Done (hardware next) |

All 85 verification checks pass (Stages 1–4 and the bench prototype). Next: build and test the bench prototype (Gate B).

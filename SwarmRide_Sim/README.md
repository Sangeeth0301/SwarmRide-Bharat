# SwarmRide_Sim: MATLAB/Simulink simulation

Simulation of SwarmRide Bharat, built stage by stage. Every stage keeps the same coach, the same rail and the same speed, and changes **only the damper**, so every comparison is fair.

**Requires:** MATLAB R2024b with Simulink, Control System Toolbox, Simscape and Simscape Electrical.

## Quick start

```matlab
sr_setup                                              % paths + opens models/SR_Stage3.slx (stage = 1 or 2 for earlier models)
trainType = 'LHB';                                    % LHB | VB | ICF | BOXN | GENERIC
v_kmh = 160;  mload_t = 12;  trackType = 'poor';      % speed, load [t], track: good | poor | bump
designType = 'C';  ctrlMode = 'C3';  t_fault = Inf;   % Stage 3: damper design, controller (C1/C2/C3), test fault
% press Run: live scopes open and the 30 s run plays in real time
```

Batch checks (results written to `results/`):

```matlab
run('scripts/check_stage1.m')     % physics and wiring checks
run('scripts/check_stage1b.m')    % baseline of today's Indian trains
run('scripts/check_stage2.m')     % smart damper and power chain: checks + full study
run('scripts/check_stage3.m')     % controllers: checks + head-to-head study
run('scripts/regenerate_all.m')   % rebuild every model, result and report (about 1 hour)
run('scripts/run_all_checks.m')   % full verification suite -> results/verification_report.txt
```

## Folder layout

| Folder / file | Contents |
|---|---|
| `sr_setup.m` | Session setup |
| `functions/` | Physics (`sr_eom`), sensors (`sr_measure`), track (`sr_track`), state-space model (`sr_linear_model`), ride index (`sr_sperling`), train library (`sr_trains`), damper sizing (`sr_damper_design`), energy balance (`sr_energy_balance`), controller design (`sr_controller_design`) |
| `builders/` | Shared Simulink block builders: track, coach, scopes, logs, MATLAB Function blocks |
| `tests/` | Verification tests run by `scripts/run_all_checks.m` |
| `scripts/` | Parameters (`sr_params`, `sr_params_stage3`), model builders (`build_stage1..3`), checks (`check_stage1`, `check_stage1b`, `check_stage2`, `check_stage3`), figures (`plot_*`), `regenerate_all`, `run_all_checks` |
| `models/` | Generated Simulink models `SR_Stage1.slx`, `SR_Stage2.slx`, `SR_Stage3.slx` |
| `results/` | Figures, reports, scope captures |
| `Stage1.md` | **Stage 1 report**: objective, every block, parameters, flow and results |
| `Stage2.md` | **Stage 2 report**: smart damper, power chain, designs A/B/C, verification and results |
| `Stage3.md` | **Stage 3 report**: LPV and preview controllers, head-to-head results |
| `MODEL_GUIDE.md` | Block-by-block reference and parameter sources |
| `VERIFICATION.md` | What is proven, how, the open issues, and what is not verified |

## Stages

| Stage | Content | Status |
|---|---|---|
| 1 | Test rig: track, 4-DOF half-coach, passive damper, verification | Done |
| 1b | Today's Indian trains (LHB, Vande Bharat, ICF, BOXN), live scopes, baseline | Done |
| 2 | Electromagnetic smart damper (designs A/B/C), rectifier, DC-DC, power bank, fail-safe | Done |
| 3 | Controllers: fixed harvester, LPV load-adaptive, LPV + Train Brain preview | Done |
| 4 | Self-powered health sensors, active preview, investor dashboard | Next |

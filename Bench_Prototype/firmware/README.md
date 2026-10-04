# SwarmRide firmware (bench version)

The C code that will run on the prototype's microcontroller. **Every function is a line-by-line port of the MATLAB code the simulation runs.** A host test checks each function against numbers MATLAB computed, so the code on the bench is the code that was simulated.

| Rate | Where it runs | Module | MATLAB original |
|---|---|---|---|
| 100 Hz | Vehicle controller (one per coach) | `sr_preview.c`: Train Brain rail samples, as a shift register | `sr_controller_design.m` (shift matrix S) |
| 100 Hz | Vehicle controller | `sr_lpv.c`: LPV state feedback + preview, F* = −Kx x − Kp p, gains blended by load | Simulink block *LPV state feedback + preview* (`build_stage3.m`) |
| 100 Hz | Vehicle controller | `sr_semiactive.c`: c = F* v / (v² + ε²), clipped to the floor and cap | Simulink block *Semi-active conversion* (`build_stage3.m`) |
| 10 kHz | Each damper drive | `sr_semiactive.c` `sr_cmd_smooth`: command smoothing (exact first-order) | Simulink *Command smoothing* integrator |
| 10 kHz | Each damper drive | `sr_drive.c` `sr_current_ref`: damping law, or the push force in a window | `functions/bp_current_ref.m` |
| 10 kHz | Each damper drive | `sr_drive.c` `sr_current_ctrl`: PI + back-EMF feed-forward, voltage limit, anti-windup | `functions/bp_current_ctrl.m` |
| 10 kHz | Each damper drive | `sr_drive.c` `sr_failsafe`: drops the contactor on a fault and latches | `functions/bp_failsafe.m` |
| 1 kHz | Bogie bank | `sr_bank.c`: supercapacitor and battery rules | `functions/sr_bank_step.m` |
| — | — | `sr_ctrl.c`: scheduler that ties the modules together | — |

`include/sr_params_lhb.h` holds the gains and constants. It is **generated** by `SwarmRide_Sim/scripts/bench_export.m` for an LHB coach at 160 km/h. The preview gains depend on speed, so a set is generated per speed band.

## Build and test

```bash
make test
```

The test builds two versions and runs both:
- **`double`:** must match MATLAB to rounding.
- **`float`:** the type used on a Cortex-M4F microcontroller. It must match within small tolerances, for example 1 N on the LPV force, which sums 442 terms.

Test vectors are in `test/vectors/` and come from `bench_export.m`:

| File | Cases | What it checks |
|---|---|---|
| `lpv.csv` | 200 | Random states, rail and loads (including beyond the load grid) → F* |
| `semiactive.csv` | 500 | Random force and speed → damping command (resist only, cap, floor) |
| `drive.csv` | 1000 | Random commands, current, speed, faults → current reference, inverter voltage, saturation, contactor, fault code |
| `bank.csv` | 1000 | Random bank states and powers (including full and empty) → next state and every power flow |

The host test also checks:
- the preview window after wrap-around;
- the smoothing against the exact exponential;
- that the scheduler drops only the faulty damper's contactor, and that the contactor stays dropped.

The MATLAB verification suite (`SwarmRide_Sim/scripts/run_all_checks.m`, `test_bench`) compiles and runs this test automatically when `gcc` is available.

## Porting to the microcontroller

- **Target:** an STM32G4-class Cortex-M4F at 170 MHz with FPU, motor-control timers and fast ADCs. Build with `-DSR_USE_FLOAT`.
- **Timing budget:**
  - At 100 Hz the LPV force takes about 900 multiply-adds, which is under 10 µs.
  - At 10 kHz each damper step takes about 30 operations.
  - The field-oriented control itself (Clarke and Park transforms, PWM) comes from the drive's own library. It takes `sr_current_ctrl`'s output as the q-axis voltage, or the reference as the q-axis current if the drive closes its own loop.
- **Still to write (next firmware steps):**
  1. A **state observer** that gives x (body bounce and pitch, bogie frames and their speeds) from the accelerometers and motor encoders.
  2. The **CAN interface** to the Train Brain, which sends the rail samples and the speed.
  3. **Gain scheduling by speed band.**
  4. The **hardware watchdog** heartbeat output.
- **Safety:** the contactor is held by hardware: the heartbeat, bank-OK comparator, gate enable and E-stop together. The firmware can only *drop* it, never hold it against a hardware fault.

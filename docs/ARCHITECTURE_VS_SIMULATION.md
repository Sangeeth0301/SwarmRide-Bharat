# Architecture vs simulation

Does the simulation (`SwarmRide_Sim`, Stages 1–4) match the system architecture diagram (`images/architecture.svg`)?

**Short answer: the core matches, but not every box.** The parts that make the ride better and the energy (the bogie and the coach controller) are in the Simulink model. The train-level parts (sensing on the locomotive, the track map, the data bus) are replaced by perfect values or are not modelled. Health monitoring is checked in MATLAB after the run.

![Architecture vs simulation](../images/architecture_sim_map.png)

Redraw with `python tools/draw_architecture_sim_map.py`.

## What one simulation run is

One half-coach (2 bogies) runs over 2 km of track at one constant speed. The 16-coach train and the all-day energy are scaled up afterwards in MATLAB (`sr_journey`). The whole train is never simulated at once.

## Box by box

Status key:

- **Simulink**: the box is a block in the Simulink model.
- **Partly**: part is in Simulink, and part is in the bench model or the firmware.
- **Ideal stand-in**: the box is replaced by a perfect value.
- **Offline**: a MATLAB script handles it after the run.
- **Not simulated**: the box is not modelled.

### ① Train level

| Architecture box | Status | Where in the simulation |
|---|---|---|
| Speed & position | Ideal stand-in | `Train Brain`: Clock × v. The speed is constant and the position is exact. A ±20 ms timing error is tested (check A5). |
| Lead-bogie sensing | Not simulated | The preview reads the true rail from the track table `TR.w`. |
| Fleet track map | Ideal stand-in | A perfect map: `TR.w`, plus the bad-spot list `bad_x` for C4. |
| Bump-warning scheduler | Simulink | `Train Brain (track preview)`: 221 rail samples, 1 s ahead, every 10 ms. |
| Loco pilot display | Not simulated | It is a screen, so there is no physics to simulate. |
| Train data bus | Not simulated | Every message arrives instantly and is never lost. |

### ② Vehicle level (one controller per coach)

| Architecture box | Status | Where in the simulation |
|---|---|---|
| Load estimation | Ideal stand-in | `Load estimate` is a constant m̂ = m(1 + err). A ±10 % error is tested (check A6). |
| LPV damping schedule | Simulink | `LPV state feedback + preview (100 Hz)`: F* = −Kx(m̂)·x, with LQR gains at 5 loads blended by m̂. |
| Preview feed-forward | Simulink | The same block adds −Kp(m̂)·p (controllers C3 and C4). |
| Health analytics | Offline | `sr_hot_axle` (bearing temperature) and an FFT of the coil voltage (wheel defects), in `check_stage4`. Parting detection is not modelled. |
| Report to Train Brain | Not simulated | There is no data bus in the model. |

### ③ Bogie level (×2 per coach)

| Architecture box | Status | Where in the simulation |
|---|---|---|
| Track & wheels | Simulink | `Track Input` (1,981 sines over 2 km) and `Wheel defect (front wheelset)`. |
| Smart EM damper | Simulink | `Smart Damper (EM)`: machine, current loop (τᵢ), passive part (oil, friction, inertance) and relay switch. |
| Active rectifier | Simulink | `Power Electronics` uses an average efficiency model. Switching is modelled only in the bench model (`SR_Bench`). |
| DC-DC converter | Simulink | `Power Electronics` uses an average efficiency model. |
| Power bank (supercap + LiFePO4) | Simulink | `Power Bank`: stored energy, SOC, dump and unserved load. |
| Energy supervisor | Simulink | `Power Bank / Energy supervisor`: charge, support and dump rules. |
| Bogie loads | Simulink | `Bogie Loads`: four constant loads, 8 W per bogie in total. |
| Fail-safe relay | Simulink | `Fail-safe Relay`: a test fault or a low bank switches the coil to the resistor. Verified by check A4. |
| Load sensing | Ideal stand-in | There is no sensor model. The controller gets m̂ directly. |
| Safety sensors | Offline | Their power use is in Simulink (`Bogie Loads`). Their detection is done offline (see Health analytics). |
| Bogie controller | Partly | The current loop is in Stage 4 (τᵢ), and the bench model has the PI loop at 10 kHz. Self-test and logging exist only in the C firmware. |

**Score: of the 22 boxes, 11 are in Simulink, 1 is partly simulated, 4 are ideal stand-ins, 2 are offline and 4 are not simulated.**

## What the old diagram got wrong or left out

1. **The LPV formula (now fixed in `images/architecture.svg`).** The old diagram showed c* = 2ζ√(k·m) with ζ held constant. The model uses LPV-LQR state feedback: F* = −Kx(m̂)·x − Kp(m̂)·p, with the gains blended by load. That force is then turned into a damping command.
2. **The semi-active conversion is missing.** The model converts F* into c* = F*·v/(v² + ε²), clipped between the damping floor and the coil limit (block `Semi-active conversion`).
3. **The C4 push is missing.** At known bad spots, the bank powers the damper as a motor (block `Active windows`). The old diagram shows energy flowing only from the damper to the bank.
4. **The ride-state input is missing.** State feedback needs the coach states x. The model feeds the true 8 states, sampled every 10 ms. A real coach needs accelerometers and a state estimator (Kalman filter).
5. **The coach and bogie plant is missing.** The model has `Vehicle Plant (half-coach 4-DOF)` between the track and the dampers.

## What this means

- The results we quote are backed by the Simulink parts: ride comfort (Wz), power into the bank, the fail-safe, and the gain across loads.
- The train-level results depend on ideal parts: a perfect preview, a perfect load estimate and perfect states. The checks show the result survives some error (A5: ±20 ms preview timing; A6: ±10 % load error). Sensor noise and an estimator are not tested yet.
- The next steps to close the gap:
  - add sensor noise and a Kalman state estimator;
  - add a model of the preview map's errors (a bump in the wrong place or of the wrong height);
  - add a data-bus delay.

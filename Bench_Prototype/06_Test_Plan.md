# 06 · Test plan: T1–T10

Each test has:
- **a drive file** for the rig and drive ([05_Test_Rig.md](05_Test_Rig.md));
- **a prediction** from the bench model (`SwarmRide_Sim/models/SR_Bench.slx`, real-hardware mode);
- **a pass band.**

The predictions and bands are also in [`expected_results.csv`](expected_results.csv), and the full predicted report is in [`bench_report.txt`](../SwarmRide_Sim/results/bench_report.txt).

**Order:** T1 → T2/T3 → T4 → T6 → T5 → T7 → T8 → T9 → T10.
- The fail-safe (T6) is proven **before** any high-speed or push test.
- Every test starts at 10% amplitude, then 50%, then 100%.

---

### T1 · Machine constant (back-EMF)

- **Drive file:** `back_emf.csv`. Constant-speed strokes at ±0.1 m/s (600 rpm), drive commanding **zero current**.
- **Measure:** inverter voltage (or line-to-line voltage) against stroke speed. Ke = voltage / speed. Also measure the line-to-line resistance with a 4-wire meter, cold.
- **Prediction:** Ke = **175.4 V s/m**, i.e. 23.9 V rms per 1000 rpm line-to-line; R = 0.33 Ω line-to-line.
- **Pass:** Ke ± 5%, R ≤ 0.35 Ω. If they are off, **update the simulation with the measured values before going on.** The damping range and efficiency follow directly from them.

### T2 · Damping law (and friction and inertance)

- **Drive file:** `damping_law.csv`. 1.5 Hz sine, 12 mm. First 4 s at **zero current** (friction and inertance alone), then damping 20, 40, 60, 80 and 100% of c_req (49 kN s/m), 4 s each.
- **Measure:** load-cell force and stroke.
  1. From the zero-current segment, fit friction Fc and inertance b (F = Fc · tanh(v/0.02) + b · a).
  2. Then, for each level, fit c from the remaining force.
- **Prediction:**
  - Measured damping = command within 0.1% at every level.
  - Friction 150 N, inertance 59 kg, which are the values the model was given.
- **Pass:**
  - c within ±5% of the command at every level.
  - Friction ≤ 300 N.
  - Inertance within the ride margin (section 3 of [02_Mechanical_Design.md](02_Mechanical_Design.md)).

### T3 · Harvesting efficiency

- **Drive file:** `damping_law.csv` (same run as T2).
- **Measure:** rig work (force × speed), DC power at the inverter, and power into the supercapacitor.
- **Prediction:**

| Damping (% of c_req) | 20 | 40 | 60 | 80 | 100 |
|---|---|---|---|---|---|
| Coil efficiency (1 − c/c_max) | 0.92 | 0.84 | 0.76 | 0.68 | 0.60 |
| Rig work → bank | 0.73 | 0.71 | 0.66 | 0.60 | 0.53 |

- **Pass:** coil efficiency ≥ 0.95 × predicted; rig work → bank ≥ 0.90 × predicted.

### T4 · Current loop

- **Drive file:** `current_step.csv`. Constant 0.05 m/s stroke; the damping command steps from 0 to c_req at 0.3 s.
- **Measure:** coil current (q-axis) at ≥ 10 kS/s.
- **Prediction:** first-order rise with a time constant of about 0.5 ms, no overshoot.
- **Pass:** time constant ≤ 1 ms. The vehicle model assumed 2 ms, so anything faster is on the safe side.

### T5 · Voltage limit (top speed)

- **Drive file:** `voltage_limit.csv`. 2 Hz sine growing from 2 to 30 mm (up to 0.38 m/s), full design damping.
- **Measure:** the stroke speed at which the inverter first runs out of voltage (drive saturation flag).
- **Prediction:**
  - Out of voltage at **0.36 m/s**.
  - Above 0.16 m/s the 46 A current limit caps the force, as designed.
  - The coach needs at most 0.16 m/s.
- **Pass:** saturation above 0.30 m/s. Above it the current is no longer controlled, and the over-current trip (T6 logic) must drop the contactor cleanly.

### T6 · Fail-safe (run before T5, T7, T8)

- **Drive file:** `fail_safe.csv`. 1.5 Hz sine, 12 mm, at today's damping; the fault input goes high at 5 s.
- **Repeat with each way of losing control:**
  - the fault input;
  - pulling the controller's power;
  - stopping the heartbeat (firmware halted);
  - bank voltage low (supply pulled down);
  - the E-stop.
- **Measure:**
  - force against speed after the fault;
  - the contactor's auxiliary contact;
  - the time with no electromagnetic force.
- **Prediction:** damping after the fault **17,500 N s/m**, which is today's damper per damper. There is a **20 ms gap** while the contactor moves, and no force spike.
- **Pass:**
  - Damping ± 10%.
  - Gap ≤ 30 ms.
  - The contactor stays dropped until a manual reset.

### T7 · Harvest on the replayed track

- **Drive files:**
  - `rough_track_C3.csv`: the front damper's motion and damping commands from the vehicle model, for a crowded LHB on rough track at 160 km/h;
  - `smooth_track_C3.csv`: the same on smooth track.
- **Measure:** rig work, coil current, DC power, power into the supercapacitor, and supercapacitor voltage.
- **Prediction:**

| | Rig work | Coil loss | Into the bank | Vehicle model |
|---|---|---|---|---|
| Rough track | 27.6 W | 7.8 W | **14.4 W** | 14.5 W |
| Smooth track | 10.6 W | 2.8 W | **5.1 W** | 5.3 W |

- **Pass:** into the bank within ±20% of the prediction. **This is the headline energy claim made real.**

### T8 · Push at a known bad spot

- **Drive file:** `settlement_push_C4.csv`. The damper's motion, damping and **push force** commands at a track settlement, for a crowded LHB at 160 km/h with controller C4.
- **Measure:** force against the push command inside the window, power from the supercapacitor, current and DC link voltage.
- **Prediction:**
  - **800 W** peak from the supercapacitor, 95 J per settlement;
  - force follows the command within **1.4%** RMS;
  - current up to 33 A, within the 46 A limit.
- **Pass:** tracking error ≤ 10% RMS; peak power within ±20%; no trip.

### T9 · Winding heat

- **Drive file:** `rough_track_C3.csv` looped for **2 h** (6 time constants), with `settlement_push_C4.csv` inserted once a minute.
- **Measure:** winding, housing, nut and resistor temperatures.
- **Prediction:** the winding settles at **42 °C** at 35 °C ambient (8.6 W average copper loss, time constant 20 min).
- **Pass:** ≤ 120 °C, the trip temperature. Then repeat T2 hot: c and friction within ±5% of the cold values.

### T10 · Controller in the loop (hardware-in-the-loop)

- **Setup:** a real-time computer runs the Simulink coach model (Stage 4), reads the load-cell force and commands the rig. The microcontroller runs the full firmware: 100 Hz LPV + preview, and 10 kHz drive.
- **Measure:** the virtual coach's ride index Wz and the power into the bank, on the same rail as Stage 3.
- **Prediction:** Wz ≈ 1.53 (today's damper 1.84) and about 33 W per bogie (twice this damper's share).
- **Pass:** Wz at least 10% better than today's damper. **Before T10:** the firmware host test must pass on the target (float build); 10 of 10 checks already pass on the PC.

---

## Gate B

All of T1–T8 within their bands, T9 under the trip temperature, and T10 at least 10% better than today. Then the simulation is updated with the measured Ke, R, friction, inertance and losses, and Stages 2–4 are rerun. See [07_Budget_and_Schedule.md](07_Budget_and_Schedule.md).

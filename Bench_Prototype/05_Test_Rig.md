# 05 · Test rig and instrumentation

The rig strokes the damper the way the coach does, and measures everything the simulation predicts. It is the **same kind of machine damper makers already use** to test today's oil dampers: a vertical frame with a displacement-controlled actuator below and a load cell above.

## 1. Rig requirements

| Item | Requirement | From |
|---|---|---|
| Actuator | Displacement-controlled (servo-hydraulic or electric roller-screw) | Replays the damper's motion from the vehicle model |
| Stroke | ±50 mm | Damper stroke ±40 mm + margin |
| Speed | ≥ 0.4 m/s | T5 sweeps to 0.38 m/s |
| Force | ≥ 10 kN dynamic | Damper peak 8 kN + inertia |
| Frequency | 0.2–20 Hz with the replayed waveforms | Coach motion is mostly below 15 Hz |
| Position accuracy | ±0.1 mm, tracking error ≤ 2% RMS on the drive files | The damper force depends on the speed it sees |
| Mounting | The LHB damper's eye-and-bush mounts, top and bottom | Same joints as on the bogie |

**How to get one:**
1. **Rent time** on a damper test machine at a damper supplier, a university or a research lab with a servo-hydraulic fatigue frame. This is cheapest for a first prototype.
2. **Build one in-house** with an electric linear actuator (10 kN, 0.5 m/s). Better for long campaigns and later hardware-in-the-loop work.

## 2. Measurements

| Channel | Sensor | Range | Rate | Used in |
|---|---|---|---|---|
| Damper force | Fatigue-rated load cell + amplifier | ±20 kN | 10 kS/s | T2, T6, T7, T8 |
| Stroke | Rig LVDT or encoder (and the motor encoder as a cross-check) | ±50 mm | 10 kS/s | All |
| Phase currents | Current probes or the drive's own sensors (logged) | ±75 A | 10 kS/s | T1, T4, T5, T8 |
| Inverter voltage command | Drive log | ±60 V | 10 kS/s | T5 |
| DC link power | Power analyser, or precision shunt + isolated voltage | 60 V / 50 A | 10 kS/s | T3, T7, T8 |
| Supercapacitor voltage and current | Isolated voltage + shunt | 50 V / 50 A | 1 kS/s | T7, T8 |
| Winding temperature | Motor's own sensor | 0–200 °C | 10 S/s | T9 |
| Resistor, housing and screw-nut temperatures | Thermocouples (type K) | 0–300 °C | 10 S/s | T6, T9 |
| Contactor state | Auxiliary contact | 0/1 | 10 kS/s | T6 |

**Data acquisition:** at least 12 isolated channels, 10 kS/s per channel, synchronised with the rig controller and the drive log. Every test is saved as a time-stamped file with the drive file name, the firmware version and the ambient temperature.

## 3. Drive files: the motion the rig plays

`drive_files/` holds one CSV per test, written by `SwarmRide_Sim/scripts/bench_export.m`. Each has 1 ms steps and the same columns:

| Column | Meaning |
|---|---|
| `time_s` | Time [s] |
| `stroke_mm` | Rig position [mm], centred |
| `speed_mm_per_s` | Rig speed [mm/s], for checking the rig's tracking |
| `damping_cmd_Ns_per_m` | Damping command sent to the drive [N s/m per damper] |
| `push_force_cmd_N` | Push force command (only inside a push window) [N] |
| `push_window` | 1 inside a push window at a known bad spot |
| `fault` | 1 = test fault input to the drive (fail-safe test) |

| File | Test | Length |
|---|---|---|
| `back_emf.csv` | T1: constant-speed strokes at ±0.1 m/s, zero current | 4 s |
| `damping_law.csv` | T2/T3: 1.5 Hz, 12 mm; damping 0, then 20–100% of c_req | 24 s |
| `current_step.csv` | T4: constant 0.05 m/s, damping steps at 0.3 s | 1 s |
| `voltage_limit.csv` | T5: 2 Hz, amplitude growing 2 → 30 mm, full design damping | 20 s |
| `fail_safe.csv` | T6: 1.5 Hz, 12 mm at today's damping; fault at 5 s | 10 s |
| `rough_track_C3.csv` | T7: **the damper's own motion and commands from the vehicle model**, crowded LHB on rough track at 160 km/h | 30 s |
| `smooth_track_C3.csv` | T7: same, smooth track | 30 s |
| `settlement_push_C4.csv` | T8: same, track settlement with the push at the known bad spot | 30 s |

## 4. Two ways to command the drive

1. **Open loop (first tests, T1–T9):** the test computer plays the damping and push columns to the drive at the same time as the rig plays the stroke. The drive runs only its 10 kHz loop. This tests the damper and drive exactly as the simulation used them.
2. **Closed loop (T10, hardware-in-the-loop):** a real-time computer runs the Simulink coach model. It reads the load-cell force, computes the coach motion and commands the rig's next position, while the firmware runs the full 100 Hz controller. The prototype then "rides" a virtual coach. This is the last step before a bogie.

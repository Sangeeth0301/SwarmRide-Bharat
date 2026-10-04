# 01 · Requirements: what one prototype damper must do

Every requirement comes from the simulation and has a bench test that proves it ([06_Test_Plan.md](06_Test_Plan.md)). The numbers are computed by `SwarmRide_Sim/functions/bp_hardware.m` from the damper's duty in the vehicle model, so they change automatically if the vehicle data change.

**Prototype:** the **LHB coach vertical secondary damper, design C** (geared rotary: ball screw + servo motor), sized for a crowded coach at 160 km/h. There are two per bogie, and the bench tests one.

## 1. The duty: what one damper really sees on the coach

From the vehicle simulation (`SwarmRide_Sim/scripts/check_bench.m`, section A). Crowded LHB coach, 160 km/h, front bogie.

| Case | Stroke speed RMS / max | Force RMS / max | Current RMS / max | Stroke max | Into the bank |
|---|---|---|---|---|---|
| Rough track, controller C3 | 0.034 / 0.115 m/s | 1.07 / 5.04 kN | 5.6 / 27.9 A | 15.8 mm | 14.5 W |
| Smooth track, C3 | 0.020 / 0.068 m/s | 0.67 / 3.11 kN | 3.3 / 16.9 A | 9.5 mm | 5.3 W |
| Track settlement with push, C4 | 0.014 / 0.163 m/s | 0.51 / 6.11 kN | 2.8 / 33.3 A | 15.6 mm | −1.9 W (pushing) |

**What this tells us:**
- The real duty is far below the 15 kN / 86 A safety rating the simulation used as a current clamp. So the motor and drive can be **much smaller**: 8 kN peak is enough, which is 30% above the highest simulated force.
- **Heat is not the problem.** Copper loss is about 8 W on rough track.
- **Peak force, top speed and the rotor's inertia are what matter.**

## 2. Requirements

| ID | Requirement | Value | Why | Proven by |
|---|---|---|---|---|
| R1 | Machine constant (force per amp = volts per m/s) | **Ke = 175 V s/m ± 5%** | Sets the damping range: c_max = Ke²/Rc = 123 kN s/m per damper | T1 |
| R2 | Equivalent resistance | **Rc ≤ 0.25 Ω** (0.33 Ω line-to-line) | Coil efficiency 1 − c/c_max; a higher resistance wastes harvest | T1, T3 |
| R3 | Peak force | **≥ 8 kN** | Simulated peak 6.1 kN (settlement push) + 30% | T2, T8 |
| R4 | Continuous force | **≥ 2.2 kN** | 2 × the rough-track RMS force | T9 |
| R5 | Stroke | **±40 mm** (bump stops), working ±16 mm | Simulated stroke ≤ 15.8 mm | T7 |
| R6 | Controlled speed | **≥ 0.30 m/s** at full design damping | Simulated speed ≤ 0.163 m/s; margin for worse track | T5 |
| R7 | Damping range | **0 to 49 kN s/m** per damper (c_req), within ±5% of the command | The controller asks for 0 … c_req | T2 |
| R8 | Push (motoring) | **≥ 0.8 kW** for 1 s, force tracking ≤ 10% RMS error | Settlement push: 721 W in the vehicle model, 800 W in the bench model | T8 |
| R9 | Current-loop speed | Time constant **≤ 1 ms** | The vehicle model assumes 2 ms; faster is better | T4 |
| R10 | Rotor + screw inertia | **J ≤ the limit from the margin study** (see section 3) | Inertia acts like a mass on the damper rod and stiffens the ride at high frequency | T2 |
| R11 | Friction (screw + seals) | **≤ 300 N** | Friction adds harshness at small strokes and wastes harvest | T2 |
| R12 | Fail-safe | Contactor drops in **≤ 30 ms**; damping then **17.5 kN s/m ± 10%** (= today's damper) | Safety rests on hardware, not software | T6 |
| R13 | Harvest | Into the bank on the rough-track replay: **14.4 W ± 20%** | The headline energy claim | T7 |
| R14 | Winding temperature | **≤ 120 °C** at 35 °C ambient, rough track + a push every minute | Class F insulation (155 °C) with margin | T9 |
| R15 | Firmware | Identical results to the MATLAB controller (host test) | The code that is tested is the code that was simulated | T10 |

## 3. The inertia budget

In design C the ball screw spins the motor fast: 1 mm of stroke is 36° of rotor turn. So the rotor's inertia appears at the damper rod as a large mass:

```
b = J · (2π / lead)²  =  J × 394,784  [kg per kg m²]
```

The simulation assumed J = 1.5 × 10⁻⁴ kg m², which is b = 59 kg. A 25 mm × 300 mm steel screw alone is 0.9 × 10⁻⁴ kg m². So the rotor would have only 0.6 × 10⁻⁴ kg m², which is less than most servo motors with 14 N m peak torque.

The margin study (`check_bench.m`, section D) reruns the vehicle model with more inertia and finds how much the ride can tolerate. See [README](README.md) and [`bench_report.txt`](../SwarmRide_Sim/results/bench_report.txt) for the result. It sets **R10** and drives the motor choice in [02_Mechanical_Design.md](02_Mechanical_Design.md).

## 4. Ratings that follow (one damper)

| Part | Rating |
|---|---|
| Motor | 3-phase permanent-magnet servo, 48 V class. **Kt 0.40 N m/A rms** (0.279 N m per amp of q-axis current). Back-EMF **23.9 V rms per 1000 rpm** line-to-line. R 0.33 Ω line-to-line. **14.1 N m peak, 3.9 N m continuous**. 1,800 rpm at 0.30 m/s. Motor constant ≥ 0.56 N m/√W |
| Ball screw | 25 mm diameter, **10 mm lead**, efficiency ≈ 0.9, 300 mm long, ±40 mm stroke |
| Inverter | 3-phase, 60 V DC link, 100 V MOSFETs, **46 A peak**, 4 A rms continuous per phase, 20 kHz PWM, four-quadrant (harvests and pushes) |
| Fail-safe | 3-pole changeover contactor (drops in 20 ms) and **3 × 1.0 Ω** star resistors, about 450 W each for a short pulse at 0.3 m/s |
| DC-DC | Bidirectional, 60 V ↔ 12–48 V, **1.5 kW** (both dampers of a bogie pushing) |
| Bank (per bogie) | Supercapacitor **10 F**: 18 cells × 180 F / 2.7 V in series, with balancing. LiFePO4 **8S 5 Ah** (128 Wh) with BMS |
| Controller | Cortex-M4F with FPU, 10 kHz current loop, 100 Hz vehicle control |

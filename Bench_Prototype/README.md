# SwarmRide bench prototype (Gate B)

> **In one line:** everything needed to build and test **one real design-C smart damper** in a lab: the hardware sized from the simulation, the controller firmware in C (checked against MATLAB), the motion files for the test rig, and a Simulink model of the bench test that predicts what the lab should measure.

**Status:**
- **Done:** the design package (this folder) and the bench model (`SwarmRide_Sim/models/SR_Bench.slx`).
- **Next:** buy the parts and build the hardware ([07_Budget_and_Schedule.md](07_Budget_and_Schedule.md)).

![Bench setup](images/bench_setup.png)

## Why a bench prototype

The simulation showed that SwarmRide rides better, makes its own power and catches faults (Stages 1–4). But a simulation is only as good as its assumptions. The bench prototype checks them **in metal, one damper at a time**:
- Does the real machine give the damping it is told to?
- Does the harvested power really reach the battery?
- Does the fail-safe really give today's damper back?
- Can it push at a bad spot without overheating?

## What is in this folder

| File | What it is |
|---|---|
| [01_Requirements.md](01_Requirements.md) | What one damper must do. Every number comes from the simulation and has a test (R1–R15) |
| [02_Mechanical_Design.md](02_Mechanical_Design.md) | Ball screw + servo motor layout, inertia and friction budgets, materials |
| [03_Electronics_Design.md](03_Electronics_Design.md) | Inverter, DC-DC, supercapacitor and battery, the hardware safety chain, sensors, protection |
| [04 · Firmware](firmware/README.md) | The C controller, drive and bank supervisor. Each function is a port of the MATLAB code, and a host test proves they match |
| [05_Test_Rig.md](05_Test_Rig.md) | The test rig, the measurements and the drive-file format |
| [06_Test_Plan.md](06_Test_Plan.md) | Tests T1–T10: how to run each one, the predicted result and the pass band |
| [07_Budget_and_Schedule.md](07_Budget_and_Schedule.md) | Indicative cost (≈ ₹4.4–13.5 lakh with contingency), 16-week plan, Gate B criteria |
| [08_Safety.md](08_Safety.md) | Hazards and rules for the lab |
| [BOM.csv](BOM.csv) | Bill of materials with specifications and indicative prices |
| [expected_results.csv](expected_results.csv) | The numbers the bench must reproduce, with acceptance bands (generated) |
| [drive_files/](drive_files) | Rig motion and drive commands for every test, including the damper's own motion from the coach simulation (generated) |
| [firmware/](firmware) | C source, generated gains (`include/sr_params_lhb.h`), host test and MATLAB test vectors |

The bench **model** and its full report are in the simulation folder: [SwarmRide_Sim/Stage5_Bench.md](../SwarmRide_Sim/Stage5_Bench.md).

## The prototype in numbers (one LHB damper, design C)

| | |
|---|---|
| Motor | 3-phase PM servo, 48 V class, Kt 0.40 N m/A rms, 14 N m peak, 3.9 N m continuous |
| Ball screw | Ø25 mm, 10 mm lead, ±40 mm stroke |
| Force | 8 kN peak (simulated peak 6.1 kN), 2.2 kN continuous |
| Drive | 60 V DC link, 46 A peak, four-quadrant, 10 kHz current loop |
| Fail-safe | Changeover contactor + 3 × 1.0 Ω resistors = today's damping (17.5 kN s/m) |
| Bank (per bogie) | 10 F supercapacitor + 128 Wh LiFePO4 |

## What the bench model predicts (the lab must reproduce these)

| Test | Prediction |
|---|---|
| T1 Machine constant | 175.4 V s/m = 23.9 V rms per 1000 rpm, line-to-line |
| T2 Damping law | Measured damping = command within 0.1% from 20 to 100% of c_req |
| T3 Efficiency | Coil 0.92 → 0.60 (= 1 − c/c_max); rig work to the bank 0.73 → 0.53 |
| T4 Current loop | Time constant ≈ 0.5 ms (the vehicle model assumed 2 ms) |
| T5 Voltage limit | The drive controls braking up to 0.36 m/s at full damping; the coach needs 0.16 m/s |
| T6 Fail-safe | 17,500 N s/m after the fault (today's damper: 17,500), with a 20 ms gap while the contactor moves |
| T7 Harvest | **14.4 W** into the bank on the replayed rough track (vehicle model 14.5 W); 5.1 W on smooth track |
| T8 Push | 800 W peak from the supercapacitor, 95 J per settlement, force tracking error 1.4% |
| T9 Heat | Winding settles at 42 °C (35 °C ambient, rough track + a push every minute); the trip is at 120 °C |
| T10 Firmware | C = MATLAB: 10 of 10 host checks pass in double and in float |

## Three findings from designing the prototype

1. **The real duty is light.** On the coach the damper sees at most 6.1 kN and 0.16 m/s, and about 8 W of coil loss. The 15 kN / 86 A clamp in the vehicle model was a safety cap, not a need. So the motor and drive are a **1–1.5 kW-class 48 V servo**, not a large machine.
2. **Rotor inertia is not the problem it looked like.** A ball screw makes even a small rotor look like hundreds of kilograms at the rod. But the vehicle model shows the ride gets slightly *better* up to 16× the assumed inertia, and stays within 2% at 32×. **Friction** is the budget to watch: 600 N loses a fifth of the harvest.
3. **The fail-safe has a 20 ms gap.** While the contactor moves, the damper gives no electromagnetic force. At 1.5 Hz that is a small dip. The bench must confirm it, and a faster solid-state bypass is an option for the bogie version.

# 07 · Budget and schedule

> **Indicative only.** Costs are rough ranges for parts bought in India (October 2026) and have not been quoted by suppliers. Get at least two quotes per item before committing. Engineering time is not included.

## 1. Budget (from [`BOM.csv`](BOM.csv))

| Group | What | Low (₹) | High (₹) |
|---|---|---|---|
| Damper mechanics | Ball screw, supports, coupling, housing and rod, LHB mounting eyes, seals | 61,500 | 1,60,000 |
| Motor | 48 V-class servo motor with encoder and winding sensor | 25,000 | 70,000 |
| Drive | Inverter, controller board, contactor, fail-safe resistors, safety-chain board | 27,500 | 95,500 |
| Power bank | DC-DC, supercapacitor bank, LiFePO4 battery, capacitors and fuses, brake chopper | 51,000 | 1,27,000 |
| **Prototype hardware** | | **1,65,000** | **4,52,500** |
| Test | 10 days of rig time, power analyser, DAQ, electronic load, lab supply, safety items | 2,05,000 | 6,70,000 |
| **Total** | | **3,70,000** | **11,22,500** |
| Contingency (20%) | Second motor or screw if the inertia budget is missed; remachining | 74,000 | 2,24,500 |
| **Total with contingency** | | **≈ ₹4.4 lakh** | **≈ ₹13.5 lakh** |

**Ways to reduce cost:**
- **Use a partner's rig and DAQ.** A university or damper maker already has them, which removes most of the "Test" line.
- **Start with a commercial 48 V servo drive.** This avoids a custom inverter for the first prototype.
- **Build the second damper of the bogie later.** It is not needed for the bench tests.

## 2. Schedule (16 weeks)

| Weeks | Work | Output | Gate |
|---|---|---|---|
| 1–3 | Detailed design: choose the motor (inertia budget, Kt, R), CAD of housing and screw, schematics of the safety chain and bank | Drawings, motor datasheet check against [01_Requirements.md](01_Requirements.md) | Design review |
| 2–8 | Procurement (motor, ball screw and supercapacitor cells have the longest lead times) | Parts in hand | — |
| 5–9 | Machining and assembly of the damper | Damper assembled, hand-turned, friction checked | Friction ≤ 300 N by hand test |
| 6–10 | Electronics bring-up: drive, contactor and safety chain, DC-DC, bank. Firmware on the microcontroller; host test passing on the target (float build) | Drive spins the motor on the bench; fail-safe chain tested | Safety review |
| 10–11 | Rig integration: mounting, sensors, DAQ, drive-file playback, dry runs | First strokes at 10% amplitude | Lab sign-off |
| 11–14 | Tests T1–T9 ([06_Test_Plan.md](06_Test_Plan.md)) | Measured data, compared with the predictions | — |
| 14–15 | T10: hardware-in-the-loop with the Simulink coach model | Prototype rides a virtual coach | — |
| 15–16 | Report; update the simulation with the measured Ke, Rc, J, friction and losses; rerun Stages 2–4 | Bench report, updated results | **Gate B** |

## 3. Gate B: the decision after the bench

The prototype passes Gate B when:
1. **T1, T2, T3, T6 and T7 meet their acceptance bands.** These cover the damping law, efficiency, fail-safe and harvested power.
2. The simulation, **rerun with the measured hardware values, still shows the ride and energy gains of Stage 3**. That means Wz at least 10% better than today on the crowded LHB, and the bogie self-powered.
3. No safety finding is open.

If Gate B passes, the next step is an **instrumented field run on one LHB bogie** (Gate C), which needs RDSO engagement.

## 4. People and partners

| Role | Needed for |
|---|---|
| Mechanical engineer (damper design, machining) | Weeks 1–9 |
| Power electronics and firmware engineer | Weeks 1–15 |
| Test engineer at the rig partner | Weeks 10–15 |
| **Partners to approach:** a damper or bogie component maker, a university vehicle-dynamics or power-electronics lab, and RDSO for the test plan's acceptance criteria | — |

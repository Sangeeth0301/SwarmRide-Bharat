# 08 · Bench safety

The prototype stores energy, moves with kilonewtons of force and carries tens of amps. Agree these rules with the lab before the first test.

## 1. Hazards

| Hazard | Size | Control |
|---|---|---|
| Stored energy: supercapacitor | 11.5 kJ at 48 V, short-circuit current of kiloamps | Discharge resistor and switch; voltmeter check before touching; insulated tools; covers over the terminals |
| Stored energy: battery | 128 Wh LiFePO4 | BMS, fuse and isolator on the pack; kept in a fire-safe box during tests |
| DC link | 60 V, 470 µF | Bleed resistor (discharges below 5 V in under 10 s); no work on the drive with the link live |
| Moving rig | 10 kN, 0.4 m/s | Guard around the frame with an interlocked door; E-stop at the operator's desk; rig limits set to ±45 mm, inside the damper's ±40 mm bump stops plus compliance |
| Pinch and crush | Damper ends and rig crosshead | Nobody inside the guard while the actuator is powered |
| Hot surfaces | Fail-safe resistors (pulses of 450 W), motor | Resistors on a heat sink behind a cover; thermocouples with alarm at 150 °C |
| Electric shock | ≤ 60 V DC (safe extra-low voltage), but high current | Insulated tools; no rings or watches; fused test leads |
| Unexpected motoring (push) | The damper can push with up to 8 kN | Push tests only with the guard closed; the drive accepts a push command only when the test computer's push window is armed |

## 2. Before every test

1. Guard closed, E-stop tested (it must drop the contactor **and** stop the rig).
2. Supercapacitor and DC link voltages read and logged.
3. Rig limits and the drive current limit (46 A) checked.
4. The drive file and firmware version recorded in the test log.
5. A dry run at 10% amplitude.

## 3. Emergency stop chain

**E-stop → rig hydraulics (or servo) off → contactor coil off → damper on the fail-safe resistors.**

A stopped rig with a damper on its resistors is safe: the damper behaves like today's oil damper.

## 4. After testing

Discharge the supercapacitor to below 5 V through the discharge resistor before any work on the power wiring. Log the reading.

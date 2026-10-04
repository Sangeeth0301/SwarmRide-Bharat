# 03 · Electronics design

![Bench setup](images/bench_setup.png)

The electronics do three jobs:
- **control the coil current**, because the current is the damping;
- **move energy** between the coil and the power bank, in both directions;
- **fall back to today's passive damper** on any fault, using hardware only.

## 1. Power path

```
motor (3 phases) ─┬─ changeover contactor ─┬─ NC: 3 × 1.0 Ω star resistors  (fail-safe = today's damping)
                  │                         └─ NO: 3-phase inverter ── DC link 60 V ── bidirectional DC-DC ── supercapacitor 10 F (12–48 V)
                  │                                                                                     └── LiFePO4 8S 5 Ah ── bogie electronics (8 W)
```

| Stage | Choice | Rating | Why |
|---|---|---|---|
| **Inverter** | 3-phase, 6 × 100 V MOSFETs (about 4 mΩ), 20 kHz PWM, field-oriented control | 46 A peak, 4 A rms continuous per phase | Four-quadrant: brakes (harvests) and motors (pushes). Off-the-shelf 48 V servo drives with a torque or current input can be used for the first prototype |
| **DC link** | 60 V, 470 µF low-ESR electrolytic + 10 µF film | 100 V parts | 60 V lets the drive control braking up to 0.30 m/s. Above that speed the back-EMF exceeds the inverter's voltage and the current is no longer controlled |
| **DC-DC** | Bidirectional 4-switch buck-boost, 60 V ↔ 12–48 V | 1.5 kW (both dampers of a bogie pushing), efficiency ≈ 94% | Holds the DC link constant while the supercapacitor voltage swings 12–48 V |
| **Supercapacitor** | 18 cells × 180 F / 2.7 V in series, with active balancing | 10 F, 48.6 V, 11.5 kJ | Catches the kW bursts of harvesting and pushing. The battery cannot: it is limited to 100 W discharge |
| **Battery** | LiFePO4 8S (25.6 V) 5 Ah with BMS | 128 Wh | Stores energy for stations and nights, and runs the bogie electronics |
| **Fail-safe resistors** | 3 × 1.0 Ω, 100 W aluminium-housed, star-connected | About 450 W each for 1 s at 0.3 m/s | Equivalent resistance 1.51 Ω gives c = Ke²/(Rc + R_fs) = 17.5 kN s/m, which is exactly today's damper |
| **Contactor** | 3-pole changeover (or two 3-pole contactors, mechanically interlocked), 24 V DC coil, **normally closed onto the resistors** | ≥ 50 A, drops in ≤ 20 ms | Unpowered = resistors connected = passive damper |

**Why the equivalent-DC numbers convert this way.** The simulation models a DC machine. The real 3-phase motor in field-oriented control behaves the same way on its q-axis, with these conversions (amplitude-invariant dq):
- torque = Kt · iq
- copper loss = 1.5 · R_phase · iq², so R_phase = Rc / 1.5 = 0.167 Ω
- the largest voltage the inverter can apply is (√3/2) · Vdc = 52 V equivalent at 60 V DC

## 2. Control and sensing

| Signal | Sensor | Rate | Used for |
|---|---|---|---|
| Phase currents (2 or 3) | Shunts + isolated amplifiers, or Hall sensors, ±75 A | 20 kHz | Current loop, over-current trip |
| Rotor angle and speed | Motor encoder (≥ 2,500 lines, or an absolute encoder) | 20 kHz | Field orientation. **Also gives the damper stroke and stroke speed (lead × turns), so no separate stroke sensor is needed** |
| DC link and supercapacitor voltage | Resistor dividers + isolated ADC | 10 kHz | DC-DC control, bank-low trip |
| Winding temperature | Sensor in the motor winding (KTY84 or PT1000) | 10 Hz | Over-temperature trip (120 °C) |
| Air-spring pressure (on the coach) | 0–10 bar transducer | 100 Hz | Load estimate for the LPV gains |
| Body and bogie accelerations (on the coach) | MEMS accelerometers | 1 kHz | State observer (next firmware step) |

**Microcontroller:** Cortex-M4F with FPU (for example the STM32G4 family). It has motor-control timers, fast ADCs and CAN-FD, and runs the firmware in [`firmware/`](firmware/). The first prototype may instead use a commercial drive's own current loop, with the SwarmRide firmware on a separate board sending the q-axis current reference.

## 3. Hardware safety chain

The contactor coil is powered through **four series contacts**. If any one opens, the coil loses power and the damper falls back to the resistors:

1. **Heartbeat:** a retriggerable monostable fed by the microcontroller. If the firmware stops, it times out in under 5 ms.
2. **Bank OK:** a comparator on the supercapacitor voltage (> 12 V), so the controller is never left without power.
3. **Gate-driver enable:** the same signal that enables the inverter's gates. The inverter and contactor can never both drive the coil.
4. **Emergency stop** on the rig.

The firmware's fail-safe supervisor (`sr_failsafe`) can **only open** this chain. It drops on a test fault, bank low, over-temperature or over-current, and latches until a manual reset. It can never hold the contactor in against the hardware. The model predicts a **20 ms gap** with no electromagnetic force while the contactor moves. Test T6 measures it.

## 4. Protection

| Hazard | Protection |
|---|---|
| Over-current | Hardware comparator on the phase currents (60 A), plus the firmware trip at 1.2 × 46 A |
| DC link over-voltage (pushing back, a fast stroke) | Brake chopper with a 10 Ω resistor at 70 V, plus a TVS diode |
| Supercapacitor over-voltage | The balancing board limits each cell to 2.7 V; the DC-DC stops charging at 48 V; a dump resistor takes the surplus |
| Battery | BMS: cell voltage, current and temperature; contactor on the pack |
| Reverse polarity, shorts | DC fuses (80 V, 63 A) on the battery and the supercapacitor |

## 5. Grounding and EMC (for the bench, and to prepare for the bogie)

- Star ground at the DC link. Twisted, shielded motor cable, with the shield bonded at both ends.
- Sensor and communication wiring kept 300 mm from the phase cables.
- Isolation (≥ 1 kV) between the power stage and the DAQ.
- For the bogie later, three railway standards apply: EN 50155 (rolling-stock electronics), EN 50121-3-2 (EMC) and IEC 61373 (shock and vibration). That is outside this bench step.

# SwarmRide Bharat: Whitepaper

**Self-powered, load-adaptive, train-synchronised suspension for Indian Railways**

Version 0.1 · October 2026 · Sangeeth
Status: concept defined; simulation Stages 1–3 complete (today's trains; smart damper and power chain; load-adaptive and preview controllers)

> **Confidential.** This document describes an invention that has not yet been filed for patent protection. Do not publish or present it openly before a provisional patent application is filed.

---

## Abstract

Every Indian Railways coach and wagon carries secondary-suspension dampers that turn vibration into heat and are tuned for a single load. At the same time, safety problems such as track defects, hot axles and train parting are checked only at fixed sites or at intervals, and goods wagons have no electricity to run sensors.

SwarmRide Bharat replaces the passive damper with an **electromagnetic smart damper**. The same device:
- **harvests** suspension energy into a per-bogie power bank
- **controls** the ride through the current it draws, adapting damping to the **measured load**
- **powers** on-bogie safety sensors

A **Train Brain** in the locomotive or driving cab shares the track ahead with every vehicle behind it, which receives each bump after t = d/v and prepares for it.

A verified MATLAB/Simulink model of today's Indian trains (LHB, Vande Bharat, ICF, BOXN) shows the baseline problem:
- fixed dampers lose **17–30% of their damping ratio** as load rises
- they turn **20–90 W per bogie** (coaches) and up to about **210 W per bogie** (loaded BOXN) into heat

A preview study estimates **about 24% lower body vibration** with self-sufficient bogie power. That estimate is to be confirmed in the next simulation stages.

---

## 1. Problem

| # | Problem | Evidence |
|---|---|---|
| 1 | Track defects are the largest cause of derailments | CAG Report 22 of 2022: 171 derailments from poor track maintenance (2017–21); track-recording checks 30–100% short of schedule |
| 2 | Hot axles | About 3 cases per day (Railway Board minutes, 2025); bearings checked at only about 25 trackside sites |
| 3 | Train parting | 643 partings and 2,059 wagon detachments in 2018–19 |
| 4 | Crowded coaches ride worse | Dampers are tuned for one load (shown in our baseline, Section 5) |
| 5 | Damper energy wasted | All suspension motion becomes heat (Section 5) |
| 6 | No power on wagons | Freight wagons cannot run continuous sensors |

Full sources: [`SwarmRide_Bharat_Pitch.md`](../SwarmRide_Bharat_Pitch.md).

## 2. The SwarmRide system

![System overview](../images/system-overview.png)

```
LEVEL 1  TRAIN BRAIN (loco / driving cab)
         track ahead · timed bump warnings (t = d / v) · health view for the loco pilot
                │ data only
LEVEL 2  VEHICLE CONTROLLER (per coach / wagon)
         weighs the vehicle · sets damping for the load · collects sensor data
                │
LEVEL 3  BOGIE UNIT (self-powered)
         smart dampers · power bank (supercap + LiFePO4) · sensors · fail-safe relay
```

**Two products, one technology**

| Product | Market | Main value |
|---|---|---|
| SwarmRide Freight | Goods wagons (BOXN, Casnub bogie), Dedicated Freight Corridors | Safety: every axle watched, partings located, track recorded, with no wiring |
| SwarmRide Vande Bharat | Vande Bharat chair car and sleeper trainsets | Comfort: ride tuned to load and to the bump ahead |

## 3. Core technology

### 3.1 Electromagnetic smart damper

A tubular permanent-magnet machine (NdFeB magnets, copper coils) mounted in place of the secondary damper.

```
Generated voltage   e = Kₑ · v_rel                       (Faraday's law)
Damper force        F = Kₑ · i                            (Lorentz force)
Effective damping   c = Kₑ² / (R_coil + R_load)           set by the power electronics
Harvested power     P = c · v_rel² · R_load / (R_coil + R_load)
```

- The **number of coil turns** sets the voltage level, not the damping. The maximum damping is set by magnet strength and copper volume: c_max = B²·V_cu/ρ.
- **Three design variants** will be simulated:
  - **A:** direct-drive linear
  - **B:** hybrid, a small passive damper plus a smart damper
  - **C:** geared or rotary
- **Fail-safe:** on power loss, a relay connects the coil to a sized resistor, so the damper behaves like a normal passive damper.

### 3.2 Power chain (per bogie)

```
coil ─► active H-bridge rectifier ─► DC-DC converter ─► supercapacitor ─► LiFePO4 ─► sensors / controller / radio
        (current sets damping)        (raises voltage,    (catches kW      (energy
                                       not energy)          peaks)            store)
```

Energy priority: safety sensors, then communication, ride control, reserve, and surplus last.

### 3.3 Control

| Controller | Description | Role |
|---|---|---|
| C0 | Today's passive damper | Baseline |
| C1 | Fixed-load harvester (research approach) | Competitor benchmark |
| C2 | **LPV load-adaptive**: gridded LQR scheduled on measured load, with a passivity limiter (the damper can only resist motion) | SwarmRide core |
| C3 | **C2 + Train Brain preview** feed-forward | SwarmRide full |
| C4 | Model predictive control | Offline upper bound |

The key equation: to keep the damping ratio ζ constant at any load,

```
c_target = 2 · ζ · √(k · m)        (m = measured body mass, k = spring stiffness at that load)
```

## 4. Simulation method

- A **half-coach, 4-DOF vertical model** (body bounce, body pitch, two bogie frames) with primary and secondary suspension, driven by four wheel inputs delayed by distance ÷ speed.
- A **vertical track irregularity spectrum** (good and poor quality) with a fixed random seed, so every controller sees the identical rail.
- **Comfort** is scored by RMS body acceleration and Sperling Wz; **safety** by secondary stroke; **energy** by harvested watts after losses.
- **Fair comparison:** the coach, rail, speed and load stay the same, and only the damper block changes.

Details: [`SwarmRide_Sim/Stage1.md`](../SwarmRide_Sim/Stage1.md).

## 5. Results so far: baseline of today's Indian trains (Stage 1)

Model verified against an independent state-space model to within **0.003%**, and against a hand calculation of the bounce frequency.

| Vehicle | Load | Damping ζ | Sperling Wz | Max stroke | Heat wasted per bogie |
|---|---|---|---|---|---|
| LHB, 160 km/h | empty → 12 t | 0.14 → **0.10** | 1.73 → 1.84 | 20 → 25 mm | 64 → 73 W |
| Vande Bharat, 160 km/h | empty → 7.6 t | 0.12 → **0.10** | 1.75 → 1.79 | 23 → 25 mm | 82 → 87 W |
| ICF, 110 km/h | empty → 15 t | 0.08 → **0.06** | 1.45 → 1.38 | 10 → 14 mm | 23 → 31 W |
| BOXN, 100 km/h | empty → 67 t | friction | 2.28 → 2.15 | 3 mm | 36 → **214 W** |

![Damping ratio vs load](../SwarmRide_Sim/results/stage1b_zeta_vs_load.png)

**Findings:**
1. Fixed dampers weaken as load rises on every coach type. This is the gap load-adaptive control closes.
2. Damper power arrives in short bursts (peaks around 1 kW against a 73 W average on LHB). A supercapacitor is required.
3. Every bump reaches each later wheel after d/v (0.34 s within a coach, about 5 s from the locomotive to the tenth coach at 160 km/h). This is the window for preview.
4. Goods wagons ride hardest and waste the most energy, yet have no power today. This is the strongest case for self-powered sensing.

## 5b. Results so far: the smart damper and power chain (Stage 2)

Today's damper was replaced by the electromagnetic damper, active rectifier, DC-DC converter and supercapacitor + LiFePO4 bank, with designs A (direct-drive), B (hybrid) and C (geared rotary) sized per vehicle. Verification: same ride as today (Wz 1.846 vs 1.844), damping law within 0.09%, energy balance within 0.001%, fail-safe exactly equal to today's damping.

| Same ride as today, crowded, top speed | Poor track: into the bank | Good track | Bogie loads |
|---|---|---|---|
| LHB | 46–51 W per bogie | 17–18 W | 8 W |
| Vande Bharat | 55–62 W | 21–22 W | 8 W |
| ICF | 21–23 W | 7.3–8.6 W | 8 W |
| BOXN (wedges replaced) | 78–90 W | 29–33 W | 8 W |

![Where the power goes](../SwarmRide_Sim/results/stage2_power_chain.png)

**Findings:** each bogie powers itself on normal track; smooth track is the weak case; harvesting at "maximum power transfer" delivers less to the bank because it heats the coil; on freight the friction wedges must be replaced (an EM damper beside them sees almost no motion), which also cuts wagon body vibration by more than half in this model. Design C leads on energy and size. Full report: [`SwarmRide_Sim/Stage2.md`](../SwarmRide_Sim/Stage2.md).

## 5c. Results so far: the controllers (Stage 3)

An LPV (load-scheduled) LQR at 100 Hz, with an optional Train Brain preview of the rail ahead, is clipped to what the semi-active damper can do (resist only, efficiency limit). Verified stable at every load, passive, energy-consistent, fail-safe, and robust to a ±20 ms warning error and a ±10% load-estimate error.

| Sperling Wz, poor track | Empty | Half | Full | Into the bank (full) |
|---|---|---|---|---|
| LHB today → SwarmRide | 1.73 → 1.49 | 1.78 → 1.50 | 1.84 → 1.53 | 33 W |
| Vande Bharat today → SwarmRide | 1.75 → 1.47 | 1.77 → 1.48 | 1.79 → 1.50 | 38 W |
| ICF today → SwarmRide | 1.45 → 1.35 | 1.34 → 1.28 | 1.38 → 1.23 | 13 W |
| BOXN today → SwarmRide | 2.28 → 2.32 | 2.15 → 1.79 | 2.15 → 1.66 | 55 W |

![Ride at every load](../SwarmRide_Sim/results/stage3_ride_vs_load.png)

**Findings:**
- The ride is better at every load: 15–17% on crowded LHB and Vande Bharat coaches, 23% on a loaded wagon.
- Body vibration is about 40% lower, and the bogie stays self-powered.
- No fixed setting reaches this comfort.
- The Train Brain preview adds only 1–2% with a resist-only damper; using it fully needs brief active pushing.
- The empty goods wagon does not ride better.

Full report: [`SwarmRide_Sim/Stage3.md`](../SwarmRide_Sim/Stage3.md).

## 6. Expected results (preview study)

From a simplified Python model; **targets until confirmed in Simulink Stages 2–3.** Crowded coach, poor track, 160 km/h.

| Measure | Today | Fixed-load harvester | SwarmRide |
|---|---|---|---|
| Body RMS acceleration | 0.165 m/s² | 0.224 m/s² | **0.125 m/s²** (−24%) |
| Sperling Wz | 1.82 | 2.06 | **1.65** |
| Harvested power per bogie | 0 W | about 45 W | about 10–40 W (depends on Kₑ) |

![Comfort vs power](../pdf/results/r6_pareto.png)

A plain harvester trades comfort for watts. SwarmRide improves comfort **and** produces enough power for its own bogie electronics and sensors (about 5–20 W).

## 7. What is new

No single component is new. The invention is the combination:
1. Suspension energy that powers the suspension's own control **and** the bogie's safety sensors.
2. Damping scheduled on measured load, to keep the ride constant.
3. A bump warning shared along the train, timed by distance and speed.
4. Every vehicle reporting its health, so a parting is located at the exact wagon.
5. A daily track map from the damper signals of every train.
6. A fail-safe that reverts to passive damping.

Prior art to distinguish: energy-harvesting dampers in research, OMRS, EoTT, Track Recording Cars, air-spring load weighing, and a self-powered end-of-train unit (US 5,267,473).

## 8. Roadmap

![Roadmap](../images/roadmap.png)

| Stage | Content | Status |
|---|---|---|
| Simulation 1 / 1b | Test rig and baseline of today's trains | **Done** |
| Simulation 2 | Smart damper (A/B/C), power chain, fail-safe, harvested watts per train | **Done** |
| Simulation 3 | LPV and preview controllers, head-to-head comparison | **Done** |
| Simulation 4 | Self-powered health sensors demo, investor dashboard | Planned |
| Bench prototype | One damper on a test rig | After simulation |
| Field pilot | Freight wagons, then Vande Bharat | After RDSO engagement |

## 9. Limits and risks

- Many model parameters are engineering estimates and must be replaced with RDSO or manufacturer data.
- The model is vertical only; lateral dynamics and wheel–rail contact come later.
- Harvested power is small (tens of watts per bogie). It is sized for the bogie's own needs, not for traction or HVAC.
- A direct-drive damper with enough force may be large and heavy. Designs B and C address this.
- Railway approval (RDSO) and safety certification are long processes.

## 10. Documents

| Document | Purpose |
|---|---|
| [`SwarmRide_Bharat_Pitch.md`](../SwarmRide_Bharat_Pitch.md) / `.pdf` / `.docx` | Investor pitch, Indian Railways edition |
| [`SwarmRide_Bharat_Technical_Document.md`](../SwarmRide_Bharat_Technical_Document.md) | Full technical design |
| [`SwarmRide_Bharat_Complete_Guide.md`](../SwarmRide_Bharat_Complete_Guide.md) | From-scratch understanding and simulation guide |
| [`SwarmRide_Simulation_Results_Preview.pdf`](../SwarmRide_Simulation_Results_Preview.pdf) | Expected results preview |
| [`SwarmRide_Sim/Stage1.md`](../SwarmRide_Sim/Stage1.md) | Stage 1 simulation report |
| [`SwarmRide_Sim/Stage2.md`](../SwarmRide_Sim/Stage2.md) | Stage 2 simulation report |
| [`SwarmRide_Sim/Stage3.md`](../SwarmRide_Sim/Stage3.md) | Stage 3 simulation report |

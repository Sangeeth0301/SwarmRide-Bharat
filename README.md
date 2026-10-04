<p align="center">
  <img src="images/hero.jpg" alt="SwarmRide Bharat: self-powered, load-adaptive, train-synchronised suspension" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-simulation%20complete%20%C2%B7%204%20of%204%20stages-2A9D8F?style=flat-square" alt="status">
  <img src="https://img.shields.io/badge/MATLAB%20%2F%20Simulink-R2024b-0076A8?style=flat-square" alt="MATLAB/Simulink R2024b">
  <img src="https://img.shields.io/badge/rolling%20stock-LHB%20%C2%B7%20Vande%20Bharat%20%C2%B7%20ICF%20%C2%B7%20BOXN-13233A?style=flat-square" alt="rolling stock">
  <a href="SwarmRide_Sim/VERIFICATION.md"><img src="https://img.shields.io/badge/verification-test%20suite-2A9D8F?style=flat-square" alt="verification"></a>
  <img src="https://img.shields.io/badge/licence-proprietary-8A93A0?style=flat-square" alt="licence">
</p>

<p align="center">
  <b>Every bogie powers itself, tunes its own ride and watches its own safety,<br>
  while the locomotive warns every coach of the bump ahead.</b>
</p>

> **Confidential.** This repository describes an invention being prepared for patent filing. Do not share or make it public before a provisional application is filed.

---

## Overview

Every coach and wagon on Indian Railways carries **secondary dampers** that turn vibration into heat and are tuned for a single load. The same fleet loses trains to track defects, hot axles and train parting, and its goods wagons have **no electricity** to run sensors.

**SwarmRide Bharat** replaces the passive damper with an **electromagnetic smart damper**. That one device harvests energy, controls the ride, and powers the bogie's own safety sensors. A **Train Brain** in the locomotive shares each bump with every vehicle behind it, so each coach prepares before the bump arrives.

| | |
|---|---|
| **Replaces** | The passive secondary damper: one part, same mounting points |
| **Adds** | Energy harvesting · load-adaptive damping · train-wide bump preview · self-powered safety sensing |
| **Markets** | Freight wagons (BOXN, Dedicated Freight Corridors) · Vande Bharat trainsets |
| **Stage** | Simulation complete (Gate A met): test rig, smart damper, power chain, controllers, active push, full-day power and health sensing verified in Simulink · bench prototype next |

---

## The problem

| Gap on today's railway | Evidence |
|---|---|
| **Track defects** are the largest cause of derailments | 171 derailments from poor track maintenance, 2017–21; track-recording runs 30–100% short of schedule *(CAG Report 22 of 2022)* |
| **Hot axles** are caught only at fixed trackside sites | About 3 cases a day *(Railway Board, 2025)*; bearings checked at about 25 OMRS sites |
| **Train parting** is detected only at the last wagon | 643 partings and 2,059 wagon detachments in 2018–19 |
| **Crowded coaches ride worse** | Fixed dampers lose 17–30% of their damping as load rises *(our simulation)* |
| **Damper energy is wasted** | 20–90 W per coach bogie, about 210 W per loaded wagon bogie, all heat *(our simulation)* |
| **Goods wagons have no power** | No continuous on-board monitoring is possible today |

---

## The solution

| Capability | How it works | Core relation |
|---|---|---|
| **Harvest** | Suspension motion moves magnets through a coil and charges a power bank on the bogie | e = Kₑ · v |
| **Control** | Power electronics set the coil current, and the current sets the damping, matched to the measured load (LPV) | F = Kₑ · i, c = Kₑ² / R |
| **Preview** | The locomotive meets every bump first; vehicle *n* receives it after tₙ = dₙ / v and prepares | tₙ = dₙ / v |
| **Protect** | The bank powers bearing, wheel, coupler and track sensors on every bogie, with no wiring | P_harvest > P_sensors |
| **Fail-safe** | On any fault a relay puts a resistor across the coil, and the damper behaves like today's | c_failsafe = c_today |

<p align="center">
  <img src="images/pitch/smart_damper_concept.jpg" alt="The smart damper: a magnet moving through a coil gives power and ride control in one part" width="100%">
</p>
<p align="center"><sub>The smart damper: a bump moves the magnet stack through the fixed coil, which makes power, sets the ride and fails safe.</sub></p>

<p align="center">
  <img src="images/pitch/train_preview_concept.jpg" alt="The locomotive warns every coach before the bump arrives; today's bogie compared with the SwarmRide bogie" width="100%">
</p>
<p align="center"><sub>Train Brain preview: the front bogie feels the bump first and every coach behind is warned t = d / v in advance. Below, today's bogie compared with the SwarmRide bogie.</sub></p>

---

## System architecture

<p align="center">
  <img src="images/architecture.svg" alt="SwarmRide end-to-end system architecture" width="100%">
</p>

| Level | Where | Responsibility |
|---|---|---|
| **① Train** | Locomotive / driving cab | Speed and position, lead-bogie bump sensing, fleet track map, bump-warning scheduling, pilot display |
| **② Vehicle** | One controller per coach or wagon | Load estimation, LPV damping schedule, preview feed-forward, health analytics, reporting |
| **③ Bogie** | Every bogie, self-powered | Smart dampers, active rectifier, DC-DC converter, supercapacitor + LiFePO4 bank, safety sensors, fail-safe relay |

---

## On a real bogie

<p align="center">
  <img src="images/casnub_annotated.jpg" alt="Casnub bogie of a BOXN wagon, annotated with SwarmRide components" width="100%">
</p>
<p align="center"><sub>Casnub bogie of a BOXNM1 wagon, annotated with where each SwarmRide part goes.</sub></p>

<p align="center">
  <img src="images/pitch/real_bogies.jpg" alt="Same bogie: SwarmRide swaps one part and adds a small power bank" width="100%">
</p>
<p align="center"><sub>Same bogie, one part swapped: LHB air-spring bogie, ICF coach bogie and Casnub wagon bogie. No new bogie, no new cables, fits today's mounts.</sub></p>

| Vehicle | What SwarmRide replaces | Load signal for the control |
|---|---|---|
| **LHB / Vande Bharat coach** | The vertical secondary dampers beside the air springs | Air-spring pressure (already on board) |
| **ICF coach** | The secondary dampers on the bolster springs | Spring deflection sensor |
| **BOXN wagon (Casnub)** | Works beside the friction wedges (hybrid) or replaces them with a geared smart damper | Spring-nest deflection sensor |

---

## Two products, one technology

<p align="center">
  <img src="images/pitch/two_products.jpg" alt="SwarmRide Passenger and SwarmRide Freight" width="100%">
</p>

| | **SwarmRide Passenger** | **SwarmRide Freight** |
|---|---|---|
| Rolling stock | Vande Bharat, LHB, ICF | BOXN wagons, DFC rakes |
| Main value | Ride tuned to the live load and to the bump ahead | Every axle watched; train parting found at the exact wagon |
| Power today | Train power exists; SwarmRide removes new wiring | None; SwarmRide makes the wagon self-powered |
| Track data | Recorded on every trip | Recorded on every run |

---

## One bump, end to end

```mermaid
sequenceDiagram
    autonumber
    participant L as Locomotive (Train Brain)
    participant N as Train data bus
    participant V as Coach n controller
    participant D as Coach n smart dampers
    participant K as Bogie power bank
    L->>L: Lead bogie meets the bump and measures it
    L->>N: Bump profile and position
    N->>V: Warning, arrives before the bump (tₙ = dₙ / v)
    V->>V: Damping for this load (LPV) plus preview
    V->>D: Damping command c*
    Note over D: Bump arrives with the damper already set
    D->>K: Harvested energy (supercap, then battery)
    K->>V: Power for sensors, controller and radio
    V->>N: Ride, bearing and track report
    N->>L: Pilot display updated
```

---

## Engineering validation

The whole system is being proven in **MATLAB/Simulink** before any hardware. Every stage uses the **same coach, rail, speed and load, and changes only the damper**, so every comparison is fair. A test suite (`scripts/run_all_checks.m`) checks the model against hand calculations, an independent state-space model, energy conservation and step-size convergence; see **[VERIFICATION.md](SwarmRide_Sim/VERIFICATION.md)** for what is proven and what is not.

```mermaid
flowchart LR
    S1["<b>Stage 1</b><br/>Test rig<br/>track · 4-DOF coach · today's damper"]
    S2["<b>Stage 2</b><br/>Smart damper<br/>designs A/B/C · power chain · fail-safe"]
    S3["<b>Stage 3</b><br/>Control<br/>LPV load-adaptive · Train Brain preview"]
    S4["<b>Stage 4</b><br/>Health and demo<br/>self-powered sensors · dashboard"]
    S1 --> S2 --> S3 --> S4
    classDef done fill:#2A9D8F,stroke:#1F6F66,color:#ffffff
    classDef now fill:#E07A1F,stroke:#A8520F,color:#ffffff
    classDef next fill:#EEF3FA,stroke:#9AA8BC,color:#13233A
    class S1,S2,S3 done
    class S4 now
```

### Stage 1: the baseline to beat (complete)

<p align="center">
  <img src="SwarmRide_Sim/results/stage1b_model_top.png" alt="Stage 1 Simulink model" width="85%">
</p>

The Simulink model matches an independent state-space model within **0.003%**, and its bounce frequency matches a hand calculation (0.83 Hz).

| Vehicle | Load | Damping ratio ζ | Sperling Wz | Max stroke | Heat wasted per bogie |
|---|---|---|---|---|---|
| LHB, 160 km/h | empty → 12 t | 0.14 → **0.10** | 1.73 → 1.84 | 20 → 25 mm | 64 → 73 W |
| Vande Bharat, 160 km/h | empty → 7.6 t | 0.12 → **0.10** | 1.75 → 1.79 | 23 → 25 mm | 82 → 87 W |
| ICF, 110 km/h | empty → 15 t | 0.08 → **0.06** | 1.45 → 1.38 | 10 → 14 mm | 23 → 31 W |
| BOXN, 100 km/h | empty → 67 t | friction | 2.28 → 2.15 | 3 mm | 36 → **214 W** |

<table>
  <tr>
    <td width="50%"><img src="SwarmRide_Sim/results/stage1b_zeta_vs_load.png" alt="Damping ratio falls with load"><br><sub><b>Fixed dampers weaken as passengers board</b>, on every coach type.</sub></td>
    <td width="50%"><img src="SwarmRide_Sim/results/stage1b_heat.png" alt="Heat wasted by today's dampers"><br><sub><b>Energy today's dampers turn into heat</b>: the ceiling on what can be recovered.</sub></td>
  </tr>
  <tr>
    <td><img src="SwarmRide_Sim/results/stage1b_scope1_body.png" alt="Body vibration scope"><br><sub><b>Body vibration:</b> passengers over the bogies feel about twice the centre level (pitch).</sub></td>
    <td><img src="SwarmRide_Sim/results/stage1b_scope4_rail.png" alt="Rail under the wheels scope"><br><sub><b>Rail under the 4 wheels:</b> the same bump arrives at each wheel later, which is the window preview uses.</sub></td>
  </tr>
</table>

Full report, block by block: **[SwarmRide_Sim/Stage1.md](SwarmRide_Sim/Stage1.md)**

### Stage 2: the smart damper and power chain (complete)

Today's damper is replaced by an electromagnetic damper, an active rectifier, a DC-DC converter and a supercapacitor + LiFePO4 bank on every bogie. All four checks pass: **same ride as today** (Wz 1.846 vs 1.844), **damping law** (0.09%), **energy balance** (< 0.001%) and **fail-safe** (exactly today's damping after a fault).

| Same ride as today, crowded, top speed | Poor track: into the bank | Good track: into the bank | Bogie loads |
|---|---|---|---|
| LHB, 160 km/h | **46–51 W** per bogie | 17–18 W | 8 W |
| Vande Bharat, 160 km/h | **55–62 W** | 21–22 W | 8 W |
| ICF, 110 km/h | **21–23 W** | 7.3–8.6 W | 8 W |
| BOXN, 100 km/h (wedges replaced) | **78–90 W** | 29–33 W | 8 W |

<table>
  <tr>
    <td width="50%"><img src="SwarmRide_Sim/results/stage2_power_chain.png" alt="Where the smart damper's power goes"><br><sub><b>Where the power goes</b> (LHB): 73 W in, 46 W into the bank, 8 W used, 38 W surplus.</sub></td>
    <td width="50%"><img src="SwarmRide_Sim/results/stage2_failsafe.png" alt="Fail-safe test"><br><sub><b>Fail-safe:</b> after a fault the damper follows today's damper exactly, and harvesting stops.</sub></td>
  </tr>
</table>

**Key findings:** the bogie powers itself on normal track. Smooth track is the weak case (ICF only just covers its load). Maximising power transfer is the wrong goal, because it burns half the power in the coil. For freight the friction wedges must be replaced, which also cuts wagon body vibration by more than half (to be confirmed). **Design C (geared rotary)** leads.

Full report: **[SwarmRide_Sim/Stage2.md](SwarmRide_Sim/Stage2.md)**

### Stage 3: the SwarmRide controllers (complete)

The fixed damping command is replaced by the **SwarmRide Controller**: an LPV (load-scheduled) LQR running at 100 Hz, plus the **Train Brain** preview of the rail ahead. It is tested head to head against today's damper and a fixed-setting harvester at empty, half and full load.

| Sperling Wz, poor track (lower = better) | Empty | Half | Full | Into the bank (full) |
|---|---|---|---|---|
| LHB, today's damper | 1.73 | 1.78 | 1.84 | 0 W |
| **LHB, SwarmRide (C3)** | **1.49** | **1.50** | **1.53** | 33 W |
| Vande Bharat, today's damper | 1.75 | 1.77 | 1.79 | 0 W |
| **Vande Bharat, SwarmRide (C3)** | **1.47** | **1.48** | **1.50** | 38 W |

<table>
  <tr>
    <td width="50%"><img src="SwarmRide_Sim/results/stage3_ride_vs_load.png" alt="Ride at every load"><br><sub><b>Better at every load:</b> today's ride worsens as passengers board; SwarmRide's stays nearly flat and 14–17% better.</sub></td>
    <td width="50%"><img src="SwarmRide_Sim/results/stage3_comfort_vs_power.png" alt="Comfort vs power"><br><sub><b>Comfort vs power:</b> no fixed setting reaches SwarmRide's comfort; a damping floor trades comfort for power on one dial.</sub></td>
  </tr>
</table>

**Key findings:**
- Ride **15–17% better** on crowded LHB and Vande Bharat coaches (worst seat −19%), body vibration **about 40% lower**, suspension travel down by a third, still **33–38 W per bogie** into the bank.
- Robust to a ±20 ms late warning and a ±10% load-estimate error, and the fail-safe still works.
- **Honest limits:**
  - The preview adds only 1–2%, because a damper that can only resist cannot act before the motion starts. Making the warning count needs brief active pushing, which is the next experiment.
  - The empty goods wagon does not ride better.

Full report: **[SwarmRide_Sim/Stage3.md](SwarmRide_Sim/Stage3.md)**

### Early estimate (preview study)

Before the Simulink stages, a simplified Python model estimated the gains below. Stage 3 has now measured them in Simulink: a ride improvement of 17% and body vibration down 41% on a crowded LHB coach, at 33 W per bogie (Section *Stage 3* above). Crowded coach, poor track, 160 km/h.

| Measure | Today's damper | Research harvester (fixed load) | **SwarmRide (target)** |
|---|---|---|---|
| Body RMS acceleration | 0.165 m/s² | 0.224 m/s² | **0.125 m/s² (−24%)** |
| Sperling ride index Wz | 1.82 | 2.06 | **1.65** |
| Power into the bogie bank | 0 W | ≈ 45 W | **≈ 10–40 W**, enough for ≈ 8 W of bogie electronics |

<p align="center">
  <img src="pdf/results/r6_pareto.png" alt="Comfort versus harvested power" width="70%">
</p>

A plain harvester trades comfort for watts. SwarmRide is designed to improve comfort **and** make the bogie self-sufficient in power.

---

## Positioning

| In service today | Its limit | SwarmRide adds |
|---|---|---|
| Fixed oil dampers / friction wedges | Tuned for one load; all energy becomes heat | Ride tuned to live load; energy reused on the bogie |
| OMRS trackside bearing checks | Sees a wagon only when it passes about 25 sites | Every axle, all the time |
| End-of-train telemetry (EoTT) | Watches the last wagon only | Every wagon reports; parting located at the exact wagon |
| Track Recording Cars | Periodic, and behind schedule | Every train records the track on every run |
| Kavach | Collision prevention through signalling | Complementary: vehicle and track health |
| Energy-harvesting dampers (research) | Power at the cost of ride comfort | Comfort and power together, with preview and fail-safe |

---

## Roadmap

<p align="center">
  <img src="images/roadmap.png" alt="Roadmap" width="85%">
</p>

| Phase | Scope | Status |
|---|---|---|
| Concept | Problem evidence, architecture, pitch, technical design | Done |
| Simulation 1 | Test rig, verification, baseline of LHB, Vande Bharat, ICF, BOXN | Done |
| Simulation 2 | Smart damper (A/B/C), rectifier, DC-DC, power bank, fail-safe | Done |
| Simulation 3 | LPV and preview control, head-to-head comparison | Done |
| Simulation 4 | Self-powered health sensing, active preview, investor dashboard | **Next** |
| Prototype | Bench test of one smart damper | Planned |
| Pilot | Freight wagons, then Vande Bharat, with RDSO | Planned |

---

## Repository

```
.
├── README.md                         project overview (this page)
├── docs/WHITEPAPER.md                technical whitepaper
├── SwarmRide_Bharat_Pitch.*          investor pitch: Markdown · Word · PDF
├── SwarmRide_Bharat_Technical_Document.md
├── SwarmRide_Bharat_Complete_Guide.md
├── SwarmRide_Simulation_Results_Preview.pdf
├── images/                           banner, architecture, annotated bogie, pitch sketches, roadmap
├── pdf/                              pitch builder, preview study, photographs and credits
└── SwarmRide_Sim/                    MATLAB/Simulink simulation
    ├── sr_setup.m                    start here
    ├── functions/                    physics, sensors, track, rolling stock, damper design
    ├── builders/                     shared Simulink block builders
    ├── scripts/                      parameters, model builders, checks, run_all_checks
    ├── tests/                        verification tests (physics, convergence, power chain, track)
    ├── models/                       generated Simulink models
    └── results/                      figures, reports, scope captures
```

### Quick start

```matlab
cd SwarmRide_Sim
sr_setup                                                   % paths + opens the model
trainType = 'LHB';  v_kmh = 160;  mload_t = 12;  trackType = 'poor';
% press Run: live scopes open and the 30 s run plays in real time
designType = 'C';  ctrlMode = 'C3';                        % Stage 3: damper design and controller
run('scripts/check_stage3.m')                              % reproduce the Stage 3 study
```

Requires MATLAB R2024b with Simulink, Control System Toolbox, Simscape and Simscape Electrical.
The pitch and preview tooling use Python 3 (numpy, scipy, matplotlib, Pillow) and Microsoft Edge for PDF export.

---

## Documentation

| Document | Audience |
|---|---|
| [Whitepaper](docs/WHITEPAPER.md) | Technical overview |
| [Investor pitch](SwarmRide_Bharat_Pitch.md) · [PDF](SwarmRide_Bharat_Pitch.pdf) · [Word](SwarmRide_Bharat_Pitch.docx) | Investors and Indian Railways |
| [Technical document](SwarmRide_Bharat_Technical_Document.md) | Engineers |
| [Complete guide](SwarmRide_Bharat_Complete_Guide.md) | Learning the project from scratch |
| [Stage 1 report](SwarmRide_Sim/Stage1.md) · [Stage 2 report](SwarmRide_Sim/Stage2.md) · [Stage 3 report](SwarmRide_Sim/Stage3.md) · [Model guide](SwarmRide_Sim/MODEL_GUIDE.md) · [Verification](SwarmRide_Sim/VERIFICATION.md) | Simulation |
| [Results preview](SwarmRide_Simulation_Results_Preview.pdf) | Expected results |

---

## Credits and licence

Photographs of Indian rolling stock are from Wikimedia Commons under their stated licences, plus project-archive images; full list in [pdf/photos/CREDITS.md](pdf/photos/CREDITS.md). Model parameters cite IRIMEE and published studies; see the [model guide](SwarmRide_Sim/MODEL_GUIDE.md).

© 2026 Sangeeth. All rights reserved. No licence is granted to use, copy or distribute this work.

# SwarmRide Simulink Model Guide

What every block in `models/SR_Stage1.slx` is, why it is there, and where every number comes from.
The model is always rebuilt by `scripts/build_stage1.m`; edit the script, not the `.slx`.

**Stage 2** (`models/SR_Stage2.slx`, the smart damper and power chain) uses the same Track Input and Vehicle Plant; its blocks, parameters and results are described in [Stage2.md](Stage2.md).

---

## 1. How to run it

```matlab
sr_setup                                   % once per MATLAB session: paths + opens the model
trainType = 'LHB';                         % LHB | VB | ICF | BOXN | GENERIC
v_kmh = 160;  mload_t = 12;  trackType = 'poor';   % speed, load [t], track: good | poor | bump
% press Run in Simulink: 4 scope windows open and the 30 s run plays in real time
```

Batch checks (no windows, results saved to `results/`):

```matlab
run('scripts/check_stage1b.m')   % today's Indian trains: baseline report + figures
run('scripts/check_stage1.m')    % generic coach: physics + wiring checks
```

---

## 2. The model, block by block

```
Track Input ──w, wd──► Vehicle Plant (half-coach 4-DOF) ──az, stroke, vrel──► Logs + Scopes 1-2
                          ▲ Fd                          │ vrel
                          └── Secondary Dampers (today's damper) ◄─┘ ──► Log Fd + Scope 3
Track Input ──► Scope 4
```

### 2.1 Track Input: what the rail does under each wheel

| Block | What it does | Why | Parameters |
|---|---|---|---|
| Clock, **Speed v**, **Start position s0** | Lead-wheel position s = s0 + v·t | The train moves along the track | `P.v` = speed, `P.s0` = 150 m |
| **Wheel offsets** + **Wheel positions** (sum) | Positions of all 4 wheels | Every wheel meets the same rail, later. This timing is the basis of SwarmRide's bump preview | `P.dist` = [0, 2a, 2l, 2l+2a] |
| **Rail height w(x)** (lookup table) | Rail irregularity under each wheel | The disturbance that shakes the coach | `TR.w` from `sr_track.m` |
| **Rail slope dw_dx** × **x speed** | Wheel vertical velocity ẇ = slope × v | Needed by the primary dampers | `TR.dwdx`, `P.v` |

Track types (`functions/sr_track.m`): `good` and `poor` use the vertical track spectrum (roughness constants 4.032e-7 and 1.08e-6 m·rad, wavelengths 1–100 m, fixed seed so every controller sees the same rail). `bump` is a single 10 mm, 4 m dip.

### 2.2 Vehicle Plant (half-coach, 4 DOF, 8 states)

| Block | What it does | Why |
|---|---|---|
| **Equations of Motion** (`functions/sr_eom.m`) | Newton's law for body bounce z, body pitch θ, front bogie z1, rear bogie z2. Includes the secondary springs (air, coil or Casnub nest) and the primary springs and dampers | The coach's physics; one file shared with all checks |
| **Velocities**, **Positions** (integrators) | acceleration → velocity → position | The 8 states |
| **Body Accelerometers** | Body acceleration at the centre and over each bogie | **Comfort** measure |
| **Stroke Sensors** | Secondary stroke and stroke velocity | **Safety** (stroke limit) and **what the damper feels** |

### 2.3 Secondary Dampers: today's damping (C0)

| Vehicle | Today's damper | Force |
|---|---|---|
| LHB, Vande Bharat, ICF | Hydraulic (oil) damper | F = c_s · v_rel |
| BOXN (Casnub bogie) | Friction wedges, load-proportional | F = μ · (load per bogie) · tanh(v_rel / 0.02) |

This is the block Stage 2 replaces with the **smart damper**.

### 2.4 Scopes (open when you press Run)

| Scope | Shows | Read it as |
|---|---|---|
| 1 Body vibration | Body acceleration: centre, over front, over rear | Lower = smoother ride |
| 2 Suspension stroke | Front and rear stroke | Must stay within about ±40 mm |
| 3 Damper force | Front and rear damper force | Today this force only makes heat |
| 4 Rail under the wheels | Rail height under wheels 1–4 | The same bumps arrive at each wheel in turn |

---

## 3. Parameters per vehicle (today's Indian rolling stock)

Defined in `functions/sr_trains.m`; turned into one scenario by `scripts/sr_params.m`.
**"Assumed" values are engineering estimates. Replace them with RDSO or manufacturer data before showing results outside the team.**

| Parameter | LHB | Vande Bharat (trailer) | ICF | BOXN (Casnub) |
|---|---|---|---|---|
| Secondary spring type | Air (stiffens with load) | Air | Coil (constant) | Two-stage spring nest |
| Body tare | 28.3 t (derived: 41.6 t coach [3] − 2 × 6.635 t bogies [1]) | 46 t (assumed; max body 53.6 t from 17 t axle load [2] and 7.21 t bogies [1]) | 33 t (assumed) | 12 t [4] |
| Load range | 0 / 5.1 [3] / 12 t (crowded, assumed) | 0 / 3.8 / 7.6 t (derived) | 0 / 7.5 / 15 t (assumed) | 0 / 33.6 / 67.25 t [4] |
| Bogie centres (2l) | 14.9 m (assumed) | 14.9 m [2] | 14.783 m (assumed) | 6.5 m (assumed) |
| Wheelbase (2a) | 2.56 m [1] | 2.70 m [1] | 2.896 m [1] | 2.0 m (assumed) |
| Bogie frame (sprung) | 3.54 t [1] | 3.45 t [1] | 3.0 t (assumed) | 1.2 t side frames (assumed) |
| Secondary stiffness, per bogie (empty) | 0.60 MN/m (assumed) | 0.90 MN/m (assumed) | 1.10 MN/m (assumed) | 4.01 → 6.73 MN/m loaded [4] |
| Today's damping, per bogie | 35 kN·s/m (assumed) | 50 kN·s/m (assumed) | 30 kN·s/m (assumed) | Friction μ = 0.1 [4] |
| Primary, per wheelset | 1.3 MN/m, 20 kN·s/m (assumed) | 1.3 MN/m, 20 kN·s/m (assumed) | 1.3 MN/m, 15 kN·s/m (assumed) | Elastomeric pads 98 MN/m [4], 50 kN·s/m (assumed) |
| Service speeds | 110 / 130 / 160 km/h [1] | 130 / 160 km/h [2] | 80 / 110 km/h [1] | 75 / 100 km/h (assumed) |

**Sources**
1. IRIMEE, *Introduction to Trainset bogie* (FIAT / Train-18 / EMU bogie comparison table): https://rskr.irimee.in/sites/default/files/Introduction%20to%20Trainset%20bogie%20(1).pdf
2. IRIMEE, *Introduction of Train 18* (160 km/h, max design axle load 17 t, load-corrected braking from air-spring pressure): https://rskr.irimee.in/sites/default/files/Introduction%20of%20Train%2018.pdf
3. *Dynamic Response of Linke Hofmann Busch (LHB) Rail Coach Considering Suspended Equipments* (coach tare 41,600 kg, gross 46,720 kg): https://www.researchgate.net/publication/323013012
4. *Parametric Study of Suspension Elements for Ride Index Analysis of an Indian Railway Freight Vehicle* (Casnub spring rates, wedge damping 0.1, body tare 12 t, loaded wagon 79.25 t): https://www.researchgate.net/publication/245574409

Sources 3 and 4 were read from search summaries (the full papers are behind ResearchGate's login). Open the PDFs and confirm the numbers before citing them.

---

## 4. Known simplifications (Stage 1b)

- Vertical motion only (no lateral, yaw or roll yet).
- Wheels follow the rail exactly (no wheel-rail contact model).
- Rigid car body (no body bending).
- Casnub friction is smoothed (no true stick-slip), and its spring-nest grouping is assumed.
- Static sag is reported but not simulated; the model runs around the loaded equilibrium.

---

## 5. Stage 1b results: today's Indian trains (baseline to beat)

Produced by `scripts/check_stage1b.m` (full text in `results/stage1b_baseline_report.txt`). Poor track, top service speed, today's damper.

| Vehicle | Load | Body mode | Damping ζ | Body RMS [m/s²] | Sperling Wz | Max stroke | Heat wasted per bogie |
|---|---|---|---|---|---|---|---|
| LHB, 160 km/h | empty | 0.93 Hz | 0.14 | 0.138 | 1.73 | 17.3 mm | 67 W |
| LHB, 160 km/h | 12 t | 0.90 Hz | 0.10 | 0.155 | 1.83 | 20.2 mm | 73 W |
| Vande Bharat, 160 km/h | empty | 0.86 Hz | 0.12 | 0.138 | 1.74 | 16.7 mm | 78 W |
| Vande Bharat, 160 km/h | 7.6 t | 0.84 Hz | 0.10 | 0.146 | 1.79 | 16.8 mm | 80 W |
| ICF, 110 km/h | empty | 1.08 Hz | 0.08 | 0.096 | 1.54 | 11.9 mm | 29 W |
| ICF, 110 km/h | 15 t | 0.90 Hz | 0.06 | 0.079 | 1.42 | 12.2 mm | 35 W |
| BOXN, 100 km/h | empty | 4.07 Hz | friction | 0.385 | 2.21 | 3.9 mm | 34 W |
| BOXN, 100 km/h | 67 t | 2.04 Hz | friction | 0.329 | 2.09 | 3.5 mm | 209 W |

Wiring check (LHB): Simulink vs independent state-space model differ by 0.004 % → PASS.

**What the baseline shows**

1. **Today's fixed damper weakens with load on every coach type:** ζ falls 0.14 → 0.10 (LHB), 0.12 → 0.10 (Vande Bharat), 0.08 → 0.06 (ICF). Figure: `results/stage1b_zeta_vs_load.png`.
2. **ICF coil springs sag** from 147 mm to 214 mm under a crowded load (67 mm extra); air-spring coaches stay levelled.
3. **Energy wasted as heat** by today's dampers: about 30–80 W per bogie on coaches and up to about 210 W per bogie on a loaded BOXN wagon (friction wedges). This is the ceiling on what SwarmRide can recover. Figure: `results/stage1b_heat.png`.
4. **Goods wagons ride hardest** (Wz 2.1–2.2), and they have no power for sensors, which is where self-power matters most.

**Cautions:** many parameters are assumed (Section 3); Casnub friction is smoothed, so its heat figure is approximate; Wz uses the frequency-domain method (same record length for all cases).

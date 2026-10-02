# SwarmRide Bharat — Technical Project Document

**Self-powered, load-adaptive, train-synchronised smart suspension for Indian Railways**

Author: Jaganath · Version 1.0 · 2 Oct 2026

---

## Contents

1. [Summary](#1-summary)
2. [Background: how a train suspension works](#2-background-how-a-train-suspension-works)
3. [The current problem](#3-the-current-problem)
4. [Main objective and specific goals](#4-main-objective-and-specific-goals)
5. [The complete idea](#5-the-complete-idea)
6. [Technical design](#6-technical-design)
7. [Energy budget](#7-energy-budget)
8. [Expected results](#8-expected-results)
9. [How we will prove it](#9-how-we-will-prove-it)
10. [What changes after this project](#10-what-changes-after-this-project)
11. [What is new (novelty and patent)](#11-what-is-new-novelty-and-patent)
12. [Risks and limits](#12-risks-and-limits)
13. [Indicative bill of materials](#13-indicative-bill-of-materials)
14. [Glossary](#14-glossary)
15. [References](#15-references)

---

## 1. Summary

Every train runs on suspension dampers. Today these dampers turn the up-and-down motion of the coach into **heat**, and they are tuned for **one fixed load**. At the same time, Indian Railways loses trains to **track defects, hot axles and broken couplings**, because most checks happen only at fixed places or from time to time.

**SwarmRide Bharat** replaces the ordinary damper with a **smart electromagnetic damper**. It does three jobs at once:

1. **Makes electricity** from track bumps (Faraday's law) and stores it in a small **power bank on the bogie**.
2. **Controls the ride**: it becomes softer or firmer in milliseconds, matched to the **live passenger load** and to the **bump coming next**.
3. **Powers safety sensors** on the same bogie: axle bearing temperature, wheel health and track condition.

A small controller in the loco or driving cab, the **Train Brain**, sends each coach a warning of the next bump and shows the loco pilot the health of every coach and wagon.

The electricity is small, tens of watts per damper, and we say so openly. It is **enough for the bogie to run itself**, which matters most on goods wagons that have no power at all.

**Two products, one technology:**

| Product | For | Main job |
|---|---|---|
| **SwarmRide Freight** | Goods wagons, starting on the Dedicated Freight Corridors | Safety: every axle watched, partings located, track recorded |
| **SwarmRide Vande Bharat** | Vande Bharat chair car and sleeper trainsets | Comfort: ride tuned to load and to the bump ahead, track recorded |

---

## 2. Background: how a train suspension works

### 2.1 Two stages of suspension

```
        COACH BODY (sprung mass: coach + passengers)
   ─────────────────────────────────────────────────
        │  Secondary suspension                     │
        │  (air springs + vertical, lateral,        │  ← SwarmRide smart dampers go here
        │   yaw dampers on Vande Bharat)            │
   ─────────────────────────────────────────────────
        BOGIE FRAME
   ─────────────────────────────────────────────────
        │  Primary suspension                       │
        │  (coil springs + dampers)                 │
   ─────────────────────────────────────────────────
        WHEELSETS + AXLE BOXES (bearings)            ← bearing and wheel sensors go here
   ═════════════════════ RAIL ══════════════════════
```

- **Primary suspension** sits between the wheels and the bogie frame. It handles sharp, high-frequency shocks.
- **Secondary suspension** sits between the bogie and the coach body. It controls the slow bounce, sway and pitch that passengers feel.
- On **Vande Bharat**, the coach body sits directly on **air springs**. The secondary suspension has **vertical, lateral and yaw dampers**, and the bogie is built for **160 km/h** [R8].

### 2.2 What a damper does, and where the energy goes

A spring stores energy and gives it back, so on its own the coach would keep bouncing. A **damper** removes that energy so the bouncing stops. In a normal hydraulic damper, oil is forced through small holes and the energy becomes **heat**, which is simply lost.

Studies of rail suspensions estimate **33–960 W per damper** available in theory (loaded freight wagon, 90 km/h). The best rail energy-harvesting damper built so far delivered **63 W** [R10].

### 2.3 Energy recovery that already exists on trains

| Method | What it recovers | Limit |
|---|---|---|
| **Regenerative braking** | Kinetic energy while braking, from kilowatts to megawatts | Only during braking; does not reach unpowered wagons |
| **Research suspension harvesters** | Vibration energy, 1–63 W per damper | Often make the ride worse; a fixed electrical load gives fixed damping |
| **Self-powered end-of-train units** | Air turbine on the brake pipe (US patent, 1991) [R13] | Only the last wagon; uses brake air |

SwarmRide does **not** compete with regenerative braking. It recovers a different energy, vibration while cruising, and uses it for a different purpose: running the suspension and its sensors.

---

## 3. The current problem

### 3.1 Evidence from Indian Railways

| # | Problem | Evidence | Source |
|---|---|---|---|
| 1 | **Track defects are the biggest cause of derailments** | 2017–21: 171 derailments from poor track maintenance and 156 from track parameters out of limits. Track Recording Car inspections fell **30–100% short**. | CAG Report 22 of 2022 [R1] |
| 2 | **Hot axles (overheated wheel bearings)** | About **3 hot-axle cases every day**, according to Railway Board minutes (2025) [R2]. Earlier: 468 cases in 9 months (2018–19) [R3]. OMRS trackside monitoring at about 25 sites (industry source; confirm) [R5]. | R2, R3, R5 |
| 3 | **Coach and wagon defects** | 182 derailments caused by the Mechanical Department (2017–21); 37% of those from wheel-diameter variation and coach or wagon defects. | R1 |
| 4 | **Train parting (coupling breaks)** | 643 train partings and 2,059 wagon detachments in 2018–19 [R3]; still "on the higher side" in 2025 [R2]. EoTT monitors only the last wagon [R6]. | R2, R3, R6 |
| 5 | **Crowded coaches ride badly** | General coaches are often overcrowded [R4]. Dampers are tuned for one load. | R4 |
| 6 | **Vande Bharat ride quality** | A passenger review reports feeling the track, with more vibration and noise than European trains [R9]. | R9 |

### 3.2 The technical root causes

1. **Checks are periodic or at fixed points, not continuous.** OMRS checks a wagon only when it passes a site, and Track Recording Cars run only from time to time. Faults that grow between checks are missed.
2. **Goods wagons have no electricity.** Continuous sensors on every axle would need batteries that run down, or cables that do not exist.
3. **Fixed damping cannot suit every load.** Section 6.4 shows that a fixed damper loses about **27%** of its damping ratio when a coach goes from 40 t to 55 t.
4. **Each vehicle acts alone.** Every coach meets every bump unprepared, even though the vehicle in front met the same bump moments earlier.
5. **Damper energy is wasted as heat** that could power the sensors that are missing.

---

## 4. Main objective and specific goals

### 4.1 Main objective

> **Turn every coach and wagon into a self-powered, self-monitoring vehicle whose suspension gives a ride matched to its live load and to the track ahead, using only energy the suspension itself recovers.**

### 4.2 Specific, measurable goals

| # | Goal | Measured by | Target |
|---|---|---|---|
| G1 | Better ride than fixed dampers at every load | Sperling ride index (Wz), ISO 2631 / EN 12299 comfort | Lower Wz than fixed dampers at empty, half and crowded load |
| G2 | Ride and energy together | Comfort compared at equal harvested power | Better comfort than a fixed-load harvester at the same watts |
| G3 | Energy self-sufficiency | Energy harvested ÷ energy used, per bogie per trip | Greater than 1 (more made than used) |
| G4 | Continuous axle health | Share of running time each axle is monitored | 100% of running time, against snapshots at OMRS sites |
| G5 | Parting located at the exact wagon | Detection time and position accuracy in trials | Correct wagon identified; time to be set in trials |
| G6 | Track recorded by every train | Route-km recorded per day | Every route the fleet runs |
| G7 | Fail-safe | Damping with all power cut | Equal to a normal passive damper |

All targets are **hypotheses to be proven** by simulation, bench tests and pilots (Section 9).

### 4.3 Scope

**In scope:** secondary-suspension smart dampers, the bogie power bank, load sensing, axle bearing and wheel sensors, track sensing, the Train Brain, and train-wide communication.

**Out of scope:** traction, braking, signalling (Kavach), coupler slack (the cause of LHB jerks), passenger HVAC, and running the coach on harvested power.

---

## 5. The complete idea

### 5.1 System architecture

![System overview](images/system-overview.png)

```
LEVEL 1 — TRAIN BRAIN (loco or driving cab)
  • Knows speed, position and the track ahead (front bogie + fleet track map)
  • Sends each vehicle a timed bump warning
  • Shows the loco pilot: load, comfort, bearing health, partings, track defects
             │  data only (Vande Bharat: TCMS network; freight: wireless along the train)
             ▼
LEVEL 2 — VEHICLE CONTROLLER (one per coach or wagon)
  • Weighs the vehicle at 4 corners
  • Sets the damping target for that load
  • Collects sensor data and reports to the Train Brain
             │
             ▼
LEVEL 3 — BOGIE UNIT (self-powered)
  • Smart dampers: make electricity + control the ride
  • Power bank: supercapacitor + small LiFePO4 battery
  • Sensors: axle bearing temperature and vibration, damper signals
  • Fail-safe relay
```

### 5.2 How one trip works

1. **At the station:** the vehicle weighs itself. Vande Bharat uses air-spring pressure; wagons use spring-deflection or strain sensors. Damping targets are set for that load.
2. **Departure:** the vehicle reports its load and status to the Train Brain.
3. **Running:** the front bogie senses each bump. Every vehicle behind receives the bump profile, delayed by distance ÷ speed, and sets its damping just before the bump arrives.
4. **Harvesting:** every damper charges its bogie power bank while it damps.
5. **Monitoring:** bearing temperature, vibration and wheel impacts are checked continuously, and alerts go straight to the loco pilot.
6. **Arrival or end of day:** a GPS-tagged track condition map is uploaded for maintenance teams.

### 5.3 Energy priority on each bogie

The power bank serves loads in this fixed order:

1. **Safety sensors** (bearing, wheel, parting): always on
2. **Communication** to the Train Brain
3. **Ride control** (damping adjustment)
4. **Reserve** for station stops and smooth track
5. **Surplus** to the vehicle's low-voltage battery, where one exists

---

## 6. Technical design

### 6.1 The smart damper: a tubular linear permanent-magnet machine

**Construction:** a moving rod carries a stack of NdFeB magnets in a **Halbach arrangement**, which concentrates the field on the coil side. The rod slides inside a fixed tube of copper coils. The unit fits the mounting points of the existing secondary damper.

**Generated voltage (Faraday's law):**

$$e = K_e \, v_{rel}$$

- $v_{rel}$ = relative velocity between bogie and coach body (m/s)
- $K_e$ = back-EMF constant (V per m/s), set by magnet strength, number of turns and coil length

**Force from current (Lorentz force):**

$$F = K_f \, i \qquad (K_f = K_e \text{ in SI units for an ideal machine})$$

**Damping from the electrical load.** When the coil is connected to a resistance $R_{load}$:

$$i = \frac{e}{R_{coil} + R_{load}}, \qquad F = \frac{K_e^2}{R_{coil} + R_{load}}\, v_{rel} = c\, v_{rel}$$

$$\boxed{c = \frac{K_e^2}{R_{coil} + R_{load}}}$$

So **changing the electrical load changes the damping**:
- Open circuit ($R_{load} \to \infty$): $c \approx 0$, the softest setting.
- Short circuit ($R_{load} = 0$): $c_{max} = K_e^2 / R_{coil}$, the firmest setting.

In practice the power converter does not switch real resistors. It controls the coil **current** directly, so any damping between 0 and $c_{max}$ can be set within milliseconds.

**Power split.** Of the mechanical power absorbed, part is harvested and part heats the coil:

$$P_{mech} = c\, v_{rel}^2, \qquad P_{harvest} = P_{mech}\,\frac{R_{load}}{R_{coil}+R_{load}}, \qquad P_{coil\,loss} = P_{mech}\,\frac{R_{coil}}{R_{coil}+R_{load}}$$

**Illustrative sizing (assumed numbers, to be replaced by the simulation):**

| Quantity | Assumed value | Result |
|---|---|---|
| Target damping c | 20 kN·s/m | — |
| Total circuit resistance $R_{coil}+R_{load}$ | 2 Ω | $K_e = \sqrt{c \cdot R} = 200$ V/(m/s) |
| Peak relative velocity | 0.2 m/s | EMF 40 V, force 4 kN |
| RMS relative velocity | 0.05 m/s | Average absorbed power $c\,v_{rms}^2$ = 50 W |
| $R_{coil}$ = 0.5 Ω, $R_{load}$ = 1.5 Ω | — | 75% harvested, about 37 W per damper |

Thirty-seven watts sits in the same range as the 63 W measured by Dong et al. [R10], which suggests the assumptions are realistic. Real values depend on track quality, speed and load.

**Why linear and not rotary?** Rotary generators need a ball-screw or rack and pinion to turn up-and-down motion into rotation. That adds backlash, friction and wear. A linear machine has **no gears and no oil**, and responds faster.

### 6.2 Power electronics

```
Coil ──► Active rectifier / H-bridge ──► Bidirectional DC-DC ──► 48 V bogie bus ──► Supercap + LiFePO4
         (current control = force control)      (MPPT, charging)                        │
                                                                                         ▼
                                                              Controller, sensors, radio (low-voltage rails)
```

- **Active rectifier (H-bridge):** turns the coil's AC into DC. Its **current setpoint is the damping command**, since F = Kf · i.
- **DC-DC converter:** charges the power bank from a coil voltage that keeps changing. **A booster raises voltage, not energy:** current drops by the same ratio, and conversion losses mean output is slightly less than input. For example, 50 W at 12 V in gives about 47.5 W at 110 V out (95% efficiency).
- **Power bank:** supercapacitors take fast charge pulses, and a small LiFePO4 battery carries the load through long station stops.
- **Over-charge:** when the bank is full, the controller simply lowers the harvest. Damping then shifts to coil losses or the fail-safe resistor, and no separate dump resistor is needed.

### 6.3 Fail-safe design

A **normally-closed relay** connects the coil to a **fixed resistor $R_{fail}$**, sized so that

$$c_{fail} = \frac{K_e^2}{R_{coil} + R_{fail}} \approx c_{passive\ nominal}$$

If power or the controller fails, the relay drops out and the damper behaves exactly like today's passive damper. **Safety therefore does not depend on software**, which simplifies RDSO approval.

Shorting the coil outright would give $c_{max}$, which may be too stiff. A sized resistor is the correct fail-safe. Earlier pitch drafts said "shorts the coil", and this document corrects that.

### 6.4 Load estimation and load-adaptive damping

**Measuring the load.**
- **Air-spring vehicles (Vande Bharat):** each corner's load is $F_i = (p_i - p_{atm})\,A_{eff}$, where $p_i$ is air-spring pressure and $A_{eff}$ the effective area. The total mass is $m = \sum F_i / g$. Comparing the corners shows uneven loading, front to back and side to side.
- **Coil-spring wagons:** spring deflection or strain sensors are used, with $F_i = k_i\,\Delta z_i$.
- **Filtering:** the load changes slowly, so it is estimated with a low-pass filter of about 0.1 Hz, mainly at stations when the train is still. A 20 Hz filter would let the whole 0.5–15 Hz vibration band through, so it would be wrong here.

**Why a heavier coach needs a firmer damper.** The damping ratio is

$$\zeta = \frac{c}{2\sqrt{k\,m}}$$

Air springs stiffen with load ($k \approx m\,\omega^2$, so the bounce frequency $\omega$ stays roughly constant), which gives

$$\zeta = \frac{c}{2\,m\,\omega} \qquad\Rightarrow\qquad c_{target} = 2\,\zeta_{opt}\,\omega\,m_{measured}$$

**Example (approximate masses):** going from 40 t to 55 t, a fixed damper's ζ falls to 40/55 = 0.73, a **27% loss**. SwarmRide raises c by 55/40 = **1.375 (+37.5%)** to keep ζ at its best value.

**Per-corner control:** each corner gets its own $c_{target,i}$ from its own load, which corrects roll and pitch when a crowd gathers on one side or at one end.

### 6.5 Ride control: semi-active, regenerative only

**Rule:** the damper may only **resist** motion, never push. This keeps the system purely regenerative and stable:

$$0 \le c(t) \le c_{max}$$

**Control layers, from base to top:**

1. **Load-adaptive base:** $c = c_{target}(m)$ from Section 6.4.
2. **Skyhook semi-active control** improves comfort. With body velocity $\dot z_b$ and relative velocity $v_{rel} = \dot z_b - \dot z_{bogie}$:

$$c(t) = \begin{cases} \text{clip}\!\left(c_{sky}\,\dfrac{\dot z_b}{v_{rel}},\; 0,\; c_{max}\right) & \text{if } \dot z_b\, v_{rel} > 0 \\[2mm] c_{min} & \text{otherwise} \end{cases}$$

   When body motion and suspension motion have the same sign, firm damping both calms the body **and** harvests well. When they have opposite signs, the damper goes soft, which gives a comfortable ride and costs little harvest.
3. **Preview control (the bump warning):** the controller knows the coming bump profile $\hat w(t)$ (Section 6.6) and chooses $c(t)$ over a short horizon N:

$$\min_{c_0..c_{N-1}} \sum_{k=0}^{N-1}\left( q\,\ddot z_{b,k}^2 \;-\; \lambda\, P_{harvest,k} \;+\; s\, z_{rel,k}^2 \right)$$

$$\text{subject to: vehicle model with } \hat w_k,\quad 0 \le c_k \le c_{max},\quad |z_{rel,k}| \le z_{max},\quad E_k \ge E_{min}$$

   - $q$: weight on comfort (body acceleration)
   - $\lambda$: weight on harvested energy
   - $s$: weight on suspension travel (stroke)
   - $E_k \ge E_{min}$: the power bank must never fall below its safety reserve

   Two versions are planned. A **fast version** computes the preview-optimal force and clips it to the allowed range, and runs on a microcontroller. A **reference version** is a full nonlinear MPC run offline (CasADi) to show the best possible result.

**Vehicle model for simulation:** a half-coach with body bounce and pitch, two bogies with bounce and pitch, and four wheelsets. Each wheelset receives the same track profile with its own delay. The simplest form, one corner (a quarter-car model):

$$m_b\,\ddot z_b = -k_s (z_b - z_{bg}) - c(t)\,(\dot z_b - \dot z_{bg})$$

$$m_{bg}\,\ddot z_{bg} = k_s (z_b - z_{bg}) + c(t)\,(\dot z_b - \dot z_{bg}) - k_p (z_{bg} - w) - c_p(\dot z_{bg} - \dot w)$$

### 6.6 Train-wide synchronisation (the bump warning)

**Delay to bogie j**, a distance $d_j$ behind the front bogie at speed $v$:

$$\tau_j = \frac{d_j}{v}$$

At 160 km/h (44.4 m/s), a bogie 100 m back gets **2.25 s** of warning.

**Timing accuracy:** at 160 km/h, 1 m of position error equals about **23 ms**. GPS alone is not precise enough. Each vehicle therefore aligns its own measured signal with the front bogie's signal by **cross-correlation**, which fixes the delay to within milliseconds.

**Communication:**
- **Vande Bharat:** the train's existing control and monitoring network (TCMS). No new hardware is needed in the cab.
- **Freight:** a low-power wireless link along the train, similar in role to EoTT radio, with each wagon relaying to the next.
- Data rates are small (bump profiles and status), well within low-power radio limits.

**If the link is lost:** each vehicle keeps load-adaptive and skyhook control and simply loses the preview. It degrades gracefully and never becomes unsafe.

### 6.7 Condition monitoring

| Function | Sensor | Method |
|---|---|---|
| **Hot axle (bearing)** | Temperature sensor on each axle box | Absolute limit plus rate-of-rise alarm; compared with the other axles on the same wagon |
| **Bearing defect (early warning)** | MEMS accelerometer on the axle box | Envelope analysis for bearing defect frequencies, to catch damage before overheating |
| **Wheel flat** | Axle-box accelerometer and damper signal | Repeating impact at wheel rotation frequency $f = v / (\pi D)$; for example, D = 0.9 m at 20 m/s gives about 7.1 Hz |
| **Train parting** | Every wagon node reports position and link status | A sudden gap between consecutive wagons, or lost reports from a group of wagons, flags a parting at an exact wagon number |
| **Overload** | Load estimate (Section 6.4) | Alert when the measured load exceeds the vehicle's rated load |
| **Damper health** | Coil voltage and current | Comparing measured force with expected force reveals a degraded damper |

### 6.8 Track recording by every train

- The damper's velocity signal, combined with a bogie accelerometer, gives the **vertical track irregularity** under each bogie.
- Every point is tagged by GPS and kilometre post, and **data from many trains is averaged**, which removes noise and shows trends day by day.
- The output is a **track condition map** that flags locations getting worse, to be checked by maintenance teams.
- This **does not replace** certified Track Recording Cars. It fills the 30–100% inspection shortfall with daily screening [R1].

---

## 7. Energy budget

### 7.1 Per bogie

| Item | Value | Basis |
|---|---|---|
| Harvest per damper (average track) | About 30–60 W | Section 6.1 sizing; Dong et al. measured 63 W [R10] |
| Dampers per bogie (Vande Bharat secondary) | 2 vertical + lateral + yaw | Bogie design [R8]; exact count per bogie to confirm |
| Controller, sensors, radio, converter | About 5–20 W | Estimate, to be measured on the bench |
| Power bank for 30 minutes of standstill at 10 W | About 5 Wh | 10 W × 0.5 h |
| **Balance** | **Positive on normal running** | To be proven (Goal G3) |

### 7.2 Honest position

- This energy **cannot run HVAC, lighting for a whole coach, or traction**, and the project does not try to.
- On **goods wagons**, self-power is essential, because there is no other power source and braking energy does not reach them.
- On **Vande Bharat**, the train already has power. Self-power there means **no new wiring and independent bogies**, not saving electricity.
- A crowded coach vibrates with more energy, so it **harvests more exactly when it needs the most control** [R10 found load to be a major factor].

---

## 8. Expected results

These are the results the project is designed to show. Each one is a **hypothesis until measured**.

| Area | Today | Expected with SwarmRide |
|---|---|---|
| Ride at different loads | Good at one load, worse when empty or crowded | Same good ride at every load (damping ratio held constant) |
| Ride over bumps | Every coach meets every bump unprepared | Each coach prepared before the bump; lower body acceleration |
| Ride and energy together | Harvesters trade comfort for watts | Better comfort at the same watts than a fixed-load harvester |
| Bogie power | None on wagons; cables on coaches | Self-powered; energy balance positive |
| Hot-axle detection | Snapshots at about 25 OMRS sites | Every axle, all the time; earlier warning from vibration trends |
| Train parting | Last wagon only (EoTT) | Exact wagon identified |
| Track inspection | Periodic; 30–100% short of schedule | Daily screening by every train in service |
| Failure behaviour | Passive damper | Never worse than passive (fail-safe resistor) |

**What the simulation must show to pass Gate A:**
1. On a comfort-versus-watts graph, the SwarmRide curve lies **above** the fixed-damper and fixed-load-harvester curves at empty, half and crowded load.
2. Energy balance is **positive** on the chosen track profiles.
3. Ride limits are never exceeded, including with preview timing errors up to ±20 ms.

---

## 9. How we will prove it

### 9.1 Stage 1: computer simulation (Gate A)

1. **Model:** half-coach (body + 2 bogies + 4 wheelsets) in Python (NumPy, SciPy, CasADi) or MATLAB/Simulink, using Vande Bharat-like parameters from published sources.
2. **Track input:** measured Indian track irregularity data if available; otherwise standard track spectra for good and poor track.
3. **Speeds:** 80, 130 and 160 km/h. **Loads:** empty, half, crowded.
4. **Controllers compared on the same input:**

| ID | Controller | Represents |
|---|---|---|
| C0 | Fixed passive damper | Today's trains |
| C1 | Fixed-load harvester | Existing research harvesters |
| C2 | Load-adaptive + skyhook (no preview) | SwarmRide without the bump warning |
| C3 | Load-adaptive + skyhook + preview | Full SwarmRide |

5. **Outputs:** Sperling Wz, RMS body acceleration, stroke, harvested watts, energy balance, and the comfort-versus-watts curve.
6. **Ablation:** each feature (load adaptation, skyhook, preview) is added one at a time to measure its share of the gain.

### 9.2 Stage 2: bench prototype (Gate B, part 1)

- Build a scaled tubular linear damper with power electronics and a power bank, driven by a hydraulic shaker or linear actuator using recorded or simulated suspension motion.
- Measure real watts, force-tracking accuracy, converter efficiency and controller power use.
- **Preview demo:** two units receive the same motion, the second one delayed. Show that unit 2 performs better using the warning.
- **Fail-safe test:** cut the power and confirm passive damping.

### 9.3 Stage 3: RDSO approval and trials (Gate B, part 2)

- Lab and rig tests to railway standards: electronics (EN 50155), shock and vibration (EN 61373), EMC (EN 50121).
- A safety case built on the fail-safe relay.
- Oscillation and ride trials as RDSO requires for the vehicle type.

### 9.4 Stage 4: pilots (Gate C)

- **Freight:** one Dedicated Freight Corridor rake, measuring axle monitoring coverage, alerts, parting detection and energy balance.
- **Vande Bharat:** one trainset, measuring ride index at different loads, preview benefit, energy balance and track-map quality.

### 9.5 Stage 5: fleet rollout

Factory fitment with coach factories (ICF, RCF, MCF) and wagon builders (Titagarh, Jupiter Wagons, Texmaco), plus a track data service for zonal railways.

![Roadmap](images/roadmap.png)

---

## 10. What changes after this project

**For passengers:** the same smooth ride whether the coach is empty or packed, and fewer shocks over bad track.

**For safety:**
- Every axle is watched all the time, so a hot bearing is caught early instead of between checkpoints.
- A train parting is located at the exact wagon.
- Wheel flats and damaged dampers are flagged during the run.

**For track maintenance:** a daily, GPS-tagged condition map from every train in service, so teams go where the track is getting worse.

**For the railway's operations:** the loco pilot and control office see the health of every coach and wagon live.

**For engineering:** smart dampers with no oil, which do not leak, monitor their own health, and need no new wiring.

**The bigger result:** Indian Railways moves from **"check sometimes, at some places"** to **"every train checks itself and the track, all the time"**, powered by energy that was being thrown away as heat.

---

## 11. What is new (novelty and patent)

### 11.1 What is new

No single part is new on its own. **The new invention is the combination:**

1. Suspension-recovered energy that powers **the suspension's own control and the safety sensors** on the same bogie (energy priority: safety first).
2. Damping set in proportion to **live measured load**, per corner.
3. A **train-wide bump warning** from the front bogie, timed by distance ÷ speed and corrected by cross-correlation.
4. **Every wagon** reporting health and position, so partings are located exactly.
5. **Track recording by every train** from damper signals.
6. A **fail-safe resistor relay** that makes the smart damper passive if power fails.

### 11.2 What already exists (prior art, not to be claimed alone)

- Self-powered end-of-train unit with an air turbine on the brake pipe (US 5,267,473, 1991) [R13]
- OMRS, EoTT and Track Recording Cars
- Load weighing from air-spring pressure
- Energy-harvesting dampers in research [R10, R11]; self-powered electromagnetic damper with economic MPC [R12]
- Preview control for active suspension (research)

### 11.3 Patent step

File a **provisional patent with the Indian Patent Office before any public disclosure**, including papers, competitions, open demos and pitches. Run a full prior-art search on Google Patents, IEEE Xplore and Indian patent databases first.

---

## 12. Risks and limits

| Risk | Effect | How we handle it |
|---|---|---|
| Less energy on smooth track | Power bank drains | Smooth track needs little control; the reserve covers it; sensors take priority |
| Wrong bump timing | Preview could hurt comfort | Cross-correlation alignment; preview switched off if confidence is low |
| Radio link lost | No preview | Vehicle works alone with load-adaptive and skyhook control |
| Load reading disturbed by vibration | Wrong damping target | 0.1 Hz filtering; weighing mainly at stations |
| Heat, dust, monsoon water | Electronics failure | IP67 sealing, wide-temperature parts, Indian-condition testing |
| Magnet cost and heat (NdFeB weakens when hot) | Cost and performance loss | Halbach array to reduce magnet mass; thermal limits in the controller |
| Higher cost than a hydraulic damper | Harder to sell | Value comes from safety, comfort and data, plus no oil and no wiring; to be costed |
| RDSO approval time | Delay | Fail-safe-first design; early engagement with RDSO |
| Over-claiming power | Loss of trust | Quote measured watts only |

**Limits we state openly:**
- The system will not power HVAC or traction.
- It does not fix coupler-slack jerks.
- It does not replace Kavach, EoTT or certified Track Recording Cars; it works alongside them.

---

## 13. Indicative bill of materials (per bogie)

| Part | Quantity | Note |
|---|---|---|
| Tubular linear PM damper (NdFeB Halbach rod, copper coil tube) | Per damper position | Replaces existing secondary dampers |
| H-bridge active rectifier per damper | Per damper | SiC or Si MOSFETs |
| Bidirectional DC-DC converter | 1 | MPPT and charging |
| Supercapacitor module + small LiFePO4 pack | 1 | About 5 Wh minimum reserve (to be sized) |
| Fail-safe relay + resistor $R_{fail}$ per damper | Per damper | Normally-closed |
| Microcontroller (e.g., ARM Cortex-M7 class) | 1 | Control, estimation, logging |
| Axle-box temperature sensors | 1 per axle box | Bearing health |
| Axle-box MEMS accelerometers | 1 per axle box | Bearing and wheel defects |
| Air-pressure or spring-deflection sensors | Per corner | Load estimation |
| Radio module / TCMS interface | 1 | Train Brain link |
| IP67 enclosure with anti-vibration mounts | 1 | Bogie-mounted |

Costs will be estimated after the bench prototype.

---

## 14. Glossary

| Term | Meaning |
|---|---|
| **Bogie** | The wheeled frame under each end of a coach or wagon |
| **Primary / secondary suspension** | Springs and dampers between wheels and bogie / between bogie and coach body |
| **Damper** | Device that removes bouncing energy; normally oil-filled |
| **Damping ratio (ζ)** | How well a damper stops bouncing for a given mass and spring |
| **Air spring** | Rubber bellows filled with air that carries the coach body |
| **Skyhook control** | Damping strategy that acts as if the body were attached to a fixed point in the sky |
| **Preview control** | Control that uses knowledge of the disturbance before it arrives |
| **MPC** | Model Predictive Control: chooses the best actions over a short future horizon |
| **Hot axle** | Overheated wheel bearing that can seize and cause derailment |
| **Train parting** | A train separating because a coupling breaks |
| **OMRS** | Online Monitoring of Rolling Stock: trackside bearing and wheel checks |
| **EoTT** | End of Train Telemetry: device on the last wagon that confirms the train is complete |
| **TCMS** | Train Control and Management System: the train's onboard network |
| **RDSO** | Research Designs and Standards Organisation, Indian Railways' technical approval body |
| **DFC / DFCCIL** | Dedicated Freight Corridor / the corporation that runs it |
| **Sperling index (Wz)** | A railway measure of ride comfort; lower is better |
| **MPPT** | Maximum Power Point Tracking: running a generator at its best output point |

---

## 15. References

- **[R1]** CAG, *Report No. 22 of 2022 — Performance Audit on Derailment in Indian Railways*. https://cag.gov.in/webroot/uploads/download_audit_report/2022/Report-No.-22-of-2022_Railway_English_DSC-063a2dda55f3ce6.38649271.pdf (figures checked via summary: https://indiafacts.in/cag-report-derailments-in-indian-railways-summary-and-recommendations/)
- **[R2]** Amar Ujala, "Increasing train parting, hot axle cases have safety implications; need investigation: Railways", 21 Oct 2025. https://english.amarujaladigital.com/national/increasing-train-parting-hot-axle-cases-have-safety-implications-need-investigation-railways
- **[R3]** The Wire, "Equipment Failure at Indian Railways Raises Questions Over Long-Term Safety Strategy", 29 Mar 2019. https://m.thewire.in/article/government/equipment-failure-at-indian-railways-raises-questions-over-long-term-safety-strategy
- **[R4]** The Wire, "Cost of Neglect: The Rising Toll of Train Accidents in India", 10 Aug 2024. https://m.thewire.in/article/government/cost-of-neglect-the-rising-toll-of-train-accidents-in-india
- **[R5]** IndoAI, "AI Models in Indian Railways 2025" (OMRS site count; confirm with an official source). https://indo.ai/content/IndoAI_AI_Indian_Railways.html
- **[R6]** Business Standard, "New system to do away with guard at rear-end of coaches". https://www.business-standard.com/article/pti-stories/new-system-to-do-away-with-guard-at-rear-end-of-coaches-116080901705_1.html
- **[R7]** India Infra Hub, "Indian Railways to equip all freight trains with End of Train Telemetry". https://indiainfrahub.com/featured/indian-railways-to-equip-all-freight-trains-with-cutting-edge-end-of-train-telemetry-technology/
- **[R8]** IRIMEE, "Introduction to Trainset Bogie" (Vande Bharat / Train-18). https://rskr.irimee.in/sites/default/files/Introduction%20to%20Trainset%20bogie%20(1).pdf
- **[R9]** Madras Musings, "Chennai–Mysuru Vande Bharat: a review". https://madrasmusings.com/vol-32-no-19/chennai-mysuru-vande-bharat-a-review/
- **[R10]** L. Dong, H. Zhang, J. Yu, G. Hu, "Energy harvesting potential assessment and systematic design for energy-regenerative shock absorbers on railway freight wagons", *Journal of Intelligent Material Systems and Structures*. https://doi.org/10.1177/1045389X231200146
- **[R11]** S. Wang et al., "An energy harvesting shock absorber for powering on-board electrical equipment in freight trains", *iScience*, 2023. https://pmc.ncbi.nlm.nih.gov/articles/PMC10457534/
- **[R12]** K. Cheng, Y. Guo, Z. Li, Q. Liang, L. Li, X. Zhang, "A novel self-powered PMSM electromagnetic damper based on adaptive economic model predictive control", *IEEE Transactions on Transportation Electrification*, 2024 (confirmed through reference 8 of https://arxiv.org/pdf/2509.11346; read the full text on IEEE Xplore).
- **[R13]** US Patent 5,267,473, "Self powered end of train unit", 1991. https://patents.google.com/patent/US5267473
- **[R14]** Y. Pan, F. Liu, R. Jiang, Z. Tu, L. Zuo, "Modeling and onboard test of an electromagnetic energy harvester for railway cars", *Applied Energy*, 2019. https://doi.org/10.1016/j.apenergy.2019.04.182

---

*All performance figures marked as targets, estimates or assumptions must be confirmed by simulation, bench tests and pilots before external use. Figures from 2018–19 should be refreshed with current Railway Board or Parliament data before presentation.*

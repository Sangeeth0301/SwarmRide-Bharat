# SwarmRide Bharat: Complete Understanding Guide

**What this guide is for:** read it before building anything. It explains every idea in the project from scratch, shows how all the parts work together, lays out exactly how to simulate the whole system in MATLAB/Simulink, and shows how to turn the simulation into something investors understand at a glance.

Author: Jaganath · Version 1.0 · 2 Oct 2026

---

## Contents

**Part A: Understand the project**
1. [The project in one page](#1-the-project-in-one-page)
2. [The ideas you must understand](#2-the-ideas-you-must-understand)
3. [How everything works together: one bump, start to finish](#3-how-everything-works-together-one-bump-start-to-finish)

**Part B: Simulate it in MATLAB/Simulink**

4. [Simulation goals: what we must prove](#4-simulation-goals-what-we-must-prove)
5. [Tools and toolboxes](#5-tools-and-toolboxes)
6. [The Simulink model: structure](#6-the-simulink-model-structure)
7. [The equations behind each block](#7-the-equations-behind-each-block)
8. [Starting parameters](#8-starting-parameters)
9. [Ready-to-use MATLAB code](#9-ready-to-use-matlab-code)
10. [The experiment plan](#10-the-experiment-plan)
11. [Build order, week by week](#11-build-order-week-by-week)
12. [How to know the simulation is right](#12-how-to-know-the-simulation-is-right)

**Part C: Show it to investors**

13. [Why MATLAB alone will not convince investors](#13-why-matlab-alone-will-not-convince-investors)
14. [The five visuals that tell the story](#14-the-five-visuals-that-tell-the-story)
15. [The live demo: from Simulink to a web dashboard](#15-the-live-demo-from-simulink-to-a-web-dashboard)
16. [The pitch flow and the questions investors will ask](#16-the-pitch-flow-and-the-questions-investors-will-ask)

**Part D: Reference**

17. [Glossary](#17-glossary)
18. [What to study, in order](#18-what-to-study-in-order)

---

# Part A: Understand the project

## 1. The project in one page

**The problem.** Indian Railways checks its trains only at fixed places (about 25 OMRS sites) or from time to time (Track Recording Cars, 30–100% short of schedule). Hot axles (about 3 a day), track faults (the biggest cause of derailments) and train partings grow unseen in between. Goods wagons have **no electricity**, so they cannot carry sensors. Coaches ride badly when crowded, because dampers are tuned for one load.

**The waste.** Every damper on every bogie turns bump energy into **heat**.

**The idea.** Replace the oil damper with a **smart damper**: a magnet moving inside a coil.

| It does | How |
|---|---|
| **Makes electricity** | Faraday's law: a moving magnet induces voltage in the coil |
| **Controls the ride** | The coil current sets how firm the damper is |
| **Powers itself and safety sensors** | Energy goes into a small power bank on the bogie |

**The system.** Every bogie becomes a self-powered unit. Every coach weighs itself and tunes its ride to its load. The loco (the **Train Brain**) warns every coach of the bump ahead and sees the health of every axle and the condition of the track.

**Two products.**
- **SwarmRide Freight:** safety for goods wagons (axles watched, partings located, track recorded).
- **SwarmRide Passenger:** comfort for Vande Bharat, LHB and ICF coaches (ride tuned to load and bump).

**What is honest.** The electricity is small: tens of watts per damper. It will never run air-conditioning. It is enough to make each bogie independent, and that is the point.

---

## 2. The ideas you must understand

Each idea below has four parts: what it is in simple words, the key equation, why it matters to SwarmRide, and what to learn next.

### 2.1 Train suspension: primary and secondary

```
   COACH BODY  (sprung mass: coach + passengers)
   ── secondary suspension: air springs (LHB, Vande Bharat) or coil springs (ICF)
      + vertical, lateral, yaw dampers   ← OUR SMART DAMPER GOES HERE
   BOGIE FRAME
   ── primary suspension: coil springs + dampers on the axle boxes
   WHEELSETS + AXLE BOXES (bearings)     ← BEARING SENSORS GO HERE
   ═══ RAIL ═══
```

- **Primary suspension:** between wheels and bogie frame. Absorbs sharp, fast shocks.
- **Secondary suspension:** between bogie and coach body. Controls the slow bounce (about 1 Hz) and pitch that passengers feel.
- **Goods wagons (Casnub bogie):** one spring stage (the spring nest) with friction wedges for damping. No oil damper, so our damper is added beside the spring nest.

**Why it matters:** our damper works in the secondary stage, in parallel with the existing spring.

### 2.2 Springs, dampers and the damping ratio

- **Spring:** force proportional to how much it is squeezed: F = k·x.
- **Damper:** force proportional to how fast it moves: F = c·v.
- **Natural frequency:** how fast the coach bounces on its springs:

$$\omega_n = \sqrt{k/m}, \qquad f_n = \frac{\omega_n}{2\pi}$$

- **Damping ratio:** how quickly the bouncing dies out.

$$\zeta = \frac{c}{2\sqrt{k\,m}}$$

| ζ | Ride |
|---|---|
| Below about 0.15 | Floats, keeps bouncing |
| About 0.2–0.3 | Typical target for comfort (to be tuned in simulation) |
| Above about 0.5 | Harsh, every bump reaches passengers |

**The key insight for SwarmRide.** Air springs get stiffer with load, so k grows roughly with m and ω stays about constant. Then:

$$\zeta = \frac{c}{2\,m\,\omega}$$

With a **fixed** damper, ζ falls as passengers board. From 40 t to 55 t (approximate figures), ζ falls by about 27%. SwarmRide raises c in proportion to m:

$$c_{target} = 2\,\zeta_{best}\,\omega\,m_{measured}$$

### 2.3 Vibration and track irregularity

- Rails are never perfectly straight. Their small vertical waviness is called **track irregularity**, w(x).
- At train speed v, a wavelength λ on the track becomes a vibration at frequency **f = v / λ**. At 160 km/h (44.4 m/s), a 44 m wave shakes the coach at 1 Hz: right at its natural frequency.
- Engineers describe track roughness with a **power spectral density (PSD)**: how much irregularity there is at each wavelength. We generate realistic track input from a standard PSD (Section 9.2), or from measured Indian track data if RDSO can provide it.

### 2.4 Faraday's law and back EMF: how the damper makes power

- A magnet moving through a coil induces a voltage (EMF):

$$e = K_e \, v_{rel}$$

  K_e is the **back-EMF constant** (volts per m/s). It depends on magnet strength, number of turns and coil length.
- When current i flows, the coil pushes back on the magnet (Lorentz force):

$$F = K_f \, i \qquad (K_f = K_e \text{ for an ideal machine, in SI units})$$

- This push-back always opposes the motion. **That is damping.** The energy taken out of the motion becomes electrical energy.

### 2.5 How the electrical load sets the damping

If the coil is connected to a resistance R_load:

$$i = \frac{e}{R_{coil} + R_{load}}, \qquad F = \frac{K_e^2}{R_{coil}+R_{load}}\,v_{rel}, \qquad c = \frac{K_e^2}{R_{coil}+R_{load}}$$

| Electrical load | Damping |
|---|---|
| Open circuit (R_load → ∞) | c ≈ 0: softest |
| Short circuit (R_load = 0) | c_max = K_e² / R_coil: firmest |
| Anything between | Any damping between 0 and c_max |

In practice the power electronics do not switch resistors. They **control the current directly**, which sets the force and therefore the damping, within milliseconds.

**Power split:**

$$P_{mech} = c\,v_{rel}^2, \qquad P_{harvest} = P_{mech}\frac{R_{load}}{R_{coil}+R_{load}}, \qquad P_{loss} = P_{mech}\frac{R_{coil}}{R_{coil}+R_{load}}$$

### 2.6 Power electronics

| Block | Job | Common mistake to avoid |
|---|---|---|
| **Active rectifier (H-bridge)** | Turns the coil's AC into DC and **controls coil current** (and so the damping force) | A plain diode rectifier cannot control damping |
| **DC-DC converter** | Turns the changing coil voltage into a steady 48 V bus | **It raises voltage, not energy.** 50 W in gives about 47.5 W out |
| **Supercapacitor** | Takes fast charge pulses from every bump | Energy E = ½CV²; usable energy depends on the voltage window |
| **Small LiFePO4 battery** | Keeps electronics alive at long station stops | Sized for reserve, not bulk storage |
| **Fail-safe relay + resistor** | If power fails, connects a fixed resistor so the damper acts like a normal passive damper | **Do not short the coil**: that gives c_max, which is too stiff |

### 2.7 Control: from simple to advanced

The controller decides, every millisecond, how firm each damper should be.

| Level | Name | Idea in one line |
|---|---|---|
| C0 | **Passive** | Fixed damping (today's trains) |
| C1 | **Fixed-load harvester** | Fixed electrical load (today's research harvesters) |
| C2 | **Load-adaptive + skyhook** | c follows measured load; extra firmness only when it calms the body |
| C3 | **C2 + preview** | Also uses the bump warning from the front of the train |

**Skyhook control** imagines the coach body hung from a fixed hook in the sky. Firm damping helps only when the body and the suspension move the same way:

$$c(t) = \begin{cases}\text{clip}\!\left(c_{sky}\,\dfrac{\dot z_b}{v_{rel}},\,0,\,c_{max}\right) & \text{if } \dot z_b\,v_{rel} > 0\\[2mm] c_{min} & \text{otherwise}\end{cases}$$

**LPV (Linear Parameter-Varying) control.** The controller gains change smoothly with **load m and speed v**: K = K(m, v). In practice we compute gains offline on a grid (for example 3 loads × 4 speeds) and interpolate. This is the formal version of "load-adaptive".

**Passivity limiter: why we never push.** The damper is allowed only to **resist** motion: 0 ≤ c ≤ c_max. Pushing (motor mode) would drain the power bank. Resisting always harvests. This keeps the system purely regenerative.

**Preview control.** Every wheel follows the same rail. The front bogie feels a bump first. A bogie at distance d behind meets it after:

$$t = d / v$$

At 160 km/h, 100 m behind gives 2.25 s of warning. The controller uses this known future input (feed-forward) instead of only reacting.

**MPC (Model Predictive Control)** is the advanced version: at every step it plans the best damping for the next second, using the preview and the energy budget. We use it as the "best possible" reference in simulation, and a simpler clipped preview controller on the real hardware.

### 2.8 Estimation: what the controller must know

| Quantity | How we get it |
|---|---|
| **Load m** | Air-spring pressure × effective area ÷ g (LHB, Vande Bharat), or spring deflection × stiffness ÷ g (ICF, goods). Low-pass filter at about 0.1 Hz; weigh mainly at stations |
| **Relative velocity v_rel** | Directly from the coil voltage: v_rel = e / K_e (free sensor) |
| **Body velocity ż_b** | Accelerometer on the body, integrated with a high-pass filter, or a Kalman filter |
| **Track ahead ŵ** | From the front bogie's axle-box accelerometer (double-integrated, band-pass filtered), plus the fleet track map |

### 2.9 Measuring comfort

- **Sperling ride index (Wz):** the classic railway comfort number; lower is better. Indian Railways (RDSO) uses ride index in oscillation trials.
- **ISO 2631 / EN 12299:** weighted RMS acceleration; the modern European comfort standards.
- We report **Wz and RMS body acceleration** for every case.

### 2.10 Railway context in India

| Term | Meaning |
|---|---|
| **ICF coach** | Older design, coil-spring secondary suspension with dampers |
| **LHB coach** | Modern design (FIAT bogie), air springs on many variants |
| **Vande Bharat** | Trainset; coach body sits directly on air springs; vertical, lateral and yaw dampers; built for 160 km/h |
| **Casnub bogie** | Standard goods-wagon bogie; spring nest with friction wedges |
| **OMRS** | Trackside bearing and wheel checks at fixed sites |
| **EoTT** | End-of-Train Telemetry; confirms the last wagon is attached |
| **TCMS** | Train Control and Management System; the trainset's onboard network |
| **RDSO** | Indian Railways' design and approval body; any trial needs its approval |

---

## 3. How everything works together: one bump, start to finish

Follow one bump through the whole system. The numbers are illustrative.

```
t = 0.000 s   Front wheel of the train hits a 5 mm dip at km 112.4
              → front bogie axle-box accelerometer records it
              → Train Brain stores the bump profile ŵ(x) with its position

t = 0.010 s   Train Brain sends "bump at km 112.400" over the train network
              to every vehicle (Vande Bharat: TCMS; goods: radio mesh)

t ≈ 0.6 s     Coach 1's bogie is about to reach the dip
  (coach 1)   Its controller already knows: load = 52 t (crowded), speed = 160 km/h
              → LPV gain for 52 t, preview feed-forward for the dip
              → passivity limiter keeps the force resistive
              → current command i* sent to the H-bridge

t ≈ 0.6 s     Dip arrives: bogie drops, coach body starts to follow
              → magnet moves inside coil at about 0.15 m/s
              → e = Ke·v ≈ 200 × 0.15 = 30 V
              → controlled current ≈ 15 A → force ≈ 3 kN opposing the motion
              → body bounce is damped; power flows into the bank

t ≈ 0.6–2 s   Bounce dies out quickly (damping matched to 52 t)
              → every joule of damping charged the supercapacitor
              → power bank feeds: axle sensors (first), radio, controller

Throughout    Axle-box sensors: bearing 47 °C, normal
              Damper voltage pattern: no wheel flat
              Data logged; health summary sent to the loco every few seconds

End of trip   Train uploads: track condition at km 112.4 (with the other trains'
              readings, this shows whether the dip is getting worse)
              → maintenance team sees it on the track map
```

**If a bearing overheats on wagon 37:** its sensor (powered by its own bogie) sends an alert. The loco pilot sees "Hot bearing · wagon 37 · axle 2" within seconds, without waiting for an OMRS site.

**If the train parts at wagon 52:** wagons 52 onward stop reporting together, or their position jumps. The loco pilot sees "Parting at wagon 52".

**If the electronics fail:** the relay drops out, the fixed resistor connects, and the damper behaves like today's passive damper. The ride is ordinary but safe.

---

# Part B: Simulate it in MATLAB/Simulink

## 4. Simulation goals: what we must prove

The simulation is **Gate A** on the roadmap. It must answer five questions with numbers:

| # | Question | Pass condition |
|---|---|---|
| Q1 | Is the ride better than fixed dampers at every load? | Lower Wz and RMS body acceleration at empty, half and crowded load |
| Q2 | Is the ride better than existing harvesters at the same power? | On a comfort-vs-watts graph, the SwarmRide curve lies above the C1 curve |
| Q3 | Does each bogie make more energy than it uses? | Energy balance ratio > 1 on the chosen tracks and speeds |
| Q4 | Does the bump warning help, and is it robust? | C3 better than C2, and still no worse than C2 with ±20 ms timing error |
| Q5 | Is it safe? | Stroke limits never exceeded; fail-safe case equals passive damper |

A sixth, simpler demo shows the **health-monitoring** idea: a simulated overheating bearing is detected and flagged.

---

## 5. Tools and toolboxes

MATLAB R2024b appears to be installed on this computer. Run `ver` in MATLAB to see which toolboxes you have.

| Toolbox | Used for | Essential? |
|---|---|---|
| **MATLAB + Simulink** | Everything | Yes |
| **Control System Toolbox** | LQR, state-space, the LPV System block | Yes |
| **Simscape + Simscape Electrical** | Physical modelling of coil, H-bridge, converter, supercapacitor (stage 2) | Recommended |
| **Stateflow** | Energy-supervisor modes (Comfort / Eco / Reserve / Fail-safe) | Recommended |
| **Model Predictive Control Toolbox** | MPC with signal previewing (C3 reference) | Optional (stage 2) |
| **Signal Processing Toolbox** | Filters, spectra, ride-index weighting | Recommended |
| **Parallel Computing Toolbox** | `parsim` to run many cases at once | Optional |
| **Simscape Multibody** or **Simulink 3D Animation** | 3D animation of the coach for videos | Optional (investor visuals) |

**Rule:** start with plain Simulink blocks and equations (fast, transparent). Move parts to Simscape only once the plain model works.

---

## 6. The Simulink model: structure

The model mirrors the architecture page of the pitch, one subsystem per box.

```
SwarmRide_Coach.slx  (one vehicle)
│
├── 1. Track Input
│      track profile w(x) → four wheel inputs w1..w4 with delays (wheel spacing ÷ v)
│
├── 2. Vehicle Plant  (half-coach: 4 DOF, 8 states)
│      body bounce z, body pitch θ, front bogie z1, rear bogie z2
│      inputs: w1..w4, damper forces F1, F2      outputs: all states + accelerations
│
├── 3. Smart Damper ×2  (front bogie, rear bogie)
│      in: v_rel, current command i*     out: force F, coil voltage e, electrical power
│
├── 4. Power Chain
│      H-bridge (average model) → DC-DC (efficiency η) → supercap + battery (SOC)
│      loads: sensors + radio + controller (5–20 W, constant)
│
├── 5. Estimators
│      load m (filtered air-spring force), v_rel from coil voltage, body velocity
│
├── 6. Controller  (variant subsystem: C0 | C1 | C2 | C3)
│      LPV gains K(m,v) · skyhook · preview feed-forward · passivity limiter
│      out: current command i*
│
├── 7. Energy Supervisor  (Stateflow)
│      SOC → mode: Comfort / Eco / Reserve / Fail-safe
│
├── 8. Fail-safe
│      if fault or SOC < floor → relay → fixed resistor R_fail
│
├── 9. Health Monitor  (demo)
│      bearing thermal model + fault injection → alert
│
└── 10. Metrics + Logging
       Wz, RMS acceleration, stroke, harvested power, energy balance → workspace

SwarmRide_Train.slx  (train level, stage 2)
│   N referenced copies of SwarmRide_Coach (Model blocks)
│   Train Brain: lead-bogie track estimate → delayed preview to each vehicle
│   network model: latency + timing error + dropout
```

**Simulink tips:**
- Use a **Variant Subsystem** for the controller, so one model runs C0–C3 by changing one variable (`ctrl`).
- Keep **all parameters in one script** (`swarmride_params.m`), never typed into blocks.
- Use **To Workspace** or **signal logging** for every output, so batch runs can be analysed by script.
- Use a fixed-step solver (for example `ode4`, 1 ms step) for controller parts, matching the future microcontroller.

---

## 7. The equations behind each block

### 7.1 Vehicle plant (half-coach, 4 DOF)

Positions: front bogie centre at +l_b from the body centre, rear at −l_b. Each bogie has two wheelsets at ±a_b from its centre.

Secondary suspension deflection points on the body:

$$z_{s1} = z + l_b\,\theta, \qquad z_{s2} = z - l_b\,\theta$$

Secondary force at each bogie (spring + smart damper):

$$S_i = k_s\,(z_{si} - z_i) + F_{d,i}, \qquad i = 1, 2$$

Body bounce and pitch (m and I include the passenger load):

$$m\,\ddot z = -(S_1 + S_2), \qquad I\,\ddot\theta = -l_b\,S_1 + l_b\,S_2$$

Bogie bounce (two wheelsets per bogie, inputs w_{i,a}, w_{i,b}):

$$m_{bg}\,\ddot z_i = S_i - k_p\left[(z_i - w_{i,a}) + (z_i - w_{i,b})\right] - c_p\left[(\dot z_i - \dot w_{i,a}) + (\dot z_i - \dot w_{i,b})\right]$$

Wheel input delays, measured from the leading wheel (front of the coach) at speed v:

| Wheel | Distance behind leading wheel | Delay |
|---|---|---|
| Front bogie, front wheelset | 0 | 0 |
| Front bogie, rear wheelset | 2a_b | 2a_b / v |
| Rear bogie, front wheelset | 2l_b | 2l_b / v |
| Rear bogie, rear wheelset | 2l_b + 2a_b | (2l_b + 2a_b) / v |

**Load effect:** m = m_tare + m_load; air-spring stiffness k_s = k_s0 · m / m_tare (constant frequency); pitch inertia scales roughly with m.

**Stage 2 upgrade:** add bogie pitch (6 DOF) and lateral dynamics (yaw dampers), then a full 3D model in Simscape Multibody.

### 7.2 Smart damper (per bogie, lumped)

$$e = K_e\,v_{rel}, \qquad L_c\frac{di}{dt} = e - R_c\,i - u_{conv}, \qquad F_d = K_f\,i$$

- **Average model (start here):** the H-bridge current loop forces i to follow i* with a fast first-order lag (time constant about 1 ms). Skip u_conv and L_c at first.
- **Electrical power into the converter:** P_el = e·i − i²·R_c.
- **Sign convention:** F_d acts on the body in the direction that opposes v_rel. The passivity limiter guarantees F_d·v_rel ≥ 0 (energy flows out of the motion).

### 7.3 Power chain and power bank

$$P_{bank,in} = \eta_{dc}\,P_{el}, \qquad C\,V\,\frac{dV}{dt} = P_{bank,in} - P_{loads}, \qquad SOC = \frac{V^2 - V_{min}^2}{V_{max}^2 - V_{min}^2}$$

- η_dc ≈ 0.9–0.95 (assumed).
- P_loads = 5–20 W constant (estimate; replace with bench measurement).
- **Energy balance ratio:** E_harvested ÷ E_used over the trip. The target is > 1.

### 7.4 Controller (C3, the full version)

$$F^* = -K(m, v)\,\hat x + K_p(m, v)\,\hat w_{preview}$$

$$c = \text{clip}\!\left(\frac{F^*}{v_{rel}},\ 0,\ c_{max}\right), \qquad i^* = \frac{c\,v_{rel}}{K_f}$$

- **K(m, v):** LQR gains computed offline for a grid of loads and speeds, interpolated with a lookup table (or the LPV System block).
- **K_p:** preview gains from the LQR-with-preview method, or replaced by MPC with signal previewing as the reference.
- Near v_rel ≈ 0, hold c at c_min to avoid dividing by zero.

### 7.5 Load estimator

$$\hat m = \text{LPF}_{0.1\,Hz}\!\left(\frac{\sum_i (p_i - p_{atm})\,A_{eff}}{g}\right) - m_{bogie\ share}$$

In simulation: the measured spring force + noise → low-pass filter → m̂.

### 7.6 Health monitor (demo model)

Bearing temperature, first-order thermal model:

$$C_{th}\frac{dT}{dt} = P_{friction} - h\,(T - T_{amb})$$

Inject a fault (P_friction rising over 10 minutes). Alarm when T exceeds an absolute limit or rises faster than a rate limit. The point is to **show continuous detection**, not to model bearing physics exactly.

**Wheel flat:** a periodic impact at the wheel rotation frequency

$$f_{flat} = \frac{v}{\pi D}$$

which is detectable in the damper voltage spectrum.

---

## 8. Starting parameters

**These are assumed starting values, typical of the literature for a passenger coach.** Replace them with real ICF, LHB or Vande Bharat data from RDSO, manufacturer documents or published papers as soon as you can. Check each one before showing results externally.

| Symbol | Meaning | Starting value | Note |
|---|---|---|---|
| m_tare | Coach body mass, empty | 40 t | assumed |
| m_load | Payload: empty / half / crowded | 0 / 7.5 / 15 t | assumed |
| I | Body pitch inertia | 1.6 × 10⁶ kg·m² | rough estimate |
| m_bg | Bogie frame mass (each) | 3.0 t | assumed |
| l_b | Half distance between bogie centres | 7.5 m | approximate |
| a_b | Half bogie wheelbase | 1.28 m | approximate |
| k_s0 | Secondary vertical stiffness per bogie (empty) | 0.8 MN/m | gives about 0.9 Hz body bounce |
| c_s | Passive secondary damping per bogie | 40 kN·s/m | baseline C0 |
| k_p | Primary stiffness per wheelset | 1.2 MN/m | assumed |
| c_p | Primary damping per wheelset | 15 kN·s/m | assumed |
| K_e = K_f | Smart damper constant (lumped per bogie) | 200 V/(m/s) | design variable |
| R_c | Coil resistance | 0.5 Ω | design variable |
| c_max | Maximum damping = K_e²/R_c | 80 kN·s/m | from the two above |
| η_dc | DC-DC efficiency | 0.92 | assumed |
| P_loads | Electronics + sensors per bogie | 10 W | estimate |
| v | Speeds | 80, 110, 130, 160 km/h | test grid |

**Sanity check:** total secondary stiffness 1.6 MN/m in series with primary 4.8 MN/m gives about 1.2 MN/m. With 40 t, that is a natural frequency of √(1.2×10⁶ / 40 000) / 2π ≈ 0.87 Hz. That is a realistic body-bounce frequency.

---

## 9. Ready-to-use MATLAB code

Put everything in one MATLAB project folder:

```
SwarmRide_Sim/
├── swarmride_params.m        parameters (Section 8)
├── track_profile.m           track generator
├── sperling_vertical.m       ride index
├── run_all_cases.m           batch experiments
├── make_investor_plots.m     the five visuals
├── export_for_dashboard.m    results → JSON for the web demo
├── models/
│   ├── SwarmRide_Coach.slx
│   └── SwarmRide_Train.slx
└── results/
```

### 9.1 Parameters (`swarmride_params.m`)

```matlab
%% SwarmRide Bharat - starting parameters (ASSUMED: replace with real coach data)
p.mtare = 40e3;            % coach body mass, empty [kg]
p.mload = [0 7.5e3 15e3];  % payload: empty / half / crowded [kg]
p.I0    = 1.6e6;           % body pitch inertia, empty [kg m^2]
p.mbg   = 3.0e3;           % bogie frame mass, each [kg]
p.lb    = 7.5;             % half distance between bogie centres [m]
p.ab    = 1.28;            % half bogie wheelbase [m]
p.ks0   = 0.8e6;           % secondary stiffness per bogie, empty [N/m]
p.cs    = 40e3;            % passive secondary damping per bogie [N s/m]
p.kp    = 1.2e6;           % primary stiffness per wheelset [N/m]
p.cp    = 15e3;            % primary damping per wheelset [N s/m]

% smart damper (lumped per bogie)
p.Ke    = 200;             % back-EMF constant [V/(m/s)] (= Kf [N/A])
p.Rc    = 0.5;             % coil resistance [ohm]
p.tau_i = 1e-3;            % current-loop time constant [s]
p.cmax  = p.Ke^2/p.Rc;     % firmest damping (coil shorted) [N s/m]
p.cmin  = 1e3;             % softest usable damping [N s/m]
p.Rfail = p.Ke^2/p.cs - p.Rc;   % fail-safe resistor -> passive damping [ohm]

% power chain
p.eta_dc = 0.92;           % DC-DC efficiency [-]
p.Pload  = 10;             % electronics + sensors per bogie [W]
p.Csc    = 50;             % supercapacitor bank [F]
p.Vmin   = 24; p.Vmax = 48;% usable voltage window [V]

% helpers that depend on load
mass   = @(ml) p.mtare + ml;
ks_of  = @(ml) p.ks0 * mass(ml) / p.mtare;   % air spring stiffens with load
I_of   = @(ml) p.I0  * mass(ml) / p.mtare;

fprintf('c_max = %.0f N s/m, R_fail = %.2f ohm\n', p.cmax, p.Rfail);
```

### 9.2 Track profile (`track_profile.m`)

This uses the vertical track spectrum widely used in rail-vehicle studies (often called the German track spectrum). **Check the PSD convention (one-sided vs two-sided) against your source** and compare the RMS of the result with published values before trusting it.

```matlab
function [x, w] = track_profile(L, dx, Av, seed)
%TRACK_PROFILE Random vertical track irregularity by sum of sines.
%   L  : track length [m]        dx : spatial step [m]
%   Av : roughness constant [m rad], e.g. 4.032e-7 (good) or 1.08e-6 (poor)
%   x, w : position [m] and irregularity [m] (column vectors)
if nargin < 4, seed = 1; end
rng(seed);
Oc = 0.8246;  Or = 0.0206;                    % [rad/m]
Om = linspace(2*pi/100, 2*pi/1, 1500);        % wavelengths 100 m .. 1 m
dOm = Om(2) - Om(1);
S  = Av*Oc^2 ./ ((Om.^2 + Or^2) .* (Om.^2 + Oc^2));   % PSD [m^2/(rad/m)]
A  = sqrt(2*S*dOm);                            % harmonic amplitudes [m]
ph = 2*pi*rand(size(Om));
x  = (0:dx:L)';
w  = zeros(size(x));
for k = 1:numel(Om)                            % loop keeps memory small
    w = w + A(k)*sin(Om(k)*x + ph(k));
end
end
```

Use it in Simulink as a lookup: wheel input w_j(t) = interp1(x, w, v·t − d_j), where d_j is the wheel's distance behind the leading wheel.

### 9.3 Sperling ride index (`sperling_vertical.m`)

```matlab
function Wz = sperling_vertical(a, fs)
%SPERLING_VERTICAL Sperling ride index for vertical body acceleration.
%   a  : acceleration [m/s^2] (vector)    fs : sample rate [Hz]
%   Frequency-domain method. Results depend on record length; use the same
%   length for every case. Check against EN 12299 / RDSO practice.
a  = a(:) - mean(a);
N  = numel(a);
A  = abs(fft(a)) * 2 / N;              % single-sided amplitude
f  = (0:N-1)' * fs / N;
k  = f >= 0.5 & f <= 30;
f  = f(k);  acm = A(k) * 100;          % [cm/s^2]
F  = ones(size(f));                    % vertical weighting
F(f < 5.9)           = 0.325 * f(f < 5.9).^2;
F(f >= 5.9 & f < 20) = 400 ./ f(f >= 5.9 & f < 20).^2;
Wi = 0.896 * (acm.^3 .* F ./ f).^(1/10);
Wz = sum(Wi.^10)^(1/10);
end
```

### 9.4 Load-adaptive damping target (inside the controller)

```matlab
% computed every control step (or as a MATLAB Function block)
zeta_best = 0.25;                         % tune in simulation
omega     = 2*pi*0.87;                    % body bounce frequency [rad/s]
c_target  = 2*zeta_best*omega*m_hat/2;    % per bogie (two bogies share the body)
c_target  = min(max(c_target, p.cmin), p.cmax);
```

### 9.5 Passivity limiter and current command (MATLAB Function block)

```matlab
function istar = passivity_limiter(Fstar, vrel, Ke, cmin, cmax)
%#codegen
% Convert the desired force into a current the damper can deliver by RESISTING only.
if abs(vrel) < 1e-3
    c = cmin;                              % avoid divide-by-zero near rest
else
    c = Fstar / vrel;                      % damping that would give Fstar
    c = min(max(c, 0), cmax);              % resist only, within limits
    c = max(c, cmin);
end
istar = c * vrel / Ke;                     % Kf = Ke for an ideal machine
end
```

### 9.6 Batch runs (`run_all_cases.m`)

```matlab
swarmride_params;
mdl    = 'SwarmRide_Coach';
speeds = [80 110 130 160] / 3.6;          % [m/s]
ctrls  = 0:3;                              % C0..C3
tracks = [4.032e-7 1.08e-6];               % good, poor
in = Simulink.SimulationInput.empty;
for v = speeds
  for ml = p.mload
    for c = ctrls
      for Av = tracks
        s = Simulink.SimulationInput(mdl);
        s = s.setVariable('v', v).setVariable('mload', ml) ...
             .setVariable('ctrl', c).setVariable('Av', Av);
        in(end+1) = s; %#ok<AGROW>
      end
    end
  end
end
out = parsim(in, 'ShowProgress', 'on');    % use sim(in) without Parallel Toolbox
save('results/all_cases.mat', 'out', 'in', '-v7.3');
```

### 9.7 Export for the investor dashboard (`export_for_dashboard.m`)

```matlab
% After run_all_cases: one row per case -> results/dashboard.json
rows = struct('speed_kmh',{}, 'load_t',{}, 'ctrl',{}, 'track',{}, ...
              'Wz',{}, 'arms',{}, 'Pharvest_W',{}, 'balance',{});
for k = 1:numel(out)
    o = out(k);  s = in(k);
    v   = s.Variables(strcmp({s.Variables.Name}, 'v')).Value;
    ml  = s.Variables(strcmp({s.Variables.Name}, 'mload')).Value;
    c   = s.Variables(strcmp({s.Variables.Name}, 'ctrl')).Value;
    Av  = s.Variables(strcmp({s.Variables.Name}, 'Av')).Value;
    a   = o.logsout.get('az_body').Values.Data;   % names must match your logging
    P   = o.logsout.get('P_harvest').Values.Data;
    E_u = o.logsout.get('E_used').Values.Data(end);
    E_h = o.logsout.get('E_harvest').Values.Data(end);
    rows(end+1) = struct('speed_kmh', round(v*3.6), 'load_t', ml/1e3, 'ctrl', c, ...
        'track', ternary(Av > 5e-7, "poor", "good"), 'Wz', sperling_vertical(a, 1000), ...
        'arms', rms(a), 'Pharvest_W', mean(P), 'balance', E_h / max(E_u, eps)); %#ok<AGROW>
end
fid = fopen('results/dashboard.json', 'w'); fwrite(fid, jsonencode(rows)); fclose(fid);

function y = ternary(c, a, b), if c, y = a; else, y = b; end, end
```

The signal names (`az_body`, `P_harvest`, `E_used`, `E_harvest`) must match the names you give logged signals in the model.

---

## 10. The experiment plan

| Factor | Values | Why |
|---|---|---|
| Controller | C0, C1, C2, C3 | Today vs existing harvesters vs SwarmRide |
| Load | Empty, half, crowded | Proves the load-adaptive claim |
| Speed | 80, 110, 130, 160 km/h | Freight to Vande Bharat range |
| Track | Good, poor | Robustness |
| Preview timing error | 0, ±10, ±20 ms | Robustness of the bump warning |
| Network dropout | On / off | "Works alone" claim |
| Fault | None, power loss | Fail-safe claim |

That is 4 × 3 × 4 × 2 = 96 main runs, plus robustness runs on the C3 cases. Each run covers 2–3 km of track.

**Outputs for every run:** Wz, RMS body acceleration, max and RMS stroke, average harvested power per bogie, energy balance ratio, SOC trace, and peak damper force.

**The ablation study** (what reviewers and investors trust most): start at C1, then add one feature at a time: load adaptation → skyhook → preview. This measures how much each feature contributes.

---

## 11. Build order, week by week

| Week | Build | Check before moving on |
|---|---|---|
| 1 | **Quarter-car** (one corner) with passive damper, step input | Natural frequency ≈ hand calculation; decay matches ζ |
| 2 | Replace the damper with the **smart damper + fixed resistor** | Same response as passive when c = K_e²/(R_c+R) |
| 3 | **Half-coach 4-DOF** model + track generator + wheel delays | Passive Wz in a sensible range; pitch appears when expected |
| 4 | **Controllers C1, C2** (variant subsystem) + passivity limiter | F·v_rel ≥ 0 always; C2 better than C0 at crowded load |
| 5 | **Power chain + power bank + Stateflow modes** | Energy conservation (Section 12); SOC behaves sensibly |
| 6 | **Preview (C3)**: LQR-with-preview or clipped feed-forward | C3 ≥ C2; robust to ±20 ms error |
| 7 | **Batch runs** + plots + ablation | All 96 cases complete; results stable across random seeds |
| 8 | **Train model** (several coaches, network delay/dropout) + **health demo** + dashboard export | Alerts appear; dropout falls back gracefully |

Optional later: Simscape Electrical detail (switching H-bridge, real supercapacitor), lateral and yaw dynamics, MPC reference, 3D animation.

---

## 12. How to know the simulation is right

1. **Hand checks.** Natural frequency and damping ratio from the formulas must match the simulated step response.
2. **Energy conservation.** Over a run: energy into the coil = harvested + coil losses (within 1%). If not, a sign or unit is wrong.
3. **Passivity.** Plot F·v_rel: it must never be negative (pure regenerative). Count violations; there should be none.
4. **Limits.** Stroke stays within ±40 mm (assumed); damper force within the machine's rating.
5. **Fail-safe equivalence.** With the relay engaged, the response must equal C0 with c = c_s.
6. **Seed robustness.** Repeat with 5 random track seeds; report mean ± spread, never one lucky run.
7. **Literature comparison.** Harvested power should sit in the published range (tens of watts per damper on average track; 63 W best built, Dong et al.). Far above that means something is wrong.
8. **Unit discipline.** SI units everywhere; convert km/h and tonnes only for display.

---

# Part C: Show it to investors

## 13. Why MATLAB alone will not convince investors

You are right: investors cannot read a Simulink diagram. They want to **see** the result and **trust** the number. So:

| Investors do not want | Investors want |
|---|---|
| Block diagrams, equations, code | A picture of the problem and the result |
| 96 tables of numbers | 3–5 headline numbers with a clear "before vs after" |
| "The simulation shows…" | "Here it is, moving" (animation, demo, video) |
| Perfect claims | Honest numbers with a clear path to proof (bench → RDSO → pilot) |

**Rule:** MATLAB produces the evidence. The **visuals, the demo and the story** sell it. Show one Simulink screenshot, at most, as "how we know".

---

## 14. The five visuals that tell the story

Each comes straight from the batch results (`make_investor_plots.m`).

| # | Visual | What it says | How to make it |
|---|---|---|---|
| 1 | **Side-by-side coach animation** (fixed damper vs SwarmRide, crowded coach, same track) | "Look how much calmer it is" | Animate the body bounce from two runs (simple 2D drawing updated per frame, saved with `VideoWriter`), or Simscape Multibody animation |
| 2 | **Comfort at every load** (bar chart: Wz for empty / half / crowded, C0 vs C3) | "Same good ride, empty or packed" | Grouped bar chart from the results table |
| 3 | **Comfort vs watts** (one curve per controller) | "Better ride *and* power, unlike existing harvesters" | Sweep the energy weight; plot Wz against harvested W |
| 4 | **Energy balance gauge** (harvested vs used per bogie) | "Each bogie powers itself" | Two bars or a gauge: e.g. "made 40 W, used 10 W" (from your results) |
| 5 | **Live alert demo** (simulated hot bearing on wagon 37 appears on a "loco screen") | "Faults caught in seconds, not at the next checkpoint" | Health-monitor run → timeline with the alert moment marked |

Keep every chart to one message, with the number written on it. Mark them "simulation results" until the bench and pilot confirm them.

---

## 15. The live demo: from Simulink to a web dashboard

Investors should be able to **play with it** without MATLAB.

**Approach: precompute in MATLAB, play in the browser.**

```
MATLAB/Simulink                     Web dashboard (no MATLAB needed)
───────────────                     ───────────────────────────────
run_all_cases.m  →  96+ runs        Sliders: speed · load · track roughness
export_for_dashboard.m              Toggle: fixed damper ↔ SwarmRide
   → dashboard.json                 Animated coach side by side
   → short time traces per case     Live numbers: ride index, watts, balance
                                    "Hot bearing" demo button
```

- **Why precompute:** the dashboard just looks up the nearest stored case, so it runs instantly on any laptop or phone, with no licence and no risk of crashing in a meeting.
- **How to build it:** a simple web page (React, or a no-code tool such as Lovable that you operate yourself) that loads `dashboard.json`. This matches the investor-dashboard idea in your v1 plan.
- **Optional live mode:** for technical investors, a FastAPI server calling MATLAB (MATLAB Engine for Python) can run a new case live. Use it only as a bonus, never as the main demo.

**Also prepare:**
- A **60-second video**: problem (photos) → animation (calm vs bouncy) → numbers → bench prototype (when built).
- The **6-page PDF** you already have, with simulation numbers filled in after Gate A.
- **One "how we know" slide:** a Simulink screenshot, the validation checks (Section 12) and the test matrix.

---

## 16. The pitch flow and the questions investors will ask

### 16.1 Pitch flow (10 minutes)

1. **Problem (1 min):** hot axles, track faults, partings, no power on wagons. Real photos.
2. **Insight (1 min):** every damper wastes energy as heat; we use it.
3. **Solution (2 min):** smart damper → power bank → sensors and ride control → loco sees everything. Architecture page.
4. **Proof (3 min):** live dashboard + animation + the four headline numbers from simulation.
5. **Plan (1 min):** bench → RDSO → DFC and Vande Bharat pilots → fleet.
6. **Business and ask (2 min):** hardware + software + data; what we need.

### 16.2 Questions to expect, and honest answers

| Question | Answer |
|---|---|
| "How much electricity does it make?" | Tens of watts per damper. Not for AC; enough for each bogie to run its own sensors and control, with spare. Measured numbers come from the bench. |
| "Why not just run a cable from the coach supply?" | Goods wagons have no supply at all. On coaches, retrofitting cables to every bogie costs time and money, and bogie cables wear out. |
| "Is it safe?" | If anything fails, a relay makes it a normal passive damper. Safety never depends on software. |
| "What already exists?" | Trackside checks (OMRS), EoTT, recording cars, research harvesters, self-powered end-of-train units. Our novelty is the combination, powered by the suspension itself. |
| "How do you know it works?" | Simulation (Gate A) with validation checks, then bench, then RDSO trials, then pilots. |
| "What does it cost?" | Set after the bench prototype is costed. Value comes from fewer derailments, better ride and track data, not from electricity. |
| "Who buys?" | Railway Board and zonal railways (after RDSO), DFCCIL, coach factories, wagon builders. |
| "Is it patented?" | Provisional patent to be filed before any public disclosure. |

---

# Part D: Reference

## 17. Glossary

| Term | Meaning |
|---|---|
| Back EMF | Voltage induced in a coil by a moving magnet; proportional to speed |
| Bogie | Wheeled frame under each end of a coach or wagon |
| c, c_max | Damping coefficient; the firmest damping the smart damper can give |
| Damping ratio ζ | How fast bouncing dies out |
| DC-DC converter | Changes DC voltage level; never creates energy |
| H-bridge | Four-switch circuit that controls current direction and size |
| K_e, K_f | Back-EMF and force constants of the smart damper |
| LPV | Controller whose gains vary with measured parameters (load, speed) |
| LQR | Optimal state-feedback control method used to compute gains |
| MPC | Controller that plans ahead over a short horizon |
| Passivity limiter | Rule that the damper only resists motion (always harvests) |
| PSD | Power spectral density; describes track roughness |
| Preview | Knowing the bump before it arrives |
| Skyhook | Comfort-focused damping strategy |
| SOC | State of charge of the power bank |
| Sperling Wz | Railway ride-comfort index; lower is better |

## 18. What to study, in order

1. **Vibration basics:** mass-spring-damper, natural frequency, damping ratio (any vibrations textbook).
2. **Railway vehicle dynamics:** primary/secondary suspension, track irregularity, ride index (search "railway vehicle dynamics" textbooks and RDSO bogie notes such as the IRIMEE trainset bogie notes).
3. **Electromagnetic energy harvesting:** Faraday's law, back EMF, electrical damping (the Dong et al. and Wang et al. papers, and the Cheng et al. IEEE paper in the references of the technical document).
4. **Power electronics basics:** rectifiers, H-bridge current control, buck/boost converters, supercapacitors.
5. **Control:** state-space models, LQR, skyhook, gain scheduling and LPV, then MPC (MATLAB documentation: "LPV System" block, "Signal Previewing" in the MPC Toolbox).
6. **MATLAB/Simulink practice:** variant subsystems, MATLAB Function blocks, Stateflow, `Simulink.SimulationInput` and `parsim`.

---

*All parameters marked "assumed" and all expected results are starting points to be replaced by real coach data and measured results. Refresh any 2018–19 railway figures with current data before presenting.*

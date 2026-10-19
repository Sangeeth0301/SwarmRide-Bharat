# Base Paper Study: Regenerative Semi-Active Suspension for High-Speed Trains

**A simple-English guide to the base paper of the SwarmRide Bharat project**

| Item | Details |
|---|---|
| **Paper** | Y. Hua, Q. Cai and S. Zhu, “Energy-Regenerative Semiactive Lateral Suspension Control in High-Speed Trains Using Electromagnetic Damper Cum Energy Harvester” |
| **Journal** | *IEEE Transactions on Vehicular Technology*, vol. 71, no. 5, pp. 4801–4812, May 2022 |
| **DOI** | 10.1109/TVT.2022.3149265 |
| **Authors’ group** | The Hong Kong Polytechnic University (civil and environmental engineering, rail transit research centre) |
| **Prepared for** | SwarmRide Bharat team: Jaganath, Niranjan, Kowshik, Sangeeth |

This guide explains the paper in our own words. Numbers are taken from the paper; read the original for the full figures.

---

## 1. The paper in one paragraph

A train’s secondary suspension has dampers that turn vibration into heat. The authors replaced the side-to-side (lateral) dampers of a high-speed train with an **electromagnetic damper that also harvests energy**. They called it an **EMDEH**: *ElectroMagnetic Damper cum Energy Harvester*. A small power circuit decides how much current the damper’s coil sends to a battery. More current means a stiffer damper, and changing the circuit’s **duty cycle** changes the damping in real time. A smart controller (LQG) decides at every moment how much force the damper should give. They tested a full-size damper in the lab and then simulated a high-speed train at 200–350 km/h. The result: **55% less side-to-side vibration** of the coach at 350 km/h, and **26–153 W** of harvested power.

---

## 2. The problem they found

The authors list three gaps in earlier research:

| # | Gap | In simple words |
|---|---|---|
| a | Power was estimated with a plain resistor | Earlier studies pretended the energy went into a simple resistor. A real charging circuit has its own losses and delays, so those studies **over-estimated** the power |
| b | Almost all work was on cars | Regenerative shock absorbers were studied for cars, vertically. Hardly anyone studied the **side-to-side suspension of high-speed trains**, for both comfort and energy |
| c | Earlier “smart” versions were weak | Most dual-function dampers were passive (one fixed setting). The semi-active ones could only switch between **two settings**, or had a very narrow range, so they were barely better than a normal damper |

**Why lateral (side-to-side)?** At high speed, side-to-side stability matters for safety (derailment) and for passenger comfort. The secondary lateral suspension also affects “hunting”, the snake-like swaying of a bogie.

---

## 3. The abstract, in simple words

- Faster trains need better suspensions for **comfort** and **energy efficiency**.
- The authors built a new **energy-recovering, semi-active secondary suspension** for high-speed trains using the EMDEH.
- The EMDEH can **smoothly change its damping** by changing the duty cycle of its energy-harvesting circuit.
- They **tested a full-size prototype** in cyclic tests, built a computer model of it, and showed the model matches the tests.
- A **semi-active controller** makes the damper follow the force wanted by an **LQG** controller.
- In simulation the semi-active damper reduced car-body vibration **more than normal passive dampers** and more than the same damper at a fixed setting (FEMDEH), at **200–350 km/h**.
- The fixed-setting version harvested **more power**, but the semi-active one still harvested **25.89–153.19 W**.

---

## 4. Key ideas you need first

| Idea | Simple explanation |
|---|---|
| **Passive damper** | A normal oil damper: one fixed stiffness, turns motion into heat |
| **Active suspension** | A powered actuator can push and pull with any force. Best comfort, but uses a lot of energy and is expensive |
| **Semi-active suspension** | The damper cannot push. It can only **change how hard it resists**. Cheap, safe and uses almost no energy |
| **Electromagnetic damper (EMD)** | A motor driven backwards. Moving it makes a voltage (**Faraday’s law**: u = Kem·v). The current flowing back makes a resisting force (**Lorentz force**: f = Kem·i) |
| **Motor constant Kem** | How strongly motion turns into voltage and current into force. Their damper: **640 N/A** |
| **Equivalent resistance Req** | How hard the circuit “pulls” current. Lower Req → more current → **stiffer damper** |
| **Damping coefficient c** | Force per unit speed (N·s/m). Their formula: c = Kem² / (Rcoil + Req), plus a little friction (parasitic damping) |
| **Buck–boost converter** | A small power circuit that raises or lowers voltage to charge a battery. A transistor switches on and off thousands of times a second |
| **Duty cycle δ** | The fraction of time the transistor is ON. Changing δ changes Req, and so the damping. **This is their control knob** |
| **DCM / CCM** | Two operating modes of the converter. In DCM, Req depends simply on δ. In CCM (at high voltage), Req drops and the damping rises above what was planned |
| **LQR** | An optimal controller: it finds the best force by balancing comfort against effort (a cost function J) |
| **Kalman filter** | Estimates all hidden motions of the train from a few accelerometers |
| **LQG** | LQR + Kalman filter together |
| **VR (vibration reduction)** | (passive − new) / passive. Positive = less vibration |

---

## 5. Methodology, step by step

### Step 1: Design the damper
The damper is a **rotary motor + an 8:1 gearbox + a ball screw (16 mm lead)**. The ball screw turns the straight motion of the suspension into rotation, and the gearbox speeds it up so the motor makes useful voltage.

### Step 2: Choose the energy-harvesting circuit (EHC)
The coil output goes through a **bridge rectifier** (AC to DC) and a **buck–boost converter** into a **battery**. The converter’s duty cycle sets Req, and so the damping force.

### Step 3: Build a computer model of the damper
- **EMD part:** speed → voltage; current → force.
- **EHC part:** voltage → stored energy, with real circuit losses.
- **Control part:** a PWM generator sets the duty cycle.

### Step 4: Account for every power loss
They split the energy into four parts:
1. **η1:** lost to friction (parasitic damping)
2. **η2:** lost in the coil resistance and the diodes
3. **η3:** lost in the converter
4. what finally reaches the battery

Total efficiency is **η = η1 × η2 × η3**.

### Step 5: Test the prototype in the lab
A full-size damper was tested on an **MTS machine** at **5 mm amplitude and 1 Hz**:
- Motor constant: **Kem = 640 N/A**
- Coil resistance: **7.5 Ω**
- Friction (parasitic) damping: **5 kN·s/m**
- Coil shorted (maximum damping): **62.6 kN·s/m**
- Duty cycle 20% → 95% gives damping **10 → 43 kN·s/m** per damper
- Maximum output power in the test: **2.61 W**, efficiency **33%**
- The computer model matched the tests well.

### Step 6: Build the train model
A **17-degree-of-freedom** high-speed-train model has:
- **one car body** (side-sway, yaw, roll);
- **two bogies** (side-sway, yaw, roll);
- **four wheelsets** (side-sway, yaw).

The train runs on **straight track** with **German low-disturbance** track irregularities (lateral alignment and cross-level, 0.5–20 Hz), at **200–350 km/h**. **Six accelerometers** measure the motion: two on the car body and four on the bogies.

### Step 7: Design the controller (LQG)
- A **Kalman filter** estimates all 34 states from the 6 accelerometers.
- An **LQR** computes the best force for each bogie, u = −K·x̂.
- The cost function puts large weights on **car-body accelerations** and **damper strokes**, and a small weight on force.
- The weights are **fixed for all speeds**.

### Step 8: Put the dampers on the train
- **Four EMDEHs**, two per bogie, replace the lateral passive dampers.
- Installed values: friction **8 kN·s/m**, 110 V battery (the train’s emergency supply voltage).
- **FEMDEH:** fixed duty cycle of 43%, about 52 kN·s/m per bogie, the same as the original passive dampers.
- **SEMDEH:** the duty cycle changes in real time.
  - Each bogie’s damping range is **16 to 90 kN·s/m** (Cmin to Cmax).
  - The wanted force from the LQG is turned into a wanted damping, **c = force ÷ speed**, clipped to that range.
  - That damping is turned into a duty cycle using the converter’s formula.

---

## 6. Architecture

**Control path** (the signal goes left to right):

```
Track irregularity
      ↓
Train (17-DOF) ── 6 accelerometers ──► Kalman filter ──► LQR gain ──► target force u
                                                                          ↓
                                       damping = u ÷ speed, clipped to [16, 90] kN·s/m
                                                                          ↓
                                       duty cycle δ (from the converter formula)
                                                                          ↓
                                       PWM signal → buck–boost converter → Req
                                                                          ↓
Train  ◄────────────────────────── damper force = c · speed ◄── EMDEH
```

**Energy path:**

```
Suspension motion → EMD coil (Kem = 640 N/A, 7.5 Ω) → bridge rectifier → buck–boost converter → 110 V battery
```

| Layer | What it is in the base paper |
|---|---|
| Sensing | 6 accelerometers (car body and bogies) |
| Brain | LQG controller (Kalman filter + LQR), fixed weights |
| Actuator | EMDEH: motor + gearbox + ball screw |
| Power electronics | Bridge rectifier + buck–boost converter, damping set by duty cycle |
| Energy store | 110 V battery, to supplement the train’s power supply |
| Mode | **Semi-active only**: it can resist, never push |

---

## 7. Results

### 7.1 Vibration (car body)
- The **FEMDEH** behaves about the same as the passive damper, as expected for a fixed setting.
- The **SEMDEH** reduces car-body vibration more than both, at most speeds.
- **At 350 km/h** (the worst case): vibration reduction **55% lateral, 34% yaw, 53% roll** (Table II quotes **58%** for lateral acceleration).
- The main body resonance at about **2.6 Hz** is fully suppressed in lateral and roll; a new small peak appears near **0.8 Hz**.
- The lowest vibration is around **300 km/h** (lateral and roll) and **270 km/h** (yaw).

### 7.2 Weak points the paper admits
- **Yaw gets worse below about 220 km/h.** The fixed controller weights do not suit low speeds.
- **Bogie vibration goes up slightly** compared with passive dampers. The control aims at passenger comfort, not the bogie.
- **The damper cannot fully follow the LQG force.**
  - Its damping range (16–90 kN·s/m) is too narrow.
  - Near maximum damping, the circuit enters CCM and the force overshoots, to about 100 kN·s/m in practice.
  - This causes a large **force-tracking error**.

### 7.3 Stroke and damping
- The semi-active damper’s **average damping falls as speed rises**.
- Its **damper stroke is smaller** than the fixed version’s at all speeds, which is good for safety.

### 7.4 Energy

| | Semi-active (SEMDEH) | Fixed (FEMDEH) |
|---|---|---|
| Output power, 2 dampers in the front bogie, 200–350 km/h | **25.89–153.19 W** | **81.145–406.5 W** |
| Efficiency | **9.3%** at 200 km/h → **23.79%** at 320 km/h (23.3% at 350) | about **31%** at all speeds |

- **Trade-off:** fast changes of the duty cycle are good for comfort but bad for harvesting.
- The input power is mostly at low frequency (about twice the body resonance). The circuit switches at **21 kHz**.

### 7.5 Comparison table (paper’s Table II, at 350 km/h)

| | Adaptive EMDEH (earlier work) | FEMDEH | SEMDEH |
|---|---|---|---|
| Train speed | 100–340 km/h | 200–350 km/h | 200–350 km/h |
| Output power, 2 dampers, front bogie | 20.25–294.9 W | 81.145–406.5 W | 25.89–153.19 W |
| Maximum efficiency | 35% | 31% | 23.8% |
| Vibration reduction (lateral) | 27% | −3% | **58%** |

**Reading this table:** the semi-active damper gives by far the best comfort, but harvests the least energy, at the lowest efficiency.

---

## 8. What they solved (their contributions)

1. **First semi-active EMDEH for a high-speed train’s lateral suspension**, with a continuously variable damping range.
2. **A real harvesting circuit**, not an ideal resistor, so the power estimates are realistic.
3. **A full-size prototype**, tested, with a model that matches the tests.
4. **A complete control chain:** LQG → target damping → duty cycle → force.
5. **Proof** that one device can both cut vibration (up to 55–58%) and harvest tens to hundreds of watts.

---

## 9. Limitations

**Stated by the authors:**
1. Backlash in the gearbox, ball screw and coupler causes force ripple.
2. Friction (parasitic damping) and coil resistance waste energy and lower efficiency.
3. Only straight track was studied; curves and other operating cases are still to do.
4. Circuit parts must be chosen carefully to avoid time delays in the damping force.
5. The controller should be tuned by train speed, and the damping range widened.

**Our observations:**
- **Semi-active only:** the damper can never push, so it cannot act *before* a bump.
- **No preview:** the controller reacts only to motion already measured.
- **No energy use case:** the harvested energy just tops up a battery; nothing on the bogie uses it.
- **No fail-safe design** and **no health monitoring** are described.
- **One vehicle**, side-to-side motion only, one load.

---

## 10. How SwarmRide builds on the base paper

| # | Where the base paper lags | SwarmRide upgrade | Our evidence |
|---|---|---|---|
| 1 | Narrow damping range (16–90 kN·s/m), large tracking error | **H-bridge current control:** the coil current is the force; 0–123 kN·s/m per damper | Bench model: measured damping = command within **0.1%** |
| 2 | One fixed controller for all speeds; yaw worse below 220 km/h | **LPV control:** gains scheduled on the measured load | Comfort flat from empty to crowded (Wz **1.493 → 1.528**) |
| 3 | Semi-active only, cannot push | **Four-quadrant drive + C4 push** from the bogie bank | **−80%** worst-seat jolt at a settlement, for 0.1 Wh |
| 4 | Efficiency 9.3–23.8% | Coil 60–92% × rectifier 95% × DC-DC 94% | Bench: rig work → bank **53–73%** |
| 5 | Energy only tops up a battery | **Bogie power bank + energy manager** that runs the bogie’s own sensors | Self-powered all day; works on goods wagons with no power |
| 6 | No look-ahead | **Train Brain preview** (t = d / v) | Robust to ±20 ms timing error |
| 7 | Circuit time delay is an open problem | **10 kHz current loop** | Time constant **0.5 ms** |
| 8 | Backlash and high friction (8:1 gearbox, 8 kN·s/m) | **Direct ball screw, no gearbox**; friction budget ≤ 300 N | Margin study in the bench model |
| 9 | No fail-safe | **Hardware contactor** back to today’s damping | **17,500 N·s/m** after a fault, 20 ms gap |
| 10 | No health monitoring | **Self-powered health sensing** | Hot axle in **10 s**; wheel defects ×5–×204 |
| 11 | One train, lateral, straight track | LHB, Vande Bharat, ICF, BOXN freight, all loads | 85 automatic checks, C firmware, bench test plan |

**An honest note for the review:** the base paper reports **lateral** vibration at 200–350 km/h. SwarmRide reports **vertical** ride at 160 km/h. The percentages measure different things, so we compare **architecture and capability**, not one percentage against another.

---

## 11. Questions an examiner may ask

**Q: Why did you pick this base paper?**
It is the IEEE Transactions paper closest to our idea: an electromagnetic damper on a train suspension that both controls vibration and harvests energy, with a real prototype and an optimal controller.

**Q: What is the main weakness of the base paper?**
The damper is controlled through the duty cycle of a simple converter. That gives a narrow damping range, a tracking error, low efficiency (9–24%), and resist-only operation. The controller also uses one fixed tuning for all speeds.

**Q: Is your result better than their 55%?**
The numbers measure different motions (their lateral at 350 km/h, our vertical at 160 km/h), so they are not directly comparable. What is comparable is the architecture: every limitation they list is addressed in SwarmRide, and our simulation shows each upgrade working.

**Q: What does SwarmRide add that the base paper cannot do at all?**
- Push at a known bad spot (−80% worst-seat jolt)
- A train-wide bump preview
- A self-powered bogie that runs its own safety sensors all day
- A hardware fail-safe

**Q: Why is their efficiency so low?**
Energy is lost in three places: friction (8 kN·s/m), the 7.5 Ω coil, and the converter, which works best at a fixed setting. Fast duty-cycle changes for comfort make harvesting worse.

---

## 12. Glossary

| Term | Meaning |
|---|---|
| HST | High-speed train |
| EMD | Electromagnetic damper |
| EMDEH | Electromagnetic damper cum energy harvester |
| FEMDEH / SEMDEH | Fixed-duty-cycle / semi-active EMDEH |
| EHC | Energy-harvesting circuit |
| DCM / CCM | Discontinuous / continuous current mode of the converter |
| PWM | Pulse-width modulation: the on/off switching signal |
| LQR / LQG | Linear-quadratic regulator / regulator + Kalman filter |
| VR | Vibration reduction ratio |
| DOF | Degree of freedom: one way a body can move |
| RMS | Root-mean-square: the average size of a vibration |
| PSD | Power spectral density: how much vibration there is at each frequency |

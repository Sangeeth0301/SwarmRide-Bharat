# 02 · Mechanical design (design C: ball screw + servo motor)

## 1. Layout

```
   top eye (rubber bush, LHB mount)
        │
   ┌────┴─────┐
   │  servo   │  3-phase PM motor, encoder, winding sensor
   │  motor   │
   └────┬─────┘
        │ zero-backlash coupling
   ┌────┴─────┐  housing (steel tube) ── fixed-side screw support (angular-contact pair)
   │    ║     │
   │    ║     │  ball screw Ø25 mm, 10 mm lead (rotates)
   │  ┌─╨─┐   │
   │  │nut│◄──┼── anti-rotation key in the housing slot (the nut slides, does not turn)
   │  └─┬─┘   │
   │    │     │  inner tube / rod fixed to the nut
   └────┼─────┘  rod seal + wiper, polyurethane bump stops at ±40 mm
        │
   bottom eye (rubber bush, LHB mount)
```

- **Stroke → rotation:** the coach pushes the rod, the nut slides and the screw turns the motor. 1 mm of stroke is 36° of rotation, so 0.1 m/s is 600 rpm.
- **Same envelope and mounts as today's damper.** The prototype uses the eyes and bushes of a spare LHB vertical secondary damper, so on the bogie it can replace the oil damper bolt-for-bolt.

## 2. Design numbers

| Item | Value | Note |
|---|---|---|
| Ball screw | Ø25 mm, **10 mm lead**, ground C5 (rolled C7 acceptable for the first build), preloaded nut | Lead sets the gearing: Kt = Ke · lead / 2π = 0.279 N m/A |
| Axial force | 8 kN peak, 2.2 kN continuous | Ø25 × 10 nuts are typically rated 10–20 kN (basic dynamic load); choose ≥ 12 kN for a long life at 2.2 kN |
| Screw speed | 1,800 rpm at 0.30 m/s | Well below the critical speed of a 300 mm Ø25 screw |
| Efficiency | ≈ 0.9 (forward and back-driving) | A ball screw back-drives easily, which a damper needs. A trapezoidal screw would not work |
| Stroke | ±40 mm to the bump stops; the simulation uses ±16 mm | |
| Friction | **≤ 300 N** (requirement R11) | Seal drag + nut preload. Measured in T2 |
| Inertia | See section 3 | Measured in T2 as inertance (kg) |

## 3. Inertia: a surprise from the margin study

Because the screw spins the motor fast, its rotating inertia J appears at the rod as a mass **b = J · (2π/lead)²**. That is 394,784 kg per kg m², so even a small rotor gives tens to hundreds of kilograms.

The simulation assumed J = 1.5 × 10⁻⁴ kg m² (b = 59 kg), which most 14 N m motors cannot meet. So the vehicle model was rerun with more inertia (`check_bench.m`, section D; crowded LHB, rough track, 160 km/h, controller C3):

| Rotor + screw inertia J | Inertance at the rod b | Ride index Wz, centre (today 1.844) | Worst seat Wz | Into the bank per bogie |
|---|---|---|---|---|
| 1.5 × 10⁻⁴ kg m² (simulation) | 59 kg | 1.528 | 1.854 | 33.1 W |
| 3 × 10⁻⁴ | 118 kg | 1.524 | 1.850 | 33.0 W |
| 6 × 10⁻⁴ | 237 kg | 1.517 | 1.841 | 32.9 W |
| 12 × 10⁻⁴ | 474 kg | 1.506 | 1.826 | 32.6 W |
| 24 × 10⁻⁴ | 947 kg | **1.497** | 1.803 | 32.0 W |
| 48 × 10⁻⁴ | 1,895 kg | 1.552 | 1.794 | 30.2 W |

**Result: inertia is a soft limit, not a hard one.**
- Up to 16× the assumed value (2.4 × 10⁻³ kg m²), the ride at the centre of the coach gets slightly **better**. The rotor acts as an "inerter" between body and bogie, which filters some of the bogie's high-frequency motion.
- Only at 32× does the centre ride turn worse (+1.6%), and even then it stays within 2% of the design.
- The worst seat improves across the whole range.
- The harvest falls slowly (−9% at 32×).
- The controller stayed stable in every case, although it does not know about the inertance.

**So the motor does not need to be an expensive low-inertia type.** Any 48 V-class servo with the right Kt, R and peak torque fits. Aim for **J ≤ 2.4 × 10⁻³ kg m²** (rotor + screw), which nearly all candidate motors meet.

## 4. Friction: the budget that matters

| Screw + seal friction | Wz | Into the bank per bogie |
|---|---|---|
| 150 N (simulation) | 1.528 | 33.1 W |
| 300 N | 1.526 | 30.7 W |
| 600 N | 1.530 | 26.4 W |

**Friction barely changes the ride, but it costs harvest:** 600 N loses a fifth of the energy. Hence requirement R11 (≤ 300 N): low-drag seals, nut preload no higher than needed, and good alignment.

## 5. Materials and sealing

| Part | Material / choice |
|---|---|
| Housing, rod | Steel tube (e.g. ST52), rod hard-chromed, as on today's dampers |
| Screw and nut | Bearing steel, induction-hardened; grease-lubricated, with wipers |
| Seals | Rod seal + wiper (PU), IP67 target for the bogie version; IP54 is enough on the bench |
| Bump stops | Polyurethane, progressive |
| Motor end | Aluminium end cap with the motor flange, motor cable through a gland |

## 6. What the bench must confirm (mechanical)

- **T2:** friction and inertance, measured at zero current, against the budgets above.
- **T7–T9:** after the full test campaign the screw shows no wear and the nut no play (hand check, plus friction re-measured).
- **Endurance** (after Gate B, not in this campaign): 10⁶ strokes at the rough-track spectrum, as a first life estimate.

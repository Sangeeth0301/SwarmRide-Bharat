# Verification: is the SwarmRide simulation correct?

This page records **what has been proven, how, and what has not**. Every check can be re-run with one command:

```matlab
run('scripts/run_all_checks.m')     % about 10 minutes; writes results/verification_report.txt
```

**Latest result: 64 of 64 checks pass.**

Latest report: [`results/verification_report.txt`](results/verification_report.txt).

---

## 1. What is verified, and how

| Area | Test | How it is checked | Result |
|---|---|---|---|
| **Ride index** | `test_sperling` | Sperling Wz of pure sines (1, 4, 8, 12 Hz) against the closed-form formula | Exact (0.000%) |
| **Coach physics** | `test_stage1_physics` | Body bounce frequency of all 5 vehicles against the hand formula f = √(k_eff/m) / 2π | Within 0.5% (the hand formula ignores bogie mass) |
| **Simulink wiring** | `test_stage1_physics` | Simulink against an independent state-space model on the same rail | 0.003% of peak |
| **Damper physics** | `test_stage1_physics` | Today's passive damper never puts energy into the coach | Always ≥ 0 |
| **Numerical accuracy** | `test_convergence` | Every result at the normal time step against half the step (LHB, BOXN friction, Stage 2 design C) | Differences below 0.002% |
| **Smart damper = today's damper** | `test_stage2` | Electromagnetic copy of today's damping against Stage 1 | 1.1% of peak acceleration (2 ms current loop), Wz within 0.08% |
| **Damping law** | `test_stage2` | Fitted force/velocity against the commanded damping | 0.09% |
| **Generator** | `test_stage2` | Coil efficiency against the formula 1 − c/c_max; harvest setting against 0.5 | Within 0.002 points |
| **Converters** | `test_stage2` | Rectifier + DC-DC chain against 0.95 × 0.94 | Within 0.0002 points |
| **Energy conservation** | `test_stage2` | Generated energy = coil + converter + battery losses + loads + dump + stored energy | Within 0.0003% |
| **Fail-safe** | `test_stage2` | Damping after a fault against today's damping; harvesting after the fault | 0.00%, 0 W |
| **Self-sufficiency** | `test_stage2` | The smart damper never draws power from the bank in normal running | Only −0.1 W blips from the current-loop lag |
| **Rail input** | `test_track` | Power of the generated rail in each wavelength band against the track spectrum | Within 3.4% in every band (Section 2) |
| **Controller stability** | `test_stage3` | Closed-loop spectral radius of every LPV load point, all 4 vehicles | All below 1 (max 0.9999, empty BOXN: one slow non-oscillating pole, see `Stage3.md` §11) |
| **Same rail across stages** | `test_stage3` | The Stage 3 train starts where the Stage 1 train starts | 150 m = 150 m |
| **Controller passivity** | `test_stage3` | The damper never needs bank power; command always within 0 … c_cap | Only −0.2 W blips from the current-loop lag |
| **Controller benefit** | `test_stage3` | C2 better than today; C3 at least as good as C2 (LHB crowded) | Wz 1.559 and 1.528 against today 1.844 |
| **Controller robustness** | `test_stage3` | Warning ±20 ms; load estimate ±10% at half load; still better than today | All pass; Wz changes under 0.01 |
| **Fail-safe under control** | `test_stage3` | Harvesting stops after a fault | 0 W |
| **Documents** | `tools/check_docs.py` | Every image and link in every Markdown file exists | All present |
| **README diagrams** | Rendered with Mermaid 11 | Both diagrams render | OK |
| **Python tooling** | Fresh run in a clean copy | Preview simulation, both PDF builders, README visuals | All run; preview results identical to the committed ones |

---

## 2. Issue found by the audit (resolved)

**The generated rail did not carry the right power at the longest wavelengths.**

| Version | How the sines were placed | 30–100 m band power vs spectrum | Why |
|---|---|---|---|
| Original | 400 sines, evenly spaced, spectrum taken at the left edge of each slice | **+19%** | The spectrum is steepest at long wavelengths, so left-edge values over-weight them |
| First fix | 400 log-spaced sines at slice centres | **−18%** (this rail) | Correct on average, but long-wave sines closer than a 1.6 km record can separate interfere, so the actual rail drifts randomly |
| **Final** | **1,981 sines on the harmonics of a fixed 2 km period** | **+3.4%** (other bands within 0.6%) | Harmonics of one period are exactly independent, so each band gets the spectrum's power; the 3.4% is half a sine at the band edge |

The test limit is now 5% per band. **All results (Stage 1b, Stage 2, figures and documents) were regenerated on the final rail.** Comparisons were always fair (today's train and SwarmRide share the rail); the absolute figures changed by a few percent to about 20%, as listed in the reports.

## 3. Corrected during the audit

| Issue | Fix |
|---|---|
| Stage 1 report showed the generic coach's pitch frequency from before Stage 1b (1.03 → 0.98 Hz) | Re-run: 0.94 → 0.90 Hz (pitch inertia now m·L²/12 for every vehicle). Bounce frequency and all checks unchanged |
| PDF builders printed "wrote" before Edge had finished writing the PDF | Shared helper `pdf/edge_pdf.py` waits until the PDF is complete |
| Track test counted the 100 m wave outside its band (floating-point edge) | Half-bin shift in the band selection |
| Rail power wrong at 30–100 m wavelengths | Sines on the harmonics of a 2 km period; all results regenerated (Section 2) |
| Stage 3 controller's stroke weight reused the name of the train start position (`P.s0`), so early Stage 3 runs drove a different stretch of rail | Renamed to `P.s_ref`; Stage 3 rerun on the same rail; guard test added |
| Load-estimate check at full load was uninformative (over-estimates clip to the top grid point) | Check moved to half load, where errors in either direction move the gains |

---

## 4. What is NOT verified (and cannot be by simulation alone)

| Limit | Why it matters | How to close it |
|---|---|---|
| Many parameters are engineering estimates | Absolute numbers depend on them | RDSO and manufacturer data (springs, dampers, masses) |
| Vertical model only | No lateral, roll or yaw; no wheel-rail contact; rigid body | Simscape Multibody or a vehicle-dynamics tool in a later stage |
| Average-model power electronics | Real converters lose more at light load | Switching-level model or bench measurement |
| Casnub friction is smoothed | BOXN figures are approximate | Better wedge model and measured wagon data |
| Damper designs are first estimates | Copper mass, torque and inertia are rough | Electromagnetic design (FEA) and a bench prototype |
| No field data | The model has not been compared with a real train | Instrumented run with accelerometers on a coach |

**In short:** the model is internally consistent, numerically converged and matches hand calculations everywhere it can be checked. Its absolute numbers are only as good as the assumed parameters (Section 4).

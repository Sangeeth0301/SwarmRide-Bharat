# Verification: is the SwarmRide simulation correct?

This page records **what has been proven, how, and what has not**. Every check can be re-run with one command:

```matlab
run('scripts/run_all_checks.m')     % about 5-10 minutes; writes results/verification_report.txt
```

Latest report: [`results/verification_report.txt`](results/verification_report.txt).

---

## 1. What is verified, and how

| Area | Test | How it is checked | Result |
|---|---|---|---|
| **Ride index** | `test_sperling` | Sperling Wz of pure sines (1, 4, 8, 12 Hz) against the closed-form formula | Exact (0.000%) |
| **Coach physics** | `test_stage1_physics` | Body bounce frequency of all 5 vehicles against the hand formula f = √(k_eff/m) / 2π | Within 0.5% (the hand formula ignores bogie mass) |
| **Simulink wiring** | `test_stage1_physics` | Simulink against an independent state-space model on the same rail | 0.004% of peak |
| **Damper physics** | `test_stage1_physics` | Today's passive damper never puts energy into the coach | Always ≥ 0 |
| **Numerical accuracy** | `test_convergence` | Every result at the normal time step against half the step (LHB, BOXN friction, Stage 2 design C) | Differences below 0.002% |
| **Smart damper = today's damper** | `test_stage2` | Electromagnetic copy of today's damping against Stage 1 | 1.2% of peak acceleration (2 ms current loop), Wz within 0.08% |
| **Damping law** | `test_stage2` | Fitted force/velocity against the commanded damping | 0.09% |
| **Generator** | `test_stage2` | Coil efficiency against the formula 1 − c/c_max; harvest setting against 0.5 | Within 0.002 points |
| **Converters** | `test_stage2` | Rectifier + DC-DC chain against 0.95 × 0.94 | Within 0.0002 points |
| **Energy conservation** | `test_stage2` | Generated energy = coil + converter + battery losses + loads + dump + stored energy | Within 0.0003% |
| **Fail-safe** | `test_stage2` | Damping after a fault against today's damping; harvesting after the fault | 0.00%, 0 W |
| **Self-sufficiency** | `test_stage2` | The smart damper never draws power from the bank in normal running | Only −0.1 W blips from the current-loop lag |
| **Rail input** | `test_track` | Power of the generated rail in each wavelength band against the track spectrum | 3 of 4 bands within 5%; **see Section 2** |
| **Documents** | `tools/check_docs.py` | Every image and link in every Markdown file exists | 70 of 70 present |
| **README diagrams** | Rendered with Mermaid 11 | Both diagrams render | OK |
| **Python tooling** | Fresh run in a clean copy | Preview simulation, both PDF builders, README visuals | All run; preview results identical to the committed ones |

---

## 2. Known issue found by the audit (open)

**The generated rail has about 19% too much power at the longest wavelengths (30–100 m).**

- **Cause.** `functions/sr_track.m` builds the rail from 400 sines spaced evenly from 1 m to 100 m wavelength. Each sine takes the spectrum value at the *left edge* of its slice. The spectrum is steep at long wavelengths, so those slices are over-weighted: +19% power in the 30–100 m band, +14% over 1–100 m in total (RMS about +7%).
- **Effect.**
  - The rail is a little **rougher** than the standard, in the band that excites the 1 Hz body bounce at 160 km/h.
  - Comparisons stay fair, because today's train and SwarmRide always ride the same rail.
  - **Absolute** numbers (heat today, watts into the bank, Wz) are likely somewhat high; how much is measured once the fix is in.
- **Fix (tested, not yet applied).**
  - Use log-spaced sines at the centre of each slice. That matches the spectrum within 1.4% in every band (total 1.000).
  - It changes the rail, so every published number would be regenerated (Stage 1b and Stage 2) and the documents updated.
  - Waiting for approval.

---

## 3. Corrected during the audit

| Issue | Fix |
|---|---|
| Stage 1 report showed the generic coach's pitch frequency from before Stage 1b (1.03 → 0.98 Hz) | Re-run: 0.94 → 0.90 Hz (pitch inertia now m·L²/12 for every vehicle). Bounce frequency and all checks unchanged |
| PDF builders printed "wrote" before Edge had finished writing the PDF | Shared helper `pdf/edge_pdf.py` waits until the PDF is complete |
| Track test counted the 100 m wave outside its band (floating-point edge) | Half-bin shift in the band selection |

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

**In short:** the model is internally consistent, numerically converged and matches hand calculations everywhere it can be checked. Its absolute numbers are only as good as the assumed parameters, and the rail-input issue in Section 2 should be fixed before figures are shown outside the team.

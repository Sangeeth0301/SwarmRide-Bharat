"""Page 7 of the investor pitch: what the MATLAB/Simulink simulation has proven (Stages 1-4)."""

NAVY, OR, ORD, TEAL, TEALD = "#13233A", "#E07A1F", "#A8520F", "#2A9D8F", "#1F6F66"
RES = "../SwarmRide_Sim/results"

EXTRA_CSS = f"""
.p7kpis {{ position:absolute; left:40px; top:104px; width:1043px; display:flex; gap:12px; }}
.p7kpi {{ flex:1; background:#fff; border-radius:12px; padding:12px 14px; border:1px solid #E3E0D6; }}
.p7kpi .v {{ font-family:Rubik, Arial; font-weight:700; font-size:28px; color:{NAVY}; line-height:1.05; }}
.p7kpi .v.o {{ color:{OR}; }} .p7kpi .v.t {{ color:{TEAL}; }}
.p7kpi .l {{ font-size:11.5px; color:#3D4A5C; margin-top:4px; }}
.p7fig {{ position:absolute; background:#fff; border-radius:12px; border:1px solid #E3E0D6; padding:8px; }}
.p7fig img {{ width:100%; display:block; }}
.p7fig .cap {{ font-size:11px; color:#3D4A5C; margin:6px 4px 0; }}
.p7box {{ position:absolute; left:571px; top:507px; width:512px; height:110px; display:flex; gap:10px; }}
.p7box div {{ flex:1; background:#fff; border-radius:12px; border:1px solid #E3E0D6; padding:9px 11px; font-size:11px; line-height:1.35; color:#3D4A5C; }}
.p7box b {{ display:block; font-family:Rubik, Arial; font-size:15px; color:{TEALD}; margin-bottom:4px; white-space:nowrap; }}
.p7note {{ position:absolute; left:40px; top:676px; width:1043px; font-size:12px; color:#2E3A4B; }}
.p7note b {{ color:{NAVY}; }}
"""


def page7():
    kpis = [("−17%", "ride index, crowded LHB coach at 160 km/h (Vande Bharat −16%, loaded wagon −23%)", ""),
            ("−41%", "body vibration on the crowded LHB coach; suspension travel down by a third", "t"),
            ("33–38 W", "into each coach bogie's bank on rough track, against 8 W of electronics", "o"),
            ("−80%", "worst-seat jolt at a track settlement when the damper pushes, for 0.1 Wh", "t")]
    k = "".join(f'<div class="p7kpi"><div class="v {c}">{v}</div><div class="l">{l}</div></div>' for v, l, c in kpis)
    return f"""
<div class="page light">
  <div class="eyebrow dark">Proven in simulation · MATLAB / Simulink · four stages</div>
  <h2>Same coach, same rail, only the damper changes. SwarmRide wins.</h2>
  <div class="p7kpis">{k}</div>
  <div class="p7fig" style="left:40px;top:210px;width:512px">
    <img src="{RES}/stage3_ride_vs_load.png">
    <div class="cap"><b>Better at every load.</b> Today's ride worsens as passengers board; SwarmRide stays nearly flat.</div>
  </div>
  <div class="p7fig" style="left:571px;top:210px;width:512px">
    <img src="{RES}/stage4_active_push.png">
    <div class="cap"><b>The Train Brain warning pays off.</b> At a known bad spot the damper briefly pushes with banked energy.</div>
  </div>
  <div class="p7box">
    <div><b>All day, all night</b>More made than used on LHB, Vande Bharat and freight, with a 1 W sleep when parked</div>
    <div><b>Hot axle in 10 s</b>On-bogie sensor; trackside checks miss 82% of faults until after 180 °C</div>
    <div><b>Wheel defect ×5–×200</b>Seen in the damper's own coil signal, located to the wheelset</div>
  </div>
  <div class="p7note"><b>Verified:</b> hand calculations, an independent model, energy conservation, step-size convergence,
    fail-safe and controller stability in an automatic test suite. <b>Honest limits:</b> vehicle parameters are estimates
    pending RDSO data; vertical model only; the bogie electronics must sleep when parked to stay self-powered overnight.</div>
  <div class="foot">Simulation results; to be confirmed on a bench prototype and in an instrumented field run<span>7 / 7</span></div>
</div>"""

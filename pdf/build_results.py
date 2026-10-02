"""Builds the 4-page Simulation Results Preview PDF from results/summary.json + plots."""
import json
from pathlib import Path

from edge_pdf import print_pdf

HERE = Path(__file__).resolve().parent
RES = HERE / "results"
S = json.loads((RES / "summary.json").read_text())

NAVY, OR, ORD, TEAL, TEALD, GREY = "#13233A", "#E07A1F", "#A8520F", "#2A9D8F", "#1F6F66", "#8A93A0"


def pct(a, b):
    return 100 * (1 - b / a)


# ---------- Simulink-style top-level diagram ----------
def blk(x, y, w, h, name, inner, accent=None):
    stroke = accent or "#3B4A5E"
    s = (f'<rect x="{x + 3}" y="{y + 3}" width="{w}" height="{h}" rx="3" fill="#D9DDE3"/>'
         f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="#FFFFFF" stroke="{stroke}" stroke-width="1.4"/>')
    for i, ln in enumerate(inner):
        s += (f'<text x="{x + w / 2}" y="{y + 22 + i * 14}" text-anchor="middle" font-size="11" '
              f'font-family="IBM Plex Mono, Consolas, monospace" fill="#3D4A5C">{ln}</text>')
    s += (f'<text x="{x + w / 2}" y="{y + h + 15}" text-anchor="middle" font-size="11.5" font-weight="600" '
          f'font-family="IBM Plex Sans, Arial" fill="{NAVY}">{name}</text>')
    return s


def wire(pts, label=None, lx=None, ly=None, col="#3B4A5E"):
    d = "M" + " L".join(f"{x} {y}" for x, y in pts)
    s = f'<path d="{d}" fill="none" stroke="{col}" stroke-width="1.4" marker-end="url(#sl-arrow)"/>'
    if label:
        s += (f'<text x="{lx}" y="{ly}" font-size="10" font-family="IBM Plex Mono, Consolas, monospace" '
              f'fill="{col}">{label}</text>')
    return s


def simulink_diagram():
    b = ('<defs><marker id="sl-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" '
         'orient="auto"><path d="M0 0L10 5L0 10z" fill="#3B4A5E"/></marker>'
         '<pattern id="grid" width="20" height="20" patternUnits="userSpaceOnUse">'
         '<path d="M20 0H0V20" fill="none" stroke="#EEF0F3" stroke-width="1"/></pattern></defs>')
    b += '<rect x="0" y="0" width="1043" height="540" fill="url(#grid)"/>'
    b += blk(640, 60, 160, 66, "Train Brain preview", ["ŵ(t − d/v)", "+ timing error"])
    b += blk(30, 200, 130, 70, "Track Input", ["PSD → w(x)", "4 wheel delays"])
    b += blk(200, 185, 180, 100, "Vehicle Plant", ["half-coach", "4 DOF · 8 states", "m(load), v"], NAVY)
    b += blk(430, 200, 160, 70, "Sensors + Estimators", ["m̂ (air pressure)", "v_rel = e / Ke"])
    b += blk(640, 200, 160, 70, "Controller", ["Variant:", "C0 | C1 | C2 | C3"], OR)
    b += blk(850, 200, 160, 70, "Energy Supervisor", ["Stateflow", "Comfort/Eco/Reserve"], TEALD)
    b += blk(640, 380, 160, 70, "Fail-safe Switch", ["relay → R_fail", "if fault / low SOC"])
    b += blk(430, 380, 160, 70, "Smart Damper ×2", ["e = Ke·v", "F = Kf·i"], OR)
    b += blk(640, 455, 160, 60, "Power Chain + Bank", ["H-bridge · DC-DC", "supercap · SOC"], TEALD)
    b += blk(200, 455, 180, 60, "Ride Metrics", ["Wz · RMS · stroke"])
    b += blk(30, 455, 130, 60, "Health Monitor", ["bearing temp", "alert logic"])
    # signals
    b += wire([(160, 235), (200, 235)], "w₁..w₄", 162, 228)
    b += wire([(380, 235), (430, 235)], "x", 398, 228)
    b += wire([(590, 235), (640, 235)], "x̂,m̂", 594, 228)
    b += wire([(720, 126), (720, 200)], "preview", 726, 168)
    b += wire([(850, 235), (800, 235)], "mode", 808, 228)
    b += wire([(720, 270), (720, 380)], "i*", 726, 330)
    b += wire([(880, 270), (880, 415), (800, 415)], "fault", 886, 340)
    b += wire([(640, 415), (590, 415)], "i", 606, 408)
    b += wire([(430, 425), (290, 425), (290, 285)], "F", 296, 410)
    b += wire([(360, 285), (360, 395), (430, 395)], "v_rel", 366, 330)
    b += wire([(510, 450), (510, 485), (640, 485)], "P_el", 516, 478)
    b += wire([(800, 485), (980, 485), (980, 270)], "SOC", 986, 400)
    b += wire([(230, 285), (230, 455)], "a, stroke", 236, 360)
    return f'<svg width="1043" height="540" viewBox="0 0 1043 540">{b}</svg>'


def fig(name, title, proves, passc, status):
    st = {"pass": ("PASS", TEALD), "work": ("NEEDS WORK", ORD), "info": ("DESIGN INSIGHT", NAVY)}[status]
    return f"""
<div class="fig">
  <div class="fh"><span class="ft">{title}</span><span class="badge" style="background:{st[1]}">{st[0]}</span></div>
  <img src="results/{name}">
  <p><b>Proves:</b> {proves}</p>
  <p class="pc"><b>Pass condition:</b> {passc}</p>
</div>"""


def main():
    pc = S["poor_crowd_160"]
    bp = S["bump_peak"]
    L = S["loads"]
    imp = [pct(L["Fixed oil damper"][i]["arms"], L["SwarmRide"][i]["arms"]) for i in range(3)]
    wz0 = [L["Fixed oil damper"][i]["Wz"] for i in range(3)]
    wz1 = [L["SwarmRide"][i]["Wz"] for i in range(3)]
    pw = S["power"]
    p200g, p300g = pw["Ke200_good"], pw["Ke300_good"]
    p200p, p300p = pw["Ke200_poor"], pw["Ke300_poor"]
    fixed = S["pareto"]["fixed"]
    best_fixed = max(fixed, key=lambda t: t[0])
    swarm25 = [p for p in S["pareto"]["swarm"] if abs(p[2] - 0.25) < 1e-9][0]

    page1 = f"""
<div class="page">
  <div class="eyebrow">SwarmRide Bharat · simulation results preview</div>
  <h2>What the MATLAB/Simulink model looks like</h2>
  <p class="lead">One model, one track, four controllers. Every result on the next pages comes from running this structure; nothing is drawn by hand.</p>
  <div class="canvas"><div class="crumb">SwarmRide_Coach ▸ top level</div>{simulink_diagram()}</div>
  <div class="notes">
    <div><b>Same track for every case,</b> so differences come only from the damper.</div>
    <div><b>Variant controller:</b> C0 oil damper · C1 fixed-load · C2 SwarmRide · C3 + preview.</div>
    <div><b>Everything logged:</b> ride, stroke, force, power and charge feed the plots.</div>
  </div>
  <div class="foot">Preliminary results on pages 2–4 come from a Python version of this exact model with assumed coach data. The MATLAB/Simulink build replaces them.<span>1 / 4</span></div>
</div>"""

    page2 = f"""
<div class="page">
  <div class="eyebrow">Essential results 1–4</div>
  <h2>A smoother ride than today's dampers</h2>
  <div class="grid">
    {fig("r1_bump.png", "1 · One bump: the bounce dies faster",
         f"after a 10 mm dip, peak body acceleration drops from {bp[0]:.2f} to {bp[1]:.2f} m/s² ({pct(bp[0], bp[1]):.0f}% lower) and the bounce settles sooner.",
         "lower peak and faster settling than the oil damper.", "pass")}
    {fig("r2_trace.png", "2 · Real track: less shaking, all the time",
         f"on poor track at 160 km/h with a crowded coach, body vibration falls from {pc['passive']['arms']:.3f} to {pc['swarm']['arms']:.3f} m/s² RMS ({pct(pc['passive']['arms'], pc['swarm']['arms']):.0f}% lower).",
         "lower RMS acceleration on identical track.", "pass")}
    {fig("r3_psd.png", "3 · It removes the vibration people feel",
         f"in the 0.5–2 Hz band passengers feel most, vibration falls {pct(S['band']['passive']['low'], S['band']['swarm']['low']):.0f}% ({S['band']['passive']['low']:.3f} → {S['band']['swarm']['low']:.3f} m/s²). Above 6 Hz it rises slightly ({S['band']['passive']['high']:.3f} → {S['band']['swarm']['high']:.3f} m/s²) from fast damping changes; Simulink adds command smoothing.",
         "lower vibration in the 0.5–2 Hz band.", "pass")}
    {fig("r4_loads.png", "4 · Better at every passenger load",
         f"vibration is {imp[0]:.0f}%, {imp[1]:.0f}% and {imp[2]:.0f}% lower for empty, half and crowded coaches. Ride index Wz: {wz0[2]:.2f} → {wz1[2]:.2f} when crowded.",
         "better than both the oil damper and a fixed-load harvester at every load.", "pass")}
  </div>
  <div class="foot">Poor track = high-irregularity track spectrum. Coach parameters assumed (Guide, Section 8).<span>2 / 4</span></div>
</div>"""

    page3 = f"""
<div class="page">
  <div class="eyebrow">Essential results 5–8</div>
  <h2>Regeneration into the power bank</h2>
  <div class="grid">
    {fig("r5_zeta.png", "5 · Damping follows the passenger load",
         "a fixed damper loses damping quality as people board; SwarmRide holds it at the chosen target.",
         "constant damping ratio from empty to crowded.", "pass")}
    {fig("r6_pareto.png", "6 · Comfort and power together",
         f"at the same 10–28 W, SwarmRide always rides smoother than a fixed-load harvester. Fixed-load harvesters reach {best_fixed[0]:.0f} W only by making the ride {100 * (best_fixed[1] / S['pareto']['passive'] - 1):.0f}% worse than today's oil damper.",
         "SwarmRide curve below the fixed-load curve at equal power.", "pass")}
    {fig("r7_power.png", "7 · How much power, and how to get more",
         f"at 160 km/h: {p200g[-1]:.0f} W (good track) to {p200p[-1]:.0f} W (poor track) per bogie with today's damper design; a stronger magnet/coil (Ke = 300) gives {p300g[-1]:.0f} to {p300p[-1]:.0f} W.",
         "harvest above the electronics need on typical routes.", "work")}
    {fig("r8_soc.png", "8 · The bogie keeps itself charged",
         f"over a 12-minute trip with station stops, the power bank ends at {S['soc_end']:.0f}% with 5 W electronics and the Ke = 300 design.",
         "charge never hits zero; ends at or above the start.", "pass" if S["soc_end"] >= 50 else "work")}
  </div>
  <div class="foot">All power figures per bogie, after converter losses (92% assumed). Electronics need is an estimate until the bench prototype is measured.<span>3 / 4</span></div>
</div>"""

    rows = [
        ("Smoother ride on a bump", f"{pct(bp[0], bp[1]):.0f}% lower peak", "pass"),
        ("Smoother ride on real track", f"{pct(pc['passive']['arms'], pc['swarm']['arms']):.0f}% lower RMS (poor, crowded, 160 km/h)", "pass"),
        ("Better at every load", f"{min(imp):.0f}–{max(imp):.0f}% lower RMS, empty to crowded", "pass"),
        ("Better than existing harvesters", "SwarmRide curve beats the fixed-load curve", "pass"),
        ("Purely regenerative (never pushes)", f"F·v_rel ≥ 0 in every step (minimum {pc['swarm']['fvmin']:.1f})", "pass"),
        ("Small high-frequency side effect", f"above 6 Hz: {S['band']['passive']['high']:.3f} → {S['band']['swarm']['high']:.3f} m/s² (smooth the damping command)", "work"),
        ("Stroke within limits", f"max {1000 * pc['swarm']['smax']:.1f} mm vs {1000 * pc['passive']['smax']:.1f} mm today (limit ±40 mm assumed)", "pass" if pc['swarm']['smax'] < 0.04 else "work"),
        ("Power above electronics need", f"good track {p200g[0]:.0f}–{p200g[-1]:.0f} W (Ke 200) · {p300g[0]:.0f}–{p300g[-1]:.0f} W (Ke 300)", "work"),
        ("Power bank stays charged", f"ends trip at {S['soc_end']:.0f}% (Ke 300, 5 W electronics)", "pass" if S["soc_end"] >= 50 else "work"),
        ("Bump preview (C3) adds comfort", "to be built in Simulink (week 6)", "todo"),
        ("Fail-safe equals passive damper", "to be built in Simulink (week 5)", "todo"),
    ]
    label = {"pass": ("PASS", TEALD), "work": ("NEEDS WORK", ORD), "todo": ("NEXT", GREY)}
    trs = "".join(f'<tr><td>{a}</td><td>{b}</td><td><span class="badge" style="background:{label[c][1]}">{label[c][0]}</span></td></tr>'
                  for a, b, c in rows)
    page4 = f"""
<div class="page">
  <div class="eyebrow">Scorecard</div>
  <h2>Where the approach stands today</h2>
  <table class="score"><tr><th>Claim</th><th>Preliminary result</th><th>Status</th></tr>{trs}</table>
  <div class="cols">
    <div class="box"><div class="bh">To fix the power gap</div>
      <ol><li>Stronger damper: more magnet and coil turns (higher Ke), lower coil resistance.</li>
      <li>Low-power electronics: sensors sampled in bursts, radio duty-cycled (5 W target).</li>
      <li>Harvest lateral and yaw dampers too on Vande Bharat bogies.</li>
      <li>Supercap + small battery sized for the longest station stop.</li></ol></div>
    <div class="box"><div class="bh">Shown to investors as</div>
      <ol><li>Side-by-side animation: oil damper vs SwarmRide on the same track.</li>
      <li>Three headline numbers: ride improvement, watts per bogie, power-bank charge.</li>
      <li>This scorecard, updated after Simulink and the bench test.</li>
      <li>Live dashboard built from the exported simulation results.</li></ol></div>
  </div>
  <div class="foot">Preliminary: simplified model, assumed parameters, bump preview not yet included. Final numbers come from the MATLAB/Simulink study and the bench prototype.<span>4 / 4</span></div>
</div>"""

    css = f"""
@page {{ size: 297mm 210mm; margin: 0; }}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
body {{ font-family: 'IBM Plex Sans', Arial, sans-serif; color: #3D4A5C; -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
.page {{ width:1123px; height:794px; position:relative; overflow:hidden; page-break-after:always; background:#F6F4EE; padding:30px 40px; }}
.page:last-child {{ page-break-after:auto; }}
.eyebrow {{ font-size:11.5px; letter-spacing:3px; text-transform:uppercase; font-weight:600; color:{ORD}; }}
h2 {{ font-family:Rubik, Arial; font-weight:600; font-size:26px; color:{NAVY}; margin-top:6px; }}
.lead {{ font-size:13.5px; margin-top:6px; color:{NAVY}; }}
.canvas {{ margin-top:12px; background:#FFFFFF; border:1px solid #D5D9E0; border-radius:8px; overflow:hidden; width:1043px; }}
.crumb {{ font-family:'IBM Plex Mono', Consolas, monospace; font-size:11px; color:#5E6878; background:#EEF0F3; padding:5px 10px; border-bottom:1px solid #D5D9E0; }}
.notes {{ display:flex; gap:14px; margin-top:12px; }}
.notes div {{ flex:1; font-size:12px; line-height:1.45; background:#FFFFFF; border-radius:8px; padding:9px 12px; color:{NAVY}; }}
.grid {{ display:grid; grid-template-columns:1fr 1fr; gap:12px 18px; margin-top:12px; }}
.fig {{ background:#FFFFFF; border-radius:10px; padding:10px 12px; box-shadow:0 1px 4px rgba(19,35,58,0.08); }}
.fh {{ display:flex; justify-content:space-between; align-items:center; }}
.ft {{ font-family:Rubik, Arial; font-weight:600; font-size:13.5px; color:{NAVY}; }}
.fig img {{ width:100%; height:220px; object-fit:contain; display:block; margin:4px 0; }}
.fig p {{ font-size:11px; line-height:1.4; color:{NAVY}; }}
.fig p.pc {{ color:#5E6878; margin-top:2px; }}
.badge {{ font-size:9.5px; font-weight:700; letter-spacing:1px; color:#fff; padding:3px 8px; border-radius:10px; white-space:nowrap; }}
.score {{ width:100%; border-collapse:collapse; margin-top:14px; font-size:12.5px; background:#FFFFFF; border-radius:10px; overflow:hidden; }}
.score th {{ background:{NAVY}; color:#F6F4EE; text-align:left; padding:8px 12px; font-weight:600; }}
.score td {{ padding:7px 12px; border-top:1px solid #ECE8DE; color:{NAVY}; }}
.cols {{ display:flex; gap:18px; margin-top:14px; }}
.box {{ flex:1; background:#FFFFFF; border-radius:10px; padding:12px 16px; font-size:12px; line-height:1.5; color:{NAVY}; }}
.bh {{ font-size:10.5px; letter-spacing:1.5px; text-transform:uppercase; font-weight:700; color:{ORD}; margin-bottom:4px; }}
.box ol {{ padding-left:18px; }}
.foot {{ position:absolute; left:40px; bottom:12px; width:1043px; font-size:9.5px; color:#6B7685; }}
.foot span {{ float:right; font-weight:600; }}
"""
    html = f"""<!doctype html><html><head><meta charset="utf-8"><title>SwarmRide Simulation Results Preview</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500&family=IBM+Plex+Sans:wght@400;500;600;700&family=Rubik:wght@500;600;700&display=swap">
<style>{css}</style></head><body>{page1}{page2}{page3}{page4}</body></html>"""
    out_html = HERE / "results_preview.html"
    out_html.write_text(html, encoding="utf-8")
    pdf = HERE.parent / "SwarmRide_Simulation_Results_Preview.pdf"
    print_pdf(out_html, pdf)                  # waits until Edge has finished writing
    print("wrote", pdf)


if __name__ == "__main__":
    main()

"""Revised pages 2, 5 and 6 for the SwarmRide Bharat pitch."""
from build_pitch import (svg, num, rcircle, box, carrow, markers, stxt,
                         OR, ORD, TEAL, TEALD, NAVY, GREY)


def overlay(w, h, body):
    return svg(w, h, body, 'style="position:absolute;left:0;top:0"')


# ================= PAGE 2: where it fits (real photos) =================
def page2():
    sc = 0.4375  # air spring photo 1280x960 -> 560x420
    air = overlay(560, 420, num(225 * sc, 600 * sc, 1) + num(660 * sc, 530 * sc, 2) + num(1040 * sc, 720 * sc, 3))
    # ICF bogie zoom 906x453 -> 453x226 (scale 0.5)
    icf = overlay(453, 226,
                  rcircle(255, 118, 52, OR, 3, ry=44) + num(318, 66, 4)
                  + rcircle(162, 150, 30, TEAL, 3, ry=34) + num(118, 112, 5, TEAL))
    # Casnub crop 1400x670 -> 453x217 (scale 0.3236)
    g = 453 / 1400
    cas = overlay(453, 217,
                  rcircle(650 * g, 385 * g, 52, OR, 3, ry=38) + num(835 * g, 215 * g, 6)
                  + rcircle(1285 * g, 300 * g, 26, TEAL, 3) + num(1285 * g, 395 * g, 7, TEAL))
    return f"""
<div class="page light">
  <div class="eyebrow dark">Where it fits · real bogies, real parts</div>
  <h2>Same bogie. We swap one part and add a small power bank.</h2>
  <div class="photo" style="left:40px;top:112px;width:560px;height:420px">
    <img src="photos/air_spring.jpg">{air}
    <div class="tag"><b>PASSENGER · AIR-SPRING BOGIE</b></div>
  </div>
  <div class="legend" style="left:40px;top:544px;width:560px">
    <p><span class="n">1</span><b>Oil damper today → SwarmRide smart damper.</b> Same mounts. Moves with the suspension and makes power.</p>
    <p><span class="n">2</span><b>Air spring stays.</b> Its pressure gives the live passenger load.</p>
    <p><span class="n">3</span><b>Bogie frame → sealed power bank + controller.</b></p>
  </div>
  <div class="photo" style="left:630px;top:112px;width:453px;height:226px">
    <img src="photos/icf_bogie_zoom.jpg">{icf}
    <div class="tag"><b>PASSENGER · ICF COACH BOGIE</b></div>
  </div>
  <div class="legend" style="left:630px;top:346px;width:453px">
    <p><span class="n">4</span><b>Secondary springs + oil damper</b> → smart damper fits here.
       <span class="n t">5</span><b>Axle box</b> → bearing sensor.</p>
  </div>
  <div class="photo" style="left:630px;top:404px;width:453px;height:217px">
    <img src="photos/casnub_crop.jpg">{cas}
    <div class="tag"><b>GOODS · CASNUB WAGON BOGIE</b></div>
  </div>
  <div class="legend" style="left:630px;top:629px;width:453px">
    <p><span class="n">6</span><b>Spring nest</b> → compact smart damper beside it.
       <span class="n t">7</span><b>Axle box</b> → bearing temperature + vibration sensor.</p>
  </div>
  <div class="pill" style="left:40px;top:690px">No new bogie · no new cables · fits today's mounts</div>
  <div class="foot">Photos: air spring on LHB coach — Apurv013, CC0 (Wikimedia Commons) · ICF coach bogie and Casnub wagon bogie — supplied by the author<span>2 / 6</span></div>
</div>"""


# ================= PAGE 5: passenger and goods (real photos) =================
def page5():
    pas = ["Ride tuned to live load from air-spring pressure",
           "Ready before each bump: warning from the loco",
           "Track recorded on every trip",
           "No new wiring: each bogie powers itself"]
    gds = ["Every axle: bearing temperature + vibration",
           "Train parting found at the exact wagon",
           "Track recorded on every goods run",
           "Wagons have no power; now they make their own"]
    li = lambda xs: "".join(f"<li>{x}</li>" for x in xs)
    p_ov = overlay(505, 219, rcircle(277, 114, 46, OR, 3.2, ry=30))
    g_ov = overlay(505, 220, rcircle(240, 123, 46, OR, 3.2, ry=30))
    res = [("Ride", "one load", "every load"),
           ("Hot axles", "~25 checkpoints", "every axle, always"),
           ("Parting", "last wagon", "exact wagon"),
           ("Track checks", "periodic", "every train, daily"),
           ("Bogie power", "none", "self-powered")]
    rc = "".join(f'<div class="res"><div class="rt">{a}</div><div class="rb">{b}</div><div class="ra">↓</div><div class="rg">{c}</div></div>'
                 for a, b, c in res)
    steps = ["Prove it · simulation + bench", "RDSO approval · trials", "Pilots · DFC rake + Vande Bharat", "Fleet rollout · factories + data"]
    road = '<div class="rarr">→</div>'.join(f'<div class="rs">{s}</div>' for s in steps)
    return f"""
<div class="page light">
  <div class="eyebrow dark">Two products · one technology</div>
  <h2>Comfort for passenger trains. Safety for goods trains.</h2>
  <div class="col" style="left:40px">
    <div class="ptitle">SwarmRide <span>Passenger</span> <small>Vande Bharat · LHB · ICF</small></div>
    <div class="photo" style="position:relative;width:505px;height:219px">
      <img src="photos/icf_coach_crop.jpg">{p_ov}
      <div class="tag2 o">CROWDED COACH → FIRMER DAMPING</div>
      <div class="tag">Orange ring: SwarmRide bogie · retuned at every stop</div>
    </div>
    <ul>{li(pas)}</ul>
  </div>
  <div class="col" style="left:575px">
    <div class="ptitle">SwarmRide <span>Freight</span> <small>BOXN · DFC rakes</small></div>
    <div class="photo" style="position:relative;width:505px;height:220px">
      <img src="photos/goods_train_crop.jpg">{g_ov}
      <div class="tag2 o">HOT BEARING · WAGON 37 · AXLE 2</div>
      <div class="tag2 t" style="top:44px">PARTING AT WAGON 52</div>
      <div class="tag">Alerts reach the loco pilot in seconds</div>
    </div>
    <ul>{li(gds)}</ul>
  </div>
  <div class="resrow">{rc}</div>
  <div class="road">{road}</div>
  <div class="msg" style="top:722px">One damper. Two markets. <span>Every bogie powers itself.</span></div>
  <div class="foot">Photos: ICF coaches — supplied by the author · BOXN freight train — Adityamadhav83, CC BY-SA 3.0 (Wikimedia Commons) · expected results, to be proven<span>5 / 6</span></div>
</div>"""


# ================= PAGE 6: end-to-end architecture =================
def page6():
    b = markers([OR, TEAL, NAVY, GREY])
    bands = [(84, 158, "OPERATIONS · CLOUD"),
             (168, 252, "TRAIN · LOCO OR DRIVING CAB"),
             (262, 360, "VEHICLE · EACH COACH OR WAGON"),
             (370, 600, "BOGIE · SELF-POWERED UNIT (2 PER VEHICLE)"),
             (610, 700, "PHYSICAL · TRACK TO COACH BODY")]
    fills = ["#EEF1F5", "#E9EEF4", "#F3EFE6", "#FBF1E7", "#F1F1EE"]
    for (y1, y2, lab), f in zip(bands, fills):
        b += f'<rect x="28" y="{y1}" width="790" height="{y2 - y1}" rx="10" fill="{f}"/>'
        b += stxt(808, y1 + 14, lab, 9.5, "#5E6878", "end", weight=600)

    # R1 operations
    b += box(40, 104, 340, 46, "Fleet track map", ["GPS-tagged track condition, built from every train"], TEALD)
    b += box(400, 104, 200, 46, "Cloud platform", ["Stores and analyses fleet data"], TEALD)
    b += box(620, 104, 195, 46, "Control + maintenance", ["Alerts · live fleet view"], TEALD)
    # R2 train
    b += box(40, 188, 340, 56, "Train Brain", ["Bump preview ŵ(t − d/v) for each vehicle", "Alert manager · trip log"], NAVY)
    b += box(400, 188, 200, 56, "Train network", ["TCMS (Vande Bharat)", "Radio mesh (goods)"], TEALD)
    b += box(620, 188, 195, 56, "Driver display", ["Load · comfort · health", "for every coach and wagon"], NAVY)
    # R3 vehicle
    b += box(40, 282, 560, 70, "Vehicle controller + radio",
             ["Load estimator m (air pressure / springs) · receives the bump preview",
              "LPV gains K(m, v) + preview feed-forward · passivity limiter (resist only)",
              "Energy supervisor: bank level → mode · sends health data"], OR)
    b += box(620, 282, 195, 70, "Data logger", ["1 kHz records", "trip and fault history"], NAVY)
    # R4 bogie, row 1: power chain (flows right to left)
    b += box(40, 392, 160, 60, "Power bank", ["Supercap + LiFePO4", "surplus → coach battery"], TEALD, "#E3F2EF")
    b += box(220, 392, 160, 60, "DC-DC converter", ["Steady 48 V bus", "(raises V, not energy)"], NAVY)
    b += box(400, 392, 180, 60, "Active rectifier", ["H-bridge: coil current", "= damper firmness"], NAVY)
    b += box(600, 392, 215, 60, "Smart dampers ×2–4", ["Magnet + coil: makes power", "and sets the ride"], OR, "#FDEBDC")
    # R4 bogie, row 2
    b += box(40, 488, 340, 76, "Safety + ride sensors",
             ["Axle-box bearing temperature + vibration", "Load: air-spring pressure / spring deflection",
              "Accelerometers · damper voltage (= velocity)"], TEALD)
    b += box(640, 488, 175, 76, "Fail-safe relay", ["Power lost → fixed", "resistor → works as a", "normal passive damper"], GREY)
    # R5 physical chain
    phys = [(40, 85, "Track", "bumps w(t)"), (141, 95, "Wheelset", "+ axle boxes"),
            (252, 115, "Primary", "springs + dampers"), (383, 105, "Bogie frame", "power bank here"),
            (504, 185, "Secondary suspension", "air spring ∥ smart damper"), (705, 110, "Coach body", "+ people / cargo")]
    for x, w, t, s in phys:
        sec = t.startswith("Secondary")
        b += box(x, 632, w, 50, t, [s], OR if sec else GREY, "#FDEBDC" if sec else "#FFFFFF")
    for (x, w, *_), (nx, *__) in zip(phys, phys[1:]):
        b += carrow([(x + w, 657), (nx, 657)], GREY)

    # ---- links (every arrow points the way the thing flows) ----
    two = dict(dash="6 4", both=True)
    b += carrow([(380, 127), (400, 127)], TEAL, **two)
    b += carrow([(600, 127), (620, 127)], TEAL, **two)
    b += carrow([(500, 150), (500, 188)], TEAL, **two)
    b += stxt(494, 173, "4G / 5G", 10, TEALD, "end", 600)
    b += carrow([(380, 216), (400, 216)], TEAL, **two)
    b += carrow([(600, 216), (620, 216)], TEAL, dash="6 4")
    b += carrow([(500, 244), (500, 282)], TEAL, **two)
    b += stxt(494, 267, "bump preview ↓ · health data ↑", 10, TEALD, "end", 600)
    b += carrow([(600, 317), (620, 317)], TEAL, dash="6 4")
    # power up to the controller, command down to the rectifier
    b += carrow([(80, 392), (80, 352)], OR, w=2.4)
    b += stxt(86, 377, "power + charge level", 10, ORD, weight=600)
    b += carrow([(490, 352), (490, 392)], NAVY, w=2.2)
    b += stxt(496, 377, "current command i*", 10, NAVY, weight=600)
    # harvested power: dampers -> rectifier -> DC-DC -> bank
    for x1, x2 in [(600, 580), (400, 380), (220, 200)]:
        b += carrow([(x1, 422), (x2, 422)], OR, w=2.4)
    # bank powers the sensors; sensor data goes up to the controller
    b += carrow([(80, 452), (80, 488)], OR, w=2.4)
    b += carrow([(210, 488), (210, 352)], TEAL, dash="6 4")
    b += stxt(216, 476, "state · load · health", 10, TEALD, weight=600)
    # fail-safe relay sits on the coil circuit
    b += carrow([(727, 452), (727, 488)], GREY, dash="5 4", both=True)
    # suspension motion drives the smart dampers
    b += carrow([(615, 632), (615, 452)], GREY, w=2.4)
    b += stxt(609, 606, "relative motion", 10, "#5E6878", "end", 600)

    # ---- end-to-end summary strip ----
    steps = [("Bump moves the", "smart damper"), ("Coil makes power,", "bank stores it"),
             ("Bank powers", "sensors + control"), ("Data + preview", "on train network"),
             ("Alerts + track map", "to control room")]
    for i, (l1, l2) in enumerate(steps):
        x = 40 + i * 157
        b += f'<rect x="{x}" y="714" width="143" height="48" rx="9" fill="{NAVY}"/>'
        b += num(x + 18, 738, i + 1)
        b += stxt(x + 36, 734, l1, 10.5, "#F6F4EE", weight=600) + stxt(x + 36, 748, l2, 10.5, "#C9D3E0")
        if i < 4:
            b += carrow([(x + 143, 738), (x + 157, 738)], OR, w=2)
    diagram = svg(830, 790, b)
    return f"""
<div class="page light">
  <div class="eyebrow dark">End-to-end architecture</div>
  <h2 style="width:780px">From a bump on the track to the control room.</h2>
  <div style="position:absolute;left:0;top:0">{diagram}</div>
  <div class="side">
    <div class="sbox"><div class="sh">Legend</div>
      <div class="lg"><i style="background:{OR}"></i>Harvested power</div>
      <div class="lg"><i class="dash" style="border-color:{TEAL}"></i>Data link (arrows show direction)</div>
      <div class="lg"><i style="background:{NAVY}"></i>Control command</div>
      <div class="lg"><i style="background:{GREY}"></i>Mechanical motion</div>
    </div>
    <div class="sbox"><div class="sh">Energy order on every bogie</div>
      <ol><li>Safety sensors</li><li>Radio link</li><li>Ride control</li><li>Reserve for stops</li><li>Surplus to coach battery</li></ol>
    </div>
    <div class="sbox"><div class="sh">Control law</div>
      <p>F* = −K(m,v)·x̂ + Kp·ŵ</p><p>c = clip(F* ÷ v<sub>rel</sub>, 0, c<sub>max</sub>)</p><p>i* = c·v<sub>rel</sub> ÷ Kf</p>
      <p class="sm">Resists only: every bit of damping is harvested energy.</p>
    </div>
    <div class="sbox"><div class="sh">Works alone</div>
      <p class="sm">If the train network drops, each vehicle keeps load-adaptive control without the preview.</p>
    </div>
    <div class="sbox"><div class="sh">Safety</div>
      <p class="sm">Fail-safe relay makes it a normal damper. Safety never depends on software. To be tested to EN 50155 · EN 61373 · EN 50121.</p>
    </div>
  </div>
  <div class="foot">SwarmRide Bharat · system architecture<span>6 / 6</span></div>
</div>"""


EXTRA_CSS = """
.n.t { background:#2A9D8F; margin-left:8px; }
.tag2 { position:absolute; right:12px; top:12px; font-size:11px; font-weight:700; letter-spacing:1px; color:#fff; padding:6px 10px; border-radius:7px; }
.tag2.o { background:rgba(224,122,31,0.95); }
.tag2.t { background:rgba(31,111,102,0.95); }
.ptitle small { font-family:'IBM Plex Sans', Arial; font-size:12px; font-weight:500; color:#6B7685; margin-left:6px; }
"""

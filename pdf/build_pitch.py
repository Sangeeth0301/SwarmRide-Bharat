"""Builds the SwarmRide Bharat 6-page pitch (HTML -> PDF via headless Edge)."""
import math
import random
from pathlib import Path

from edge_pdf import print_pdf

HERE = Path(__file__).resolve().parent
R = random.Random(7)

INK = "#2E3A4B"
NAVY = "#13233A"
NAVY2 = "#1E3557"
OR = "#E07A1F"
ORD = "#A8520F"
TEAL = "#2A9D8F"
TEALD = "#1F6F66"
PAPER = "#FBF8F1"
GREY = "#8A93A0"
LIGHT = "#F6F4EE"


# ---------- hand-drawn (rough) SVG helpers ----------
def j(a=1.2):
    return R.uniform(-a, a)


def rline(x1, y1, x2, y2, c=INK, w=2.2, passes=2, jit=1.3, dash=None):
    out = []
    for p in range(passes):
        ax, ay = x1 + j(jit), y1 + j(jit)
        bx, by = x2 + j(jit), y2 + j(jit)
        mx, my = (ax + bx) / 2 + j(jit * 1.4), (ay + by) / 2 + j(jit * 1.4)
        sw = w if p == 0 else w * 0.55
        op = 1 if p == 0 else 0.6
        d = f' stroke-dasharray="{dash}"' if dash else ""
        out.append(
            f'<path d="M{ax:.1f} {ay:.1f} Q{mx:.1f} {my:.1f} {bx:.1f} {by:.1f}" stroke="{c}" '
            f'stroke-width="{sw:.1f}" fill="none" stroke-linecap="round" opacity="{op}"{d}/>'
        )
    return "".join(out)


def rpoly(pts, c=INK, w=2.2, passes=2, jit=1.0, close=False):
    out = []
    p = list(pts) + ([pts[0]] if close else [])
    for k in range(passes):
        q = [(x + j(jit), y + j(jit)) for x, y in p]
        d = "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in q)
        sw = w if k == 0 else w * 0.55
        out.append(f'<path d="{d}" stroke="{c}" stroke-width="{sw:.1f}" fill="none" '
                   f'stroke-linejoin="round" stroke-linecap="round" opacity="{1 if k == 0 else 0.6}"/>')
    return "".join(out)


def rrect(x, y, w, h, c=INK, sw=2.2, fill=None, fop=1.0):
    s = ""
    if fill:
        s += (f'<rect x="{x + j(1.5):.1f}" y="{y + j(1.5):.1f}" width="{w}" height="{h}" '
              f'fill="{fill}" opacity="{fop}" rx="3"/>')
    s += rline(x, y, x + w, y, c, sw) + rline(x + w, y, x + w, y + h, c, sw)
    s += rline(x + w, y + h, x, y + h, c, sw) + rline(x, y + h, x, y, c, sw)
    return s


def rcircle(cx, cy, r, c=INK, sw=2.2, fill=None, ry=None):
    ry = ry or r
    s = ""
    if fill:
        s += f'<ellipse cx="{cx + j(1):.1f}" cy="{cy + j(1):.1f}" rx="{r}" ry="{ry}" fill="{fill}"/>'
    for k in range(2):
        a0 = R.uniform(0, 2 * math.pi)
        pts = []
        n = 26
        for i in range(n + 3):
            a = a0 + 2 * math.pi * i / n
            f = 1 + R.uniform(-0.03, 0.03)
            pts.append((cx + r * f * math.cos(a), cy + ry * f * math.sin(a)))
        d = "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts)
        s += (f'<path d="{d}" stroke="{c}" stroke-width="{sw if k == 0 else sw * 0.55:.1f}" '
              f'fill="none" opacity="{1 if k == 0 else 0.6}" stroke-linejoin="round"/>')
    return s


def spring(x, y1, y2, wdt=18, turns=5, c=INK, w=2.2):
    pts = [(x, y1)]
    step = (y2 - y1) / (turns * 2 + 1)
    for i in range(turns * 2):
        pts.append((x + (wdt if i % 2 == 0 else -wdt) / 2, y1 + step * (i + 1)))
    pts.append((x, y2))
    return rpoly(pts, c, w, passes=1, jit=0.6)


def arrow(x1, y1, x2, y2, c=INK, w=2.2, dash=None, head=11):
    s = rline(x1, y1, x2, y2, c, w, dash=dash)
    a = math.atan2(y2 - y1, x2 - x1)
    for da in (2.6, -2.6):
        s += rline(x2, y2, x2 + head * math.cos(a + da), y2 + head * math.sin(a + da), c, w, passes=1)
    return s


def htext(x, y, s, size=24, c=INK, anchor="start", weight=700):
    return (f'<text x="{x}" y="{y}" font-family="Caveat, cursive" font-size="{size}" '
            f'font-weight="{weight}" fill="{c}" text-anchor="{anchor}">{s}</text>')


def stxt(x, y, s, size=12, c=INK, anchor="start", weight=400):
    return (f'<text x="{x}" y="{y}" font-family="IBM Plex Sans, Arial, sans-serif" font-size="{size}" '
            f'font-weight="{weight}" fill="{c}" text-anchor="{anchor}">{s}</text>')


def stick(x, y, c=INK):
    return (rcircle(x, y, 5, c, 1.6) + rline(x, y + 5, x, y + 22, c, 1.6, 1)
            + rline(x - 8, y + 12, x + 8, y + 12, c, 1.6, 1)
            + rline(x, y + 22, x - 6, y + 34, c, 1.6, 1) + rline(x, y + 22, x + 6, y + 34, c, 1.6, 1))


def svg(w, h, body, extra=""):
    return f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" {extra}>{body}</svg>'


# ---------- crisp diagram helpers (architecture page) ----------
def box(x, y, w, h, title, lines=(), stroke=NAVY, fill="#FFFFFF", tcol=NAVY):
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{fill}" stroke="{stroke}" stroke-width="1.6"/>'
    s += stxt(x + 10, y + 18, title, 12.5, tcol, weight=600)
    for i, ln in enumerate(lines):
        s += stxt(x + 10, y + 33 + i * 13.5, ln, 10.5, "#3D4A5C")
    return s


def carrow(pts, c, dash=None, both=False, w=2):
    d = "M" + " L".join(f"{x} {y}" for x, y in pts)
    da = f' stroke-dasharray="{dash}"' if dash else ""
    me = f' marker-end="url(#h-{c[1:]})"'
    ms = f' marker-start="url(#h-{c[1:]})"' if both else ""
    return f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}"{da}{me}{ms}/>'


def markers(colors):
    return "".join(
        f'<marker id="h-{c[1:]}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" '
        f'orient="auto-start-reverse"><path d="M0 0L10 5L0 10z" fill="{c}"/></marker>' for c in colors)


def num(x, y, n, c=OR):
    return (f'<circle cx="{x}" cy="{y}" r="13" fill="{c}" stroke="#FFFFFF" stroke-width="3"/>'
            f'<text x="{x}" y="{y + 5}" font-family="Rubik, Arial" font-size="14" font-weight="700" '
            f'fill="#FFFFFF" text-anchor="middle">{n}</text>')


# ================= PAGE 1 =================
def page1():
    chips = [("1", "Harvest", "Smart damper makes power"),
             ("2", "Store", "Power bank on every bogie"),
             ("3", "Sense + tune", "Axles, track, load, ride"),
             ("4", "Sync", "Loco warns every coach")]
    chip_html = ""
    for i, (n, t, s) in enumerate(chips):
        chip_html += (f'<div class="chip"><div class="cn">{n}</div><div><b>{t}</b><br>{s}</div></div>')
        if i < 3:
            chip_html += '<div class="carr">→</div>'
    stats = [("~3 / day", "hot-axle cases on Indian Railways", "Railway Board, 2025"),
             ("327", "derailments from track faults, 2017–21", "CAG audit"),
             ("30–100%", "shortfall in Track Recording Car checks", "CAG audit"),
             ("0 W", "electrical power on a goods wagon today", "no sensors possible")]
    st = "".join(f'<div class="stat"><div class="big">{a}</div><div class="lab">{b}</div><div class="src">{c}</div></div>'
                 for a, b, c in stats)
    return f"""
<div class="page">
  <div class="band">
    <div class="eyebrow">SwarmRide Bharat · self-aware trains for Indian Railways</div>
    <h1>Every bogie powers itself, rides smarter and checks itself.</h1>
    <div class="row2">
      <div class="what"><div class="lbl">What we do</div>
        We replace the oil damper on each bogie with a <b>smart magnet-and-coil damper</b>.
        The bump energy that becomes heat today now <b>powers safety sensors</b> and <b>tunes the ride</b>.</div>
      <div class="appr"><div class="lbl">Approach</div><div class="chips">{chip_html}</div></div>
    </div>
  </div>
  <div class="photo" style="left:40px;top:262px;width:515px;height:300px">
    <img src="photos/vande_bharat.jpg" style="object-position:50% 62%">
    <div class="tag"><b>PASSENGER · VANDE BHARAT</b><br>Ride tuned to every load · no new wiring</div>
  </div>
  <div class="photo" style="left:568px;top:262px;width:515px;height:300px">
    <img src="photos/goods_train.jpg" style="object-position:30% 50%">
    <div class="tag"><b>GOODS · BOXN WAGONS</b><br>Every axle watched · wagons power themselves</div>
  </div>
  <div class="stats">{st}</div>
  <div class="msg">The energy is already in every bump. Today it becomes heat. <span>We turn it into safety and comfort.</span></div>
  <div class="foot">Photos (Wikimedia Commons): Vande Bharat Express — Ravi Dwivedi, CC BY-SA 4.0 · BOXN freight train at Rajahmundry — Adityamadhav83, CC BY-SA 3.0<span>1 / 6</span></div>
</div>"""


# ================= PAGE 2 =================
def page2():
    # air spring photo 1280x960 shown at 560x420 (scale 0.4375)
    sc = 0.4375
    air = svg(560, 420, num(225 * sc, 600 * sc, 1) + num(660 * sc, 530 * sc, 2) + num(1040 * sc, 720 * sc, 3),
              'style="position:absolute;left:0;top:0"')
    # LHB crop 720x440 shown at 449x274 (scale 0.6236)
    s2 = 449 / 720
    lhb = svg(449, 274, rcircle(345 * s2, 240 * s2, 70 * s2, OR, 3, ry=55 * s2) + num(430 * s2, 175 * s2, 4),
              'style="position:absolute;left:0;top:0"')
    # goods crop 640x430 shown at 400x269 (scale 0.625)
    s3 = 0.625
    gd = svg(400, 269, rcircle(365 * s3, 235 * s3, 30, OR, 3, ry=36) + num(430 * s3, 200 * s3, 5)
             + num(232 * s3, 345 * s3, 6),
             'style="position:absolute;left:0;top:0"')
    return f"""
<div class="page light">
  <div class="eyebrow dark">Where it fits · real bogies, real parts</div>
  <h2>Same bogie. We swap one part and add a small power bank.</h2>
  <div class="photo" style="left:40px;top:112px;width:560px;height:420px">
    <img src="photos/air_spring.jpg">{air}
  </div>
  <div class="legend" style="left:40px;top:544px;width:560px">
    <p><span class="n">1</span><b>Oil damper today → SwarmRide smart damper.</b> Same mounts. Moves with the suspension and makes power.</p>
    <p><span class="n">2</span><b>Air spring stays.</b> Its pressure gives the live passenger load.</p>
    <p><span class="n">3</span><b>Bogie frame → sealed power bank + controller.</b></p>
  </div>
  <div class="photo" style="left:630px;top:112px;width:449px;height:274px">
    <img src="photos/lhb_bogie_crop.jpg">{lhb}
  </div>
  <div class="legend" style="left:630px;top:392px;width:449px">
    <p><span class="n">4</span><b>Passenger coach:</b> 2 bogies per coach → 2 self-powered SwarmRide units.</p>
  </div>
  <div class="photo" style="left:630px;top:446px;width:400px;height:269px">
    <img src="photos/goods_bogie_crop.jpg">{gd}
  </div>
  <div class="legend" style="left:630px;top:720px;width:449px">
    <p><span class="n">5</span><b>Goods bogie:</b> compact smart damper beside the spring nest. <span class="n">6</span><b>Axle box:</b> bearing sensor.</p>
  </div>
  <div class="pill" style="left:40px;top:680px">No new bogie · no new cables · fits today's mounts</div>
  <div class="foot">Photos (Wikimedia Commons): air spring on LHB coach — Apurv013, CC0 · Duranto LHB coach — Universalashic, CC BY-SA 3.0 · goods-wagon bogie model — Destination8infinity, CC BY-SA 3.0<span>2 / 6</span></div>
</div>"""


# ================= PAGE 3 =================
def damper_sketch():
    b = ""
    b += rcircle(200, 58, 24, INK, 3)
    b += rline(200, 82, 200, 200, GREY, 9, 1)
    b += rrect(120, 150, 160, 380, INK, 2.6, "#FFFFFF")
    for yy in range(168, 514, 10):
        b += rline(133, yy, 155, yy, OR, 4, 1, 0.4) + rline(245, yy, 267, yy, OR, 4, 1, 0.4)
    for i in range(6):
        y = 196 + i * 40
        col = NAVY if i % 2 == 0 else TEAL
        b += rrect(172, y, 56, 38, INK, 1.6, col, 0.9)
        b += htext(200, y + 28, "N" if i % 2 == 0 else "S", 24, "#FFFFFF", "middle")
    b += rline(200, 530, 200, 572, GREY, 9, 1)
    b += rcircle(200, 596, 24, INK, 3)
    b += arrow(60, 360, 60, 238, INK, 2.6) + arrow(60, 360, 60, 482, INK, 2.6)
    b += rline(280, 430, 362, 430, OR, 4) + rline(280, 456, 362, 456, OR, 4)
    b += rrect(362, 410, 100, 66, TEALD, 2.4, "#D7EEEA")
    b += htext(412, 438, "power", 22, TEALD, "middle") + htext(412, 462, "bank", 22, TEALD, "middle")
    b += htext(236, 46, "to coach body", 24, INK)
    b += htext(298, 214, "copper coil", 25, ORD) + htext(298, 236, "(fixed)", 22, ORD)
    b += arrow(296, 222, 270, 238, ORD, 2)
    b += htext(298, 322, "magnet stack", 25, NAVY) + htext(298, 344, "(moves)", 22, NAVY)
    b += arrow(296, 330, 232, 330, NAVY, 2)
    b += htext(16, 520, "moves with", 24, INK) + htext(16, 544, "every bump", 24, INK)
    b += htext(236, 612, "to bogie frame", 24, INK)
    return svg(480, 630, b)


def card(title, body_svg, caption):
    return (f'<div class="card"><div class="ct">{title}</div>{body_svg}'
            f'<div class="cc">{caption}</div></div>')


def page3():
    # card 1: bump moves it
    c1 = rpoly([(10, 150), (70, 150), (95, 132), (120, 150), (240, 150)], INK, 2.4)
    c1 += rrect(70, 40, 110, 50, INK, 2.2, "#FFFFFF") + spring(105, 90, 128, 14, 4) + spring(150, 90, 128, 14, 4)
    c1 += arrow(200, 95, 200, 40, OR, 2.6) + htext(208, 70, "up!", 24, ORD)
    c1 = svg(250, 165, c1)
    # card 2: makes power
    c2 = rrect(20, 40, 60, 90, INK, 2.2, "#FFFFFF")
    for yy in range(48, 126, 9):
        c2 += rline(26, yy, 74, yy, OR, 3, 1, 0.4)
    c2 += rpoly([(118, 45), (100, 88), (122, 88), (104, 130)], OR, 3.4)
    c2 += rrect(150, 55, 80, 60, TEALD, 2.4, "#D7EEEA") + rrect(230, 72, 8, 26, TEALD, 2)
    c2 += htext(190, 95, "+ −", 26, TEALD, "middle")
    c2 = svg(250, 165, c2)
    # card 3: sets the ride (dial)
    c3 = ""
    pts = [(125 + 80 * math.cos(math.pi + a * math.pi / 20), 125 + 80 * math.sin(math.pi + a * math.pi / 20)) for a in range(21)]
    c3 += rpoly(pts, INK, 2.6)
    c3 += arrow(125, 125, 175, 70, OR, 3)
    c3 += rcircle(125, 125, 6, INK, 2, INK)
    c3 += htext(30, 150, "soft", 24, INK) + htext(195, 150, "firm", 24, INK)
    c3 = svg(250, 165, c3)
    # card 4: fails safe
    c4 = rline(20, 90, 70, 90, INK, 2.4) + rcircle(76, 90, 6, INK, 2, INK) + rline(80, 88, 120, 62, INK, 2.6)
    c4 += rcircle(124, 90, 6, INK, 2, INK)
    c4 += rpoly([(130, 90), (140, 90), (146, 76), (156, 104), (166, 76), (176, 104), (186, 76), (192, 90), (232, 90)], OR, 2.6)
    c4 += htext(160, 135, "resistor", 24, ORD, "middle") + htext(98, 50, "relay", 24, INK, "middle")
    c4 = svg(250, 165, c4)
    cards = (card("1 · A bump moves it", c1, "Track bump → coach moves → magnet slides through the coil")
             + card("2 · It makes power", c2, "<b>e = Ke · v</b> (Faraday's law) → charges the bogie power bank")
             + card("3 · It sets the ride", c3, "<b>c = Ke² ÷ (R coil + R load)</b> → firmness set in milliseconds")
             + card("4 · It fails safe", c4, "Power lost → relay → resistor → works like a normal damper"))
    return f"""
<div class="page light">
  <div class="eyebrow dark">How it works · the smart damper (concept sketch)</div>
  <h2>A magnet moving through a coil: power and ride control in one part.</h2>
  <div class="sketch" style="left:40px;top:108px;width:480px;height:630px">{damper_sketch()}</div>
  <div class="cards">{cards}</div>
  <div class="pill" style="left:550px;top:706px">Fits existing damper mounts · no oil · no gears</div>
  <div class="foot">Concept sketches, not to scale<span>3 / 6</span></div>
</div>"""


# ================= PAGE 4 =================
def train_sketch():
    b = rline(10, 252, 1025, 252, INK, 2.6)
    for x in range(20, 1020, 28):
        b += rline(x, 252, x - 6, 262, GREY, 1.6, 1)
    b += rpoly([(40, 252), (60, 238), (80, 252)], OR, 4, passes=2)
    # loco
    b += rpoly([(20, 230), (20, 140), (62, 100), (250, 100), (250, 230)], INK, 2.6, close=True)
    b += rrect(34, 122, 40, 30, TEALD, 2, "#D7EEEA")
    b += htext(150, 165, "LOCO", 28, NAVY, "middle") + htext(150, 193, "Train Brain", 26, TEALD, "middle")
    vehicles = [(270, "Coach 1"), (515, "Coach 2"), (760, "Wagon N")]
    for x, lab in vehicles:
        b += rrect(x, 100, 230, 130, INK, 2.4, "#FFFFFF")
        for k in range(4):
            b += rrect(x + 18 + k * 52, 118, 36, 26, GREY, 1.4)
        b += htext(x + 115, 190, lab, 28, NAVY, "middle")
    for x0, w in [(20, 230), (270, 230), (515, 230), (760, 230)]:
        for c in (x0 + 48, x0 + w - 48):
            b += rline(c - 30, 232, c + 30, 232, INK, 3, 1)
            b += rcircle(c - 17, 240, 11, INK, 2) + rcircle(c + 17, 240, 11, INK, 2)
            if x0 > 100:
                b += rcircle(c, 236, 40, OR, 2.4, ry=26)
    # warnings (dashed arcs) from loco
    for (x, lab), t in zip(vehicles, ["bump in ≈0.6 s", "bump in ≈1.1 s", "bump in 2.25 s"]):
        cx = x + 115
        b += (f'<path d="M150 98 Q{(150 + cx) / 2:.0f} 44 {cx} 98" stroke="{TEAL}" stroke-width="2.6" '
              f'fill="none" stroke-dasharray="9 7"/>')
        b += htext(cx, 30, t, 24, TEALD, "middle")
    b += htext(20, 292, "front bogie feels the bump first", 24, ORD)
    b += htext(1015, 292, "warning time t = d ÷ v  (at 160 km/h, 100 m back = 2.25 s)", 24, TEALD, "end")
    return svg(1040, 300, b)


def bogie_sketch(smart):
    b = rrect(20, 18, 465, 44, INK, 2.2, "#ECE8DE") + htext(36, 48, "coach body", 22, INK)
    for x in (110, 335):
        b += rrect(x, 62, 60, 62, INK, 2.2, "#5E6878", 0.85)
        b += rline(x, 83, x + 60, 83, "#C9D3E0", 1.6, 1) + rline(x, 103, x + 60, 103, "#C9D3E0", 1.6, 1)
    if smart:
        b += rrect(236, 64, 28, 60, ORD, 2.2, OR)
        for yy in range(72, 120, 8):
            b += rline(240, yy, 260, yy, "#FFFFFF", 2, 1, 0.3)
    else:
        b += rrect(242, 70, 16, 38, INK, 2, "#B9C0C9") + rline(250, 108, 250, 124, INK, 3, 1)
    b += rrect(70, 124, 365, 32, INK, 2.4, NAVY2, 0.9)
    if smart:
        b += rrect(196, 129, 110, 22, TEALD, 2, TEAL)
    for x in (140, 365):
        b += spring(x, 156, 196, 22, 4)
        b += rcircle(x, 236, 50, INK, 2.4, "#E6E9ED")
        b += rrect(x - 18, 196, 36, 28, INK, 2, "#5E6878")
    b += rline(0, 288, 505, 288, INK, 3)
    if smart:
        for x, y in [(140, 210), (365, 210), (178, 94), (403, 94)]:
            b += rcircle(x, y, 7, "#FFFFFF", 1.6, TEAL)
        b += rline(140, 204, 210, 152, TEAL, 2, 1, dash="6 5") + rline(365, 204, 292, 152, TEAL, 2, 1, dash="6 5")
        b += htext(300, 48, "smart damper", 24, ORD) + arrow(296, 42, 266, 66, ORD, 2, head=8)
        b += htext(251, 180, "power bank", 22, TEALD, "middle")
        b += htext(415, 214, "bearing", 22, TEALD) + htext(415, 234, "sensor", 22, TEALD)
        b += htext(442, 92, "load", 22, TEALD) + htext(442, 112, "sensor", 22, TEALD)
    else:
        b += htext(300, 48, "oil damper → heat", 24, INK) + arrow(296, 42, 260, 70, INK, 2, head=8)
        b += htext(252, 182, "no power · no sensors", 22, GREY, "middle")
    return svg(505, 300, b)


def page4():
    return f"""
<div class="page light">
  <div class="eyebrow dark">On the train · concept sketch</div>
  <h2>The loco warns every coach before the bump arrives.</h2>
  <div class="sketch" style="left:40px;top:104px;width:1040px;height:300px">{train_sketch()}</div>
  <div class="stitle" style="left:40px;top:416px">Bogie today</div>
  <div class="stitle orange" style="left:575px;top:416px">SwarmRide bogie</div>
  <div class="sketch" style="left:40px;top:446px;width:505px;height:300px">{bogie_sketch(False)}</div>
  <div class="sketch" style="left:575px;top:446px;width:505px;height:300px">{bogie_sketch(True)}</div>
  <div class="foot">Orange rings: SwarmRide on every coach and wagon bogie · concept sketches, not to scale<span>4 / 6</span></div>
</div>"""


# ================= PAGE 5 =================
def passenger_sketch():
    b = rrect(15, 40, 200, 92, INK, 2.2, "#FFFFFF")
    for i, x in enumerate(range(35, 200, 24)):
        b += stick(x, 62 + (i % 2) * 4)
    b += htext(115, 30, "crowded coach", 24, NAVY, "middle")
    b += spring(70, 132, 168, 16, 4) + spring(160, 132, 168, 16, 4)
    b += rrect(108, 136, 14, 30, ORD, 1.8, OR)
    b += rline(15, 172, 215, 172, INK, 2.6)
    # graph
    b += arrow(250, 190, 250, 25, INK, 2) + arrow(250, 190, 495, 190, INK, 2)
    g1 = [(250 + t * 2.4, 110 - 55 * math.exp(-t / 60) * math.sin(t / 7)) for t in range(0, 100)]
    g2 = [(250 + t * 2.4, 110 - 55 * math.exp(-t / 12) * math.sin(t / 7)) for t in range(0, 100)]
    b += rpoly(g1, GREY, 2.2, passes=1, jit=0.3) + rpoly(g2, OR, 3, passes=1, jit=0.3)
    b += htext(380, 50, "fixed damper", 22, GREY) + htext(380, 150, "SwarmRide", 24, ORD)
    b += htext(256, 22, "body bounce", 20, INK) + htext(490, 212, "time", 20, INK, "end")
    return svg(505, 220, b)


def goods_sketch():
    b = rpoly([(15, 60), (35, 140), (295, 140), (315, 60)], INK, 2.4, close=True)
    b += rpoly([(25, 60), (305, 60)], INK, 2)
    for x in range(55, 300, 40):
        b += rline(x, 64, x - 3, 136, GREY, 1.4, 1)
    for c in (70, 255):
        b += rline(c - 34, 150, c + 34, 150, INK, 3, 1)
        b += rcircle(c - 20, 165, 15, INK, 2.2) + rcircle(c + 20, 165, 15, INK, 2.2)
        b += rcircle(c - 20, 165, 6, "#FFFFFF", 1.4, TEAL) + rcircle(c + 20, 165, 6, "#FFFFFF", 1.4, TEAL)
    b += rline(0, 182, 340, 182, INK, 2.6)
    b += rrect(330, 18, 168, 62, ORD, 2.2, "#FDEBDC")
    b += htext(414, 44, "hot bearing!", 26, ORD, "middle") + htext(414, 68, "wagon 37 · axle 2", 22, INK, "middle")
    b += rrect(330, 100, 168, 62, TEALD, 2.2, "#D7EEEA")
    b += htext(414, 126, "parting at", 24, TEALD, "middle") + htext(414, 150, "wagon 52", 24, TEALD, "middle")
    b += rline(300, 70, 330, 50, ORD, 2, 1) + rline(290, 120, 330, 130, TEALD, 2, 1)
    return svg(505, 220, b)


def page5():
    pas = ["Ride tuned to live load from air-spring pressure",
           "Ready before each bump: warning from the loco",
           "Track recorded at 160 km/h, every trip",
           "No new wiring: each bogie powers itself"]
    gds = ["Every axle: bearing temperature + vibration",
           "Train parting found at the exact wagon",
           "Track recorded on every goods run",
           "Wagons have no power; now they make their own"]
    li = lambda xs: "".join(f"<li>{x}</li>" for x in xs)
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
  <h2>Comfort for Vande Bharat. Safety for goods trains.</h2>
  <div class="col" style="left:40px">
    <div class="ptitle">SwarmRide <span>Vande Bharat</span></div>
    <div class="sketch" style="position:relative;width:505px;height:220px">{passenger_sketch()}</div>
    <ul>{li(pas)}</ul>
  </div>
  <div class="col" style="left:575px">
    <div class="ptitle">SwarmRide <span>Freight</span></div>
    <div class="sketch" style="position:relative;width:505px;height:220px">{goods_sketch()}</div>
    <ul>{li(gds)}</ul>
  </div>
  <div class="resrow">{rc}</div>
  <div class="road">{road}</div>
  <div class="msg" style="top:722px">One damper. Two markets. <span>Every bogie powers itself.</span></div>
  <div class="foot">Expected results, to be proven in simulation, bench tests and pilots<span>5 / 6</span></div>
</div>"""


# ================= PAGE 6: architecture =================
def page6():
    b = markers([OR, TEAL, NAVY, GREY])
    bands = [(84, 160, "OPERATIONS · CLOUD"), (170, 268, "TRAIN · LOCO OR DRIVING CAB"),
             (278, 384, "VEHICLE · EACH COACH OR WAGON"), (394, 590, "BOGIE · SELF-POWERED UNIT (2 PER VEHICLE)"),
             (600, 766, "PHYSICAL · TRACK TO COACH BODY")]
    fills = ["#EEF1F5", "#E9EEF4", "#F3EFE6", "#FBF1E7", "#F1F1EE"]
    for (y1, y2, lab), f in zip(bands, fills):
        b += f'<rect x="28" y="{y1}" width="790" height="{y2 - y1}" rx="10" fill="{f}"/>'
        b += stxt(808, y1 + 14, lab, 9.5, "#5E6878", "end", weight=600)
    # A
    b += box(40, 104, 230, 50, "Fleet track map", ["GPS-tagged track condition,", "built from every train"], TEALD)
    b += box(290, 104, 230, 50, "Maintenance alerts", ["Hot axles · wheel flats ·", "track defects by km"], TEALD)
    b += box(540, 104, 265, 50, "Control office dashboard", ["Every train, every coach, live"], TEALD)
    # B
    b += box(40, 194, 300, 66, "Train Brain", ["Bump preview ŵ(t − d/v) for each vehicle", "Alert manager · trip log"], NAVY, "#FFFFFF")
    b += box(360, 194, 230, 66, "Train network", ["TCMS (Vande Bharat)", "Low-power radio mesh (goods)"], TEALD)
    b += box(610, 194, 195, 66, "Driver display", ["Load · comfort · health", "per coach and wagon"], NAVY)
    # C
    b += box(40, 300, 330, 78, "Vehicle controller", ["Load estimator m (air pressure / springs)", "LPV gains K(m, v) + preview feed-forward",
                                                          "Passivity limiter · energy supervisor"], OR)
    b += box(390, 300, 415, 78, "Logger + radio link", ["Health and track data out to the Train Brain", "Bump preview in · works alone if the link drops"], TEALD)
    # D row 1 (power chain, right to left)
    b += box(620, 418, 185, 58, "Smart dampers ×2–4", ["Magnet + coil: power", "and ride control"], OR, "#FDEBDC")
    b += box(430, 418, 170, 58, "Active rectifier", ["H-bridge: coil current", "= damper firmness"], NAVY)
    b += box(240, 418, 170, 58, "DC-DC converter", ["Steady 48 V bus", "(raises V, not energy)"], NAVY)
    b += box(40, 418, 180, 58, "Power bank", ["Supercap + small", "LiFePO4 battery"], TEALD, "#E3F2EF")
    # D row 2
    b += box(40, 508, 400, 74, "Safety + ride sensors", ["Axle-box bearing temperature + vibration",
                                                          "Load: air-spring pressure / spring deflection", "Accelerometers · damper voltage (velocity)"], TEALD)
    b += box(640, 508, 165, 74, "Fail-safe relay", ["Power lost → fixed", "resistor → normal", "passive damper"], GREY)
    # E physical chain
    ey = 630
    b += box(40, ey, 118, 50, "Track bumps", ["w(t)"], GREY, "#FFFFFF")
    b += box(178, ey, 110, 50, "Wheelset", ["+ axle boxes"], GREY)
    b += box(308, ey, 128, 50, "Primary springs", ["+ dampers"], GREY)
    b += box(456, ey, 128, 50, "Bogie frame", ["power bank here"], GREY)
    b += box(605, ey, 200, 50, "Air spring ∥ smart damper", ["secondary suspension"], OR, "#FDEBDC")
    b += box(605, 706, 200, 50, "Coach body", ["+ passengers or cargo"], GREY)
    for x1, x2 in [(158, 178), (288, 308), (436, 456), (584, 605)]:
        b += carrow([(x1, ey + 25), (x2, ey + 25)], GREY)
    b += carrow([(705, 680), (705, 706)], GREY, both=True)
    # mechanical motion into dampers
    b += carrow([(625, 630), (625, 476)], GREY, w=2.4)
    b += stxt(590, 600, "relative motion", 10, "#5E6878", "end")
    # power chain
    for x1, x2 in [(620, 600), (430, 410), (240, 220)]:
        b += carrow([(x1, 447), (x2, 447)], OR, w=2.4)
    b += carrow([(100, 476), (100, 508)], OR, w=2.4)
    b += carrow([(130, 418), (130, 378)], OR, w=2.4)
    b += stxt(136, 403, "power", 10, ORD, weight=600)
    # fail-safe link
    b += carrow([(722, 508), (722, 476)], GREY, dash="5 4")
    # control command
    b += carrow([(330, 378), (330, 400), (515, 400), (515, 418)], NAVY, w=2)
    b += stxt(340, 396, "current command i*", 10, NAVY, weight=600)
    # sensor data up
    b += carrow([(230, 508), (230, 378)], TEAL, dash="6 4")
    b += stxt(236, 497, "state · load · health", 10, TEALD, weight=600)
    # vehicle <-> logger, logger <-> network
    b += carrow([(370, 339), (390, 339)], TEAL, dash="6 4", both=True)
    b += carrow([(490, 300), (490, 260)], TEAL, dash="6 4", both=True)
    # train level
    b += carrow([(340, 227), (360, 227)], TEAL, dash="6 4", both=True)
    b += carrow([(590, 227), (610, 227)], TEAL, dash="6 4")
    b += carrow([(190, 260), (190, 300)], TEAL, w=2.2)
    b += stxt(196, 286, "bump preview ŵ", 10, TEALD, weight=600)
    # operations
    b += carrow([(150, 154), (150, 194)], TEAL, dash="6 4", both=True)
    b += stxt(156, 180, "track ahead", 10, TEALD, weight=600)
    b += carrow([(310, 194), (310, 154)], TEAL, dash="6 4")
    b += stxt(316, 180, "alerts", 10, TEALD, weight=600)
    b += carrow([(570, 194), (570, 154)], TEAL, dash="6 4")
    b += stxt(576, 180, "live status", 10, TEALD, weight=600)
    diagram = svg(830, 790, b)
    return f"""
<div class="page light">
  <div class="eyebrow dark">End-to-end architecture</div>
  <h2 style="width:780px">From a bump on the track to the control room.</h2>
  <div style="position:absolute;left:0;top:0">{diagram}</div>
  <div class="side">
    <div class="sbox"><div class="sh">Legend</div>
      <div class="lg"><i style="background:{OR}"></i>Power (harvested energy)</div>
      <div class="lg"><i class="dash" style="border-color:{TEAL}"></i>Data</div>
      <div class="lg"><i style="background:{TEAL}"></i>Bump preview</div>
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
    <div class="sbox"><div class="sh">Safety</div>
      <p class="sm">Fail-safe relay makes it a normal damper. Safety never depends on software. Tested to EN 50155 · EN 61373 · EN 50121.</p>
    </div>
  </div>
  <div class="foot">SwarmRide Bharat · system architecture<span>6 / 6</span></div>
</div>"""


CSS = f"""
@page {{ size: 297mm 210mm; margin: 0; }}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
body {{ font-family: 'IBM Plex Sans', Arial, sans-serif; color: #3D4A5C; -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
.page {{ width: 1123px; height: 794px; position: relative; overflow: hidden; page-break-after: always; background: {LIGHT}; }}
.page:last-child {{ page-break-after: auto; }}
.band {{ position:absolute; left:0; top:0; width:1123px; height:246px; background:{NAVY}; padding:28px 40px; color:#C9D3E0; }}
.eyebrow {{ font-size:11.5px; letter-spacing:3px; text-transform:uppercase; font-weight:600; color:{OR}; }}
.eyebrow.dark {{ position:absolute; left:40px; top:30px; color:{ORD}; }}
h1 {{ font-family:Rubik, Arial; font-weight:700; font-size:31px; color:{LIGHT}; margin-top:8px; }}
h2 {{ position:absolute; left:40px; top:46px; font-family:Rubik, Arial; font-weight:600; font-size:27px; color:{NAVY}; }}
.row2 {{ display:flex; gap:28px; margin-top:16px; }}
.what {{ width:390px; font-size:14px; line-height:1.5; }}
.what b {{ color:{LIGHT}; }}
.lbl {{ font-size:11px; letter-spacing:2.5px; text-transform:uppercase; font-weight:600; color:{OR}; margin-bottom:6px; }}
.chips {{ display:flex; align-items:center; gap:6px; }}
.chip {{ display:flex; gap:8px; align-items:flex-start; background:{NAVY2}; border-radius:10px; padding:10px 10px; width:142px; font-size:11.5px; line-height:1.35; }}
.chip b {{ color:{LIGHT}; font-size:13px; }}
.cn {{ flex:none; width:22px; height:22px; border-radius:50%; background:{OR}; color:#fff; font-weight:700; font-size:12px; text-align:center; line-height:22px; }}
.carr {{ color:{OR}; font-size:18px; font-weight:700; }}
.photo {{ position:absolute; border-radius:12px; overflow:hidden; background:#ddd; }}
.photo img {{ width:100%; height:100%; object-fit:cover; display:block; }}
.tag {{ position:absolute; left:12px; bottom:12px; background:rgba(19,35,58,0.86); color:#E8EDF3; font-size:12px; line-height:1.45; padding:8px 12px; border-radius:8px; }}
.tag b {{ color:{OR}; letter-spacing:1px; }}
.stats {{ position:absolute; left:40px; top:578px; width:1043px; display:flex; gap:14px; }}
.stat {{ flex:1; background:#FFFFFF; border-radius:12px; padding:12px 16px; box-shadow:0 1px 4px rgba(19,35,58,0.08); }}
.big {{ font-family:Rubik, Arial; font-weight:700; font-size:27px; color:{NAVY}; }}
.stat:first-child .big {{ color:{ORD}; }}
.lab {{ font-size:12.5px; color:{NAVY}; margin-top:2px; }}
.src {{ font-size:10px; color:#6B7685; margin-top:3px; }}
.msg {{ position:absolute; left:40px; top:700px; width:1043px; font-family:Rubik, Arial; font-size:19px; font-weight:600; color:{NAVY}; }}
.msg span {{ color:{ORD}; }}
.foot {{ position:absolute; left:40px; bottom:12px; width:1043px; font-size:9.5px; color:#6B7685; }}
.foot span {{ float:right; font-weight:600; }}
.legend {{ position:absolute; font-size:12.5px; line-height:1.45; color:{NAVY}; }}
.legend p {{ margin-bottom:6px; }}
.n {{ display:inline-block; width:19px; height:19px; border-radius:50%; background:{OR}; color:#fff; font-weight:700; font-size:11px; text-align:center; line-height:19px; margin-right:6px; }}
.pill {{ position:absolute; background:{NAVY}; color:{LIGHT}; font-family:Rubik, Arial; font-size:14px; font-weight:600; padding:9px 18px; border-radius:30px; }}
.sketch {{ position:absolute; background:{PAPER}; border-radius:12px; border:1px solid #E4DCCB; overflow:hidden; }}
.cards {{ position:absolute; left:550px; top:108px; width:533px; display:grid; grid-template-columns:1fr 1fr; gap:16px; }}
.card {{ background:{PAPER}; border:1px solid #E4DCCB; border-radius:12px; padding:10px 10px 12px; height:284px; }}
.ct {{ font-family:Caveat, cursive; font-weight:700; font-size:27px; color:{NAVY}; }}
.cc {{ font-size:12px; line-height:1.4; color:{NAVY}; margin-top:6px; }}
.stitle {{ position:absolute; font-family:Rubik, Arial; font-size:17px; font-weight:600; color:{NAVY}; }}
.stitle.orange {{ color:{ORD}; }}
.col {{ position:absolute; top:102px; width:505px; }}
.ptitle {{ font-family:Rubik, Arial; font-size:19px; font-weight:700; color:{NAVY}; margin-bottom:8px; }}
.ptitle span {{ color:{ORD}; }}
.col ul {{ margin-top:10px; padding-left:18px; font-size:13px; line-height:1.6; color:{NAVY}; }}
.resrow {{ position:absolute; left:40px; top:512px; width:1043px; display:flex; gap:12px; }}
.res {{ flex:1; background:#FFFFFF; border-radius:10px; padding:9px 12px; text-align:center; box-shadow:0 1px 4px rgba(19,35,58,0.08); }}
.rt {{ font-size:10.5px; letter-spacing:1.5px; text-transform:uppercase; font-weight:600; color:#6B7685; }}
.rb {{ font-size:12.5px; color:#6B7685; margin-top:3px; }}
.ra {{ color:{OR}; font-weight:700; font-size:13px; }}
.rg {{ font-size:14px; font-weight:600; color:{TEALD}; }}
.road {{ position:absolute; left:40px; top:630px; width:1043px; display:flex; align-items:center; gap:8px; }}
.rs {{ flex:1; background:{NAVY}; color:{LIGHT}; font-size:12px; font-weight:600; padding:10px 12px; border-radius:10px; text-align:center; }}
.rs:first-child {{ background:{OR}; color:#fff; }}
.rarr {{ color:{OR}; font-weight:700; font-size:16px; }}
.side {{ position:absolute; left:842px; top:100px; width:250px; display:flex; flex-direction:column; gap:10px; }}
.sbox {{ background:#FFFFFF; border-radius:10px; padding:10px 14px; box-shadow:0 1px 4px rgba(19,35,58,0.08); font-size:11.5px; color:{NAVY}; line-height:1.5; }}
.sh {{ font-size:10.5px; letter-spacing:1.5px; text-transform:uppercase; font-weight:600; color:{ORD}; margin-bottom:4px; }}
.lg {{ display:flex; align-items:center; gap:8px; }}
.lg i {{ display:inline-block; width:26px; height:3px; }}
.lg i.dash {{ height:0; border-top:3px dashed; }}
.sbox ol {{ padding-left:18px; }}
.sbox .sm {{ font-size:10.5px; color:#3D4A5C; }}
"""


def main():
    import pages_v2
    pages = page1() + pages_v2.page2() + page3() + page4() + pages_v2.page5() + pages_v2.page6()
    html = f"""<!doctype html><html><head><meta charset="utf-8"><title>SwarmRide Bharat — Pitch</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Caveat:wght@500;700&family=IBM+Plex+Sans:wght@400;500;600&family=Rubik:wght@500;600;700&display=swap">
<style>{CSS}{pages_v2.EXTRA_CSS}</style></head><body>{pages}</body></html>"""
    out_html = HERE / "pitch.html"
    out_html.write_text(html, encoding="utf-8")
    pdf = HERE.parent / "SwarmRide_Bharat_Pitch.pdf"
    print_pdf(out_html, pdf)                  # waits until Edge has finished writing
    print("wrote", pdf)


if __name__ == "__main__":
    main()

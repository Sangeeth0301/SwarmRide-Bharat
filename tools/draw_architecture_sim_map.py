"""Draws images/architecture_sim_map.svg: the SwarmRide architecture, each box marked by how the
simulation covers it (Simulink / partly / ideal stand-in / MATLAB offline / not simulated).
Run from the repository root:  python tools/draw_architecture_sim_map.py   (PNG: render the SVG in a browser)
"""
import sys
from xml.sax.saxutils import escape

OUT = sys.argv[1] if len(sys.argv) > 1 else "images/architecture_sim_map.svg"
W, H = 1600, 1290

ST = {  # status: (fill, stroke, dash, pill fill, pill text, label)
    'SIM':  ('#F1FAF8', '#2A9D8F', '',      '#2A9D8F', '#FFFFFF', 'SIMULINK'),
    'PART': ('#F6FBFA', '#2A9D8F', '7 4',   '#BFE3DE', '#1F6F66', 'PARTLY SIMULATED'),
    'IDEAL':('#FFF9EC', '#D9A21B', '7 4',   '#F6D27A', '#6B4E00', 'IDEAL STAND-IN'),
    'OFF':  ('#F2F6FC', '#3A6FB0', '3 3',   '#3A6FB0', '#FFFFFF', 'MATLAB, AFTER THE RUN'),
    'NOT':  ('#F5F6F8', '#9AA3AE', '2 4',   '#D5DAE0', '#4A5568', 'NOT SIMULATED'),
}

out = []
def t(x, y, s, cls, anchor=None):
    a = f' text-anchor="{anchor}"' if anchor else ''
    out.append(f'<text x="{x}" y="{y}" class="{cls}"{a}>{escape(s)}</text>')

def box(x, y, w, h, st, title, arch, sim, new=False):
    f, s, d, pf, pt, lab = ST[st]
    da = f' stroke-dasharray="{d}"' if d else ''
    out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="{f}" stroke="{s}" stroke-width="2"{da}/>')
    pw = 7.0 * len(lab) + 16
    out.append(f'<rect x="{x+10}" y="{y+9}" width="{pw:.0f}" height="19" rx="9.5" fill="{pf}"/>')
    t(x + 18, y + 22.5, lab, 'pill" fill="' + pt)
    if new:
        out.append(f'<rect x="{x+w-56}" y="{y+9}" width="46" height="19" rx="9.5" fill="#E07A1F"/>')
        t(x + w - 33, y + 22.5, 'NEW', 'pill" fill="#FFFFFF', 'middle')
    t(x + 12, y + 48, title, 'bt')
    yy = y + 66
    for line in arch:
        t(x + 12, yy, line, 'bl'); yy += 16
    yy = y + h - 12 - 16 * (len(sim) - 1)
    out.append(f'<line x1="{x+12}" y1="{yy-19}" x2="{x+w-12}" y2="{yy-19}" stroke="{s}" stroke-opacity="0.35"/>')
    for i, line in enumerate(sim):
        t(x + 12, yy + 16 * i, ('Sim: ' if i == 0 else '') + line, 'sm')

def band(y, h, color, label):
    out.append(f'<rect x="20" y="{y}" width="{W-40}" height="{h}" rx="14" fill="{color}" fill-opacity="0.07" stroke="{color}" stroke-opacity="0.5"/>')
    t(40, y + 24, label, 'band" fill="' + color)

def arrow(x1, y1, x2, y2, color, dash='', mid='aO'):
    da = f' stroke-dasharray="{dash}"' if dash else ''
    out.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="2.4"{da} marker-end="url(#{mid})"/>')

# ---------------- title and legend ----------------
t(40, 46, 'SwarmRide Bharat · Architecture vs simulation', 'ttl')
t(40, 74, 'Every box of the system architecture, marked by how SwarmRide_Sim (Stages 1–4) covers it. Box text: the design above the line, what the simulation does below it.', 'sub')
lx = 40
for k in ['SIM', 'PART', 'IDEAL', 'OFF', 'NOT']:
    f, s, d, pf, pt, lab = ST[k]
    da = f' stroke-dasharray="{d}"' if d else ''
    out.append(f'<rect x="{lx}" y="94" width="34" height="20" rx="5" fill="{f}" stroke="{s}" stroke-width="2"{da}/>')
    desc = {'SIM': 'Simulink: in the model', 'PART': 'Partly: Simulink + bench model / firmware',
            'IDEAL': 'Ideal stand-in: a perfect value', 'OFF': 'MATLAB offline: after the run',
            'NOT': 'Not simulated'}[k]
    t(lx + 42, 109, desc, 'lg')
    lx += 42 + 6.4 * len(desc) + 30
out.append(f'<rect x="{lx}" y="94" width="46" height="19" rx="9.5" fill="#E07A1F"/>')
t(lx + 23, 107.5, 'NEW', 'pill" fill="#FFFFFF', 'middle')
t(lx + 54, 109, 'in the sim, missing from the old diagram', 'lg')

# ---------------- ① train level ----------------
band(134, 262, '#E07A1F', '① TRAIN LEVEL · TRAIN BRAIN (LOCOMOTIVE)   →  in the sim: the "Train Brain (track preview)" block')
bw, g, x0, y = 284, 25, 40, 170
B1 = [
    ('IDEAL', 'Speed & position', ['GPS + odometry: speed v and', 'position on the route'], ['Clock × v: constant, exact speed;', 'timing error ±20 ms tested (A5)']),
    ('NOT', 'Lead-bogie sensing', ['the loco meets every bump first', 'and measures it'], ['not modelled: the preview reads', 'the true rail from the track table']),
    ('IDEAL', 'Fleet track map', ['GPS-tagged track condition', '→ known bumps ahead'], ['perfect map: track table TR.w,', 'bad-spot list bad_x (C4)']),
    ('SIM', 'Bump-warning scheduler', ['coach n gets each bump', 'tₙ = dₙ / v later'], ['Train Brain block: 221 rail', 'samples, 1 s ahead, every 10 ms']),
    ('NOT', 'Loco pilot display', ['load · ride · bearings ·', 'parting · track defects'], ['not modelled (a screen,', 'no physics to simulate)']),
]
for i, b in enumerate(B1):
    box(x0 + i * (bw + g), y, bw, 168, *b)
out.append(f'<rect x="40" y="350" width="{W-80}" height="32" rx="8" fill="#F5F6F8" stroke="#9AA3AE" stroke-width="2" stroke-dasharray="2 4"/>')
t(W / 2, 371, 'TRAIN DATA BUS (TCMS Ethernet · wireless mesh) — NOT SIMULATED: every message arrives instantly and is never lost', 'busT', 'middle')

# ---------------- ② vehicle level ----------------
band(410, 262, '#2A9D8F', '② VEHICLE LEVEL · ONE CONTROLLER PER COACH   →  in the sim: the "SwarmRide Controller (LPV + preview)" block')
bw, g, y = 202, 18, 446
B2 = [
    ('IDEAL', 'Load estimate', ['air-spring pressure or', 'spring deflection → m̂'], ['fixed m̂ = m(1 + err);', '±10 % error tested (A6)'], False),
    ('IDEAL', 'Ride state', ['body accelerometers +', 'stroke sensors → states x'], ['true 8 states, sampled', 'every 10 ms; no Kalman'], True),
    ('SIM', 'LPV state feedback', ['LQR gains at 5 loads,', 'blended by m̂'], ['F* = −Kx(m̂)·x', '(C2, C3, C4)'], False),
    ('SIM', 'Preview feed-forward', ['acts before the bump', 'reaches this coach'], ['F* −= Kp(m̂)·p', '(C3, C4)'], False),
    ('SIM', 'Semi-active + push', ['c* = F*v/(v²+ε²), limited;', 'C4: push at bad spots'], ['Semi-active conversion', 'and Active windows blocks'], True),
    ('OFF', 'Health analytics', ['bearing temperature, wheel', 'defects, parting check'], ['sr_hot_axle, coil FFT;', 'parting not modelled'], False),
    ('NOT', 'Report to Train Brain', ['status, alerts and track', 'data every few seconds'], ['not modelled', '(no data bus)'], False),
]
for i, (st, ti, a, s, n) in enumerate(B2):
    box(40 + i * (bw + g), y, bw, 210, st, ti, a, s, n)
for i in range(1, 4):  # data flow: state -> LPV -> preview -> semi-active
    xa = 40 + i * (bw + g) + bw
    arrow(xa + 1, y + 105, xa + g - 2, y + 105, '#2A9D8F', mid='aT')

# ---------------- ③ bogie level ----------------
band(686, 438, '#13233A', '③ BOGIE LEVEL · SELF-POWERED BOGIE UNIT (×2 per coach)   →  in the sim: Track Input, Vehicle Plant, Smart Damper, Power Electronics, Power Bank, Bogie Loads, Fail-safe Relay')
bw, g, y = 236, 21, 722
B3 = [
    ('SIM', 'Track & wheels', ['rail irregularity,', 'out-of-round wheels'], ['Track Input (1,981 sines,', '2 km) + Wheel defect'], False),
    ('SIM', 'Coach & bogies', ['primary + secondary springs,', 'body bounce and pitch'], ['Vehicle Plant', '(half-coach, 4 DOF)'], True),
    ('SIM', 'Smart EM damper', ['e = Kₑ·v,  F = Kₑ·i,', 'plus oil/friction/inertance'], ['machine, current loop τᵢ,', 'passive part, relay switch'], False),
    ('SIM', 'Active rectifier', ['H-bridge, AC → DC;', 'current = damping'], ['efficiency (average) model;', 'switching: bench only'], False),
    ('SIM', 'DC-DC converter', ['raises the voltage to', 'charge the bank'], ['efficiency (average) model', 'in Power Electronics'], False),
    ('SIM', 'Power bank + supervisor', ['supercap + LiFePO4;', 'charge · support · dump'], ['energies, SOC, dump,', 'unserved load'], False),
]
for i, (st, ti, a, s, n) in enumerate(B3):
    box(40 + i * (bw + g), y, bw, 176, st, ti, a, s, n)
for i in range(5):  # energy chain
    xa = 40 + i * (bw + g) + bw
    arrow(xa + 1, y + 88, xa + g - 2, y + 88, '#E07A1F')
# C4 push: bank powers the damper as a motor
xb, xd = 40 + 5 * (bw + g) + bw / 2, 40 + 2 * (bw + g) + bw / 2
out.append(f'<path d="M{xb},{y+176} L{xb},{y+196} L{xd},{y+196} L{xd},{y+180}" fill="none" stroke="#E07A1F" stroke-width="2.4" stroke-dasharray="8 5" marker-end="url(#aO)"/>')
out.append(f'<rect x="{(xb+xd)/2-235}" y="{y+187}" width="470" height="18" fill="#EBEDF0"/>')
t((xb + xd) / 2, y + 200, 'C4 push: the bank powers the damper as a motor  (Simulink · NEW)', 'push', 'middle')

bw, g, y = 284, 25, 932
B4 = [
    ('IDEAL', 'Load sensing', ['air-spring pressure or', 'spring-deflection sensor'], ['no sensor model: controller', 'gets m̂ directly (see ②)'], False),
    ('OFF', 'Safety sensors', ['bearing temp · vibration ·', 'wheel impact · coupler'], ['power drawn: Simulink (Loads);', 'detection: sr_hot_axle, FFT'], False),
    ('PART', 'Bogie controller', ['current loop · supervisor ·', 'self-test · data logging'], ['current loop: Stage 4 + bench PI;', 'self-test, logs: C firmware only'], False),
    ('SIM', 'Fail-safe relay', ['fault or power lost → coil on', 'resistor = today\'s damper'], ['Fail-safe Relay: test fault or', 'bank low; verified (A4)'], False),
    ('SIM', 'Bogie loads', ['sensors · controller · radio ·', 'gate drivers'], ['Bogie Loads: 4 constants,', '8 W per bogie'], False),
]
for i, (st, ti, a, s, n) in enumerate(B4):
    box(40 + i * (bw + g), y, bw, 176, st, ti, a, s, n)

# ---------------- scope and score ----------------
y = 1140
out.append(f'<rect x="20" y="{y}" width="{W-40}" height="62" rx="12" fill="#13233A"/>')
t(40, y + 26, 'WHAT ONE SIMULATION RUN IS', 'scopeH')
t(40, y + 48, 'One half-coach (2 bogies) on 2 km of track at one constant speed. The 16-coach train and the all-day energy are scaled up afterwards in MATLAB (sr_journey), not simulated as a whole train.', 'scopeT')
y = 1214
out.append(f'<rect x="20" y="{y}" width="{W-40}" height="62" rx="12" fill="#FFF3E6" stroke="#E07A1F" stroke-width="2"/>')
t(40, y + 26, 'SCORE vs the old diagram (22 boxes): 11 in Simulink · 1 partly · 4 ideal stand-ins · 2 MATLAB offline · 4 not simulated', 'scoreH')
t(40, y + 48, 'Fixed: the LPV box used to show c* = 2ζ√(k·m) (now corrected in architecture.svg); the sim uses LQR gains blended by load. Added what the sim has: coach & bogie plant, ride-state input, semi-active conversion, C4 push.', 'scoreT')

css = """
.ttl{font-size:28px;font-weight:700;fill:#13233A}.sub{font-size:14.5px;fill:#5E6878}
.lg{font-size:13px;fill:#3D4A5C}.band{font-size:13px;font-weight:700;letter-spacing:1.2px}
.pill{font-size:10.5px;font-weight:700;letter-spacing:0.6px}
.bt{font-size:16px;font-weight:700;fill:#13233A}.bl{font-size:13px;fill:#4A5568}
.sm{font-size:12.5px;fill:#1F2A37;font-weight:600}.busT{font-size:13.5px;fill:#4A5568;font-weight:600}
.push{font-size:12.5px;fill:#A8520F;font-weight:700}
.scopeH{font-size:13px;font-weight:700;fill:#F0974A;letter-spacing:1.2px}.scopeT{font-size:14px;fill:#E4E8EE}
.scoreH{font-size:15px;font-weight:700;fill:#A8520F}.scoreT{font-size:14px;fill:#3D4A5C}
"""
mk = lambda i, c: f'<marker id="{i}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{c}"/></marker>'
svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
       f'font-family="\'Segoe UI\', Helvetica, Arial, sans-serif">\n<defs>{mk("aO", "#E07A1F")}{mk("aT", "#2A9D8F")}'
       f'<style>{css}</style></defs>\n<rect width="{W}" height="{H}" fill="#FBFBFC"/>\n' + '\n'.join(out) + '\n</svg>\n')
open(OUT, 'w', encoding='utf-8').write(svg)
print('wrote', OUT)

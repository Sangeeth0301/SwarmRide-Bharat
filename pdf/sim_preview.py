"""Preliminary SwarmRide results from a simplified half-coach model (Python stand-in for Simulink).

Same equations as the Complete Guide, Section 7. Assumed parameters (Guide, Section 8).
Every curve below comes from simulation; nothing is drawn by hand.
"""
import json
import math
from pathlib import Path

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from scipy.signal import welch

OUT = Path(__file__).resolve().parent / "results"
OUT.mkdir(exist_ok=True)

NAVY, OR, TEAL, GREY, GREY2 = "#13233A", "#E07A1F", "#2A9D8F", "#8A93A0", "#C9CED6"
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10, "axes.spines.top": False,
                     "axes.spines.right": False, "axes.grid": True, "grid.color": "#E6E2D8",
                     "grid.linewidth": 0.8, "axes.edgecolor": "#5E6878", "axes.titleweight": "bold",
                     "axes.titlesize": 11.5, "figure.dpi": 150})

P = dict(mt=40e3, I0=1.6e6, mbg=3e3, lb=7.5, ab=1.28, ks0=0.8e6, cs=40e3, kp=1.2e6, cp=15e3,
         Ke=200.0, Rc=0.5, cmin=2e3, eta=0.92)
DT = 2e-3
GOOD, POOR = 4.032e-7, 1.08e-6


def make_track(Av, seed=7, L=9000.0, dx=0.05):
    rng = np.random.default_rng(seed)
    Oc, Or = 0.8246, 0.0206
    Om = np.linspace(2 * math.pi / 100, 2 * math.pi / 1, 400)
    dOm = Om[1] - Om[0]
    S = Av * Oc ** 2 / ((Om ** 2 + Or ** 2) * (Om ** 2 + Oc ** 2))
    A = np.sqrt(2 * S * dOm)
    ph = rng.uniform(0, 2 * math.pi, Om.size)
    x = np.arange(0, L, dx)
    w = np.zeros_like(x)
    for a, o, p in zip(A, Om, ph):
        w += a * np.sin(o * x + p)
    return dx, w


def bump_track(L=2000.0, dx=0.05, depth=0.010, length=4.0, at=200.0):
    x = np.arange(0, L, dx)
    w = np.zeros_like(x)
    k = (x >= at) & (x <= at + length)
    w[k] = -depth * 0.5 * (1 - np.cos(2 * math.pi * (x[k] - at) / length))
    return dx, w


TRACKS = {}


def track(name):
    if name not in TRACKS:
        TRACKS[name] = {"good": lambda: make_track(GOOD), "poor": lambda: make_track(POOR),
                        "bump": bump_track}[name]()
    return TRACKS[name]


def simulate(ctrl, mload, v_kmh, trk, T=20.0, Ke=None, zeta=0.25, cfix=None, keep=False):
    """ctrl: 'passive' | 'fixed' (fixed-load harvester) | 'swarm'. Returns metrics (+ traces)."""
    Ke = Ke or P["Ke"]
    cmax = Ke ** 2 / P["Rc"]
    dx, w = track(trk)
    v = v_kmh / 3.6
    m = P["mt"] + mload
    I = P["I0"] * m / P["mt"]
    ks = P["ks0"] * m / P["mt"]
    kp, cp, mbg, lb, ab = P["kp"], P["cp"], P["mbg"], P["lb"], P["ab"]
    keff = 1 / (1 / (2 * ks) + 1 / (4 * kp))
    om = math.sqrt(keff / m)
    ctgt = min(max(2 * zeta * om * m / 2, P["cmin"]), cmax)
    dists = np.array([0, 2 * ab, 2 * lb, 2 * lb + 2 * ab])
    s0 = 150.0 if trk != "bump" else 120.0

    def wheel(t):
        s = s0 + v * t - dists
        i = np.clip((s / dx).astype(int), 1, w.size - 2)
        return w[i], (w[i + 1] - w[i - 1]) / (2 * dx) * v

    def f(y, t, c1, c2):
        z, th, z1, z2, zd, thd, z1d, z2d = y
        wv, wd = wheel(t)
        zs1, zs2 = z + lb * th, z - lb * th
        zs1d, zs2d = zd + lb * thd, zd - lb * thd
        S1 = ks * (zs1 - z1) + c1 * (zs1d - z1d)
        S2 = ks * (zs2 - z2) + c2 * (zs2d - z2d)
        zdd = -(S1 + S2) / m
        thdd = (-lb * S1 + lb * S2) / I
        z1dd = (S1 - kp * ((z1 - wv[0]) + (z1 - wv[1])) - cp * ((z1d - wd[0]) + (z1d - wd[1]))) / mbg
        z2dd = (S2 - kp * ((z2 - wv[2]) + (z2 - wv[3])) - cp * ((z2d - wd[2]) + (z2d - wd[3]))) / mbg
        return np.array([zd, thd, z1d, z2d, zdd, thdd, z1dd, z2dd]), zdd

    n = int(T / DT)
    y = np.zeros(8)
    acc = np.empty(n)
    pw = np.zeros(n)
    stroke = np.empty(n)
    cc = np.empty(n)
    fv_min = 0.0
    for k in range(n):
        t = k * DT
        z, th, z1, z2, zd, thd, z1d, z2d = y
        cs_ = []
        p_k = 0.0
        for sgn, zbd in ((1, z1d), (-1, z2d)):
            vb = zd + sgn * lb * thd
            vr = vb - zbd
            if ctrl == "passive":
                c = P["cs"]
            elif ctrl == "fixed":
                c = cfix
            else:
                F = ctgt * vb + 0.3 * ctgt * vr          # clipped skyhook + passive part
                c = P["cmin"] if abs(vr) < 1e-4 else min(max(F / vr, P["cmin"]), cmax)
            cs_.append(c)
            if ctrl != "passive":
                p_k += P["eta"] * c * vr * vr * (1 - c / cmax)
                fv_min = min(fv_min, c * vr * vr)          # F*v_rel, must never be < 0
        k1, a = f(y, t, *cs_)
        k2, _ = f(y + DT / 2 * k1, t + DT / 2, *cs_)
        k3, _ = f(y + DT / 2 * k2, t + DT / 2, *cs_)
        k4, _ = f(y + DT * k3, t + DT, *cs_)
        y = y + DT / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
        acc[k] = a
        pw[k] = p_k / 2                                    # per bogie
        stroke[k] = (y[0] + lb * y[1]) - y[2]
        cc[k] = cs_[0]
    skip = int(3 / DT)
    a = acc[skip:]
    res = dict(arms=float(np.sqrt(np.mean(a ** 2))), Wz=sperling(a, 1 / DT), P=float(pw[skip:].mean()),
               smax=float(np.abs(stroke[skip:]).max()), fvmin=fv_min, ctgt=ctgt, cmax=cmax)
    if keep:
        res.update(t=np.arange(n) * DT, a=acc, p=pw, c=cc)
    return res


def sperling(a, fs):
    a = a - a.mean()
    N = a.size
    A = np.abs(np.fft.rfft(a)) * 2 / N
    f = np.fft.rfftfreq(N, 1 / fs)
    k = (f >= 0.5) & (f <= 30)
    f, acm = f[k], A[k] * 100
    F = np.ones_like(f)
    F[f < 5.9] = 0.325 * f[f < 5.9] ** 2
    m = (f >= 5.9) & (f < 20)
    F[m] = 400 / f[m] ** 2
    Wi = 0.896 * (acm ** 3 * F / f) ** 0.1
    return float(np.sum(Wi ** 10) ** 0.1)


def save(fig, name):
    fig.tight_layout()
    fig.savefig(OUT / name, dpi=170, facecolor="white")
    plt.close(fig)


def main():
    R = {}
    CROWD, HALF = 15e3, 7.5e3
    loads = [0.0, HALF, CROWD]
    lnames = ["Empty", "Half", "Crowded"]

    # 1. single bump response (crowded, 130 km/h)
    b0 = simulate("passive", CROWD, 130, "bump", T=8, keep=True)
    b1 = simulate("swarm", CROWD, 130, "bump", T=8, keep=True)
    fig, ax = plt.subplots(figsize=(6.4, 3.2))
    ax.plot(b0["t"], b0["a"], color=GREY, lw=1.6, label="Fixed oil damper (today)")
    ax.plot(b1["t"], b1["a"], color=OR, lw=2.0, label="SwarmRide")
    ax.set_xlim(2.0, 7.5)
    ax.set_xlabel("time [s]"); ax.set_ylabel("body acceleration [m/s²]")
    ax.set_title("One 10 mm dip, crowded coach, 130 km/h")
    ax.legend(frameon=False, loc="upper right")
    save(fig, "r1_bump.png")
    R["bump_peak"] = [float(np.abs(b0["a"]).max()), float(np.abs(b1["a"]).max())]

    # 2 + 3. random poor track, crowded, 160 km/h: time trace and spectrum
    a0 = simulate("passive", CROWD, 160, "poor", T=60, keep=True)
    a1 = simulate("swarm", CROWD, 160, "poor", T=60, keep=True)
    fig, ax = plt.subplots(figsize=(6.4, 3.2))
    k = (a0["t"] > 20) & (a0["t"] < 30)
    ax.plot(a0["t"][k], a0["a"][k], color=GREY, lw=1.0, label=f"Fixed damper · RMS {a0['arms']:.3f}")
    ax.plot(a1["t"][k], a1["a"][k], color=OR, lw=1.2, label=f"SwarmRide · RMS {a1['arms']:.3f}")
    ax.set_xlabel("time [s]"); ax.set_ylabel("body acceleration [m/s²]")
    ax.set_title("Poor track, crowded coach, 160 km/h (10 s window)")
    ax.legend(frameon=False, loc="upper right", fontsize=9)
    save(fig, "r2_trace.png")
    fig, ax = plt.subplots(figsize=(6.4, 3.2))
    band = {}
    for r, col, lab, key in ((a0, GREY, "Fixed damper", "passive"), (a1, OR, "SwarmRide", "swarm")):
        f, Pxx = welch(r["a"][int(3 / DT):], fs=1 / DT, nperseg=8192)
        ax.plot(f, Pxx, color=col, lw=2, label=lab)
        df = f[1] - f[0]
        band[key] = {"low": float(np.sqrt(Pxx[(f >= 0.5) & (f <= 2)].sum() * df)),
                     "high": float(np.sqrt(Pxx[(f >= 6) & (f <= 30)].sum() * df))}
    ax.set_xlim(0.2, 4); ax.set_xlabel("frequency [Hz]"); ax.set_ylabel("PSD [(m/s²)²/Hz]")
    ax.set_title("Body-bounce band (0.5–2 Hz): what passengers feel most")
    ax.legend(frameon=False)
    save(fig, "r3_psd.png")
    R["band"] = band
    R["poor_crowd_160"] = {"passive": {k_: a0[k_] for k_ in ("arms", "Wz", "smax")},
                           "swarm": {k_: a1[k_] for k_ in ("arms", "Wz", "smax", "P", "fvmin")}}

    # 6. Pareto: comfort vs harvested power (poor track, crowded, 160 km/h)
    fixed_pts, swarm_pts = [], []
    for cf in [10e3, 20e3, 30e3, 40e3, 55e3, 70e3]:
        r = simulate("fixed", CROWD, 160, "poor", cfix=cf)
        fixed_pts.append((r["P"], r["arms"], cf))
    for z in [0.12, 0.18, 0.25, 0.35, 0.5]:
        r = simulate("swarm", CROWD, 160, "poor", zeta=z)
        swarm_pts.append((r["P"], r["arms"], z))
    p0 = simulate("passive", CROWD, 160, "poor")
    fig, ax = plt.subplots(figsize=(6.4, 3.4))
    fx = np.array(fixed_pts); sx = np.array(swarm_pts)
    ax.plot(fx[:, 0], fx[:, 1], "o-", color=GREY, lw=1.8, label="Fixed-load harvester (existing approach)")
    ax.plot(sx[:, 0], sx[:, 1], "o-", color=OR, lw=2.2, label="SwarmRide (load-adaptive, skyhook)")
    ax.scatter([0], [p0["arms"]], color=NAVY, zorder=5, label="Oil damper today (0 W)")
    ax.set_xlabel("harvested power per bogie [W]"); ax.set_ylabel("body acceleration RMS [m/s²]")
    ax.set_title("Comfort vs power (lower and further right is better)")
    ax.legend(frameon=False, fontsize=8.5)
    save(fig, "r6_pareto.png")
    R["pareto"] = {"fixed": fixed_pts, "swarm": swarm_pts, "passive": p0["arms"]}

    # 4. comfort at every load (poor track, 160): passive vs best-power fixed harvester vs SwarmRide
    best_fixed = max(fixed_pts, key=lambda t: t[0])[2]
    bars = {"Fixed oil damper": [], "Fixed-load harvester": [], "SwarmRide": []}
    for ml in loads:
        bars["Fixed oil damper"].append(simulate("passive", ml, 160, "poor"))
        bars["Fixed-load harvester"].append(simulate("fixed", ml, 160, "poor", cfix=best_fixed))
        bars["SwarmRide"].append(simulate("swarm", ml, 160, "poor"))
    fig, ax = plt.subplots(figsize=(6.4, 3.4))
    xs = np.arange(3); wbar = 0.26
    for i, (lab, col) in enumerate((("Fixed oil damper", GREY), ("Fixed-load harvester", GREY2), ("SwarmRide", OR))):
        vals = [r["arms"] for r in bars[lab]]
        ax.bar(xs + (i - 1) * wbar, vals, wbar, color=col, label=lab, edgecolor="white")
    for j in range(3):
        base = bars["Fixed oil damper"][j]["arms"]; sr = bars["SwarmRide"][j]["arms"]
        ax.text(xs[j] + wbar, sr + 0.004, f"−{100 * (1 - sr / base):.0f}%", ha="center", color=OR,
                fontweight="bold", fontsize=9)
    ax.set_xticks(xs, lnames); ax.set_ylabel("body acceleration RMS [m/s²]"); ax.set_ylim(0, 0.30)
    ax.set_title("Smoother ride at every passenger load (poor track, 160 km/h)")
    ax.legend(frameon=False, fontsize=8, loc="upper center", ncol=3)
    save(fig, "r4_loads.png")
    R["loads"] = {lab: [{k_: r[k_] for k_ in ("arms", "Wz", "P")} for r in rs] for lab, rs in bars.items()}

    # 5. damping ratio vs load (analytic, same model)
    ml = np.linspace(0, 15e3, 50)
    zf, zs = [], []
    for x_ in ml:
        m = P["mt"] + x_; ks = P["ks0"] * m / P["mt"]
        keff = 1 / (1 / (2 * ks) + 1 / (4 * P["kp"]))
        zf.append(2 * P["cs"] / (2 * math.sqrt(keff * m)))
        zs.append(0.25)
    fig, ax = plt.subplots(figsize=(6.4, 3.2))
    ax.plot(ml / 1e3, zf, color=GREY, lw=2, label="Fixed oil damper")
    ax.plot(ml / 1e3, zs, color=OR, lw=2.4, label="SwarmRide (damping follows load)")
    ax.set_xlabel("passenger load [t]"); ax.set_ylabel("damping ratio ζ")
    ax.set_ylim(0, 0.32); ax.set_title("Damping quality stays constant as passengers board")
    ax.legend(frameon=False, loc="lower left")
    save(fig, "r5_zeta.png")

    # 7. harvested power vs speed, two damper designs, two tracks (half load)
    speeds = [80, 110, 130, 160]
    E = {}
    for Ke in (200.0, 300.0):
        for trk in ("good", "poor"):
            E[(Ke, trk)] = [simulate("swarm", HALF, s, trk, Ke=Ke)["P"] for s in speeds]
    fig, ax = plt.subplots(figsize=(6.4, 3.4))
    ax.axhspan(5, 20, color=TEAL, alpha=0.10, lw=0)
    ax.text(82, 12.5, "electronics need: 5–20 W per bogie (estimate)", color="#1F6F66", fontsize=8.5)
    for (Ke, trk), col, ls in (((200.0, "good"), GREY, "--"), ((200.0, "poor"), GREY, "-"),
                               ((300.0, "good"), OR, "--"), ((300.0, "poor"), OR, "-")):
        ax.plot(speeds, E[(Ke, trk)], ls, color=col, lw=2, marker="o",
                label=f"Ke = {Ke:.0f} V/(m/s), {trk} track")
    ax.set_xlabel("speed [km/h]"); ax.set_ylabel("harvested power per bogie [W]")
    ax.set_title("Power grows with speed, roughness and damper design")
    ax.legend(frameon=False, fontsize=8.2, loc="upper left")
    save(fig, "r7_power.png")
    R["power"] = {f"Ke{int(k[0])}_{k[1]}": v_ for k, v_ in E.items()}

    # 8. power bank over a 12-minute trip (Ke = 300, half load), 5 W duty-cycled electronics
    segs = [("stop", 0, 60), ("poor", 110, 150), ("good", 130, 180), ("stop", 0, 60), ("poor", 160, 150),
            ("good", 160, 120)]
    Csc, Vmin, Vmax = 50.0, 24.0, 48.0
    E_full = 0.5 * Csc * (Vmax ** 2 - Vmin ** 2)
    E_now = 0.5 * E_full
    tt, soc, pin = [], [], []
    t0 = 0.0
    for trk, spd, dur in segs:
        if trk == "stop":
            pt = np.zeros(int(dur / DT))
        else:
            r = simulate("swarm", HALF, spd, trk, T=min(dur, 40) + 3, Ke=300.0, keep=True)
            base = r["p"][int(3 / DT):]
            reps = int(math.ceil(dur / (base.size * DT)))
            pt = np.tile(base, reps)[: int(dur / DT)]
        for k in range(0, pt.size, 50):
            seg = pt[k:k + 50]
            E_now = min(max(E_now + (seg.mean() - 5.0) * seg.size * DT, 0), E_full)
            tt.append((t0 + k * DT) / 60); soc.append(100 * E_now / E_full); pin.append(seg.mean())
        t0 += dur
    fig, ax = plt.subplots(figsize=(6.4, 3.2))
    ax.plot(tt, soc, color=TEAL, lw=2.2)
    ax.set_xlabel("trip time [min]"); ax.set_ylabel("power bank charge [%]")
    ax.set_ylim(0, 105)
    t_acc = 0
    for trk, spd, dur in segs:
        lab = "station" if trk == "stop" else f"{trk} {spd}"
        ax.text((t_acc + dur / 2) / 60, 6, lab, ha="center", fontsize=7.5, color="#5E6878")
        ax.axvline(t_acc / 60, color="#E6E2D8", lw=1)
        t_acc += dur
    ax.set_title("Bogie power bank over a 12-minute trip (5 W electronics)")
    save(fig, "r8_soc.png")
    R["soc_end"] = soc[-1]

    (OUT / "summary.json").write_text(json.dumps(R, indent=1, default=float))
    print(json.dumps({"band": R["band"], "bump_peak": R["bump_peak"], "poor_crowd_160": R["poor_crowd_160"],
                      "loads": R["loads"], "power": R["power"], "soc_end": R["soc_end"],
                      "best_fixed_c": best_fixed}, indent=1, default=float))


if __name__ == "__main__":
    main()

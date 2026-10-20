// SwarmRide Bharat — Control Systems Project Review deck (pptxgenjs, structured deck)
const pptxgen = require("pptxgenjs");
const path = require("path");
// Image paths in images.json are relative to the repository root.
const ROOT = path.resolve(__dirname, "..", "..");
const IMG = require("./images.json");
for (const k of Object.keys(IMG)) IMG[k].path = path.join(ROOT, IMG[k].path);
const OUT = process.argv[2] || path.join(ROOT, "presentation", "SwarmRide_Bharat_Project_Review.pptx");

const THEME = {
  name: "SwarmRide",
  headFontFace: "Calibri",
  bodyFontFace: "Calibri",
  colors: {
    dk1: "13233A", lt1: "FFFFFF", dk2: "1F2A37", lt2: "F7F5F0",
    accent1: "E07A1F", accent2: "2A9D8F", accent3: "1F6F66", accent4: "A8520F", accent5: "5E6878", accent6: "1E3557",
    hlink: "1F6F66", folHlink: "A8520F",
  },
};
// hex copies for hex-only options and readable code
const H = { navy: "13233A", navy2: "1E3557", ink: "1F2A37", body: "3D4A5C", muted: "6B7686", paper: "F7F5F0", card: "FDFCF9",
  line: "E3E0D6", orange: "E07A1F", orangeD: "A8520F", orangeL: "F0974A", teal: "2A9D8F", tealD: "1F6F66", tealL: "5FC4B6",
  ice: "E4E8EE", mist: "C9D3E2", sky: "DCE8F9", mint: "D6EFEA", peach: "FCE3CC", cream: "FFF4D6", red: "C0392B", white: "FFFFFF" };

const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE"; // 13.333 x 7.5 in
pres.title = "SwarmRide Bharat — Control Systems Project Review";
pres.author = "Jaganath, Niranjan, Kowshik, Sangeeth";
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
const C = pres.SchemeColor;

const W = 13.333, M = 0.6, CW = W - 2 * M;
const FOOT = "SwarmRide Bharat · Control Systems Project Review";

// ---------- layouts ----------
function contentLayout(name, bg, eyebrowColor, titleColor, footColor) {
  pres.defineSlideMaster({
    title: name,
    background: { color: bg },
    objects: [
      { placeholder: { options: { name: "eyebrow", type: "body", x: M, y: 0.42, w: CW, h: 0.34, fontSize: 12, bold: true, charSpacing: 3, color: eyebrowColor, margin: 0, valign: "middle" }, text: "" } },
      { placeholder: { options: { name: "title", type: "title", x: M, y: 0.78, w: CW, h: 0.78, fontSize: 30, bold: true, color: titleColor, margin: 0, valign: "top", align: "left" }, text: "" } },
      { text: { text: FOOT, options: { x: M, y: 7.02, w: 9, h: 0.3, fontSize: 10, color: footColor, margin: 0 } } },
    ],
    slideNumber: { x: 12.2, y: 7.02, w: 0.53, h: 0.3, fontSize: 10, color: footColor, align: "right" },
  });
}
contentLayout("LIGHT", H.paper, H.orangeD, H.navy, H.muted);
contentLayout("DARK", H.navy, H.orangeL, H.paper, "9AA8BC");
pres.defineSlideMaster({ title: "COVER", background: { color: H.navy }, objects: [] });
pres.defineSlideMaster({
  title: "ACCENT", background: { color: H.orange },
  objects: [{ text: { text: FOOT, options: { x: M, y: 7.02, w: 9, h: 0.3, fontSize: 10, color: H.navy, margin: 0 } } }],
  slideNumber: { x: 12.2, y: 7.02, w: 0.53, h: 0.3, fontSize: 10, color: H.navy, align: "right" },
});

// ---------- helpers ----------
let sec = "";
function section(title) { sec = title; pres.addSection({ title }); }
function slide(master, eyebrow, title) {
  const s = pres.addSlide({ masterName: master, sectionTitle: sec });
  if (eyebrow) s.addText(eyebrow.toUpperCase(), { placeholder: "eyebrow" });
  if (title) s.addText(title, { placeholder: "title" });
  return s;
}
// fit an image inside a box (contain), optionally on a white/paper frame
function pic(s, key, x, y, w, h, opts = {}) {
  const im = IMG[key];
  if (opts.frame) s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, fill: { color: opts.frame }, line: { color: H.line, width: 0.75 }, rectRadius: 0.08, objectName: key + " frame" });
  const pad = opts.frame ? 0.08 : 0;
  const bw = w - 2 * pad, bh = h - 2 * pad, r = Math.min(bw / im.w, bh / im.h);
  const iw = im.w * r, ih = im.h * r;
  s.addImage({ path: im.path, x: x + pad + (bw - iw) / 2, y: y + pad + (bh - ih) / 2, w: iw, h: ih, altText: opts.alt || key, objectName: key });
}
// cover-crop a photo into a box
function photo(s, key, x, y, w, h, alt, extra = {}) {
  const im = IMG[key];
  s.addImage({ path: im.path, x, y, w, h, sizing: { type: "cover", w, h }, altText: alt, objectName: key, ...extra });
}
function card(s, x, y, w, h, fill, line) {
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, fill: { color: fill }, line: line ? { color: line, width: 0.75 } : { type: "none" }, rectRadius: 0.1 });
}
function txt(s, text, x, y, w, h, o = {}) {
  s.addText(text, { x, y, w, h, isTextBox: true, margin: 0, valign: "top", fontSize: 15, color: H.body, ...o });
}
function stat(s, x, y, w, h, big, label, dark, bigColor) {
  card(s, x, y, w, h, dark ? H.navy : H.card, dark ? null : H.line);
  txt(s, big, x + 0.22, y + 0.16, w - 0.44, 0.62, { fontSize: 32, bold: true, color: bigColor || (dark ? H.orangeL : H.tealD), fontFace: THEME.headFontFace });
  txt(s, label, x + 0.22, y + 0.8, w - 0.44, h - 0.92, { fontSize: 14, color: dark ? H.ice : H.body });
}
function table(s, rows, x, y, w, colW, o = {}) {
  const head = rows[0].map((t) => ({ text: t, options: { bold: true, color: H.muted, fontSize: o.headSize || 12, fill: { color: H.paper } } }));
  const body = rows.slice(1).map((r, i) => r.map((t) => {
    const hl = o.highlight && o.highlight.includes(i);
    const bold = typeof t === "object" && t.b;
    return { text: typeof t === "object" ? t.t : t, options: { bold, fill: { color: hl ? (o.hlColor || "DCEFEA") : H.white } } };
  }));
  s.addTable([head, ...body], { x, y, w, colW, fontSize: o.size || 14, color: H.ink, fontFace: THEME.bodyFontFace,
    border: { type: "solid", color: H.line, pt: 0.75 }, margin: o.pad || [0.07, 0.1, 0.07, 0.1], valign: "middle", autoPage: false,
    ...(o.rowH ? { rowH: o.rowH } : {}) });
}
function arrow(s, x1, y1, x2, y2, color = H.navy, dash) {
  const flipH = x2 < x1, flipV = y2 < y1;
  s.addShape(pres.shapes.LINE, { x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.max(Math.abs(x2 - x1), 0.001), h: Math.max(Math.abs(y2 - y1), 0.001),
    flipH, flipV, line: { color, width: 2, endArrowType: "triangle", dashType: dash || "solid" } });
}
function seg(s, x1, y1, x2, y2, color = H.navy, dash) {
  s.addShape(pres.shapes.LINE, { x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.max(Math.abs(x2 - x1), 0.001), h: Math.max(Math.abs(y2 - y1), 0.001),
    flipH: x2 < x1, flipV: y2 < y1, line: { color, width: 2, dashType: dash || "solid" } });
}
function block(s, x, y, w, h, fill, line, lines) {
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, fill: { color: fill }, line: { color: line, width: 1.5 }, rectRadius: 0.06 });
  s.addText(lines.map((l, i) => ({ text: l.t, options: { bold: !!l.b, fontSize: l.size || 14, color: H.navy, fontFace: l.mono ? "Courier New" : THEME.bodyFontFace, breakLine: i < lines.length - 1 } })),
    { x, y, w, h, isTextBox: true, align: "center", valign: "middle", margin: 0.05 });
}
function sigma(s, cx, cy) {
  s.addShape(pres.shapes.OVAL, { x: cx - 0.28, y: cy - 0.28, w: 0.56, h: 0.56, fill: { color: H.card }, line: { color: H.navy, width: 2 } });
  txt(s, "Σ", cx - 0.28, cy - 0.28, 0.56, 0.56, { fontSize: 20, bold: true, color: H.navy, align: "center", valign: "middle" });
}

// ======================= 1. PROBLEM =======================
section("The problem");
{ // cover
  const s = pres.addSlide({ masterName: "COVER", sectionTitle: sec });
  photo(s, "vb", 8.2, 0, 5.133, 7.5, "Vande Bharat train at a platform", { transparency: 45 });
  txt(s, "CONTROL SYSTEMS · PROJECT REVIEW", M, 0.75, 7.6, 0.4, { fontSize: 14, bold: true, charSpacing: 3, color: H.orangeL });
  s.addText([{ text: "SwarmRide ", options: { color: H.paper } }, { text: "Bharat", options: { color: H.orangeL } }],
    { x: M, y: 1.2, w: 7.6, h: 1.2, isTextBox: true, margin: 0, fontSize: 60, bold: true, fontFace: THEME.headFontFace, valign: "top" });
  txt(s, "A self-powered, load-adaptive, train-synchronised suspension for Indian Railways — the damper that harvests energy, tunes the ride, and watches the bogie’s safety.",
    M, 2.5, 7.4, 1.3, { fontSize: 18, color: H.mist });
  const team = [["Jaganath", "CB.AI.U4AID24021"], ["Niranjan", "CB.AI.U4AID24035"], ["Kowshik", "CB.AI.U4AID24036"], ["Sangeeth", "CB.AI.U4AID24050"]];
  team.forEach(([n, r], i) => {
    const x = M + (i % 2) * 3.7, y = 4.25 + Math.floor(i / 2) * 1.05;
    card(s, x, y, 3.55, 0.9, H.navy2);
    txt(s, n, x + 0.25, y + 0.1, 3.1, 0.4, { fontSize: 18, bold: true, color: H.paper });
    txt(s, r, x + 0.25, y + 0.5, 3.1, 0.3, { fontSize: 13, color: "9FD9D0", fontFace: "Courier New" });
  });
  txt(s, "Amrita School of Artificial Intelligence, Coimbatore · Amrita Vishwa Vidyapeetham, India", M, 6.5, 7.6, 0.35, { fontSize: 13, color: H.mist });
  s.addNotes("Introduce the team and the one-line idea: today’s oil damper on every train bogie becomes a smart electromagnetic damper that makes its own power, tunes the ride to the live load, gets a bump warning from the locomotive, and powers safety sensors on the bogie.");
}
{ // problem stats
  const s = slide("DARK", "01 · The problem", "Today’s dampers waste energy, ride worse when the coach is full, and see nothing");
  const st = [["171", "derailments from poor track maintenance, 2017–21", "CAG Report 22 of 2022", H.orangeL],
    ["≈ 3 / day", "hot-axle cases, checked at only ~25 trackside sites", "Railway Board, 2025", H.orangeL],
    ["643", "train partings + 2,059 wagon detachments, 2018–19", "Seen only at the last wagon", H.orangeL],
    ["17–30%", "of damping lost as a fixed-damper coach fills up", "Our simulation, Stage 1", H.tealL],
    ["20–90 W", "per coach bogie burned as heat by today’s dampers", "≈ 210 W per loaded wagon bogie · Stage 1", H.tealL],
    ["0 W", "of electricity on goods wagons — so no sensors at all", "Indian Railways freight stock", H.tealL]];
  st.forEach(([big, lab, src, col], i) => {
    const w = (CW - 0.5) / 3, x = M + (i % 3) * (w + 0.25), y = 2.0 + Math.floor(i / 3) * 2.45;
    card(s, x, y, w, 2.2, H.navy2);
    txt(s, big, x + 0.3, y + 0.22, w - 0.6, 0.7, { fontSize: 36, bold: true, color: col });
    txt(s, lab, x + 0.3, y + 0.98, w - 0.6, 0.7, { fontSize: 15, color: H.ice });
    txt(s, src, x + 0.3, y + 1.72, w - 0.6, 0.35, { fontSize: 12, color: "9AA8BC" });
  });
  s.addNotes("Three safety gaps (track, bearings, couplings) and three engineering gaps (comfort falls with load, energy wasted, no power on wagons). One device can close all six.");
}
{ // today's bogie
  const s = slide("LIGHT", "01 · The problem", "Today’s bogie: a passive damper tuned for one load");
  const w = (CW - 0.4) / 3;
  [["casnub", "Casnub bogie of a BOXN goods wagon"], ["goods", "Indian goods train"], ["air", "LHB coach bogie air spring"]].forEach(([k, a], i) =>
    photo(s, k, M + i * (w + 0.2), 1.75, w, 2.0, a));
  const w2 = (CW - 0.3) / 2;
  pic(s, "zeta", M, 3.95, w2, 2.45, { frame: H.white, alt: "Damping ratio falls as load rises on LHB, Vande Bharat and ICF" });
  pic(s, "heat", M + w2 + 0.3, 3.95, w2, 2.45, { frame: H.white, alt: "Heat wasted by today's dampers per bogie" });
  txt(s, [{ text: "Comfort falls with load: ", options: { bold: true, color: H.navy } }, { text: "damping ratio 0.14 → 0.10 on LHB as passengers board." }], M, 6.5, w2, 0.4, { fontSize: 14 });
  txt(s, [{ text: "Energy thrown away: ", options: { bold: true, color: H.navy } }, { text: "64–73 W per LHB bogie, 214 W per loaded BOXN bogie." }], M + w2 + 0.3, 6.5, w2, 0.4, { fontSize: 14 });
  s.addNotes("Photos: the Casnub wagon bogie, a goods train and an LHB air spring. Our Stage 1 simulation of today’s trains shows the two engineering gaps: fixed dampers lose damping as load rises, and all suspension energy becomes heat.");
}

// ======================= 2. SOLUTION =======================
section("The solution");
{
  const s = slide("LIGHT", "02 · The solution", "One smart electromagnetic damper. Five jobs.");
  pic(s, "damper", M, 1.75, 6.4, 4.95, { frame: H.white, alt: "Smart damper concept: magnet stack moving through a fixed copper coil" });
  const jobs = [["1 · Harvest", "motion in a coil charges the power bank", "e = Ke · v"], ["2 · Control", "coil current sets damping, by load", "F = Ke · i,  c = Ke² / R"],
    ["3 · Preview", "the loco warns every coach ahead", "tₙ = dₙ / v"], ["4 · Protect", "the bank powers safety sensors", "P_harvest > P_sensors"],
    ["5 · Fail-safe", "a relay restores today’s damping", "c_failsafe = c_today"]];
  jobs.forEach(([h, d, eq], i) => {
    const x = 7.3, y = 1.75 + i * 1.0, w = W - M - 7.3;
    card(s, x, y, w, 0.9, H.card, H.line);
    txt(s, [{ text: h + " — ", options: { bold: true, color: H.navy } }, { text: d, options: { color: H.body } }], x + 0.2, y + 0.1, w - 0.4, 0.4, { fontSize: 15 });
    txt(s, eq, x + 0.2, y + 0.53, w - 0.4, 0.3, { fontSize: 13, color: H.orangeD, fontFace: "Courier New" });
  });
  s.addNotes("Same mounting points as today’s damper. A magnet moving through a coil makes electricity; the current drawn sets how firm the damper is. So one device harvests, controls the ride, powers sensors and fails safe.");
}
{
  const s = slide("LIGHT", "02 · The solution", "Train Brain: the loco warns every coach before the bump");
  pic(s, "preview", M, 1.75, 6.9, 4.95, { frame: H.white, alt: "The locomotive warns every coach; today's bogie compared with the SwarmRide bogie" });
  const x = 7.8, w = W - M - 7.8;
  txt(s, "The lead bogie feels every bump first. Coach n reaches the same spot after", x, 1.8, w, 0.7, { fontSize: 16 });
  card(s, x, 2.55, w, 0.8, H.card, H.line);
  txt(s, "tₙ = dₙ / v", x, 2.55, w, 0.8, { fontSize: 30, bold: true, color: H.navy, fontFace: "Courier New", align: "center", valign: "middle" });
  table(s, [["At 160 km/h", "Warning"], ["Coach 1", { t: "0.5 s", b: true }], ["Coach 5", { t: "2.6 s = 260 control steps", b: true }], ["Coach 10", { t: "5.3 s", b: true }]], x, 3.6, w, [w * 0.42, w * 0.58], { size: 15 });
  txt(s, "Tested robust to a ±20 ms late warning. The Train Brain also keeps a map of known bad spots for the push (C4).", x, 5.6, w, 1.0, { fontSize: 15 });
  s.addNotes("Distances: locomotive 20 m, LHB coach 23.5 m, measured to each coach’s front bogie. The controller runs at 100 Hz, so even coach 1 gets 50 steps to prepare.");
}

// ======================= 3. LITERATURE =======================
section("Literature review and base paper");
{
  const s = slide("LIGHT", "03 · Literature review", "Regenerative dampers: from cars to trains");
  table(s, [["Year", "Paper · venue", "Key idea", "SwarmRide adds"],
    ["2013", "Li, Zuo et al. · IEEE Trans. Vehicular Technology", "Energy-harvesting shock absorber, road tests (cars)", "Train suspension, control"],
    [{ t: "2022", b: true }, { t: "Hua, Cai, Zhu · IEEE Trans. Vehicular Technology — BASE PAPER", b: true }, "EM damper cum harvester, semi-active, high-speed train (lateral)", "Load scheduling, preview, push, power bank"],
    ["2024", "Dong et al. · J. Intell. Mater. Syst. Struct.", "Harvest potential on freight wagons: 33–960 W per absorber", "A controller that uses it"],
    ["2024", "Tao et al. · IEEE Trans. Transportation Electrification", "Energy harvesting for freight-train sensors", "Sensors powered by the damper"],
    ["2025", "Cheng et al. · IEEE Trans. Transportation Electrification", "Self-powered PMSM damper, economic MPC", "Railway duty, fail-safe"],
    ["2025", "Xia, Ning et al. · IEEE/ASME Trans. Mechatronics", "Supercapacitor-voltage control in an EM damper", "Full-day bank on a train"]],
    M, 1.8, CW, [0.75, 4.5, 3.75, CW - 9.0], { size: 13.5, highlight: [1], hlColor: "FCEBD9" });
  txt(s, "All six verified in Crossref · DOIs in the speaker notes", M, 6.55, CW, 0.3, { fontSize: 12, color: H.muted });
  s.addNotes("DOIs: 10.1109/TVT.2012.2229308 (Li, Zuo, Luhrs, Lin, Qin 2013); 10.1109/TVT.2022.3149265 (Hua, Cai, Zhu 2022, base paper); 10.1177/1045389X231200146 (Dong et al. 2024); 10.1109/TTE.2023.3314056 (Tao et al. 2024); 10.1109/TTE.2024.3481067 (Cheng et al. 2025); 10.1109/TMECH.2025.3582402 (Xia, Ning et al. 2025). The field moved from car shock absorbers (2013) to train suspensions (2022) and now to self-powered dampers with supercapacitor management (2025). No paper combines load-scheduled control, train-wide preview, active push, a full-day power bank and self-powered health sensing on Indian rolling stock — that is SwarmRide’s gap.");
}
{
  const s = slide("LIGHT", "03 · Base paper", "Hua, Cai & Zhu, IEEE Trans. Vehicular Technology 71(5), 2022");
  txt(s, "“Energy-Regenerative Semiactive Lateral Suspension Control in High-Speed Trains Using Electromagnetic Damper Cum Energy Harvester”",
    M, 1.62, CW, 0.5, { fontSize: 15, italic: true, color: H.body });
  const w = (CW - 0.3) / 2;
  card(s, M, 2.3, w, 4.45, H.card, H.line);
  txt(s, "What they did", M + 0.3, 2.5, w - 0.6, 0.45, { fontSize: 20, bold: true, color: H.navy });
  s.addText([
    "Full-scale EM damper cum harvester (EMDEH), tested in cyclic tests",
    "Damping tuned by the duty cycle of the harvesting circuit",
    "Semi-active tracking of an LQG target force",
    "Lateral secondary suspension, high-speed train, 200–350 km/h",
    "Beat passive and fixed-duty dampers on car-body vibration; harvested 25.89–153.19 W",
  ].map((t, i, a) => ({ text: t, options: { bullet: true, breakLine: i < a.length - 1 } })),
    { x: M + 0.3, y: 3.05, w: w - 0.6, h: 3.5, isTextBox: true, margin: 0, fontSize: 15, color: H.body, valign: "top", paraSpaceAfter: 8 });
  const x2 = M + w + 0.3;
  card(s, x2, 2.3, w, 4.45, H.navy);
  txt(s, "Where SwarmRide goes further", x2 + 0.3, 2.5, w - 0.6, 0.45, { fontSize: 20, bold: true, color: H.orangeL });
  s.addText([
    "Vertical ride on LHB, Vande Bharat, ICF and BOXN freight",
    "LPV gains scheduled on the measured load",
    "Train Brain preview shared along the train",
    "Active push (C4) from the bogie’s own bank",
    "Full-day power bank + self-powered health sensing",
    "Fail-safe, C firmware, bench design, 85 checks",
  ].map((t, i, a) => ({ text: t, options: { bullet: true, breakLine: i < a.length - 1 } })),
    { x: x2 + 0.3, y: 3.05, w: w - 0.6, h: 3.5, isTextBox: true, margin: 0, fontSize: 15, color: H.ice, valign: "top", paraSpaceAfter: 8 });
  s.addNotes("DOI 10.1109/TVT.2022.3149265, summary from the published abstract. Why this base paper: it is the IEEE Transactions paper closest to our idea — an electromagnetic damper on a train suspension that both controls vibration and harvests energy. Their controller is an LQG target force tracked semi-actively. We keep their core idea and extend it in five directions.");
}

// ======================= 4. ARCHITECTURE + CONTROL =======================
section("Architecture and control system design");
{
  const s = slide("LIGHT", "04 · Architecture", "Three levels: train, vehicle, self-powered bogie");
  pic(s, "arch", M, 1.75, 6.9, 4.95, { frame: H.white, alt: "SwarmRide end-to-end system architecture: Train Brain, vehicle controller, bogie unit" });
  const x = 7.8, w = W - M - 7.8;
  [["① Train Brain · locomotive", "Lead-bogie bump sensing, track map, timed warnings tₙ = dₙ / v", H.navy],
   ["② Vehicle controller · 100 Hz", "Load estimate, LPV-LQR + preview, push windows, health analytics", H.tealD],
   ["③ Bogie unit · self-powered", "Smart dampers, 10 kHz drive, supercap + LiFePO4, sensors, fail-safe relay", H.orangeD]].forEach(([h, d, col], i) => {
    const y = 1.75 + i * 1.45;
    card(s, x, y, w, 1.3, H.card, H.line);
    s.addShape(pres.shapes.OVAL, { x: x + 0.2, y: y + 0.25, w: 0.3, h: 0.3, fill: { color: col }, line: { type: "none" } });
    txt(s, h, x + 0.65, y + 0.18, w - 0.85, 0.42, { fontSize: 17, bold: true, color: H.navy });
    txt(s, d, x + 0.65, y + 0.62, w - 0.85, 0.62, { fontSize: 14 });
  });
  txt(s, "Energy stays on the bogie; only data travels along the train.", x, 6.2, w, 0.5, { fontSize: 15, bold: true, color: H.navy });
  s.addNotes("Walk the three levels top to bottom. The key architectural point versus the base paper: the harvested energy is stored and used on the bogie itself, so goods wagons with no electricity can run sensors.");
}
{
  const s = slide("LIGHT", "04 · Architecture", "On a real bogie: no new bogie, no new cables");
  const w = (CW - 0.3) / 2;
  photo(s, "casnub_ann", M, 1.75, w, 4.4, "Casnub bogie of a BOXN wagon annotated with SwarmRide components");
  pic(s, "bogies", M + w + 0.3, 1.75, w, 4.4, { frame: H.white, alt: "LHB, ICF and Casnub bogies with the smart damper swapped in" });
  txt(s, [{ text: "Casnub (BOXN wagon): ", options: { bold: true, color: H.navy } }, { text: "where each SwarmRide part goes" }], M, 6.3, w, 0.4, { fontSize: 15 });
  txt(s, [{ text: "LHB · ICF · Casnub: ", options: { bold: true, color: H.navy } }, { text: "one part swapped, same mounts" }], M + w + 0.3, 6.3, w, 0.4, { fontSize: 15 });
  s.addNotes("LHB and Vande Bharat: replaces the vertical secondary dampers beside the air springs; load from air-spring pressure. ICF: secondary dampers on the bolster springs. BOXN: beside or in place of the friction wedges, with a geared smart damper.");
}
{ // block diagram (native shapes, coordinates from a 1920 x 1080 grid)
  const s = slide("LIGHT", "05 · Control system design", "Closed-loop block diagram: two loops, one plant");
  const p = (v) => v / 144;
  txt(s, "Track w(t)", p(128), p(330), p(170), p(50), { fontSize: 14, bold: true, color: H.navy });
  block(s, p(300), p(300), p(260), p(110), H.sky, H.navy, [{ t: "Train Brain", b: true }, { t: "p = rail ahead", size: 13 }]);
  block(s, p(640), p(300), p(220), p(110), H.mint, H.tealD, [{ t: "Preview gain", b: true }, { t: "Kp(m)", mono: true }]);
  sigma(s, p(960), p(560));
  block(s, p(1060), p(500), p(280), p(120), H.peach, H.orangeD, [{ t: "Semi-active map", b: true }, { t: "+ C4 push → i*", size: 13 }]);
  sigma(s, p(1440), p(560));
  block(s, p(1540), p(480), p(252), p(160), H.cream, H.orangeD, [{ t: "PI current loop", b: true }, { t: "+ back-EMF FF", size: 13 }, { t: "coil: F = Ke·i", size: 13 }]);
  block(s, p(1380), p(740), p(412), p(140), H.sky, H.navy, [{ t: "Half-coach vehicle G(s)", b: true }, { t: "ẋ = A(m)x + B_F F + B_w w", mono: true, size: 13 }]);
  block(s, p(980), p(760), p(280), p(100), H.mint, H.tealD, [{ t: "State observer x̂", b: true }]);
  block(s, p(560), p(760), p(300), p(100), H.mint, H.tealD, [{ t: "LPV-LQR gain", b: true }, { t: "Kx(m)", mono: true }]);
  arrow(s, p(280), p(355), p(300), p(355));
  arrow(s, p(560), p(355), p(640), p(355));
  seg(s, p(860), p(355), p(960), p(355)); arrow(s, p(960), p(355), p(960), p(520));
  arrow(s, p(1000), p(560), p(1060), p(560));
  arrow(s, p(1340), p(560), p(1400), p(560));
  arrow(s, p(1480), p(560), p(1540), p(560));
  arrow(s, p(1680), p(640), p(1680), p(740));
  arrow(s, p(1380), p(810), p(1260), p(810));
  arrow(s, p(980), p(810), p(860), p(810));
  seg(s, p(710), p(760), p(710), p(560)); arrow(s, p(710), p(560), p(920), p(560));
  seg(s, p(1580), p(640), p(1580), p(690), H.orangeD, "dash"); seg(s, p(1580), p(690), p(1440), p(690), H.orangeD, "dash"); arrow(s, p(1440), p(690), p(1440), p(600), H.orangeD, "dash");
  [["−", 975, 470], ["−", 880, 565], ["−", 1450, 600]].forEach(([t, x, y]) => txt(s, t, p(x), p(y), p(40), p(40), { fontSize: 18, bold: true, color: H.red }));
  [["F*", 1005, 515], ["i*", 1345, 515], ["F_d", 1695, 672], ["x", 1300, 765]].forEach(([t, x, y]) => txt(s, t, p(x), p(y), p(70), p(40), { fontSize: 14, bold: true, color: H.navy }));
  txt(s, "i (meas.)", p(1460), p(700), p(130), p(36), { fontSize: 12, color: H.orangeD });
  card(s, p(128), p(445), p(540), p(270), H.navy);
  txt(s, [{ text: "Controllers used", options: { bold: true, color: H.orangeL, fontSize: 15, breakLine: true } },
    { text: "Outer: LPV-LQR state feedback + preview, 100 Hz", options: { breakLine: true } },
    { text: "F* = −Kx(m)·x − Kp(m)·p", options: { fontFace: "Courier New", breakLine: true } },
    { text: "Inner: PI current loop + back-EMF feed-forward, 10 kHz, τ = 0.5 ms" }],
    p(128) + 0.2, p(445) + 0.15, p(540) - 0.4, p(270) - 0.3, { fontSize: 13, color: H.ice, paraSpaceAfter: 4 });
  txt(s, "m = measured load (air-spring pressure) schedules both gains · dashed = inner current feedback", M, 6.55, CW, 0.3, { fontSize: 12, color: H.muted });
  s.addNotes("Outer loop: the state observer estimates body bounce, pitch and bogie motion; the LPV-LQR gain, blended between five load points by the measured load, gives the ideal force; the Train Brain preview adds a feed-forward term. The semi-active map turns F* into a damping command the damper can give (resist only), except inside a push window at a known bad spot (C4). Inner loop: a PI current controller with back-EMF feed-forward makes the coil current follow i* within 0.5 ms; the current is the force.");
}
{
  const s = slide("LIGHT", "05 · Control system design", "Control system architecture: two loops, self-powered, fail-safe");
  pic(s, "ctrl", M, 1.55, CW, 5.05, { frame: H.white, alt: "SwarmRide control system architecture: vehicle controller outer loop, damper drive inner loop, smart damper and vehicle, power, fail-safe and sensing" });
  txt(s, "Outer loop 100 Hz · inner current loop 10 kHz · harvested energy to the bogie bank · contactor falls back to today’s damper on a fault", M, 6.66, CW, 0.3, { fontSize: 12, color: H.muted });
  s.addNotes("Read it in three rows. Top, the vehicle controller (outer loop, 100 Hz): the track map and Train Brain give the preview feed-forward, the state feedback (LPV-LQR) uses the estimated coach state, and the load estimate schedules both gains. The force command goes through the semi-active conversion and the damping law, or, at a known bad spot, the push command; the C4 switch picks one, then the current limit. Middle, the damper drive (inner loop, 10 kHz): the PI current controller with back-EMF feed-forward, the voltage limit and the contactor drive the coil; the electromagnetic damper and the ball screw make the damper force on the half-coach vehicle, and the measured coil current is fed back. Bottom: harvested energy goes through the power electronics to the bogie's power bank; the fail-safe supervisor switches the contactor to the fail-safe resistors on a fault or a low bank; sensors and the state estimator close the outer loop. The Simulink version is SR_ControlDiagram.slx.");
}
{
  const s = slide("LIGHT", "05 · Control system design", "Controllers used: optimal, load-scheduled, with preview");
  table(s, [["Controller", "Control law", "Role"],
    ["C0 Oil damper", "Passive, fixed c = c_today", "Baseline"],
    ["C1 Fixed harvester", "One fixed damping setting", "Benchmark"],
    [{ t: "C2 LPV-LQR", b: true }, "LQR at 5 loads, gains blended by load m, Tc = 10 ms", "Core"],
    [{ t: "C3 + preview", b: true }, "States [x; p], 221 rail samples ahead and behind", "Full"],
    [{ t: "C4 + push", b: true }, "Coil motors inside a window at a known bad spot", "Stage 4"],
    [{ t: "Drive PI", b: true }, "Kp = L/τ, Ki = R/τ, τ = 0.5 ms, back-EMF FF, anti-windup", "10 kHz"]],
    M, 1.8, 7.3, [1.9, 4.1, 1.3], { size: 14, highlight: [2, 3, 4], rowH: 0.67 });
  const x = 8.2, w = W - M - 8.2;
  card(s, x, 1.8, w, 4.75, H.navy);
  txt(s, [{ text: "Optimal design (LQR)", options: { bold: true, color: H.orangeL, fontSize: 18, breakLine: true } },
    { text: " ", options: { breakLine: true } },
    { text: "J = Σ (a/a_ref)² + (d/s_ref)²", options: { fontFace: "Courier New", breakLine: true } },
    { text: "      + r_w·(F/F_ref)²", options: { fontFace: "Courier New", breakLine: true } },
    { text: " ", options: { breakLine: true } },
    { text: "F* = −Kx(m)·x − Kp(m)·p", options: { fontFace: "Courier New", breakLine: true } },
    { text: " ", options: { breakLine: true } },
    { text: "c* = F*·v / (v² + ε²)", options: { fontFace: "Courier New", breakLine: true } },
    { text: "c_floor ≤ c* ≤ c_cap", options: { fontFace: "Courier New", breakLine: true } },
    { text: " ", options: { breakLine: true } },
    { text: "Stable at every load: closed-loop spectral radius 0.979–0.981 (LHB, < 1)", options: { color: "BFD8D5" } }],
    x + 0.3, 2.05, w - 0.6, 4.3, { fontSize: 14, color: H.ice });
  txt(s, "a = body acceleration over both bogies · d = suspension stroke · F = damper force · m = measured load", M, 6.62, CW, 0.3, { fontSize: 12, color: H.muted });
  s.addNotes("The ladder of controllers proves each idea separately. C1 is the same kind of approach as the base paper’s fixed-duty-cycle damper. C2 is the optimal controller made load-adaptive (LPV). C3 adds the Train Brain preview, C4 the active push. The inner PI loop with back-EMF feed-forward cancels the coil’s own pole, so the current follows its reference as a first-order lag of 0.5 ms.");
}
{
  const s = slide("LIGHT", "05 · Implementation", "Built and run in MATLAB/Simulink R2024b");
  pic(s, "m4", M, 1.7, 7.1, 4.5, { frame: H.white, alt: "Simulink model SR_Stage4: track, Train Brain, controller, smart damper, power electronics, power bank, scopes" });
  txt(s, [{ text: "SR_Stage4: ", options: { bold: true, color: H.navy } }, { text: "track · Train Brain · controller · damper · bank · 8 live scopes" }], M, 6.3, 7.1, 0.4, { fontSize: 14 });
  const x = 7.95, w = W - M - 7.95;
  pic(s, "mctrl", x, 1.7, w, 1.55, { frame: H.white, alt: "Controller subsystem: LPV state feedback with preview, semi-active conversion, command smoothing" });
  txt(s, [{ text: "Controller: ", options: { bold: true, color: H.navy } }, { text: "LPV + preview, semi-active map" }], x, 3.32, w, 0.35, { fontSize: 14 });
  pic(s, "mbench", x, 3.8, w, 2.4, { frame: H.white, alt: "Simulink bench model SR_Bench: test rig, drive firmware, damper hardware, power electronics, bank, winding temperature" });
  txt(s, [{ text: "SR_Bench: ", options: { bold: true, color: H.navy } }, { text: "one damper on a test rig" }], x, 6.3, w, 0.4, { fontSize: 14 });
  s.addNotes("Every model is generated by a MATLAB script, so the whole project rebuilds from code. Half-coach 4-DOF model; same coach, same rail, only the damper changes. The test suite checks the model against hand calculations, an independent state-space model, energy conservation and step-size convergence: 85 of 85 checks pass.");
}

// ======================= 5. RESULTS =======================
section("Results");
{
  const s = slide("LIGHT", "06 · Results · ride comfort", "Better ride at every load, on every train");
  pic(s, "ride", M, 1.7, 7.6, 5.0, { frame: H.white, alt: "Sperling ride index against load for LHB, Vande Bharat, ICF and BOXN: today's damper, fixed harvester, SwarmRide LPV and LPV plus preview" });
  const x = 8.5, w = W - M - 8.5;
  stat(s, x, 1.7, w, 1.55, "−17%", "Sperling Wz, crowded LHB, 160 km/h · 1.844 → 1.528", true);
  stat(s, x, 3.42, w, 1.55, "−41%", "body vibration RMS · 0.174 → 0.103 m/s²", false);
  stat(s, x, 5.14, w, 1.55, "−16% · −23%", "Vande Bharat · loaded BOXN wagon", false);
  s.addNotes("Same coach, same rail, poor track; controller C3 (LPV-LQR + preview) against today’s damper. Today’s ride gets worse as passengers board, because a fixed damper is tuned for one load. SwarmRide’s line stays nearly flat. Lower Wz is more comfortable.");
}
{
  const s = slide("LIGHT", "06 · Results · comfort and power", "Each controller step buys comfort — and still makes power");
  table(s, [["Crowded LHB, rough track", "Wz", "RMS m/s²", "Stroke", "Bank"],
    ["C0 today’s damper", "1.844", "0.174", "25 mm", "0 W"],
    ["C1 fixed harvester", "1.639", "0.124", "12 mm", "37 W"],
    ["C2 LPV-LQR", "1.559", "0.109", "17 mm", "37 W"],
    [{ t: "C3 LPV + preview", b: true }, { t: "1.528", b: true }, { t: "0.103", b: true }, "16 mm", { t: "33 W", b: true }]],
    M, 1.85, 6.9, [2.5, 1.0, 1.2, 1.1, 1.1], { size: 15, highlight: [3] });
  pic(s, "cvp", 7.75, 1.75, W - M - 7.75, 3.9, { frame: H.white, alt: "Comfort against harvested power for fixed settings and SwarmRide controllers" });
  txt(s, "No fixed setting reaches C3 — the best fixed one stops at Wz 1.635.", 7.75, 5.75, W - M - 7.75, 0.6, { fontSize: 14 });
  card(s, M, 4.6, 6.9, 1.6, H.navy);
  txt(s, [{ text: "33 W into the bank against 8 W needed", options: { bold: true, color: H.orangeL, breakLine: true } }, { text: "by the bogie electronics — the bogie powers itself, with 25 W to spare.", options: { color: H.ice } }],
    M + 0.3, 4.8, 6.3, 1.2, { fontSize: 17 });
  txt(s, "C1 corresponds to the base paper’s fixed-duty-cycle harvester · design C damper · 160 km/h · poor track", M, 6.62, CW, 0.3, { fontSize: 12, color: H.muted });
  s.addNotes("This is the head-to-head ladder. C1, a fixed harvester, already beats today’s damper but only at one setting. The optimal LPV controller C2 does better at every load, and the preview C3 adds a little more. Power into the bank stays at 33–38 W per coach bogie across Vande Bharat and LHB.");
}
{
  const s = slide("LIGHT", "06 · Results · active push (C4)", "At a known bad spot, the damper pushes with its own energy");
  pic(s, "push", M, 1.7, CW, 3.35, { frame: H.white, alt: "Body acceleration at a track settlement and a short dip: today's damper, C3 resist only, C4 push" });
  const w = (CW - 0.5) / 3;
  stat(s, M, 5.2, w, 1.5, "−80%", "worst seat at a settlement: 0.97 → 0.76 (C3) → 0.20 m/s²", true);
  stat(s, M + w + 0.25, 5.2, w, 1.5, "0.1 Wh", "energy per push (345 J), peak 1.5 kW from the supercap", false);
  stat(s, M + 2 * (w + 0.25), 5.2, w, 1.5, "−67%", "at a short dip, for just 20 J", false);
  s.addNotes("Crowded LHB, 160 km/h. A semi-active damper (like the base paper’s) can only resist, so it cannot act before the motion starts — that is why the preview added only 1–2% in Stage 3. In Stage 4 the same H-bridge drives the coil as a motor for about a second around a known bad spot, using banked energy. The Train Brain warning finally pays off.");
}
{
  const s = slide("LIGHT", "06 · Results · a full day", "Self-powered through a whole day and night");
  pic(s, "day", M, 1.7, 7.2, 5.0, { frame: H.white, alt: "Battery state of charge over a full day for LHB, Vande Bharat, ICF and BOXN with three electronics strategies" });
  const x = 8.1, w = W - M - 8.1;
  table(s, [["Battery, 1 W sleep", "Start", "End"], ["LHB day", "60%", { t: "60%", b: true }], ["Vande Bharat", "60%", { t: "69%", b: true }], ["BOXN freight", "60%", { t: "80%", b: true }], ["ICF (slow)", "60%", "36%"]],
    x, 1.8, w, [w * 0.5, w * 0.25, w * 0.25], { size: 15 });
  txt(s, [{ text: "Electronics left on at 8 W through a 10 h night drain every vehicle to its 10% floor. " }, { text: "A 1 W sleep when parked fixes it", options: { bold: true, color: H.navy } }, { text: " — no load is ever left unpowered." }],
    x, 4.4, w, 2.0, { fontSize: 15 });
  s.addNotes("Journey simulator stepping the Simulink power-bank rules over 14–20 h, with power tables from Simulink. Honest finding: the slow ICF coach and all-smooth track still drain slowly, so they need a small top-up or a lower sensing rate. That is a design rule for the product, not a showstopper.");
}
{
  const s = slide("LIGHT", "06 · Results · self-powered safety sensing", "The damper is also a safety sensor");
  const w = (CW - 0.3) / 2;
  pic(s, "axle", M, 1.7, w, 3.2, { frame: H.white, alt: "Hot axle: bearing temperature rise and trackside checkpoint detection histogram" });
  pic(s, "wheel", M + w + 0.3, 1.7, w, 3.2, { frame: H.white, alt: "Wheel defect: coil-voltage spectrum and front versus rear bogie signal" });
  const w3 = (CW - 0.5) / 3;
  stat(s, M, 5.1, w3, 1.5, "10 s", "hot-axle alarm by the on-bogie sensor", true);
  stat(s, M + w3 + 0.25, 5.1, w3, 1.5, "82%", "of faults pass 180 °C before a trackside check", false);
  stat(s, M + 2 * (w3 + 0.25), 5.1, w3, 1.5, "×5 – ×204", "wheel-defect signal in the coil, located to the wheelset", false);
  s.addNotes("Hot axle: illustrative bearing model, checkpoints every 250 km. The danger window between the alarm temperature and failure is about 30 minutes, much shorter than the 2.5 h between trackside checkpoints. A sensor riding on the bogie, powered by the damper, is the only reliable way. Wheel: eccentric 0.5 mm and three-lobed 0.3 mm; the damper’s coil voltage already contains the wheel’s signature, so no extra sensor is needed.");
}
{
  const s = slide("LIGHT", "06 · Results · bench prototype (Stage 5)", "Ready for hardware: the bench model agrees");
  const w = (CW - 0.3) / 2;
  pic(s, "breplay", M, 1.7, w, 3.2, { frame: H.white, alt: "Bench model replaying the coach motion: damper force and power into the bank" });
  pic(s, "bfs", M + w + 0.3, 1.7, w, 3.2, { frame: H.white, alt: "Fail-safe test: force during the contactor change and damping after the fault" });
  const w4 = (CW - 0.6) / 4;
  stat(s, M, 5.1, w4, 1.5, "14.4 W", "into the bank on replayed track (coach model 14.5 W)", true);
  stat(s, M + (w4 + 0.2), 5.1, w4, 1.5, "17,500", "N s/m after a fault = today’s damper (20 ms gap)", false);
  stat(s, M + 2 * (w4 + 0.2), 5.1, w4, 1.5, "10 / 10", "C firmware = MATLAB, double and float", false);
  stat(s, M + 3 * (w4 + 0.2), 5.1, w4, 1.5, "85 / 85", "automatic verification checks pass", false);
  s.addNotes("Design-C damper: 48 V servo, 25 mm × 10 mm ball screw, 8 kN, 60 V / 46 A drive, 10 F supercap. The bench model adds everything the coach model idealised: a 10 kHz current loop with a voltage limit, inverter and DC-DC losses, a contactor that takes 20 ms, and winding heat. It still predicts the same power into the bank, and the fail-safe gives exactly today’s damping. The C firmware matches MATLAB on 2,700 test vectors.");
}

// ======================= 6. COMPARISON =======================
section("Base paper vs SwarmRide");
{
  const s = slide("LIGHT", "07 · Base paper vs SwarmRide", "Architecture: same core idea, five new capabilities");
  table(s, [["Aspect", "Base paper · Hua et al., IEEE TVT 2022", "SwarmRide (ours)"],
    ["Vehicle, axis", "High-speed train, lateral", "LHB, Vande Bharat, ICF, BOXN freight — vertical"],
    ["Damper drive", "Damping set by harvesting-circuit duty cycle", "Ball-screw servo + 4-quadrant H-bridge: current = force"],
    ["Controller", "LQG target force, semi-active tracking", { t: "LPV-LQR scheduled on measured load + 10 kHz PI loop", b: true }],
    ["Look-ahead", "—", { t: "Train Brain preview, 221 rail samples", b: true }],
    ["Active push", "No (semi-active, resist only)", { t: "Yes — C4 at known bad spots, from banked energy", b: true }],
    ["Energy use", "Harvested power reported", { t: "Bogie power bank, full-day self-powered", b: true }],
    ["Safety sensing", "—", { t: "Hot axle in 10 s, wheel defects in the coil signal", b: true }],
    ["Fail-safe", "—", "Hardware contactor → today’s damping"],
    ["Validation", "Prototype cyclic tests + simulation", "85 automated checks, bench model, C firmware"]],
    M, 1.75, CW, [2.1, 4.4, CW - 6.5], { size: 16, headSize: 13, highlight: [3, 4, 5, 6], rowH: 0.47 });
  txt(s, "“—” = not part of the base paper’s study as described in its published abstract (DOI 10.1109/TVT.2022.3149265)", M, 6.62, CW, 0.3, { fontSize: 12, color: H.muted });
  s.addNotes("We keep the base paper’s core idea — one electromagnetic device that both controls vibration and harvests energy on a train — and add the capabilities highlighted in teal: look-ahead, push, a power bank that actually runs the bogie, safety sensing, plus a hardware fail-safe and a verified firmware path to hardware.");
}
{
  const s = slide("LIGHT", "07 · Base paper vs SwarmRide", "Results side by side");
  table(s, [["Metric", "Base paper (lateral, high-speed train)", "SwarmRide (vertical, crowded LHB)"],
    ["Speed", "200–350 km/h", "160 km/h (LHB / Vande Bharat top speed)"],
    ["Ride", "Better than passive and fixed-duty dampers", { t: "Wz −17% (1.844 → 1.528), RMS −41%", b: true }],
    ["Bad spots", "Resist only", { t: "−80% worst seat at a settlement, for 0.1 Wh", b: true }],
    ["Power", "25.89–153.19 W (semi-active)", { t: "33–38 W per coach bogie; 55 W loaded wagon", b: true }],
    ["vs fixed harvester", "Fixed duty harvested more power", "Fixed (C1) Wz 1.639 at 37 W vs C3 1.528 at 33 W"],
    ["Load change", "One design load", { t: "Flat comfort: Wz 1.493 empty → 1.528 crowded", b: true }],
    ["Power use", "Not reported", "Bogie self-powered all day (1 W sleep when parked)"]],
    M, 1.75, CW, [2.3, 4.6, CW - 6.9], { size: 16, headSize: 13, rowH: 0.46 });
  card(s, M, 5.65, CW, 0.85, H.card, H.line);
  txt(s, [{ text: "The axis and speeds differ, so the two power figures are not like-for-like. " }, { text: "What is directly comparable is the capability: ", options: { bold: true, color: H.navy } }, { text: "ours adapts to load, looks ahead, can push, and uses its energy on the bogie." }],
    M + 0.25, 5.75, CW - 0.5, 0.7, { fontSize: 14, valign: "middle" });
  txt(s, "Base-paper values from its abstract · SwarmRide values from SwarmRide_Sim/results (Stages 3–4)", M, 6.62, CW, 0.3, { fontSize: 12, color: H.muted });
  s.addNotes("Be honest with the examiners: the base paper studies lateral ride at higher speeds, so their watts and ours are not a like-for-like contest. The comparison that matters is architectural, and our own controller ladder (C0 to C4) shows each new capability’s value on the same coach and rail.");
}
{
  const s = pres.addSlide({ masterName: "ACCENT", sectionTitle: sec });
  txt(s, "08 · WHY IT MATTERS", M, 0.75, CW, 0.4, { fontSize: 14, bold: true, charSpacing: 3, color: H.navy });
  txt(s, "Not a better damper. A self-powered, train-aware suspension.", M, 1.3, 11, 2.0, { fontSize: 44, bold: true, color: H.navy });
  const w = (CW - 0.6) / 4;
  [["Adapts", "Comfort stays flat from empty to crowded"], ["Anticipates", "The loco warns every coach, t = d / v"], ["Acts", "Pushes at bad spots: −80% jolt"], ["Protects", "Powers its own safety sensors, all day"]].forEach(([h, d], i) => {
    const x = M + i * (w + 0.2);
    card(s, x, 4.3, w, 2.1, H.navy);
    txt(s, h, x + 0.25, 4.5, w - 0.5, 0.55, { fontSize: 24, bold: true, color: H.orangeL });
    txt(s, d, x + 0.25, 5.15, w - 0.5, 1.1, { fontSize: 15, color: H.ice });
  });
  s.addNotes("This is the pitch line. One part swapped, same mounts, fail-safe to today’s damper. Freight wagons have no electricity today; SwarmRide makes every wagon self-powered and watched. Passenger coaches get a ride tuned to their load and to the bump ahead.");
}
{
  const s = slide("LIGHT", "08 · Roadmap", "Proven in simulation. Next: proven in metal.");
  const w = (CW - 0.6) / 4;
  [["DONE", "Simulation, Stages 1–4", "Gate A met: better ride at every load, self-powered all day", H.teal],
   ["DONE", "Bench design, Stage 5", "Ratings, bench model, C firmware, test plan T1–T10", H.teal],
   ["NEXT · 16 WEEKS", "Gate B: bench prototype", "One damper on a rig; ≈ ₹4.4–13.5 lakh (indicative)", H.orange],
   ["LATER", "Field run, RDSO, pilot", "Instrumented bogie; freight first, then Vande Bharat", "9AA8BC"]].forEach(([tag, h, d, col], i) => {
    const x = M + i * (w + 0.2);
    card(s, x, 1.8, w, 2.6, H.card, H.line);
    s.addShape(pres.shapes.OVAL, { x: x + 0.25, y: 2.05, w: 0.32, h: 0.32, fill: { color: col }, line: { type: "none" } });
    txt(s, tag, x + 0.7, 2.06, w - 0.9, 0.32, { fontSize: 12, bold: true, color: H.muted, valign: "middle" });
    txt(s, h, x + 0.25, 2.55, w - 0.5, 0.75, { fontSize: 18, bold: true, color: H.navy });
    txt(s, d, x + 0.25, 3.3, w - 0.5, 1.0, { fontSize: 14 });
  });
  const w2 = (CW - 0.3) / 2;
  card(s, M, 4.75, w2, 1.6, H.navy);
  txt(s, [{ text: "Honest limits: ", options: { bold: true, color: H.orangeL } }, { text: "vehicle parameters are estimates until RDSO data; vertical model only; hardware costs not yet quoted.", options: { color: H.ice } }], M + 0.3, 4.95, w2 - 0.6, 1.2, { fontSize: 15 });
  card(s, M + w2 + 0.3, 4.75, w2, 1.6, H.navy);
  txt(s, [{ text: "Urgent: ", options: { bold: true, color: H.orangeL } }, { text: "file a provisional patent — the repository is now public.", options: { color: H.ice } }], M + w2 + 0.6, 4.95, w2 - 0.6, 1.2, { fontSize: 15 });
  s.addNotes("Gate B criteria: tests T1–T8 within their bands, T9 under the trip temperature, and the hardware-in-the-loop run at least 10% better than today’s damper. Then a field run on one LHB bogie with RDSO.");
}
{
  const s = pres.addSlide({ masterName: "COVER", sectionTitle: sec });
  photo(s, "products", 7.8, 0, 5.533, 7.5, "SwarmRide Passenger and SwarmRide Freight concept", { transparency: 82 });
  txt(s, "THANK YOU · QUESTIONS", M, 0.75, 7, 0.4, { fontSize: 14, bold: true, charSpacing: 3, color: H.orangeL });
  txt(s, "Every bogie powers itself.", M, 1.3, 7, 1.8, { fontSize: 54, bold: true, color: H.paper });
  txt(s, "Tunes its own ride, watches its own safety — while the locomotive warns every coach of the bump ahead.", M, 3.2, 6.9, 1.2, { fontSize: 18, color: H.mist });
  txt(s, "Jaganath · Niranjan · Kowshik · Sangeeth", M, 5.2, 7, 0.45, { fontSize: 20, bold: true, color: H.paper });
  txt(s, "Website: sangeeth0301.github.io/SwarmRide-Bharat", M, 5.8, 7, 0.35, { fontSize: 14, color: H.mist });
  txt(s, "Code and data: github.com/Sangeeth0301/SwarmRide-Bharat", M, 6.2, 7, 0.35, { fontSize: 14, color: H.mist });
  s.addNotes("Close on the one-line promise and invite questions. The website and repository have every model, result, the firmware and the bench prototype package.");
}

(async () => {
  await pres.writeFile({ fileName: OUT });
  try {
    const { applyTheme } = require(process.env.PPTX_SKILL + "/scripts/apply_theme.js");
    await applyTheme(OUT, THEME);
  } catch (e) { console.log("theme step skipped:", e.message); }
  console.log("wrote", OUT);
})();

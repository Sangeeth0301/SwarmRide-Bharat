%% CHECK_BENCH  Bench prototype: requirements, model checks and the predicted bench test results.
%   A. Requirements: the duty of one damper in the vehicle simulation (LHB crowded, 160 km/h) and
%      the hardware ratings that follow (functions/bp_hardware.m); records the rig drive data
%   B. Bench model checks: same damper as the vehicle model when simplified the same way; energy
%      balance; back-EMF; time-step convergence
%   C. Predicted bench results (the numbers the lab test must reproduce): T1-T10
%   D. Hardware margins in the vehicle model: how much rotor inertia and friction the real damper
%      may have, and the bench current limit
%   Writes results/bench_report.txt, results/bench_results.mat, ../Bench_Prototype/expected_results.csv,
%   then runs plot_bench and bench_export.   Run from the SwarmRide_Sim folder: >> run scripts/check_bench

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'), ...
    fullfile(root, 'models'), fullfile(root, 'tests'));
resdir = fullfile(root, 'results');
m1 = 'SR_Stage1';  m3 = 'SR_Stage3';  m4 = 'SR_Stage4';  mb = 'SR_Bench';
for m = {m1, m3, m4, mb}, load_system(fullfile(root, 'models', [m{1} '.slx'])); end
fid = fopen(fullfile(resdir, 'bench_report.txt'), 'w');
say = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];

%% A. Requirements from the vehicle simulation
say('=== A. Duty of one damper in the vehicle simulation (LHB crowded, 160 km/h, design C) ===\n');
cases = {'poor', 'C3', 'poor'; 'good', 'C3', 'good'; 'settle', 'C4', 'settlement'};
DR = struct();  Ust = struct();
for k = 1:size(cases, 1)
    [o, P, D] = sr_run(m4, 'LHB', 'designType', 'C', 'ctrlMode', cases{k, 2}, 'trackType', cases{k, 3});
    t = o.az.Time;  nd = P.nd;
    v  = sr_sig(o, 'e_coil', t) / P.Ke;            % stroke speed of each bogie's dampers
    st = sr_sig(o, 'stroke', t);
    c  = sr_sig(o, 'ccmd', t) / nd;
    Fs = sr_sig(o, 'Fstar', t) / nd;
    ac = sr_sig(o, 'act', t);
    Fd = sr_sig(o, 'Fd', t) / nd;  ic = sr_sig(o, 'i_coil', t);
    pt = sr_sig(o, 'Pterm', t) / nd;  pd = sr_sig(o, 'Pdc', t) / nd;
    kk = t > 3;
    DR.(cases{k, 1}) = struct('t', single(t), 'x', single(st(1, :) - mean(st(1, :))), 'v', single(v(1, :)), ...
        'c', single(c(1, :)), 'F', single(Fs(1, :)), 'act', single(ac(1, :)), ...
        'Fd', single(Fd(1, :)), 'i', single(ic(1, :)), 'Pterm', single(pt(1, :)), 'Pdc', single(pd(1, :)));
    Ust.(cases{k, 1}) = struct('v_rms', rms(v(1, kk)), 'v_max', max(abs(v(:, kk)), [], 'all'), ...
        'F_rms', rms(Fd(1, kk)), 'F_max', max(abs(Fd(:, kk)), [], 'all'), 'i_rms', rms(ic(1, kk)), ...
        'i_max', max(abs(ic(:, kk)), [], 'all'), 'P_push', -min(pt(:, kk), [], 'all'), ...
        'stroke_max', max(abs(st(:, kk) - mean(st(:, kk), 2)), [], 'all'), 'Pterm', mean(pt(1, kk)), 'Pdc', mean(pd(1, kk)));
    u = Ust.(cases{k, 1});
    say('%-7s (%s): speed RMS %.3f / max %.3f m/s, force RMS %4.0f / max %4.0f N, current RMS %4.1f / max %4.1f A, stroke max %4.1f mm, into the bank %5.1f W, push max %4.0f W\n', ...
        cases{k, 1}, cases{k, 2}, u.v_rms, u.v_max, u.F_rms, u.F_max, u.i_rms, u.i_max, 1e3 * u.stroke_max, u.Pdc, u.P_push);
end
U = struct('v_rms', Ust.poor.v_rms, 'F_rms', Ust.poor.F_rms, 'i_rms', Ust.poor.i_rms, ...
    'v_max', max([Ust.poor.v_max Ust.good.v_max Ust.settle.v_max]), ...
    'F_max', max([Ust.poor.F_max Ust.good.F_max Ust.settle.F_max]), ...
    'i_max', max([Ust.poor.i_max Ust.good.i_max Ust.settle.i_max]), ...
    'P_push', Ust.settle.P_push, 'stroke_max', max([Ust.poor.stroke_max Ust.settle.stroke_max]));
save(fullfile(resdir, 'bench_drive.mat'), 'DR', 'U');
HW = bp_hardware(D, P, U);
say('\nHardware ratings for one damper (functions/bp_hardware.m):\n');
say('  Motor: 3-phase PM servo, Kt %.3f N m/A (%.3f N m/A rms), back-EMF %.1f V rms/1000 rpm line-to-line, R %.3f ohm line-to-line, L %.2f mH per phase\n', ...
    HW.Kt, HW.Kt_rms, HW.Ke_ll, HW.Rll, 1e3 * HW.Lph);
say('         torque %.1f N m continuous / %.1f N m peak, speed %.0f rpm at %.2f m/s, motor constant %.2f N m/sqrt(W)\n', ...
    HW.T_cont, HW.T_peak, HW.n_max, HW.v_design, HW.Km);
say('  Damper: force %.1f kN continuous / %.1f kN peak (simulated peak %.1f kN), stroke +-%.0f mm, ball screw %.0f mm x %.0f mm lead\n', ...
    HW.F_cont / 1e3, HW.F_peak / 1e3, U.F_max / 1e3, 500 * HW.stroke, 1e3 * HW.screw_d, 1e3 * HW.lead);
say('  Inertia budget: %.2g kg m^2 in total (simulation); a %.0f x %.0f mm steel screw takes %.2g, leaving %.2g for the rotor\n', ...
    HW.J_sim, 1e3 * HW.screw_d, 1e3 * HW.screw_L, HW.J_screw, HW.J_rotor_max);
say('  Drive: DC link %.0f V, %.0f V MOSFETs, current limit %.0f A (sim %.0f A), phase current %.1f A rms on rough track; controls braking up to %.2f m/s\n', ...
    HW.Vdc, HW.V_fet, HW.i_lim, D.imax, HW.i_ph_cont, HW.v_ctrl);
say('  Fail-safe: changeover contactor, 3 x %.2f ohm star resistors (pulse %.0f W each at %.1f m/s), drop-out %.0f ms\n', ...
    HW.R_fs_ph, HW.P_fs_pulse, HW.fs_v_peak, 1e3 * HW.t_contactor);
say('  Bank (per bogie): DC-DC %.0f W bidirectional, supercapacitor %d x %.0f F / 2.7 V cells = %.0f F, LiFePO4 %dS %d Ah\n\n', ...
    HW.P_dcdc, HW.sc_cells, HW.sc_cellF, HW.Csc, HW.bat_S, HW.bat_Ah);

%% B. Bench model checks
say('=== B. Bench model checks ===\n');
[ob, Bs] = bench_run(mb, 'replay_poor', 'simequiv');
tb = ob.F_lc.Time;  Fb = squeeze(ob.F_lc.Data);
Rv = DR.poor;  Fv = interp1(double(Rv.t), double(Rv.Fd), tb);
kb = tb > 3 & tb < tb(end) - 0.01;
dB1 = 100 * max(abs(Fb(kb) - Fv(kb))) / max(abs(Fv(kb)));
Pt_b = mean(squeeze(ob.Pterm.Data(kb)));
say('B1 Bench model simplified like the vehicle model vs the vehicle model (rough-track replay): force differs by %.2f %% of peak, terminal power %.2f vs %.2f W -> %s\n', ...
    dB1, Pt_b, Ust.poor.Pterm, pf(dB1 < 3 && abs(Pt_b - Ust.poor.Pterm) < 0.03 * Ust.poor.Pterm));
[o, Bs] = bench_run(mb, 'replay_poor', 'real');
EBb = bench_energy(o, Bs);
say('B2 Energy balance (rough-track replay, real hardware): residual %.4f %% of the rig work (%.0f J) -> %s\n', ...
    100 * EBb.rel, EBb.Emech, pf(abs(EBb.rel) < 0.005));
o2 = bench_run(mb, 'replay_poor', 'real', struct('Ts', 0.5e-4));
p1 = mean(squeeze(o.Pbank.Data(kb)));  p2 = mean(squeeze(o2.Pbank.Data(kb)));
say('B3 Time step 0.1 ms vs 0.05 ms: power into the bank %.3f vs %.3f W (%.2f %%) -> %s\n', p1, p2, 100 * abs(p1 - p2) / p2, pf(abs(p1 - p2) / p2 < 0.01));
[oe, Be] = bench_run(mb, 'emf', 'real');
T1 = test_emf(oe, Be);
say('B4 Back-EMF test recovers the machine constant: %.2f vs %.2f V s/m (%.2f %%) -> %s\n\n', T1.Ke, Be.Ke, 100 * (T1.Ke / Be.Ke - 1), pf(abs(T1.Ke / Be.Ke - 1) < 0.01));

%% C. Predicted bench results
say('=== C. Predicted bench results (real hardware model: what the lab should measure) ===\n');
R = struct();
R.T1 = T1;
say('T1 Back-EMF constant: %.1f V s/m, i.e. %.1f V rms / 1000 rpm line-to-line (open circuit, +-0.1 m/s)\n', T1.Ke, T1.Ke_ll);

[od, Bd] = bench_run(mb, 'damping', 'real');
R.T2 = test_damping(od, Bd);
for k = 1:numel(R.T2.c_cmd)
    say('T2/T3 Damping %3.0f %% of c_req: commanded %6.0f, measured %6.0f N s/m (%+.1f %%); coil efficiency %.3f (formula 1 - c/c_max = %.3f); rig work to bank %.3f\n', ...
        100 * R.T2.c_cmd(k) / Bd.c_req, R.T2.c_cmd(k), R.T2.c_fit(k), 100 * (R.T2.c_fit(k) / R.T2.c_cmd(k) - 1), ...
        R.T2.eta_coil(k), 1 - R.T2.c_cmd(k) / Bd.cmax, R.T2.eta_total(k));
end
say('      Friction fitted %.0f N (model %.0f N); inertance fitted %.0f kg (model %.0f kg)\n', R.T2.Fc_fit, Bd.Fc, R.T2.b_fit, Bd.b_in);

[os, Bst] = bench_run(mb, 'step', 'real');
R.T4 = test_step(os, Bst);
say('T4 Current loop: 63 %% rise time %.2f ms (designed %.2f ms); overshoot %.1f %%\n', 1e3 * R.T4.tau, 1e3 * Bst.tau_cl, R.T4.overshoot);

[ov, Bv] = bench_run(mb, 'vlimit', 'real');
R.T5 = test_vlimit(ov, Bv);
say('T5 Voltage limit at full design damping: the drive runs out of voltage at %.3f m/s (formula Umax / (Ke - Rc c / Ke) = %.3f m/s); simulated damper speeds stay below %.3f m/s\n', ...
    R.T5.v_sat, R.T5.v_formula, U.v_max);

[ofs, Bf] = bench_run(mb, 'failsafe', 'real');
R.T6 = test_failsafe(ofs, Bf);
say('T6 Fail-safe: damping before %.0f, after %.0f N s/m (today''s damper %.0f, %+.1f %%); %.0f ms with no electromagnetic force while the contactor moves; peak force in the change %.0f N (before %.0f N)\n', ...
    R.T6.c_before, R.T6.c_after, Bf.c_today, 100 * (R.T6.c_after / Bf.c_today - 1), 1e3 * R.T6.gap, R.T6.F_change, R.T6.F_before);

O = struct();
for rp = {'replay_poor', 'replay_good', 'replay_settle'}
    [orp, Br] = bench_run(mb, rp{1}, 'real');
    O.(rp{1}) = orp;
    key = strrep(rp{1}, 'replay_', '');
    R.(rp{1}) = test_replay(orp, Br, DR.(key));
    q = R.(rp{1});
    say('T7 %-13s: rig work %6.1f W, coil %5.1f W, inverter %4.2f W, DC-DC %4.2f W, into the bank %5.1f W (vehicle model %5.1f W, %+.1f %%); current %4.1f A rms / %4.1f A max; out of voltage %.2f %% of the time\n', ...
        rp{1}, q.Pmech, q.Pcu, q.Pinv, q.Pdcdc, q.Pbank, Ust.(key).Pdc, 100 * (q.Pbank / Ust.(key).Pdc - 1), q.i_rms, q.i_max, 100 * q.sat_frac);
end
q = R.replay_settle;
say('T8 Push at the settlement: %.0f W peak from the bank, %.0f J drawn; force follows the push command within %.1f %% (RMS of error / RMS of command)\n', ...
    q.Ppush, q.Epush, q.F_track);

R.T9 = test_thermal(R.replay_poor, R.replay_settle, Bv);
say('T9 Winding temperature: %.1f W average copper loss on rough track (with one settlement push a minute) -> %.1f C steady (ambient %.0f C, trip %.0f C); time constant %.0f min\n\n', ...
    R.T9.Pcu, R.T9.Tss, Bv.Tamb, Bv.T_trip, R.T9.tau_min);

%% D. Hardware margins in the vehicle model
say('=== D. Hardware margins (vehicle model, LHB crowded, poor track, 160 km/h, C3) ===\n');
MG = struct('what', {}, 'val', {}, 'Wz', {}, 'rms', {}, 'Pdc', {});
base = struct();
for J = [1.5e-4 3e-4 6e-4 1.2e-3]
    [o, P] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 'D_override', struct('J', J));
    MG(end+1) = mrec('J', J, o, P); %#ok<SAGROW>
end
for Fc = [300 600]
    [o, P] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 'D_override', struct('Fc', Fc));
    MG(end+1) = mrec('Fc', Fc, o, P); %#ok<SAGROW>
end
[o, P] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 'D_override', struct('F_rated', HW.F_peak));
MG(end+1) = mrec('F_rated', HW.F_peak, o, P);
[o, P] = sr_run(m4, 'LHB', 'designType', 'C', 'ctrlMode', 'C4', 'trackType', 'settlement', 'D_override', struct('F_rated', HW.F_peak));
r8 = squeeze(o.az.Data);  tt = o.az.Time;  k8 = tt > 0.3 & tt < 15;
MG(end+1) = struct('what', 'F_rated_settle', 'val', HW.F_peak, 'Wz', NaN, 'rms', max(abs(r8(:, k8)), [], 'all'), 'Pdc', NaN);
[o, P] = sr_run(m1, 'LHB');
r0 = squeeze(o.az.Data);  W0 = sr_sperling(r0(1, o.az.Time > 3), 1 / P.Ts);
Wb = MG(1).Wz;
for k = 1:numel(MG) - 1
    g = MG(k);
    say('%-8s = %8.3g: Wz %.3f (%+.1f %% vs design; today %.3f), body RMS %.4f m/s^2, into the bank %.1f W per bogie\n', ...
        g.what, g.val, g.Wz, 100 * (g.Wz / Wb - 1), W0, g.rms, g.Pdc);
end
say('F_rated  = %8.3g at the settlement with push (C4): worst seat %.3f m/s^2 (vehicle model with 15 kN: 0.196)\n', HW.F_peak, MG(end).rms);
Jv = [MG(strcmp({MG.what}, 'J')).val];  Wj = [MG(strcmp({MG.what}, 'J')).Wz];
R.J_limit = interp1(Wj, Jv, Wb * 1.02, 'linear', 'extrap');
say('Inertia that costs 2 %% of the ride gain at most: J <= %.2g kg m^2 (rotor + screw)\n\n', R.J_limit);

%% E. Save
fclose(fid);
g = @(o, n) single(squeeze(o.(n).Data));
TRc = struct();
TRc.damping  = struct('t', single(od.v.Time), 'v', g(od, 'v'), 'F', g(od, 'F_lc'), 'c', g(od, 'c'));
TRc.step     = struct('t', single(os.i.Time), 'i', g(os, 'i'), 'iref', g(os, 'iref'));
TRc.vlimit   = struct('t', single(ov.u.Time), 'v', g(ov, 'v'), 'u', g(ov, 'u'), 'sat', g(ov, 'sat'), 'i', g(ov, 'i'), 'iref', g(ov, 'iref'));
TRc.failsafe = struct('t', single(ofs.F_lc.Time), 'F', g(ofs, 'F_lc'), 'Fem', g(ofs, 'F_em'), 'mode', g(ofs, 'mode'), 'v', g(ofs, 'v'));
TRc.poor     = struct('t', single(O.replay_poor.F_lc.Time), 'F', g(O.replay_poor, 'F_lc'), 'Pbank', g(O.replay_poor, 'Pbank'), ...
    'Pmech', g(O.replay_poor, 'Pmech'), 'i', g(O.replay_poor, 'i'), 'Fveh', single(interp1(double(DR.poor.t), double(DR.poor.Fd), double(O.replay_poor.F_lc.Time))));
TRc.settle   = struct('t', single(O.replay_settle.F_lc.Time), 'Fem', g(O.replay_settle, 'F_em'), 'act', g(O.replay_settle, 'act'), ...
    'Pbank', g(O.replay_settle, 'Pbank'), 'Vsc', g(O.replay_settle, 'Vsc'), 'i', g(O.replay_settle, 'i'), ...
    'Fcmd', single(interp1(double(DR.settle.t), double(DR.settle.F), double(O.replay_settle.F_lc.Time))));
R.traces = TRc;
R.HW = HW;  R.U = U;  R.Ust = Ust;  R.MG = MG;  R.W0 = W0;  R.EB = EBb;  R.B1 = dB1;
save(fullfile(resdir, 'bench_results.mat'), 'R');
write_expected(fullfile(fileparts(root), 'Bench_Prototype', 'expected_results.csv'), R, Bd, Bf, Bst);
run(fullfile(root, 'scripts', 'plot_bench.m'));
run(fullfile(root, 'scripts', 'bench_export.m'));

%% helpers
function [o, BP] = bench_run(mdl, test, mode, ovr)
% one bench test; scenario variables go to the base workspace, where the model's InitFcn reads them
if nargin < 4, ovr = []; end
assignin('base', 'benchTest', test);
assignin('base', 'benchMode', mode);
assignin('base', 'BP_override', ovr);
evalin('base', 'clear D_override ctrlMode load_err preview_dt rw c_fix_override c_floor_frac bad_x bad_len act_window_s wheel_runout wheel_order');
o = sim(mdl, 'EnablePacing', 'off');
BP = evalin('base', 'BP');
assignin('base', 'BP_override', []);
end

function EB = bench_energy(o, BP)
% rig work = friction + copper + fail-safe + terminals + stored (rotor kinetic, coil magnetic);
% terminals = inverter + DC-DC + bank
E = squeeze(o.E.Data);  E = E(:, end);          % [Pmech Pfric Pcu Pfs Pterm Pinv Pdcdc Pbank]
v = squeeze(o.v.Data);  i = squeeze(o.i.Data);
dKE = 0.5 * BP.b_in * (v(end)^2 - v(1)^2) + 0.5 * BP.L * (i(end)^2 - i(1)^2);
res1 = E(1) - (E(2) + E(3) + E(4) + E(5) + dKE);
res2 = E(5) - (E(6) + E(7) + E(8));
EB = struct('Emech', E(1), 'res', res1 + res2, 'rel', (abs(res1) + abs(res2)) / sum(abs(E(1:5))));
end

function T = test_emf(o, BP)
v = squeeze(o.v.Data);  u = squeeze(o.u.Data);  k = abs(v) > 0.095;
T.Ke = sum(u(k) .* v(k)) / sum(v(k).^2);
T.Ke_ll = T.Ke * BP.lead / (2*pi) * sqrt(2) / sqrt(3) * 2*pi*1000/60;
end

function T = test_damping(o, BP)
t = o.F_lc.Time;  F = squeeze(o.F_lc.Data);  v = squeeze(o.v.Data);  c = squeeze(o.c.Data);
a = gradient(v, t);  E = squeeze(o.E.Data);
Pm = squeeze(o.Pmech.Data);  Pt = squeeze(o.Pterm.Data);  Fe = squeeze(o.F_em.Data);  Pb = squeeze(o.Pbank.Data);
[lev, ~, ic] = unique(round(c));  cnt = accumarray(ic, 1);
lev = lev(lev > 0 & cnt > 500);                      % the commanded levels (not the 1 ms ramps between them)
T.c_cmd = lev';  T.c_fit = 0 * T.c_cmd;  T.eta_coil = T.c_fit;  T.eta_total = T.c_fit;
Fcs = [];  bs = [];
for k = 1:numel(lev)
    sel = find(abs(c - lev(k)) < 1);
    sel = sel(t(sel) > t(sel(1)) + 0.5);             % let each level settle
    X = [v(sel), tanh(v(sel) / BP.veps), a(sel)];
    th = X \ F(sel);
    T.c_fit(k) = th(1);  Fcs(end+1) = th(2);  bs(end+1) = th(3); %#ok<AGROW>
    T.eta_coil(k) = trapz(t(sel), Pt(sel)) / trapz(t(sel), Fe(sel) .* v(sel));
    T.eta_total(k) = trapz(t(sel), Pb(sel)) / trapz(t(sel), Pm(sel));
end
T.Fc_fit = mean(Fcs);  T.b_fit = mean(bs);
end

function T = test_step(o, BP)
t = o.i.Time;  i = squeeze(o.i.Data);  t0 = 0.3;
k = t >= t0;  ti = t(k) - t0;  ii = i(k);
ifin = BP.c_req * 0.05 / BP.Ke;
T.tau = interp1(ii(1:find(ii > 0.9 * ifin, 1)), ti(1:find(ii > 0.9 * ifin, 1)), 0.632 * ifin);
T.overshoot = 100 * max(0, max(ii) / ifin - 1);
end

function T = test_vlimit(o, BP)
v = squeeze(o.v.Data);  s = squeeze(o.sat.Data);
k = find(s > 0.5, 1);
if isempty(k), T.v_sat = NaN; else, T.v_sat = abs(v(k)); end
T.v_formula = BP.Umax / (BP.Ke - BP.Rc * BP.c_req / BP.Ke);
end

function T = test_failsafe(o, BP)
t = o.F_lc.Time;  F = squeeze(o.F_lc.Data);  v = squeeze(o.v.Data);  Fe = squeeze(o.F_em.Data);
a = gradient(v, t);  fit = @(sel) [v(sel), tanh(v(sel) / BP.veps), a(sel)] \ F(sel);
b = fit(t > 1 & t < 5);  af = fit(t > 5.2);
T.c_before = b(1);  T.c_after = af(1);
k = t >= 5 & t < 5.1;
md = squeeze(o.mode.Data);
T.gap = sum(md(k) > 0.5 & md(k) < 1.5) * (t(2) - t(1));
T.F_change = max(abs(F(k)));  T.F_before = max(abs(F(t > 1 & t < 5)));
T.Fe_gap = max(abs(Fe(k & md > 0.5 & md < 1.5)));
end

function q = test_replay(o, BP, Rv)
t = o.F_lc.Time;  k = t > 3 & t < t(end) - 0.01;
g = @(n) squeeze(o.(n).Data);
Pm = g('Pmech');  Pc = g('Pcu');  Pb = g('Pbank');  i = g('i');  s = g('sat');  Fe = g('F_em');  act = g('act');
E = g('E');  T = t(end);
q.Pmech = mean(Pm(k));  q.Pcu = mean(Pc(k));  q.Pbank = mean(Pb(k));
q.Pinv = E(6, end) / T;  q.Pdcdc = E(7, end) / T;
q.i_rms = rms(i(k));  q.i_max = max(abs(i(k)));  q.sat_frac = mean(s(k) > 0.5);
q.Ppush = max(0, -min(Pb(k)));  q.Epush = -trapz(t(k), min(Pb(k), 0));
q.Pcu_t = Pc;  q.t = t;
q.Ecu_win = trapz(t, Pc .* (act > 0.5));          % copper energy inside the push windows [J]
Fc = interp1(double(Rv.t) - double(Rv.t(1)), double(Rv.F), t);
w = act > 0.5;
if any(w)
    q.F_track = 100 * rms(Fe(w) - Fc(w)) / rms(Fc(w));
else
    q.F_track = NaN;
end
end

function T = test_thermal(rp, rs, BP)
% average copper loss: rough-track running plus one settlement push a minute
T.Pcu = mean(rp.Pcu_t) + rs.Ecu_win / 60;
T.Tss = BP.Tamb + BP.Rth * T.Pcu;
T.tau_min = BP.Rth * BP.Cth / 60;
end

function r = mrec(what, val, o, P)
t = o.az.Time;  k = t > 3;  a = squeeze(o.az.Data);
pd = sr_sig(o, 'Pdc', t);
r = struct('what', what, 'val', val, 'Wz', sr_sperling(a(1, k), 1 / P.Ts), 'rms', sqrt(mean(a(1, k).^2)), ...
    'Pdc', mean(pd(:, k), 'all'));
end

function write_expected(f, R, Bd, Bf, Bst)
% the numbers the lab test must reproduce, with the acceptance band
rows = {
 'T1', 'Back-EMF constant', 'V s/m', R.T1.Ke, '+-5 %'
 'T1', 'Back-EMF line-to-line', 'V rms per 1000 rpm', R.T1.Ke_ll, '+-5 %'
 'T2', 'Measured / commanded damping at 60 % of c_req', '-', R.T2.c_fit(3) / R.T2.c_cmd(3), '0.95-1.05'
 'T2', 'Friction (screw + seals)', 'N', R.T2.Fc_fit, '<= 300'
 'T2', 'Inertance (rotor + screw)', 'kg', R.T2.b_fit, sprintf('<= %.0f', R.J_limit * (2*pi / Bd.lead)^2)
 'T3', 'Coil efficiency at 60 % of c_req', '-', R.T2.eta_coil(3), '>= 0.95 x predicted'
 'T3', 'Rig work to bank at 60 % of c_req', '-', R.T2.eta_total(3), '>= 0.90 x predicted'
 'T4', 'Current-loop 63 % rise time', 'ms', 1e3 * R.T4.tau, sprintf('<= %.1f', 2e3 * Bst.tau_cl)
 'T5', 'Speed where the drive runs out of voltage (full damping)', 'm/s', R.T5.v_sat, sprintf('>= %.2f', R.U.v_max)
 'T6', 'Damping after the fail-safe drops', 'N s/m', R.T6.c_after, sprintf('%.0f +-10 %%', Bf.c_today)
 'T6', 'Time with no electromagnetic force (contactor moving)', 'ms', 1e3 * R.T6.gap, '<= 30'
 'T7', 'Into the bank, rough-track replay', 'W', R.replay_poor.Pbank, '+-20 %'
 'T7', 'Into the bank, smooth-track replay', 'W', R.replay_good.Pbank, '+-20 %'
 'T8', 'Peak push power from the bank (settlement)', 'W', R.replay_settle.Ppush, '+-20 %'
 'T8', 'Push force tracking error (RMS)', '%', R.replay_settle.F_track, '<= 10'
 'T9', 'Steady winding temperature (rough track + pushes, 35 C ambient)', 'C', R.T9.Tss, sprintf('<= %.0f', R.HW.T_trip)
 };
fh = fopen(f, 'w');
fprintf(fh, 'test,quantity,unit,predicted,acceptance\n');
for k = 1:size(rows, 1)
    fprintf(fh, '%s,"%s",%s,%.4g,"%s"\n', rows{k, :});
end
fclose(fh);
end

function s = pf(ok)
if ok, s = 'PASS'; else, s = 'FAIL'; end
end

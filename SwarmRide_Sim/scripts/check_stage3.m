%% CHECK_STAGE3  Verification and head-to-head results of the SwarmRide controllers.
%   C0 today's damper (Stage 1 model)  |  C1 fixed-load harvester  |  C2 LPV load-adaptive
%   C3 LPV + Train Brain preview.  Smart damper design C (lead design).
%   A. Verification: stability of every LPV grid point, passivity, energy balance, fail-safe,
%      preview timing error +/-20 ms, load-estimate error +/-10 %
%   B. Head to head: 4 vehicles x empty/half/full load, poor track (+ good track at full load)
%   C. Single events (short dip, track settlement) and the comfort-vs-power trade-off
%   Figures: scripts/plot_stage3.m.   Run from the SwarmRide_Sim folder: >> run scripts/check_stage3

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'), ...
    fullfile(root, 'models'), fullfile(root, 'tests'));
resdir = fullfile(root, 'results');
m1 = 'SR_Stage1';  m3 = 'SR_Stage3';
load_system(fullfile(root, 'models', [m1 '.slx']));
load_system(fullfile(root, 'models', [m3 '.slx']));
fid = fopen(fullfile(resdir, 'stage3_report.txt'), 'w');
say = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
trains = {'LHB', 'VB', 'ICF', 'BOXN'};
ctrls  = {'C1', 'C2', 'C3'};
T0 = 3;

%% A. Verification (LHB, crowded, 160 km/h, poor track)
say('=== A. Verification: LHB coach, 12 t, 160 km/h, poor track, design C ===\n');
for tr = trains
    [~, CD] = design_for(tr{1});
    say('A1 %-4s LPV design: closed-loop spectral radius %.4f .. %.4f at %d load points -> %s\n', ...
        tr{1}, min(CD.rho), max(CD.rho), numel(CD.rho), pf(all(CD.rho < 1)));
end
[o3, P3] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', 'C3');
t = o3.az.Time;  k = t > T0;
pg = sr_sig(o3, 'Pgen', t);  cc = sr_sig(o3, 'ccmd', t);
say('A2 Passivity: smart damper never needs bank power (min Pgen %.2f W); command within 0..c_cap (%.0f..%.0f of %.0f N s/m) -> %s\n', ...
    min(pg(:, k), [], 'all'), min(cc, [], 'all'), max(cc, [], 'all'), P3.c_cap, ...
    pf(min(pg(:, k), [], 'all') > -2 && min(cc, [], 'all') > -1e-6 && max(cc, [], 'all') <= P3.c_cap * 1.0001));
EB = sr_energy_balance(o3, P3);
say('A3 Energy balance (C3): residual %.4f %% / %.4f %% -> %s\n', 100 * EB.rel, pf(all(abs(EB.rel) < 0.001)));
[of, Pf] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 't_fault', 15);
tf = of.az.Time;  aft = tf > 15.05;
Ff = squeeze(of.Fd.Data);  vf = squeeze(of.vrel.Data);  pt = sr_sig(of, 'Pterm', tf);
Fem = Ff(:, aft) - (Pf.nd * Pf.Fc) * tanh(vf(:, aft) / Pf.veps);              % remove screw friction
ca = sum(Fem .* vf(:, aft), 'all') / sum(vf(:, aft).^2, 'all');
say('A4 Fail-safe with C3 (fault at 15 s): damping after %.0f N s/m vs today %.0f (inertance aside); harvest after %.2f W -> %s\n', ...
    ca, Pf.c_today, max(abs(pt(:, aft)), [], 'all'), pf(abs(ca - Pf.c_today) / Pf.c_today < 0.05));
M3 = metrics3(o3, P3, T0);
[o2, P2] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', 'C2');  M2 = metrics3(o2, P2, T0);
for dt = [-0.02 0.02]
    [od, Pd] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 'preview_dt', dt);
    Md = metrics3(od, Pd, T0);
    say('A5 Preview timing error %+3.0f ms: Wz %.3f (C3 exact %.3f, C2 %.3f) -> %s\n', 1e3 * dt, Md.Wz, M3.Wz, M2.Wz, pf(Md.Wz < M2.Wz));
end
[o1, P1] = sr_run(m1, 'LHB');  M0 = metrics3(o1, P1, T0);
% at half load, so an error in either direction moves the gains (full load sits at the top of the grid)
[oh0, Ph0] = sr_run(m1, 'LHB', 'mload_t', 5.1);  Mh0 = metrics3(oh0, Ph0, T0);
[oh, Ph] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 'mload_t', 5.1, 'load_err', 0);  Mh = metrics3(oh, Ph, T0);
for le = [-0.10 0.10]
    [ol, Pl] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 'mload_t', 5.1, 'load_err', le);
    Ml = metrics3(ol, Pl, T0);
    say('A6 Load estimate %+3.0f %% (half load): Wz %.3f (exact estimate %.3f, today %.3f) -> %s\n', ...
        100 * le, Ml.Wz, Mh.Wz, Mh0.Wz, pf(Ml.Wz < Mh0.Wz));
end
say('\n');

%% B. Head to head
say('=== B. Head to head: design C, top speed (per bogie: power; ride at the centre and worst seat) ===\n');
say('%-5s %-5s %6s %-3s | %6s %6s %6s | %7s %8s %8s\n', 'train', 'track', 'load', 'C', 'Wz', 'Wzmax', 'RMS', 'stroke', 'P_bank', 'net');
R = struct('train', {}, 'track', {}, 'load', {}, 'ctrl', {}, 'M', {});
for tr = trains
    TB = sr_trains(tr{1});
    for trk = {'poor', 'good'}
        loads = TB.loads_t;
        if strcmp(trk{1}, 'good'), loads = max(TB.loads_t); end
        for mt = loads
            [o, P] = sr_run(m1, tr{1}, 'mload_t', mt, 'trackType', trk{1});
            M = metrics3(o, P, T0);  R(end+1) = struct('train', tr{1}, 'track', trk{1}, 'load', mt, 'ctrl', 'C0', 'M', M); %#ok<SAGROW>
            sayrow(say, R(end));
            for c = ctrls
                [o, P] = sr_run(m3, tr{1}, 'designType', 'C', 'ctrlMode', c{1}, 'mload_t', mt, 'trackType', trk{1});
                M = metrics3(o, P, T0);
                R(end+1) = struct('train', tr{1}, 'track', trk{1}, 'load', mt, 'ctrl', c{1}, 'M', M); %#ok<SAGROW>
                sayrow(say, R(end));
            end
        end
    end
end
say('(Wz = centre of the coach; Wzmax = worst of centre / over front bogie / over rear bogie; net = P_bank - 8 W)\n\n');

%% C. Single events and the comfort-vs-power trade-off (LHB, crowded)
say('=== C1. Single events, LHB crowded, 160 km/h ===\n');
B = struct('track', {}, 'ctrl', {}, 't', {}, 'az', {}, 'peak', {}, 'peakw', {}, 'rms', {});
for trk = {'bump', 'settlement'}
    [o, P] = sr_run(m1, 'LHB', 'trackType', trk{1});
    B(end+1) = bumprec(trk{1}, 'C0', o); %#ok<SAGROW>
    for c = ctrls
        [o, P] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', c{1}, 'trackType', trk{1});
        B(end+1) = bumprec(trk{1}, c{1}, o); %#ok<SAGROW>
    end
end
for b = 1:numel(B)
    say('%-10s %s: peak body acceleration %.3f (worst seat %.3f) m/s^2, RMS over the event %.4f m/s^2\n', ...
        B(b).track, B(b).ctrl, B(b).peak, B(b).peakw, B(b).rms);
end
say('\n=== C2. Comfort vs power (LHB crowded, poor track) ===\n');
PF = struct('ctrl', {}, 'x', {}, 'Wz', {}, 'P', {});
Pd = design_for('LHB');
for fr = [0.1 0.2 0.3 0.45 0.6 0.8]
    cfix = fr * Pd.cmax_emd;
    [o, P] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', 'C1', 'c_fix_override', cfix);
    M = metrics3(o, P, T0);  PF(end+1) = struct('ctrl', 'C1', 'x', cfix, 'Wz', M.Wz, 'P', M.Pdc); %#ok<SAGROW>
    say('C1 fixed c = %6.0f N s/m: Wz %.3f, P_bank %.1f W\n', cfix, M.Wz, M.Pdc);
end
for cf = [0.15 0.3 0.45 0.6 0.8]
    [o, P] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 'c_floor_frac', cf);
    M = metrics3(o, P, T0);  PF(end+1) = struct('ctrl', 'C3floor', 'x', cf, 'Wz', M.Wz, 'P', M.Pdc); %#ok<SAGROW>
    say('C3 damping floor %.2f x c_req: Wz %.3f, P_bank %.1f W, stroke %.1f mm\n', cf, M.Wz, M.Pdc, M.stroke);
end
for c = {'C2', 'C3'}
    for rwv = [0.1 0.3 1 3 10 30]
        [o, P] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', c{1}, 'rw', rwv);
        M = metrics3(o, P, T0);  PF(end+1) = struct('ctrl', c{1}, 'x', rwv, 'Wz', M.Wz, 'P', M.Pdc); %#ok<SAGROW>
        say('%s force weight %5.1f: Wz %.3f, P_bank %.1f W, stroke %.1f mm\n', c{1}, rwv, M.Wz, M.Pdc, M.stroke);
    end
end
fclose(fid);
save(fullfile(resdir, 'stage3_results.mat'), 'R', 'B', 'PF', 'M0', 'M2', 'M3');
run(fullfile(root, 'scripts', 'plot_stage3.m'));

%% helpers
function M = metrics3(o, P, t0)
% Ride at the centre and at the worst seat, stroke and power (per bogie, average of front and rear).
t = o.az.Time;  k = t > t0;
a = squeeze(o.az.Data);
W = arrayfun(@(r) sr_sperling(a(r, k), 1 / P.Ts), 1:3);
M.Wz = W(1);  M.Wzmax = max(W);  M.rms = sqrt(mean(a(1, k).^2));
st = squeeze(o.stroke.Data);  M.stroke = 1000 * max(abs(st(:, k)), [], 'all');
M.Pdc = 0;  M.Pnet = 0;
if any(strcmp(o.who, 'Pdc'))
    pd = sr_sig(o, 'Pdc', t);  pl = sr_sig(o, 'Pload', t);
    M.Pdc = mean(pd(:, k), 'all');  M.Pnet = M.Pdc - mean(pl(:, k), 'all');
end
end

function r = bumprec(trk, c, o)
% one event: 10 mm / 4 m dip (lead wheel at 1.1 s) or 20 mm / 20 m settlement (lead wheel at 3.4 s)
t = o.az.Time;  a = squeeze(o.az.Data);
k = t > 0.3 & t < 15;
r = struct('track', trk, 'ctrl', c, 't', t, 'az', a(1, :), 'peak', max(abs(a(1, k))), ...
    'peakw', max(abs(a(:, k)), [], 'all'), 'rms', sqrt(mean(a(1, k).^2)));
end

function sayrow(say, r)
M = r.M;
say('%-5s %-5s %5.1ft %-3s | %6.3f %6.3f %6.3f | %5.1fmm %7.1fW %+7.1fW\n', r.train, r.track, r.load, r.ctrl, ...
    M.Wz, M.Wzmax, M.rms, M.stroke, M.Pdc, M.Pnet);
end

function [P, CD] = design_for(trainType) %#ok<INUSD>
% Parameters and LPV design of one vehicle (full load, top speed, design C, C3) without a simulation.
designType = 'C'; ctrlMode = 'C3'; trackType = 'poor'; %#ok<NASGU>
sr_params;
sr_params_stage3;
end

function s = pf(ok)
if ok, s = 'PASS'; else, s = 'CHECK'; end
end

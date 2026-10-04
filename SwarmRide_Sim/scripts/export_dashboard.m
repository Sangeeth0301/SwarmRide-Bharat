%% EXPORT_DASHBOARD  Writes dashboard/data.js (the investor dashboard's data) from the saved results.
%   Needs results/stage3_results.mat, stage4_results.mat and verification_report.txt
%   (and results/bench_results.mat for the bench-prototype cards, if present).
%   Open dashboard/index.html in a browser afterwards (works offline from the file).

root = fileparts(fileparts(mfilename('fullpath')));
repo = fileparts(root);
resdir = fullfile(root, 'results');
S3 = load(fullfile(resdir, 'stage3_results.mat'));
S4 = load(fullfile(resdir, 'stage4_results.mat'));
trains = {'LHB', 'VB', 'ICF', 'BOXN'};
ctrls = {'C0', 'C1', 'C2', 'C3'};
r2 = @(x) round(x, 3);

D = struct();
D.meta.generated = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm'));
rep = fileread(fullfile(resdir, 'verification_report.txt'));
tok = regexp(rep, '(\d+) of (\d+) checks passed', 'tokens', 'once');
D.meta.checks = sprintf('%s of %s', tok{1}, tok{2});

%% ride and power per vehicle and load (Stage 3, poor track)
for i = 1:numel(trains)
    for c = 1:numel(ctrls)
        r = S3.R(strcmp({S3.R.train}, trains{i}) & strcmp({S3.R.track}, 'poor') & strcmp({S3.R.ctrl}, ctrls{c}));
        M = [r.M];
        D.ride.(trains{i}).loads = [r.load];
        D.ride.(trains{i}).(ctrls{c}) = r2([M.Wz]);
        D.worst.(trains{i}).(ctrls{c}) = r2([M.Wzmax]);
        D.rms.(trains{i}).(ctrls{c}) = r2([M.rms]);
        D.bank.(trains{i}).(ctrls{c}) = round([M.Pdc], 1);
    end
end

%% comfort vs power (LHB crowded)
for c = {'C1', 'C2', 'C3', 'C3floor'}
    p = S3.PF(strcmp({S3.PF.ctrl}, c{1}));
    [~, o] = sort([p.P]);  p = p(o);
    D.pareto.(c{1}) = [round([p.P]', 1), r2([p.Wz]')];
end
r0 = S3.R(strcmp({S3.R.train}, 'LHB') & strcmp({S3.R.track}, 'poor') & strcmp({S3.R.ctrl}, 'C0'));
D.pareto.C0 = [0, r2(r0(end).M.Wz)];

%% active push at bad spots (Stage 4)
for ev = {'settlement', 'bump'}
    e0 = S4.E(strcmp({S4.E.track}, ev{1}) & strcmp({S4.E.ctrl}, 'C0'));
    e3 = S4.E(strcmp({S4.E.track}, ev{1}) & strcmp({S4.E.ctrl}, 'C3'));
    e4 = S4.E(strcmp({S4.E.track}, ev{1}) & strcmp({S4.E.ctrl}, 'C4') & [S4.E.win] == 1);
    k = 1:10:numel(e0.t);                                    % every 10 ms
    D.events.(ev{1}).t = round(e0.t(k)', 2);
    D.events.(ev{1}).C0 = r2(e0.az(k));
    D.events.(ev{1}).C3 = r2(e3.az(k));
    D.events.(ev{1}).C4 = r2(e4.az(k));
    D.events.(ev{1}).peak = r2([e0.peakw e3.peakw e4.peakw]);
    D.events.(ev{1}).energyJ = round(e4.Epush);
end

%% journeys
for s = 1:numel(S4.JR)
    J = S4.JR(s).J;  Js = S4.JR(s).Js;  Jg = S4.JR(s).Jg;  k = 1:60:numel(J.t);    % every minute
    D.journey.(S4.JR(s).train) = struct('name', S4.JR(s).name, 't', round(J.t(k)', 3), ...
        'soc_on', round(100 * J.SOC(k)', 1), 'soc', round(100 * Js.SOC(k)', 1), 'soc_good', round(100 * Jg.SOC(k)', 1), ...
        'harvest', round(J.E_harvest), 'used_on', round(J.E_used), 'used', round(Js.E_used), ...
        'unserved_on', round(J.E_unserved, 1), 'unserved', round(Js.E_unserved, 1), 'unserved_good', round(Jg.E_unserved, 1));
end

%% hot axle
H = S4.H;  k = 1:30:numel(H.t);
[cnt, edges] = histcounts(min(H.track.T_detect, H.opt.T_fail + 20), 25);
D.hotaxle = struct('t', round(H.t(k)' / 60, 1), 'T', round(H.T(k)', 1), 'alarm', H.opt.T_alarm, 'fail', H.opt.T_fail, ...
    'self_T', round(H.self.T_detect), 'gap_h', round(H.track.gap_h, 1), 'p_missed', round(100 * H.track.p_missed), ...
    'median_delay_min', round(median(H.track.delay) / 60), 'hist_edges', round(edges, 1), 'hist_counts', cnt, ...
    'spacing_km', H.opt.spacing_km);

%% wheel defect
W = S4.W;  k = W(1).f >= 5 & W(1).f <= 55;
D.wheel = struct('f', round(W(1).f(k), 2), 'healthy', round(W(1).Ef(k), 4), 'ecc', round(W(2).Ef(k), 4), ...
    'lobe3', round(W(3).Ef(k), 4), 'fw', round([W.fw], 2), 'front', round([W.peak_f], 3), 'rear', round([W.peak_r], 3), ...
    'cases', {{W.case}});

%% bench prototype (Stage 5)
bf = fullfile(resdir, 'bench_results.mat');
if isfile(bf)
    B = load(bf);  B = B.R;  T = B.traces.poor;
    t = double(T.t);  dt = t(2) - t(1);  w = round(1 / dt);
    pb = movmean(double(T.Pbank), w);  pm = movmean(double(T.Pmech), w);
    k = find(t > 3, 1):round(0.25 / dt):numel(t);
    D.bench.replay = struct('t', round(t(k)', 2), 'Pbank', round(pb(k)', 1), 'Pmech', round(pm(k)', 1), ...
        'mean_bank', round(B.replay_poor.Pbank, 1), 'vehicle', round(B.Ust.poor.Pdc, 1), ...
        'mean_good', round(B.replay_good.Pbank, 1), 'vehicle_good', round(B.Ust.good.Pdc, 1));
    D.bench.pred = {
        {'T1', 'Machine constant', sprintf('%.1f V s/m', B.T1.Ke)}
        {'T2', 'Damping = command', sprintf('within %.1f %% (20-100 %% of c_req)', 100 * max(abs(B.T2.c_fit ./ B.T2.c_cmd - 1)))}
        {'T3', 'Rig work to the bank', sprintf('%.2f to %.2f', max(B.T2.eta_total), min(B.T2.eta_total))}
        {'T4', 'Current loop', sprintf('%.2f ms time constant', 1e3 * B.T4.tau)}
        {'T5', 'Controlled up to', sprintf('%.2f m/s (coach needs %.2f)', B.T5.v_sat, B.U.v_max)}
        {'T6', 'Fail-safe damping', sprintf('%.0f N s/m (today %.0f), %.0f ms gap', B.T6.c_after, B.HW.c_today, 1e3 * B.T6.gap)}
        {'T7', 'Into the bank, rough track', sprintf('%.1f W (vehicle model %.1f W)', B.replay_poor.Pbank, B.Ust.poor.Pdc)}
        {'T8', 'Push at a settlement', sprintf('%.0f W peak, %.0f J, %.1f %% tracking error', B.replay_settle.Ppush, B.replay_settle.Epush, B.replay_settle.F_track)}
        {'T9', 'Winding temperature', sprintf('%.0f C at 35 C ambient', B.T9.Tss)}
        };
    D.bench.hw = struct('motor', sprintf('%.2f N m/A rms, %.0f N m peak', B.HW.Kt_rms, B.HW.T_peak), ...
        'force', sprintf('%.0f kN peak', B.HW.F_peak / 1e3), 'drive', sprintf('%.0f V, %.0f A', B.HW.Vdc, B.HW.i_lim));
end

out = fullfile(repo, 'dashboard', 'data.js');
if ~isfolder(fileparts(out)), mkdir(fileparts(out)); end
fid = fopen(out, 'w');
fprintf(fid, '// Generated by SwarmRide_Sim/scripts/export_dashboard.m - do not edit by hand\nwindow.SR = %s;\n', jsonencode(D));
fclose(fid);
fprintf('Wrote %s\n', out);

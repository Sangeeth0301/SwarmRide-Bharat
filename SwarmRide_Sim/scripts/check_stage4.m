%% CHECK_STAGE4  Verification and results of Stage 4.
%   A. Verification: Stage 4 = Stage 3 when its new parts are off; journey bank model = Simulink bank;
%      energy balance with active pushes; C4 only acts inside its windows
%   B. Active push at known bad spots (C4) vs C3 and today's damper, with the energy it costs
%   C. Long journeys: power into the bank over a day (passenger) and a round trip (freight)
%   D. Health sensing: hot axle (on-bogie vs trackside) and an out-of-round wheel seen by the damper
%   Figures: scripts/plot_stage4.m.   Run from the SwarmRide_Sim folder: >> run scripts/check_stage4

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'), ...
    fullfile(root, 'models'), fullfile(root, 'tests'));
resdir = fullfile(root, 'results');
m1 = 'SR_Stage1';  m3 = 'SR_Stage3';  m4 = 'SR_Stage4';
for m = {m1, m3, m4}, load_system(fullfile(root, 'models', [m{1} '.slx'])); end
fid = fopen(fullfile(resdir, 'stage4_report.txt'), 'w');
say = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
T0 = 3;

%% A. Verification
say('=== A. Verification ===\n');
[o3, P3] = sr_run(m3, 'LHB', 'designType', 'C', 'ctrlMode', 'C3');
[o4, P4] = sr_run(m4, 'LHB', 'designType', 'C', 'ctrlMode', 'C3');
a3 = squeeze(o3.az.Data);  a4 = squeeze(o4.az.Data);
d = 100 * max(abs(a3(1, :) - a4(1, :))) / max(abs(a3(1, :)));
say('A1 Stage 4 with its new parts off reproduces Stage 3 (C3): difference %.2e %% of peak -> %s\n', d, pf(d < 1e-6));

t = o4.az.Time;  pd = sr_sig(o4, 'Pdc', t);  pl = sr_sig(o4, 'Pload', t);  vsc = squeeze(o4.Vsc.Data);
Esc = P4.Esc0;  SOC = P4.SOC0;
for k = 1:numel(t) - 1
    [Esc, SOC] = sr_bank_step(Esc, SOC, pd(1, k), pl(1, k), P4, t(k + 1) - t(k));
end
dv = abs(sqrt(2 * Esc / P4.Csc) - vsc(1, end));
say('A2 Journey bank model vs Simulink bank (same power, 30 s): supercap %.3f V vs %.3f V -> %s\n', ...
    sqrt(2 * Esc / P4.Csc), vsc(1, end), pf(dv < 0.02));

[oc, Pc] = sr_run(m4, 'LHB', 'designType', 'C', 'ctrlMode', 'C4', 'trackType', 'settlement');
EB = sr_energy_balance(oc, Pc);
tc = oc.az.Time;  un = sr_sig(oc, 'Punserved', tc);
say('A3 Energy balance with active pushes (C4, settlement): residual %.4f %% / %.4f %% of the energy that flowed (%.0f / %.0f J); loads always served (max unserved %.2f W) -> %s\n', ...
    100 * EB.rel_flow, EB.flow, max(un, [], 'all'), pf(all(abs(EB.rel_flow) < 0.01) && max(un, [], 'all') < 1e-9));

[o4p, P4p] = sr_run(m4, 'LHB', 'designType', 'C', 'ctrlMode', 'C4');           % poor track: no bad spots
a4p = squeeze(o4p.az.Data);
d4 = 100 * max(abs(a4p(1, :) - a3(1, :))) / max(abs(a3(1, :)));
say('A4 C4 acts only inside its windows (poor track, no known bad spots): differs from C3 by %.2e %% -> %s\n\n', d4, pf(d4 < 1e-6));

%% B. Active push at known bad spots (LHB crowded, 160 km/h)
say('=== B. Active push at known bad spots (LHB crowded, 160 km/h) ===\n');
E = struct('track', {}, 'ctrl', {}, 'win', {}, 't', {}, 'az', {}, 'peak', {}, 'peakw', {}, 'rms', {}, 'Epush', {}, 'Ppush', {});
for trk = {'settlement', 'bump'}
    [o, ~] = sr_run(m1, 'LHB', 'trackType', trk{1});
    E(end+1) = evrec(trk{1}, 'C0', 0, o); %#ok<SAGROW>
    [o, ~] = sr_run(m4, 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 'trackType', trk{1});
    E(end+1) = evrec(trk{1}, 'C3', 0, o); %#ok<SAGROW>
    for w = [0.5 1 2]
        [o, ~] = sr_run(m4, 'LHB', 'designType', 'C', 'ctrlMode', 'C4', 'trackType', trk{1}, 'act_window_s', w);
        E(end+1) = evrec(trk{1}, 'C4', w, o); %#ok<SAGROW>
    end
end
for e = 1:numel(E)
    say('%-10s %s window %3.1f s: peak %.3f (worst seat %.3f) m/s^2, RMS %.4f m/s^2, bank energy spent pushing %6.1f J (peak %5.0f W)\n', ...
        E(e).track, E(e).ctrl, E(e).win, E(e).peak, E(e).peakw, E(e).rms, E(e).Epush, E(e).Ppush);
end
say('\n');

%% C. Long journeys
say('=== C. Long journeys (power table from Stage 3, controller C3, design C) ===\n');
spec = struct('train', {'LHB', 'VB', 'ICF', 'BOXN'}, 'v', {[80 120 160], [80 120 160], [60 90 110], [50 75 100]}, ...
    'loads', {{'half', 5.1}, {'half', 3.8}, {'half', 7.5}, {'loaded', 67.25; 'empty', 0}});
PT = struct();
for s = 1:numel(spec)
    pt = struct('v', spec(s).v, 'load', spec(s).loads{1, 1});
    for L = 1:size(spec(s).loads, 1)
        for trk = {'good', 'poor'}
            pw = zeros(size(spec(s).v));
            for j = 1:numel(spec(s).v)
                [o, ~] = sr_run(m3, spec(s).train, 'designType', 'C', 'ctrlMode', 'C3', 'trackType', trk{1}, ...
                    'v_kmh', spec(s).v(j), 'mload_t', spec(s).loads{L, 2});
                tt = o.az.Time;  pdx = sr_sig(o, 'Pdc', tt);
                pw(j) = mean(pdx(:, tt > T0), 'all');
            end
            pt.(spec(s).loads{L, 1}).(trk{1}) = pw;
            say('%-4s %-6s %-4s: power into the bank %s W at %s km/h\n', spec(s).train, spec(s).loads{L, 1}, trk{1}, ...
                mat2str(round(pw, 1)), mat2str(spec(s).v));
        end
    end
    PT.(spec(s).train) = pt;
end
% Three cases per vehicle: electronics always on (8 W); standby (1 W after 5 min parked, wake on
% motion); standby on the same route with all-smooth track (the hardest case).
sb = struct('Pstandby', 1, 'standby_after', 5);
JR = struct('train', {}, 'name', {}, 'J', {}, 'Js', {}, 'Jg', {});
for s = 1:numel(spec)
    tr = spec(s).train;  TB = sr_trains(tr);
    P = params_for(tr);
    [route, name] = route_for(tr, TB);
    J  = sr_journey(route, PT.(tr), P, 1);
    Js = sr_journey(route, PT.(tr), P, 1, sb);
    Jg = sr_journey(all_good(route), PT.(tr), P, 1, sb);
    JR(end+1) = struct('train', tr, 'name', name, 'J', J, 'Js', Js, 'Jg', Jg); %#ok<SAGROW>
    say('%-4s %s, %.1f h (incl. %d h parked), harvested %.0f Wh:\n', tr, name, J.hours, 10, J.E_harvest);
    lines = {'always on (8 W)', J; 'standby when parked (1 W)', Js; 'standby, all-smooth track', Jg};
    for q = 1:size(lines, 1)
        Jq = lines{q, 2};
        say('     %-27s used %4.0f Wh, unserved %5.1f Wh; battery %.0f%% -> min %.0f%%, end %.0f%%\n', lines{q, 1}, ...
            Jq.E_used, Jq.E_unserved, 100 * P.SOC0, 100 * Jq.SOC_min, 100 * Jq.SOC_end);
    end
end
P = params_for('LHB');
say('Parked with no motion, a full bank (120 Wh battery + supercap) runs the %.0f W bogie electronics for about %.0f h\n\n', ...
    P.P_sens + P.P_mcu + P.P_radio + P.P_aux, (P.Ebat_Wh * (P.SOCmax - P.SOCmin)) / (P.P_sens + P.P_mcu + P.P_radio + P.P_aux));

%% D. Health sensing
say('=== D. Health sensing ===\n');
H = sr_hot_axle();
say('D1 Hot axle (illustrative): bearing reaches %d C %.0f min after the fault starts and %d C (failure risk) %.0f min after it\n', ...
    H.opt.T_alarm, H.t_alarm / 60, H.opt.T_fail, H.t_fail / 60);
say('   On-bogie sensor (self-powered, read every %d s): alarm within %d s, bearing at %.0f C\n', H.opt.ts, H.opt.ts, H.self.T_detect);
say('   Trackside checkpoints every %d km at %d km/h (one check every %.1f h): median delay %.0f min after %d C (%d C follows only %.0f min after it); %.0f%% of faults reach %d C before any check\n', ...
    H.opt.spacing_km, H.opt.v_kmh, H.track.gap_h, median(H.track.delay) / 60, H.opt.T_alarm, H.opt.T_fail, ...
    (H.t_fail - H.t_alarm) / 60, 100 * H.track.p_missed, H.opt.T_fail);

W = struct('case', {}, 'f', {}, 'Ef', {}, 'Er', {}, 'peak_f', {}, 'peak_r', {}, 'fw', {});
cases = {'healthy', 0, 1; 'eccentric 0.5 mm', 0.5e-3, 1; 'three-lobed 0.3 mm', 0.3e-3, 3};
for c = 1:size(cases, 1)
    [o, P] = sr_run(m4, 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 'wheel_runout', cases{c, 2}, 'wheel_order', cases{c, 3});
    tt = o.az.Time;  k = tt > T0;  ec = sr_sig(o, 'e_coil', tt);
    n = nnz(k);  fs = 1 / P.Ts;
    Ef = abs(fft(ec(1, k) - mean(ec(1, k)))) * 2 / n;  Er = abs(fft(ec(2, k) - mean(ec(2, k)))) * 2 / n;
    fax = (0:n - 1) * fs / n;
    fw = cases{c, 3} * P.v / (2 * pi * P.wheel_R);
    band = abs(fax - fw) < 0.3;
    W(end+1) = struct('case', cases{c, 1}, 'f', fax(fax <= 60), 'Ef', Ef(fax <= 60), 'Er', Er(fax <= 60), ...
        'peak_f', max(Ef(band)), 'peak_r', max(Er(band)), 'fw', fw); %#ok<SAGROW>
end
for c = 1:numel(W)
    base = W(1);  bandb = abs(base.f - W(c).fw) < 0.3;
    say('D2 %-20s: coil signal at %.1f Hz (wheel %s): front bogie %.3f V (healthy %.3f V, x%.0f), rear bogie %.3f V\n', ...
        W(c).case, W(c).fw, ifelse(c == 1, 'rotation', 'defect order'), W(c).peak_f, max(base.Ef(bandb)), ...
        W(c).peak_f / max(max(base.Ef(bandb)), eps), W(c).peak_r);
end
fclose(fid);
save(fullfile(resdir, 'stage4_results.mat'), 'E', 'JR', 'PT', 'H', 'W');
run(fullfile(root, 'scripts', 'plot_stage4.m'));

%% helpers
function r = evrec(trk, c, w, o)
t = o.az.Time;  a = squeeze(o.az.Data);  k = t > 0.3 & t < 15;
Ep = 0;  Pp = 0;
if any(strcmp(o.who, 'Pterm'))
    pt = sr_sig(o, 'Pterm', t);
    neg = min(pt, 0);                                % power drawn from the bank by pushing
    Ep = -trapz(t, sum(neg, 1));  Pp = -min(sum(neg, 1));
end
r = struct('track', trk, 'ctrl', c, 'win', w, 't', t, 'az', a(1, :), 'peak', max(abs(a(1, k))), ...
    'peakw', max(abs(a(:, k)), [], 'all'), 'rms', sqrt(mean(a(1, k).^2)), 'Epush', Ep, 'Ppush', Pp);
end

function P = params_for(trainType) %#ok<INUSD>
designType = 'C'; trackType = 'poor'; %#ok<NASGU>
sr_params;
end

function [route, name] = route_for(tr, TB)
% Representative days. Passenger: 10 legs of 50 km between stations (5 km approach, 40 km at top
% speed, 5 km approach), every third leg on poor track, 3 min stops, then 10 h stabled overnight.
% Freight: 300 km loaded, 3 h in the yard, 300 km empty, then 10 h parked.
vt = max(TB.speeds);
if strcmp(tr, 'BOXN')
    name = 'freight round trip';
    route = struct('km', {}, 'v', {}, 'track', {}, 'stop', {}, 'load', {});
    for L = {'loaded', 'empty'}
        for k = 1:6
            trk = 'good';  if mod(k, 3) == 0, trk = 'poor'; end
            route(end+1) = struct('km', 50, 'v', ifelse(mod(k, 2) == 0, 75, vt), 'track', trk, 'stop', 0, 'load', L{1}); %#ok<AGROW>
        end
        route(end).stop = 180;
    end
    route(end).stop = 600;
else
    name = 'passenger day';
    va = ifelse(strcmp(tr, 'ICF'), 60, 80);
    route = struct('km', {}, 'v', {}, 'track', {}, 'stop', {}, 'load', {});
    for k = 1:10
        trk = 'good';  if mod(k, 3) == 0, trk = 'poor'; end
        route(end+1) = struct('km', 5, 'v', va, 'track', trk, 'stop', 0, 'load', ''); %#ok<AGROW>
        route(end+1) = struct('km', 40, 'v', vt, 'track', trk, 'stop', 0, 'load', ''); %#ok<AGROW>
        route(end+1) = struct('km', 5, 'v', va, 'track', trk, 'stop', 3, 'load', ''); %#ok<AGROW>
    end
    route(end).stop = 600;
end
end

function r = all_good(route)
r = route;
for k = 1:numel(r), r(k).track = 'good'; end
end

function y = ifelse(c, a, b)
if c, y = a; else, y = b; end
end

function s = pf(ok)
if ok, s = 'PASS'; else, s = 'CHECK'; end
end

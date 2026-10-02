%% CHECK_STAGE2  Verification and results of the SwarmRide smart damper and power chain.
%   A. Verification (LHB, crowded, 160 km/h, poor track)
%      A1 an electromagnetic copy of today's damper gives today's ride
%      A2 the damper force follows the commanded damping, F = c v
%      A3 energy is conserved through the whole power chain
%      A4 the fail-safe relay gives exactly today's damping, and harvesting stops
%   B. Results: every train x design (A, B, C) x mode (match, harvest), poor and good track
%   C. Figures (scripts/plot_stage2.m) and report in results/stage2_*
%   Run from the SwarmRide_Sim folder:   >> run scripts/check_stage2

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'), fullfile(root, 'models'));
resdir = fullfile(root, 'results');
m1 = 'SR_Stage1';  m2 = 'SR_Stage2';
load_system(fullfile(root, 'models', [m1 '.slx']));
load_system(fullfile(root, 'models', [m2 '.slx']));
fid = fopen(fullfile(resdir, 'stage2_report.txt'), 'w');
say = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
trains  = {'LHB', 'VB', 'ICF', 'BOXN'};
designs = {'A', 'B', 'C'};
T0 = 3;                                         % skip the start-up transient when scoring

%% A. Verification
say('=== A. Verification: LHB coach, 12 t, 160 km/h, poor track ===\n');
[o1, P1] = run2(m1, 'LHB', 'A', 'match', 'poor', Inf);
[oA, PA, DA] = run2(m2, 'LHB', 'A', 'match', 'poor', Inf);
M1 = metrics(o1, P1, T0);  MA = metrics(oA, PA, T0);
a1 = squeeze(o1.az.Data);  a2 = squeeze(oA.az.Data);
d1 = 100 * max(abs(a1(1, :) - a2(1, :))) / max(abs(a1(1, :)));
say('A1 Same ride as today (design A, match): body acceleration differs by %.2f %% of peak; Wz %.3f vs %.3f today -> %s\n', ...
    d1, MA.Wz, M1.Wz, pf(d1 < 3));

t = oA.az.Time;  k = t > T0;
F = squeeze(oA.Fd.Data);  vr = squeeze(oA.vrel.Data);
c_fit = sum(F(:, k) .* vr(:, k), 'all') / sum(vr(:, k).^2, 'all');
e2 = 100 * abs(c_fit - PA.c_cmd_emd) / PA.c_cmd_emd;
say('A2 Damping law: fitted c = %.0f N s/m, commanded %.0f N s/m (error %.2f %%) -> %s\n', ...
    c_fit, PA.c_cmd_emd, e2, pf(e2 < 2));

EB = sr_energy_balance(oA, PA);
say('A3 Energy balance (design A, match): generator %.0f / %.0f J, residual %.3f %% / %.3f %% -> %s\n', ...
    EB.gen, 100 * EB.rel, pf(all(abs(EB.rel) < 0.01)));
[oC, PC] = run2(m2, 'LHB', 'C', 'harvest', 'poor', Inf);
EBc = sr_energy_balance(oC, PC);
say('   Energy balance (design C, harvest): residual %.3f %% / %.3f %% -> %s\n', 100 * EBc.rel, pf(all(abs(EBc.rel) < 0.01)));

FS = struct('design', {}, 'c_after', {}, 'c_today', {}, 'err', {}, 'Pbefore', {}, 'Pafter', {});
for dz = {'A', 'B'}
    [of, Pf] = run2(m2, 'LHB', dz{1}, 'match', 'poor', 15);
    t = of.az.Time;  F = squeeze(of.Fd.Data);  vr = squeeze(of.vrel.Data);  pt = squeeze(of.Pterm.Data);
    aft = t > 15.05;  bef = t > T0 & t < 15;
    ca = sum(F(:, aft) .* vr(:, aft), 'all') / sum(vr(:, aft).^2, 'all');
    FS(end+1) = struct('design', dz{1}, 'c_after', ca, 'c_today', Pf.c_today, ...
        'err', 100 * abs(ca - Pf.c_today) / Pf.c_today, 'Pbefore', mean(pt(:, bef), 'all'), ...
        'Pafter', max(abs(pt(:, aft)), [], 'all')); %#ok<SAGROW>
    say('A4 Fail-safe (design %s, fault at 15 s): damping after = %.0f N s/m vs today %.0f (error %.2f %%); harvest %.1f W before, %.2f W after -> %s\n', ...
        dz{1}, ca, Pf.c_today, FS(end).err, FS(end).Pbefore, FS(end).Pafter, pf(FS(end).err < 1 && FS(end).Pafter < 1e-6));
    if strcmp(dz{1}, 'A'), ofA = of; end
end
say('\n');

%% B. Results matrix
say('=== B. Smart damper results: crowded, top speed (per bogie, average of front and rear) ===\n');
say('%-5s %-7s %-6s %-7s | %6s %6s %7s | %8s %8s %8s %8s %7s\n', 'train', 'track', 'design', 'mode', ...
    'RMS', 'Wz', 'stroke', 'P_mech', 'P_gen', 'P_bank', 'net', 'chain');
R = struct('train', {}, 'track', {}, 'design', {}, 'mode', {}, 'M', {});
for tr = trains
    for trk = {'poor', 'good'}
        [ot, Pt] = run2(m1, tr{1}, 'A', 'match', trk{1}, Inf);
        Mt = metrics(ot, Pt, T0);
        R(end+1) = struct('train', tr{1}, 'track', trk{1}, 'design', '-', 'mode', 'today', 'M', Mt); %#ok<SAGROW>
        say('%-5s %-7s %-6s %-7s | %6.3f %6.2f %5.1fmm | %7.1fW %8s %8s %8s %7s\n', tr{1}, trk{1}, '-', 'today', ...
            Mt.rms, Mt.Wz, Mt.stroke, Mt.Pmech, '-', '-', '-', '-');
        modes = {'match', 'harvest'};
        if strcmp(trk{1}, 'good'), modes = {'match'}; end
        for dz = designs
            for md = modes
                [o, P, D] = run2(m2, tr{1}, dz{1}, md{1}, trk{1}, Inf);
                M = metrics(o, P, T0);
                M.cu_kg = D.cu_kg;  M.T_peak = D.T_peak;  M.Ke = D.Ke;  M.cmax = D.cmax_emd;  M.c_cmd = P.c_cmd_emd;
                R(end+1) = struct('train', tr{1}, 'track', trk{1}, 'design', dz{1}, 'mode', md{1}, 'M', M); %#ok<SAGROW>
                say('%-5s %-7s %-6s %-7s | %6.3f %6.2f %5.1fmm | %7.1fW %7.1fW %7.1fW %+7.1fW %6.0f%%\n', ...
                    tr{1}, trk{1}, dz{1}, md{1}, M.rms, M.Wz, M.stroke, M.Pmech, M.Pgen, M.Pdc, M.Pnet, 100 * M.Pdc / M.Pmech);
                if strcmp(tr{1}, 'LHB') && strcmp(trk{1}, 'poor') && strcmp(dz{1}, 'A') && strcmp(md{1}, 'match')
                    oBank = o;  PBank = P;
                end
            end
        end
    end
end
say('(P_mech = power into the whole damper; P_gen = into the generator; P_bank = after rectifier and DC-DC;\n');
say(' net = P_bank minus %.0f W of bogie loads; chain = P_bank / P_mech)\n\n', PA.P_sens + PA.P_mcu + PA.P_radio + PA.P_aux);

say('=== Damper sizes (per damper, 2 per bogie) ===\n');
for tr = trains
    for dz = designs
        clear v_kmh mload_t trackType
        trainType = tr{1}; designType = dz{1}; sr_params;
        if strcmp(dz{1}, 'C')
            sz = sprintf('generator peak torque %.0f N m, inertance %.0f kg', D.T_peak, D.b_in);
        else
            sz = sprintf('copper about %.0f kg', D.cu_kg);
        end
        say('%-5s %s  Ke %5.0f N/A, Rc %.2f ohm, max EM damping %4.0f kN s/m per bogie; fail-safe %6s ohm; %s\n', ...
            tr{1}, D.name(1), D.Ke, D.Rc, D.cmax_emd / 1e3, num2str(D.R_fs, '%.2f'), sz);
    end
end
fclose(fid);
save(fullfile(resdir, 'stage2_results.mat'), 'R', 'FS', 'EB', 'EBc');

%% C. Figures (separate script, so figures can be redrawn without the full study)
run(fullfile(root, 'scripts', 'plot_stage2.m'));

%% helpers
function [o, P, D] = run2(mdl, train, design, mode, track, tfault)
% Runs one scenario. Variables go to the base workspace, where the model's InitFcn reads them.
TB = sr_trains(train);
assignin('base', 'trainType', train);   assignin('base', 'designType', design);
assignin('base', 'cmdMode', mode);      assignin('base', 'trackType', track);
assignin('base', 't_fault', tfault);    assignin('base', 'v_kmh', max(TB.speeds));
assignin('base', 'mload_t', max(TB.loads_t));
o = sim(mdl, 'EnablePacing', 'off');
P = evalin('base', 'P');  D = evalin('base', 'D');
end

function M = metrics(o, P, t0)
% Ride and power figures for one run (power per bogie, average of front and rear).
t = o.az.Time;  k = t > t0;
a = squeeze(o.az.Data);  a = a(1, k);
st = squeeze(o.stroke.Data);  F = squeeze(o.Fd.Data);  vr = squeeze(o.vrel.Data);
M.rms = sqrt(mean(a.^2));
M.Wz = sr_sperling(a, 1 / P.Ts);
M.stroke = 1000 * max(abs(st(:, k)), [], 'all');
M.Pmech = mean(F(:, k) .* vr(:, k), 'all');
if any(strcmp(o.who, 'Pdc'))
    avg = @(n) mean(subsref(sr_sig(o, n, t), struct('type', '()', 'subs', {{':', k}})), 'all');
    M.Pgen = avg('Pgen');  M.Pheat = avg('Pheat');  M.Ppe = avg('Ppe_loss');  M.Ppas = avg('Ppas');
    M.Pdc = avg('Pdc');  M.Pload = avg('Pload');  M.Pnet = M.Pdc - M.Pload;
end
end

function s = pf(ok)
if ok, s = 'PASS'; else, s = 'CHECK'; end
end

%% CHECK_STAGE1  Verifies the Stage 1 model before anything is added to it.
%   1. Natural frequencies and damping ratios (hand-check of the physics)
%   2. Simulink result == independent state-space result on the same track (model is wired right)
%   3. Ride level on poor track, empty vs crowded (sanity check against the preview study)
%   4. Single-bump response plot
%   Run from the SwarmRide_Sim folder:   >> run scripts/check_stage1

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'models'));
resdir = fullfile(root, 'results');
mdl = 'SR_Stage1';
load_system(fullfile(root, 'models', [mdl '.slx']));
fid = fopen(fullfile(resdir, 'stage1_report.txt'), 'w');
say = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];

%% 1. Natural frequencies (passive damper)
say('=== 1. Modes of the coach (passive oil damper) ===\n');
for mt = [0 15]
    clear v_kmh mload_t trackType; trainType = 'GENERIC'; %#ok<NASGU> read by sr_params
    v_kmh = 160; mload_t = mt; trackType = 'poor'; sr_params; %#ok<NASGU>
    [~, ~, ~, info] = sr_linear_model(P, P.cs);
    say('Load %2d t: ', mt);
    say('%.2f Hz (zeta %.2f)  ', [info.f_hz info.zeta]');
    say('\n');
end
keff = 1 / (1/(2*P.ks) + 1/(4*P.kp));
say('Hand check, body bounce (crowded): sqrt(keff/m)/2pi = %.2f Hz\n\n', sqrt(keff/P.m)/(2*pi));

%% 2. Simulink vs state space on the same track
say('=== 2. Simulink vs independent state-space model ===\n');
clear v_kmh mload_t trackType; trainType = 'GENERIC'; %#ok<NASGU> read by sr_params
v_kmh = 160; mload_t = 15; trackType = 'poor'; %#ok<NASGU> read by sr_params
out = sim(mdl, 'EnablePacing', 'off');
sr_params; TR = sr_track(P, trackType);
[A, Bw] = sr_linear_model(P, P.cs);
t = out.az.Time;
s = P.s0 + P.v * t - P.dist';                       % wheel positions over time
u = [interp1(TR.x, TR.w, s), P.v * interp1(TR.x, TR.dwdx, s)];
sys = ss(A, Bw, [A(5,:); zeros(0,8)], [Bw(5,:)]);  % output: body centre acceleration
y = lsim(sys, u, t);
azs = squeeze(out.az.Data); azs = azs(1, :)';
err = max(abs(y - azs)) / max(abs(y));
say('Max difference (body acceleration): %.3f %% of peak  -> %s\n\n', 100*err, ternary(err < 0.02, 'PASS', 'CHECK'));

%% 3. Ride level, poor track, 160 km/h
say('=== 3. Ride on poor track, 160 km/h (passive oil damper) ===\n');
rmsv = zeros(1, 2); k = 0;
for mt = [0 15]
    k = k + 1;
    clear v_kmh mload_t trackType; trainType = 'GENERIC'; %#ok<NASGU> read by sr_params
    v_kmh = 160; mload_t = mt; trackType = 'poor'; %#ok<NASGU> read by sr_params
    o = sim(mdl, 'EnablePacing', 'off');
    a = squeeze(o.az.Data); a = a(1, o.az.Time > 3);
    st = squeeze(o.stroke.Data);
    rmsv(k) = sqrt(mean(a.^2));
    say('Load %2d t: body RMS %.3f m/s^2, Sperling Wz %.2f, max stroke %.1f mm\n', mt, rmsv(k), ...
        sr_sperling(a, 1/P.Ts), 1000*max(abs(st(:))));
end
say('(Python preview study gave 0.148 empty / 0.176 crowded on its own random track)\n\n');

%% 4. One-bump response
clear v_kmh mload_t trackType; trainType = 'GENERIC';
v_kmh = 130; mload_t = 15; trackType = 'bump';
o = sim(mdl, 'EnablePacing', 'off');
fig = figure('Visible', 'off', 'Position', [100 100 900 420]);
tb = o.az.Time; ab = squeeze(o.az.Data);
plot(tb, ab(1, :), 'LineWidth', 1.6, 'Color', [0.08 0.14 0.23]); grid on
xlim([0.5 8]); xlabel('time [s]'); ylabel('body acceleration [m/s^2]');
title('Stage 1 check: 10 mm dip, crowded coach, 130 km/h, passive oil damper');
exportgraphics(fig, fullfile(resdir, 'stage1_bump.png'), 'Resolution', 150);
close(fig);
say('Saved results/stage1_bump.png\n');
fclose(fid);

function y = ternary(c, a, b), if c, y = a; else, y = b; end, end

%% CHECK_STAGE1B  Baseline of TODAY's Indian trains (before SwarmRide).
%   For LHB, Vande Bharat, ICF and BOXN, empty and fully loaded:
%     - vibration modes and damping ratio (does the fixed damper still fit the load?)
%     - static sag of the secondary suspension
%     - ride on poor track at service speed (RMS, Sperling Wz, stroke)
%     - power the dampers turn into HEAT (the energy SwarmRide wants to recover)
%   Plus the Simulink-vs-state-space wiring check on the LHB coach.
%   Run from the SwarmRide_Sim folder:   >> run scripts/check_stage1b

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'models'));
resdir = fullfile(root, 'results');
mdl = 'SR_Stage1';
load_system(fullfile(root, 'models', [mdl '.slx']));
fid = fopen(fullfile(resdir, 'stage1b_baseline_report.txt'), 'w');
say = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
trains = {'LHB', 'VB', 'ICF', 'BOXN'};

%% A. Wiring check on the LHB coach (passive oil damper)
say('=== A. Wiring check: Simulink vs independent state-space model (LHB, crowded, poor track) ===\n');
trainType = 'LHB'; v_kmh = 160; mload_t = 12; trackType = 'poor';
out = sim(mdl, 'EnablePacing', 'off');
sr_params; TR = sr_track(P, trackType);
[A, Bw] = sr_linear_model(P, P.cs);
t = out.az.Time;
s = P.s0 + P.v * t - P.dist';
u = [interp1(TR.x, TR.w, s), P.v * interp1(TR.x, TR.dwdx, s)];
y = lsim(ss(A, Bw, A(5,:), Bw(5,:)), u, t);
azs = squeeze(out.az.Data); azs = azs(1, :)';
err = max(abs(y - azs)) / max(abs(y));
say('Max difference: %.3f %% of peak -> %s\n\n', 100*err, ternary(err < 0.02, 'PASS', 'CHECK'));

%% B. Modes, damping and sag vs load
say('=== B. Modes, damping ratio and sag (today''s damper) ===\n');
loadgrid = struct();
for k = 1:numel(trains)
    clear v_kmh mload_t trackType
    trainType = trains{k};
    TB = sr_trains(trainType);
    lg = linspace(0, max(TB.loads_t), 12);
    z = nan(size(lg)); fb = nan(size(lg));
    for j = 1:numel(lg)
        mload_t = lg(j); sr_params;
        ceq = P.cs;
        if P.Ffr > 0, ceq = 0; end                      % friction: no viscous equivalent here
        [~, ~, ~, info] = sr_linear_model(P, ceq);
        fb(j) = info.f_hz(1); z(j) = info.zeta(1);
    end
    loadgrid.(trainType) = struct('load', lg, 'zeta', z, 'f', fb);
    for mt = [0 max(TB.loads_t)]
        mload_t = mt; sr_params;
        if P.sag == 0, sagtxt = 'levelled (air spring)'; else, sagtxt = sprintf('%5.1f mm', 1000*P.sag); end
        say('%-28s load %5.1f t: body mode %.2f Hz, zeta %.2f, static sag %s\n', ...
            Pinfo.trainName, mt, interp1(lg, fb, mt), interp1(lg, z, mt), sagtxt);
    end
end
say('(BOXN damping comes from friction wedges, so its viscous zeta is not meaningful)\n\n');

%% C. Ride and wasted heat on poor track at service speed
say('=== C. Ride on poor track at top service speed, today''s damper ===\n');
R = struct('train', {}, 'load', {}, 'speed', {}, 'rms', {}, 'Wz', {}, 'stroke', {}, 'heat', {});
for k = 1:numel(trains)
    TB = sr_trains(trains{k});
    for mt = [0 max(TB.loads_t)]
        clear v_kmh mload_t trackType
        trainType = trains{k}; v_kmh = max(TB.speeds); mload_t = mt; trackType = 'poor';
        o = sim(mdl, 'EnablePacing', 'off');
        sr_params;
        keep = o.az.Time > 3;
        a = squeeze(o.az.Data);  a = a(1, keep);
        st = squeeze(o.stroke.Data);
        F = squeeze(o.Fd.Data);   vr = squeeze(o.vrel.Data);
        heat = mean(sum(F(:, keep) .* vr(:, keep), 1)) / 2;      % per bogie [W]
        R(end+1) = struct('train', trains{k}, 'load', mt, 'speed', v_kmh, 'rms', sqrt(mean(a.^2)), ...
            'Wz', sr_sperling(a, 1/P.Ts), 'stroke', 1000*max(abs(st(:))), 'heat', heat); %#ok<SAGROW>
        say('%-28s %5.1f t @ %3d km/h: body RMS %.3f m/s^2, Wz %.2f, max stroke %5.1f mm, heat %6.1f W per bogie\n', ...
            Pinfo.trainName, mt, v_kmh, R(end).rms, R(end).Wz, R(end).stroke, R(end).heat);
    end
end
fclose(fid);
save(fullfile(resdir, 'stage1b_baseline.mat'), 'R', 'loadgrid');

%% D. Figures
col = [0.08 0.14 0.23; 0.88 0.48 0.12; 0.16 0.62 0.56; 0.54 0.58 0.63];
names = {'LHB', 'Vande Bharat', 'ICF', 'BOXN'};

fig = figure('Visible', 'off', 'Position', [100 100 900 420]);
hold on
for k = 1:3
    g = loadgrid.(trains{k});
    plot(g.load, g.zeta, 'LineWidth', 2.2, 'Color', col(k, :));
end
grid on; xlabel('passenger load [t]'); ylabel('damping ratio \zeta (body mode)');
title('Today: a fixed damper gets weaker as passengers board');
legend(names(1:3), 'Location', 'northeast'); ylim([0 0.35]);
exportgraphics(fig, fullfile(resdir, 'stage1b_zeta_vs_load.png'), 'Resolution', 150); close(fig);

fig = figure('Visible', 'off', 'Position', [100 100 900 420]);
W = reshape([R.Wz], 2, []).';
b = bar(categorical(names, names), W, 'grouped');
b(1).FaceColor = [0.79 0.81 0.84]; b(2).FaceColor = col(1, :);
grid on; ylabel('Sperling ride index Wz (lower is better)');
legend({'empty', 'fully loaded'}, 'Location', 'northwest');
title('Today''s ride on poor track at top service speed');
exportgraphics(fig, fullfile(resdir, 'stage1b_ride.png'), 'Resolution', 150); close(fig);

fig = figure('Visible', 'off', 'Position', [100 100 900 420]);
H = reshape([R.heat], 2, []).';
b = bar(categorical(names, names), H, 'grouped');
b(1).FaceColor = [0.79 0.81 0.84]; b(2).FaceColor = col(2, :);
grid on; ylabel('power turned into heat [W per bogie]');
legend({'empty', 'fully loaded'}, 'Location', 'northwest');
title('Energy today''s dampers waste as heat (what SwarmRide can recover)');
exportgraphics(fig, fullfile(resdir, 'stage1b_heat.png'), 'Resolution', 150); close(fig);

fprintf('Saved results/stage1b_*.png, stage1b_baseline_report.txt, stage1b_baseline.mat\n');

function y = ternary(c, a, b), if c, y = a; else, y = b; end, end

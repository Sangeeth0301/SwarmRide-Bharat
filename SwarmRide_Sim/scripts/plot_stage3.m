%% PLOT_STAGE3  Figures for Stage 3 (called by check_stage3, or run alone after it).
%   Uses results/stage3_results.mat; re-runs one C3 scenario for the damping-command trace.

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'), ...
    fullfile(root, 'models'), fullfile(root, 'tests'));
resdir = fullfile(root, 'results');
S = load(fullfile(resdir, 'stage3_results.mat'));
R = S.R;  B = S.B;  PF = S.PF;
trains = {'LHB', 'VB', 'ICF', 'BOXN'};
names  = {'LHB, 160 km/h', 'Vande Bharat, 160 km/h', 'ICF, 110 km/h', 'BOXN, 100 km/h'};
ctrls  = {'C0', 'C1', 'C2', 'C3'};
labels = {'C0 today''s damper', 'C1 fixed harvester', 'C2 LPV load-adaptive', 'C3 LPV + Train Brain preview'};
col = [0.54 0.58 0.63; 0.88 0.48 0.12; 0.16 0.62 0.56; 0.08 0.14 0.23];
mk  = {'s', '^', 'o', 'd'};
sel = @(tr, trk, c) R(strcmp({R.train}, tr) & strcmp({R.track}, trk) & strcmp({R.ctrl}, c));

%% 1. Ride vs load (centre and worst seat)
for metric = {'Wz', 'Wzmax'}
    fig = figure('Visible', 'off', 'Position', [100 100 1100 760]);
    for i = 1:4
        subplot(2, 2, i); hold on
        for c = 1:4
            r = sel(trains{i}, 'poor', ctrls{c});
            M = [r.M];
            plot([r.load], [M.(metric{1})], ['-' mk{c}], 'Color', col(c, :), 'MarkerFaceColor', col(c, :), 'LineWidth', 1.8);
        end
        grid on; xlabel('passenger / cargo load [t]'); ylabel('Sperling Wz (lower = better)'); title(names{i});
        if i == 1, legend(labels, 'Location', 'best'); end
    end
    if strcmp(metric{1}, 'Wz')
        sgtitle('Ride comfort at every load (centre of the coach, poor track)');
        fn = 'stage3_ride_vs_load.png';
    else
        sgtitle('Ride comfort at every load (worst seat: over the front or rear bogie, poor track)');
        fn = 'stage3_ride_worst_seat.png';
    end
    exportgraphics(fig, fullfile(resdir, fn), 'Resolution', 150); close(fig);
end

%% 2. Comfort vs power (LHB crowded)
fig = figure('Visible', 'off', 'Position', [100 100 900 560]); hold on
r0 = sel('LHB', 'poor', 'C0');  r0 = r0([r0.load] == max([r0.load]));
plot(0, r0.M.Wz, 'p', 'MarkerSize', 18, 'MarkerFaceColor', col(1, :), 'MarkerEdgeColor', 'k');
for c = 2:4
    p = PF(strcmp({PF.ctrl}, ctrls{c}));
    [~, o] = sort([p.P]);  p = p(o);
    plot([p.P], [p.Wz], ['-' mk{c}], 'Color', col(c, :), 'MarkerFaceColor', col(c, :), 'LineWidth', 2, 'MarkerSize', 8);
end
p = PF(strcmp({PF.ctrl}, 'C3floor'));  p3 = PF(strcmp({PF.ctrl}, 'C3') & [PF.x] == 3);
p = [p3, p];  [~, o] = sort([p.P]);  p = p(o);
plot([p.P], [p.Wz], '--d', 'Color', col(4, :), 'MarkerFaceColor', 'w', 'LineWidth', 2, 'MarkerSize', 8);
yline(r0.M.Wz, ':', 'today', 'Color', col(1, :), 'LineWidth', 1.2);
xline(8, '--', 'bogie loads 8 W', 'Color', [0.84 0.27 0.25], 'LineWidth', 1.2);
grid on; xlabel('power into the bank [W per bogie]'); ylabel('Sperling Wz (lower = better)');
legend([labels, {'C3 with a damping floor (more power)'}], 'Location', 'northwest');
title({'Comfort vs power, LHB crowded, 160 km/h, poor track', 'lower = more comfortable, right = more power'});
exportgraphics(fig, fullfile(resdir, 'stage3_comfort_vs_power.png'), 'Resolution', 150); close(fig);

%% 3. Single events: short dip and track settlement
fig = figure('Visible', 'off', 'Position', [100 100 1150 460]);
evs = {'bump', 'settlement'};
ttl = {'Short dip: 10 mm over 4 m', 'Track settlement: 20 mm over 20 m (e.g. bridge approach)'};
xl  = {[0.5 7], [3 10]};
for e = 1:2
    subplot(1, 2, e); hold on
    Be = B(strcmp({B.track}, evs{e}));
    for b = 1:numel(Be)
        c = find(strcmp(ctrls, Be(b).ctrl));
        plot(Be(b).t, Be(b).az, 'Color', col(c, :), 'LineWidth', 1.4 + 0.4 * (c == 4));
    end
    xlim(xl{e}); grid on; xlabel('time [s]'); ylabel('body acceleration, centre [m/s^2]'); title(ttl{e});
    legend(arrayfun(@(b) sprintf('%s (peak %.2f)', b.ctrl, b.peak), Be, 'UniformOutput', false), 'Location', 'northeast');
end
sgtitle('Single events, LHB crowded, 160 km/h: C0 today, C1 fixed harvester, C2 LPV, C3 LPV + preview');
exportgraphics(fig, fullfile(resdir, 'stage3_events.png'), 'Resolution', 150); close(fig);

%% 4. Power into the bank (full load)
fig = figure('Visible', 'off', 'Position', [100 100 1150 440]);
trks = {'poor', 'good'};
for s = 1:2
    subplot(1, 2, s); hold on
    Y = zeros(4, 3);
    for i = 1:4
        for c = 2:4
            r = sel(trains{i}, trks{s}, ctrls{c});  r = r([r.load] == max([r.load]));
            Y(i, c - 1) = r.M.Pdc;
        end
    end
    bb = bar(categorical(trains, trains), Y, 'grouped');
    for c = 1:3, bb(c).FaceColor = col(c + 1, :); end
    yline(8, '--', 'bogie loads 8 W', 'Color', [0.84 0.27 0.25], 'LineWidth', 1.5, ...
        'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'top');
    grid on; ylabel('power into the bank [W per bogie]'); title(sprintf('%s track, full load', trks{s}));
    if s == 1, legend(labels(2:4), 'Location', 'northwest'); end
end
exportgraphics(fig, fullfile(resdir, 'stage3_power.png'), 'Resolution', 150); close(fig);

%% 5. Damping command over time (LHB crowded, C3)
load_system(fullfile(root, 'models', 'SR_Stage3.slx'));
[o, P] = sr_run('SR_Stage3', 'LHB', 'designType', 'C', 'ctrlMode', 'C3');
t = o.az.Time;  k = t >= 20 & t <= 24;
cc = sr_sig(o, 'ccmd', t);  vr = squeeze(o.vrel.Data);
fig = figure('Visible', 'off', 'Position', [100 100 1000 560]);
subplot(2, 1, 1); plot(t(k), vr(1, k), 'Color', col(4, :), 'LineWidth', 1.3); grid on;
ylabel('stroke velocity [m/s]'); title('Front bogie: how the suspension moves');
subplot(2, 1, 2); plot(t(k), cc(1, k) / 1e3, 'Color', col(3, :), 'LineWidth', 1.3); hold on;
yline(P.c_today / 1e3, ':', 'today''s fixed damper', 'Color', col(1, :), 'LineWidth', 1.4);
yline(P.c_cap / 1e3, '--', 'efficiency limit', 'Color', [0.84 0.27 0.25], 'LineWidth', 1.2);
grid on; ylabel('damping [kN s/m]'); xlabel('time [s]');
title('C3 changes the damping many times a second: firm when it calms the body, soft when it would push it');
exportgraphics(fig, fullfile(resdir, 'stage3_command.png'), 'Resolution', 150); close(fig);

%% 6. Model diagrams
try
    print('-sSR_Stage3', '-dpng', '-r150', fullfile(resdir, 'stage3_model_top.png'));
    print('-sSR_Stage3/SwarmRide Controller (LPV + preview)', '-dpng', '-r150', fullfile(resdir, 'stage3_model_controller.png'));
    print('-sSR_Stage3/Train Brain (track preview)', '-dpng', '-r150', fullfile(resdir, 'stage3_model_trainbrain.png'));
catch err
    warning('swarmride:diagram', 'Diagram export failed: %s', err.message);
end
fprintf('Saved results/stage3_*.png\n');

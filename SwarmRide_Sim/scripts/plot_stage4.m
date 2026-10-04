%% PLOT_STAGE4  Figures for Stage 4 (called by check_stage4, or run alone after it).

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'models'));
resdir = fullfile(root, 'results');
S = load(fullfile(resdir, 'stage4_results.mat'));
E = S.E;  JR = S.JR;  H = S.H;  W = S.W;
navy = [0.08 0.14 0.23]; orange = [0.88 0.48 0.12]; teal = [0.16 0.62 0.56]; grey = [0.54 0.58 0.63];
red = [0.84 0.27 0.25];

%% 1. Active push at known bad spots
fig = figure('Visible', 'off', 'Position', [100 100 1150 470]);
evs = {'settlement', 'bump'};
ttl = {'Track settlement: 20 mm over 20 m', 'Short dip: 10 mm over 4 m'};
xl = {[3 9], [0.8 5]};
for e = 1:2
    subplot(1, 2, e); hold on
    r0 = E(strcmp({E.track}, evs{e}) & strcmp({E.ctrl}, 'C0'));
    r3 = E(strcmp({E.track}, evs{e}) & strcmp({E.ctrl}, 'C3'));
    r4 = E(strcmp({E.track}, evs{e}) & strcmp({E.ctrl}, 'C4') & [E.win] == 1);
    plot(r0.t, r0.az, 'Color', grey, 'LineWidth', 1.4);
    plot(r3.t, r3.az, 'Color', teal, 'LineWidth', 1.4);
    plot(r4.t, r4.az, 'Color', navy, 'LineWidth', 2);
    xlim(xl{e}); grid on; xlabel('time [s]'); ylabel('body acceleration, centre [m/s^2]'); title(ttl{e});
    legend({sprintf('C0 today (peak %.2f)', r0.peak), sprintf('C3 resist only (peak %.2f)', r3.peak), ...
        sprintf('C4 push at the spot (peak %.2f, %.0f J from the bank)', r4.peak, r4.Epush)}, 'Location', 'southeast');
end
sgtitle('Active push at known bad spots: the Train Brain warning finally pays off (LHB crowded, 160 km/h)');
exportgraphics(fig, fullfile(resdir, 'stage4_active_push.png'), 'Resolution', 150); close(fig);

%% 2. Long journeys
fig = figure('Visible', 'off', 'Position', [100 100 1150 720]);
for s = 1:numel(JR)
    subplot(2, 2, s); hold on
    J = JR(s).J;  Js = JR(s).Js;  Jg = JR(s).Jg;
    plot(J.t, 100 * J.SOC, ':', 'Color', red, 'LineWidth', 1.8);
    plot(Js.t, 100 * Js.SOC, 'Color', navy, 'LineWidth', 2);
    plot(Jg.t, 100 * Jg.SOC, '--', 'Color', orange, 'LineWidth', 1.5);
    grid on; xlabel('time [h]'); ylabel('battery state of charge [%]'); ylim([0 100]);
    title(sprintf('%s: %s (harvested %.0f Wh)', JR(s).train, JR(s).name, J.E_harvest));
    if s == 1
        legend({'electronics always on (8 W)', 'standby when parked (1 W)', 'standby, all-smooth track'}, 'Location', 'northeast');
    end
end
sgtitle('One bogie''s power bank over a full day: the electronics must sleep when the train is parked');
exportgraphics(fig, fullfile(resdir, 'stage4_journey.png'), 'Resolution', 150); close(fig);

%% 3. Hot axle
fig = figure('Visible', 'off', 'Position', [100 100 1150 450]);
subplot(1, 2, 1); hold on
plot(H.t / 60, H.T, 'Color', navy, 'LineWidth', 2);
yline(H.opt.T_alarm, '--', 'alarm', 'Color', orange, 'LineWidth', 1.4);
yline(H.opt.T_fail, '--', 'failure risk', 'Color', red, 'LineWidth', 1.4);
plot((H.t_alarm + H.opt.ts) / 60, H.self.T_detect, 'o', 'MarkerSize', 10, 'MarkerFaceColor', teal, 'MarkerEdgeColor', 'k');
xlim([0 H.t_fail / 60 * 1.15]); grid on; xlabel('minutes after the fault starts'); ylabel('bearing temperature [C]');
title('A developing bearing fault (illustrative)');
legend({'bearing temperature', '', '', 'SwarmRide alarm (on-bogie, every 10 s)'}, 'Location', 'northwest');
subplot(1, 2, 2); hold on
histogram(min(H.track.T_detect, H.opt.T_fail + 20), 30, 'FaceColor', grey, 'EdgeColor', 'w');
xline(H.self.T_detect, '-', 'SwarmRide', 'Color', teal, 'LineWidth', 2.5);
xline(H.opt.T_fail, '--', 'failure risk', 'Color', red, 'LineWidth', 1.4);
grid on; xlabel('bearing temperature when the alarm is raised [C]'); ylabel('faults (2000 random cases)');
title(sprintf('Trackside checkpoints every %d km: %.0f%% of faults pass %d C first', H.opt.spacing_km, ...
    100 * H.track.p_missed, H.opt.T_fail));
exportgraphics(fig, fullfile(resdir, 'stage4_hot_axle.png'), 'Resolution', 150); close(fig);

%% 4. Wheel defect seen by the smart damper
fig = figure('Visible', 'off', 'Position', [100 100 1150 450]);
subplot(1, 2, 1); hold on
cols = [grey; orange; navy];
for c = 1:numel(W)
    plot(W(c).f, W(c).Ef, 'Color', cols(c, :), 'LineWidth', 1.2 + 0.4 * (c > 1));
end
for c = 2:numel(W), xline(W(c).fw, ':', 'Color', cols(c, :), 'LineWidth', 1.2); end
xlim([5 55]); grid on; xlabel('frequency [Hz]'); ylabel('front-bogie coil voltage amplitude [V]');
legend({W.case}, 'Location', 'northeast'); title('The damper''s own coil signal shows the wheel defect');
subplot(1, 2, 2);
Y = [[W.peak_f]; [W.peak_r]]';
b = bar(categorical({W.case}, {W.case}), Y, 'grouped');  b(1).FaceColor = navy;  b(2).FaceColor = light_or(grey);
grid on; ylabel('coil voltage at the defect frequency [V]'); legend({'front bogie (defective wheelset)', 'rear bogie'}, 'Location', 'northwest');
title('The front bogie lights up: the defect is located to its wheelset');
exportgraphics(fig, fullfile(resdir, 'stage4_wheel_defect.png'), 'Resolution', 150); close(fig);

%% 5. Model diagram
try
    load_system(fullfile(root, 'models', 'SR_Stage4.slx'));
    print('-sSR_Stage4', '-dpng', '-r150', fullfile(resdir, 'stage4_model_top.png'));
catch err
    warning('Diagram export failed: %s', err.message);
end
fprintf('Saved results/stage4_*.png\n');

function c = light_or(c)
c = 0.6 * c + 0.4;
end

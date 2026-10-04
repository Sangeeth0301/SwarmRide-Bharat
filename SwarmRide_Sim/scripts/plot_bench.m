%% PLOT_BENCH  Figures of the bench-prototype study (called by check_bench, or run alone after it).

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'models'));
resdir = fullfile(root, 'results');
S = load(fullfile(resdir, 'bench_results.mat'));  R = S.R;  T = R.traces;  HW = R.HW;
navy = [0.08 0.14 0.23]; orange = [0.88 0.48 0.12]; teal = [0.16 0.62 0.56]; grey = [0.54 0.58 0.63];
red = [0.84 0.27 0.25];
d = @(x) double(x);

%% 1. Damping law and efficiency (T2, T3)
fig = figure('Visible', 'off', 'Position', [100 100 1150 450]);
subplot(1, 2, 1); hold on
lev = R.T2.c_cmd;  cols = interp1([0 1], [light(teal); navy], linspace(0, 1, numel(lev)));
t = d(T.damping.t);  v = d(T.damping.v);  F = d(T.damping.F);  c = d(T.damping.c);
a = gradient(v, t);
Fem = F - R.T2.Fc_fit * tanh(v / 0.02) - R.T2.b_fit * a;      % force left after friction and inertance
for k = 1:numel(lev)
    sel = abs(c - lev(k)) < 1;  idx = find(sel);  sel(idx(t(idx) < t(idx(1)) + 0.5)) = false;
    plot(v(sel), Fem(sel) / 1e3, '.', 'Color', cols(k, :), 'MarkerSize', 4);
    plot([-0.12 0.12], lev(k) * [-0.12 0.12] / 1e3, '-', 'Color', cols(k, :), 'LineWidth', 1.2);
end
grid on; xlabel('stroke speed [m/s]'); ylabel('damper force less friction and inertia [kN]');
title('T2: the damper gives the commanded damping (lines: command)');
subplot(1, 2, 2); hold on
cf = linspace(0, 1, 50) * HW.c_req;
plot(cf / 1e3, 1 - cf / HW.cmax, '-', 'Color', grey, 'LineWidth', 1.5);
plot(lev / 1e3, R.T2.eta_coil, 'o', 'MarkerFaceColor', teal, 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
plot(lev / 1e3, R.T2.eta_total, 's', 'MarkerFaceColor', orange, 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
ylim([0 1]); grid on; xlabel('damping command [kN s/m]'); ylabel('efficiency');
legend({'coil, formula 1 - c / c_{max}', 'coil, bench model', 'rig work to the bank, bench model'}, 'Location', 'southwest');
title('T3: harvesting efficiency');
exportgraphics(fig, fullfile(resdir, 'bench_damping_law.png'), 'Resolution', 150); close(fig);

%% 2. Rough-track replay (T7)
fig = figure('Visible', 'off', 'Position', [100 100 1150 450]);
t = d(T.poor.t);  k = t > 10 & t < 12;
subplot(1, 2, 1); hold on
plot(t(k), d(T.poor.Fveh(k)) / 1e3, '-', 'Color', grey, 'LineWidth', 2.5);
plot(t(k), d(T.poor.F(k)) / 1e3, '-', 'Color', navy, 'LineWidth', 1.1);
grid on; xlabel('time [s]'); ylabel('damper force [kN]');
legend({'vehicle model (Stage 4)', 'bench model, real hardware'}, 'Location', 'southwest');
title('T7: the damper''s own motion from the coach, replayed on the rig');
subplot(1, 2, 2); hold on
kk = t > 3;  w = 1000;
pm = movmean(d(T.poor.Pmech), w);  pb = movmean(d(T.poor.Pbank), w);
plot(t(kk), pm(kk), '-', 'Color', grey, 'LineWidth', 1.5);
plot(t(kk), pb(kk), '-', 'Color', teal, 'LineWidth', 2);
yline(R.Ust.poor.Pdc, '--', sprintf('vehicle model %.1f W', R.Ust.poor.Pdc), 'Color', orange, 'LineWidth', 1.3);
grid on; xlabel('time [s]'); ylabel('power, 1 s average [W]');
legend({'rig work into the damper', sprintf('into the bank (mean %.1f W)', R.replay_poor.Pbank)}, 'Location', 'northwest');
title('Power: rough track, crowded LHB, 160 km/h');
exportgraphics(fig, fullfile(resdir, 'bench_replay.png'), 'Resolution', 150); close(fig);

%% 3. Push at the settlement (T8)
fig = figure('Visible', 'off', 'Position', [100 100 1150 450]);
t = d(T.settle.t);  k = t > 2.6 & t < 5.6;
subplot(1, 2, 1); hold on
area(t(k), 6 * d(T.settle.act(k)), 'FaceColor', light(orange), 'EdgeColor', 'none', 'FaceAlpha', 0.35);
plot(t(k), d(T.settle.Fcmd(k)) / 1e3, '-', 'Color', grey, 'LineWidth', 2.5);
plot(t(k), d(T.settle.Fem(k)) / 1e3, '-', 'Color', navy, 'LineWidth', 1.1);
ylim([-6 6]); grid on; xlabel('time [s]'); ylabel('electromagnetic force [kN]');
legend({'push window', 'push command (controller C4)', 'bench model'}, 'Location', 'southwest');
title(sprintf('T8: the damper follows the push (error %.1f %% RMS)', R.replay_settle.F_track));
subplot(1, 2, 2);
yyaxis left
plot(t(k), d(T.settle.Pbank(k)), '-', 'Color', teal, 'LineWidth', 1.4);
ylabel('power into the bank [W] (negative = pushing)');
yyaxis right
plot(t(k), d(T.settle.Vsc(k)), '-', 'Color', orange, 'LineWidth', 1.4);
ylabel('supercapacitor [V]');
grid on; xlabel('time [s]');
title(sprintf('%.0f W peak from the supercapacitor, %.0f J', R.replay_settle.Ppush, R.replay_settle.Epush));
exportgraphics(fig, fullfile(resdir, 'bench_push.png'), 'Resolution', 150); close(fig);

%% 4. Fail-safe (T6)
fig = figure('Visible', 'off', 'Position', [100 100 1150 420]);
t = d(T.failsafe.t);  k = t > 4.6 & t < 5.6;
subplot(1, 2, 1); hold on
plot(t(k), d(T.failsafe.F(k)) / 1e3, '-', 'Color', navy, 'LineWidth', 1.4);
plot(t(k), d(T.failsafe.Fem(k)) / 1e3, '-', 'Color', orange, 'LineWidth', 1.1);
xline(5, '--', 'fault', 'Color', red, 'LineWidth', 1.3);
grid on; xlabel('time [s]'); ylabel('force [kN]');
legend({'load cell', 'electromagnetic part'}, 'Location', 'southwest');
title(sprintf('T6: fault at 5 s, %.0f ms gap while the contactor moves', 1e3 * R.T6.gap));
subplot(1, 2, 2); hold on
v = d(T.failsafe.v);  F = d(T.failsafe.F);
b = t > 1 & t < 5;  af = t > 5.2;
plot(v(b), F(b) / 1e3, '.', 'Color', light(teal), 'MarkerSize', 4);
plot(v(af), F(af) / 1e3, '.', 'Color', navy, 'MarkerSize', 4);
plot([-0.12 0.12], HW.c_today * [-0.12 0.12] / 1e3, '--', 'Color', red, 'LineWidth', 1.3);
grid on; xlabel('stroke speed [m/s]'); ylabel('load-cell force [kN]');
legend({'drive in control', 'contactor dropped (fail-safe resistors)', 'today''s damper'}, 'Location', 'northwest');
title(sprintf('Fail-safe damping %.0f N s/m vs today''s %.0f N s/m', R.T6.c_after, HW.c_today));
exportgraphics(fig, fullfile(resdir, 'bench_failsafe.png'), 'Resolution', 150); close(fig);

%% 5. Current loop and voltage limit (T4, T5)
fig = figure('Visible', 'off', 'Position', [100 100 1150 420]);
subplot(1, 2, 1); hold on
t = d(T.step.t);  k = t > 0.29 & t < 0.31;
plot(1e3 * (t(k) - 0.3), d(T.step.iref(k)), '-', 'Color', grey, 'LineWidth', 2);
plot(1e3 * (t(k) - 0.3), d(T.step.i(k)), '-', 'Color', navy, 'LineWidth', 1.4);
grid on; xlabel('time after the command step [ms]'); ylabel('coil current [A]');
legend({'reference', 'coil current'}, 'Location', 'southeast');
title(sprintf('T4: current loop, 63 %% in %.2f ms', 1e3 * R.T4.tau));
subplot(1, 2, 2); hold on
v = d(T.vlimit.v);  u = d(T.vlimit.u);  s = d(T.vlimit.sat);
plot(v, u, '.', 'Color', navy, 'MarkerSize', 3);
plot(v(s > 0.5), u(s > 0.5), '.', 'Color', red, 'MarkerSize', 5);
yline([-1 1] * HW.Umax, '--', 'Color', orange, 'LineWidth', 1.3);
xline([-1 1] * R.U.v_max, ':', 'Color', teal, 'LineWidth', 1.5);
grid on; xlabel('stroke speed [m/s]'); ylabel('inverter voltage u [V]');
title(sprintf('T5: out of voltage above %.2f m/s (coach needs %.2f m/s)', R.T5.v_sat, R.U.v_max));
exportgraphics(fig, fullfile(resdir, 'bench_drive_limits.png'), 'Resolution', 150); close(fig);

%% 6. Hardware margins in the vehicle model
fig = figure('Visible', 'off', 'Position', [100 100 1150 420]);
MG = R.MG;  W0 = R.W0;  Wb = MG(1).Wz;
subplot(1, 2, 1); hold on
mj = MG(strcmp({MG.what}, 'J'));
semilogx([mj.val] * 1e4, [mj.Wz], 'o-', 'Color', navy, 'MarkerFaceColor', navy, 'LineWidth', 1.6);
set(gca, 'XScale', 'log');
yline(W0, '--', 'today''s damper', 'Color', grey, 'LineWidth', 1.3);
yline(Wb * 1.02, ':', '2 % of the gain lost', 'Color', orange, 'LineWidth', 1.3);
xline(R.J_limit * 1e4, '-', sprintf('limit %.1f', R.J_limit * 1e4), 'Color', red, 'LineWidth', 1.3);
grid on; xlabel('rotor + screw inertia [10^{-4} kg m^2]'); ylabel('Sperling Wz (lower = better)');
title('Inertia budget for the real motor and screw');
subplot(1, 2, 2); hold on
mf = MG(strcmp({MG.what}, 'Fc'));                   % first point: the design friction (run with the design inertia)
plot([HW.Fc, mf.val], [Wb, mf.Wz], 's-', 'Color', teal, 'MarkerFaceColor', teal, 'LineWidth', 1.6);
yline(W0, '--', 'today''s damper', 'Color', grey, 'LineWidth', 1.3);
grid on; xlabel('screw + seal friction [N]'); ylabel('Sperling Wz (lower = better)');
title('Friction budget');
exportgraphics(fig, fullfile(resdir, 'bench_margins.png'), 'Resolution', 150); close(fig);

%% 7. Model diagram
try
    load_system(fullfile(root, 'models', 'SR_Bench.slx'));
    print('-sSR_Bench', '-dpng', '-r150', fullfile(resdir, 'bench_model_top.png'));
catch err
    warning('Diagram export failed: %s', err.message);
end
fprintf('Saved results/bench_*.png\n');

function c = light(c)
c = 0.55 * c + 0.45;
end

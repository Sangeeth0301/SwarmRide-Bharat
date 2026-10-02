%% PLOT_STAGE2  Figures for Stage 2 (called by check_stage2, or run alone after it).
%   Uses results/stage2_results.mat and re-runs two scenarios for the time traces:
%   the fail-safe test and the power-bank trace (LHB, design A, match, poor track).

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'), fullfile(root, 'models'));
resdir = fullfile(root, 'results');
m2 = 'SR_Stage2';
load_system(fullfile(root, 'models', [m2 '.slx']));
S = load(fullfile(resdir, 'stage2_results.mat'));
R = S.R;
trains  = {'LHB', 'VB', 'ICF', 'BOXN'};
designs = {'A', 'B', 'C'};
names   = {'LHB', 'Vande Bharat', 'ICF', 'BOXN'};
T0 = 3;
navy = [0.08 0.14 0.23]; orange = [0.88 0.48 0.12]; teal = [0.16 0.62 0.56]; grey = [0.54 0.58 0.63];
red = [0.84 0.27 0.25];
pick = @(tr, trk, dz, md) R(strcmp({R.train}, tr) & strcmp({R.track}, trk) & strcmp({R.design}, dz) & strcmp({R.mode}, md)).M;

[ofA, PA] = run2p(m2, 'LHB', 'A', 'match', 'poor', 15);     % fail-safe test
[oBank, PB] = run2p(m2, 'LHB', 'A', 'match', 'poor', Inf);  % power bank trace
Pload = PA.P_sens + PA.P_mcu + PA.P_radio + PA.P_aux;

%% 1. Where the damper's power goes (LHB, design A, match, poor track)
M = pick('LHB', 'poor', 'A', 'match');
vals = [M.Pmech, M.Pheat, M.Ppe, Pload, M.Pdc - Pload];
labs = {'Power into the damper', 'Coil copper loss', 'Rectifier + DC-DC losses', ...
        'Bogie loads (sensors, controller, radio)', 'Surplus stored in the bank'};
cols = [navy; red; red; teal; orange];
fig = figure('Visible', 'off', 'Position', [100 100 1000 420]);
hold on
for k = 1:numel(vals)
    barh(k, vals(k), 0.6, 'FaceColor', cols(k, :));
    text(vals(k) + 1, k, sprintf('%.1f W', vals(k)), 'FontWeight', 'bold', 'VerticalAlignment', 'middle');
end
set(gca, 'YTick', 1:numel(vals), 'YTickLabel', labs, 'YDir', 'reverse');
xlim([0 max(vals) * 1.18]); ylim([0.4 numel(vals) + 0.6]); grid on; box on;
xlabel('average power per bogie [W]');
title({'Where the smart damper''s power goes', 'LHB coach, crowded, 160 km/h, poor track, same ride as today (design A)'});
exportgraphics(fig, fullfile(resdir, 'stage2_power_chain.png'), 'Resolution', 150); close(fig);

%% 2. Power into the bank per train and design (match mode), poor and good track
fig = figure('Visible', 'off', 'Position', [100 100 1150 440]);
trks = {'poor', 'good'};
for s = 1:2
    subplot(1, 2, s); hold on
    Y = zeros(4, 3);
    for i = 1:4, for j = 1:3, Y(i, j) = pick(trains{i}, trks{s}, designs{j}, 'match').Pdc; end, end
    bb = bar(categorical(names, names), Y, 'grouped');
    bb(1).FaceColor = navy; bb(2).FaceColor = teal; bb(3).FaceColor = orange;
    yline(Pload, '--', sprintf('bogie loads %.0f W', Pload), 'Color', red, 'LineWidth', 1.5, ...
        'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'top');
    grid on; ylabel('power into the bank [W per bogie]');
    title(sprintf('%s track, same damping as today', trks{s}));
    if s == 1, legend({'A direct-drive', 'B hybrid', 'C geared rotary'}, 'Location', 'northwest'); end
end
exportgraphics(fig, fullfile(resdir, 'stage2_bank_power.png'), 'Resolution', 150); close(fig);

%% 3. Ride vs power: today, match and harvest for each design
fig = figure('Visible', 'off', 'Position', [100 100 1100 760]);
mk = {'o', 's', '^'};
for i = 1:4
    subplot(2, 2, i); hold on
    Mt = pick(trains{i}, 'poor', '-', 'today');
    plot(0, Mt.Wz, 'p', 'MarkerSize', 16, 'MarkerFaceColor', grey, 'MarkerEdgeColor', 'k');
    for j = 1:3
        Mm = pick(trains{i}, 'poor', designs{j}, 'match');  Mh = pick(trains{i}, 'poor', designs{j}, 'harvest');
        plot(Mm.Pdc, Mm.Wz, mk{j}, 'MarkerSize', 10, 'MarkerFaceColor', teal, 'MarkerEdgeColor', 'k');
        plot(Mh.Pdc, Mh.Wz, mk{j}, 'MarkerSize', 10, 'MarkerFaceColor', orange, 'MarkerEdgeColor', 'k');
        text(Mm.Pdc, Mm.Wz, ['  ' designs{j}], 'FontWeight', 'bold');
        text(Mh.Pdc, Mh.Wz, ['  ' designs{j}], 'FontWeight', 'bold');
    end
    grid on; xlabel('power into the bank [W per bogie]'); ylabel('Sperling Wz (lower = better)');
    title(names{i});
    if i == 1
        h = [plot(nan, nan, 'p', 'MarkerFaceColor', grey, 'MarkerEdgeColor', 'k'), ...
             plot(nan, nan, 'o', 'MarkerFaceColor', teal, 'MarkerEdgeColor', 'k'), ...
             plot(nan, nan, 'o', 'MarkerFaceColor', orange, 'MarkerEdgeColor', 'k')];
        legend(h, {'today', 'smart damper: match today', 'smart damper: harvest setting'}, 'Location', 'southwest');
    end
end
sgtitle('Ride and power with one fixed setting per run (crowded, top speed, poor track)');
exportgraphics(fig, fullfile(resdir, 'stage2_ride_vs_power.png'), 'Resolution', 150); close(fig);

%% 4. Fail-safe
t = ofA.az.Time;  F = squeeze(ofA.Fd.Data);  vr = squeeze(ofA.vrel.Data);  pt = squeeze(ofA.Pterm.Data);
fig = figure('Visible', 'off', 'Position', [100 100 1100 420]);
subplot(1, 2, 1); hold on
bef = t > T0 & t < 15;  aft = t > 15.05;
plot(vr(1, bef), F(1, bef) / 1e3, '.', 'Color', teal, 'MarkerSize', 4);
plot(vr(1, aft), F(1, aft) / 1e3, '.', 'Color', red, 'MarkerSize', 4);
vv = linspace(min(vr(1, :)), max(vr(1, :)), 10);
plot(vv, PA.c_today * vv / 1e3, 'k--', 'LineWidth', 1.2);
grid on; xlabel('stroke velocity [m/s]'); ylabel('damper force [kN]');
legend({'normal (converter)', 'after fault (relay + resistor)', 'today''s damper'}, 'Location', 'northwest');
title('Force law before and after the fault');
subplot(1, 2, 2);
plot(t, pt(1, :), 'Color', orange); hold on; xline(15, 'r--', 'fault', 'LineWidth', 1.5);
grid on; xlabel('time [s]'); ylabel('power to the converter [W]'); xlim([10 20]);
title('Harvesting stops, damping continues');
sgtitle('Fail-safe: on a fault the smart damper becomes today''s damper (LHB, design A)');
exportgraphics(fig, fullfile(resdir, 'stage2_failsafe.png'), 'Resolution', 150); close(fig);

%% 5. Power bank over the run (front bogie)
t = oBank.az.Time;  V = squeeze(oBank.Vsc.Data);  SOC = squeeze(oBank.SOC.Data);
pg = squeeze(oBank.Pgen.Data);  pd = squeeze(oBank.Pdc.Data);
rate = (V(1, end) - V(1, 1)) / (t(end) - t(1));                     % average supercap rise [V/s]
t40 = t(end) + (PB.Vchg - V(1, end)) / max(rate, eps);               % when battery charging would start
fig = figure('Visible', 'off', 'Position', [100 100 1100 640]);
subplot(3, 1, 1); plot(t, pg(1, :), 'Color', navy); hold on; plot(t, pd(1, :), 'Color', orange);
grid on; ylabel('power [W]'); legend({'into the generator', 'into the bank'});
title(sprintf('Front bogie: power arrives in bursts (average %.0f W into the bank, peaks above 300 W)', mean(pd(1, t > T0))));
subplot(3, 1, 2); plot(t, V(1, :), 'Color', teal, 'LineWidth', 1.5); grid on; ylabel('supercap [V]');
title(sprintf('Supercapacitor absorbs the bursts: %.1f V to %.1f V in 30 s', V(1, 1), V(1, end)));
subplot(3, 1, 3); plot(t, 100 * SOC(1, :), 'Color', navy, 'LineWidth', 1.5); grid on;
ylabel('battery SOC [%]'); xlabel('time [s]'); ylim([59 61]);
title(sprintf('Battery: charging starts once the supercap passes %.0f V (about %.0f s at this rate)', PB.Vchg, t40));
exportgraphics(fig, fullfile(resdir, 'stage2_bank.png'), 'Resolution', 150); close(fig);

%% 6. Model diagrams
try
    print(['-s' m2], '-dpng', '-r150', fullfile(resdir, 'stage2_model_top.png'));
    print(['-s' m2 '/Smart Damper (EM)'], '-dpng', '-r150', fullfile(resdir, 'stage2_model_damper.png'));
    print(['-s' m2 '/Power Bank (supercap + LiFePO4)'], '-dpng', '-r150', fullfile(resdir, 'stage2_model_bank.png'));
    print(['-s' m2 '/Power Electronics'], '-dpng', '-r150', fullfile(resdir, 'stage2_model_pe.png'));
catch err
    warning('Diagram export failed: %s', err.message);
end
fprintf('Saved results/stage2_*.png\n');

function [o, P] = run2p(mdl, train, design, mode, track, tfault)
% Runs one scenario. Variables go to the base workspace, where the model's InitFcn reads them.
TB = sr_trains(train);
assignin('base', 'trainType', train);   assignin('base', 'designType', design);
assignin('base', 'cmdMode', mode);      assignin('base', 'trackType', track);
assignin('base', 't_fault', tfault);    assignin('base', 'v_kmh', max(TB.speeds));
assignin('base', 'mload_t', max(TB.loads_t));
o = sim(mdl, 'EnablePacing', 'off');
P = evalin('base', 'P');
end

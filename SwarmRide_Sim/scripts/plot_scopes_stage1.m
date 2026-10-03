%% PLOT_SCOPES_STAGE1  Scope views of the default Stage 1 run, drawn from logged data.
%   LHB coach, 12 t, 160 km/h, poor track, today's damper; window 20-30 s.
%   Same signals, colours and layout as the live Simulink scopes, so the figures in the Stage 1
%   report can be regenerated whenever the model changes.

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'), ...
    fullfile(root, 'models'), fullfile(root, 'tests'));
resdir = fullfile(root, 'results');
load_system(fullfile(root, 'models', 'SR_Stage1.slx'));
[o, P] = sr_run('SR_Stage1', 'LHB');
TR = sr_track(P, 'poor');

t = o.az.Time;  k = t >= 20 & t <= 30;
s = P.s0 + P.v * t - P.dist';
w = interp1(TR.x, TR.w, s);
views = { ...
    'stage1b_scope1_body.png',   squeeze(o.az.Data),     'Body acceleration [m/s^2]: centre, over front bogie, over rear bogie', ...
        {'centre', 'over front bogie', 'over rear bogie'}; ...
    'stage1b_scope2_stroke.png', squeeze(o.stroke.Data), 'Secondary stroke [m]: front, rear (limit about +/-0.04 m)', ...
        {'front', 'rear'}; ...
    'stage1b_scope3_force.png',  squeeze(o.Fd.Data),     'Damper force [N]: front, rear', ...
        {'front', 'rear'}; ...
    'stage1b_scope4_rail.png',   w',                     'Rail height [m] under wheels 1-4 (front bogie: 1,2  rear bogie: 3,4)', ...
        {'wheel 1', 'wheel 2', 'wheel 3', 'wheel 4'}};
cols = [1 0.85 0.2; 0.25 0.65 1; 1 0.5 0.15; 0.3 0.85 0.35];       % scope-style line colours
for v = 1:size(views, 1)
    y = views{v, 2};
    fig = figure('Visible', 'off', 'Position', [100 100 760 520], 'Color', [0.13 0.13 0.13]);
    ax = axes(fig, 'Color', 'k', 'XColor', [0.85 0.85 0.85], 'YColor', [0.85 0.85 0.85], ...
        'GridColor', [0.6 0.6 0.6], 'GridAlpha', 0.35);
    hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
    for c = 1:size(y, 1)
        plot(ax, t(k) - 20, y(c, k), 'LineWidth', 1.1, 'Color', cols(c, :));
    end
    xlim(ax, [0 10]); xlabel(ax, 'time in window [s] (20-30 s of the run)');
    title(ax, views{v, 3}, 'Color', [0.92 0.92 0.92], 'FontWeight', 'normal');
    lg = legend(ax, views{v, 4}, 'TextColor', 'w', 'Color', 'k', 'EdgeColor', [0.6 0.6 0.6]);
    lg.Location = 'northeast';
    exportgraphics(fig, fullfile(resdir, views{v, 1}), 'Resolution', 120);
    close(fig);
end
fprintf('Saved results/stage1b_scope1..4 (LHB, 12 t, 160 km/h, poor track, 20-30 s)\n');
fprintf('Window figures: body acc. centre %.2f, front %.2f, rear %.2f m/s^2 peak; stroke %.1f mm peak; force %.1f kN peak; rail %.1f mm peak\n', ...
    max(abs(views{1, 2}(1, k))), max(abs(views{1, 2}(2, k))), max(abs(views{1, 2}(3, k))), ...
    1e3 * max(abs(views{2, 2}(:, k)), [], 'all'), 1e-3 * max(abs(views{3, 2}(:, k)), [], 'all'), ...
    1e3 * max(abs(w(k, :)), [], 'all'));

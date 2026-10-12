function R = test_stage1_physics()
%TEST_STAGE1_PHYSICS The coach model against hand calculations and an independent model.
%   1. Body bounce frequency of every vehicle vs the hand formula (springs in series)
%   2. Simulink vs independent state-space model on the same rail (wiring)
%   3. The passive damper only ever absorbs energy

R = [];
for tr = {'GENERIC', 'LHB', 'VB', 'ICF', 'BOXN'}
    TB = sr_trains(tr{1});
    P = params_for(tr{1}, max(TB.loads_t));
    [~, ~, ~, info] = sr_linear_model(P, 0);
    keff = 1 / (1 / (2 * P.ks) + 1 / (4 * P.kp));             % 2 secondary in series with 4 primary
    f_hand = sqrt(keff / P.m) / (2*pi);
    [~, j] = min(abs(info.f_hz - f_hand));
    R = [R; sr_check(sprintf('%s bounce frequency vs hand formula', tr{1}), ...
        100 * abs(info.f_hz(j) - f_hand) / f_hand, 5, '%', ...
        sprintf('%.3f Hz model vs %.3f Hz hand (bogie mass ignored by hand)', info.f_hz(j), f_hand))]; %#ok<AGROW>
end

[o, P] = sr_run('SR_Stage1', 'LHB');
TR = sr_track(P, 'poor');
[A, Bw] = sr_linear_model(P, P.cs);
t = o.az.Time;
s = P.s0 + P.v * t - P.dist';
u = [interp1(TR.x, TR.w, s), P.v * interp1(TR.x, TR.dwdx, s)];
y = lsim(ss(A, Bw, A(5, :), Bw(5, :)), u, t);
az = squeeze(o.az.Data);  az = az(1, :)';
R = [R; sr_check('Simulink vs state-space model (LHB, poor track)', ...
    100 * max(abs(y - az)) / max(abs(y)), 0.1, '% of peak')];

F = squeeze(o.Fd.Data);  vr = squeeze(o.vrel.Data);
R = [R; sr_check('Passive damper never gives energy (min F*v)', ...
    min(0, min(F .* vr, [], 'all')), 1e-9, 'W')];
end

function P = params_for(trainType, mload_t) %#ok<INUSD,STOUT> outputs are set by the parameter scripts
% Builds P for one vehicle and load without touching the base workspace
% (sr_params is a script, so it runs in this function's workspace).
trackType = 'poor'; %#ok<NASGU>
sr_params;
end

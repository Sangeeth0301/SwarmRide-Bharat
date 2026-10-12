function R = test_stage3()
%TEST_STAGE3 The SwarmRide controllers: stable, passive, energy-consistent, fail-safe, and better.

R = [];
% 1. every LPV grid point is stable (closed loop, discrete time)
for tr = {'LHB', 'VB', 'ICF', 'BOXN'}
    CD = design_for(tr{1});
    R = [R; sr_check(sprintf('%s LPV design: closed-loop spectral radius below 1', tr{1}), ...
        max(0, max(CD.rho) - 1), 0, '', sprintf('max %.5f over %d load points', max(CD.rho), numel(CD.rho)))]; %#ok<AGROW>
end

% 2. C3 on the LHB coach: passive, energy balance, better than today and than C2
[o0, P0] = sr_run('SR_Stage1', 'LHB');
[o3, P3] = sr_run('SR_Stage3', 'LHB', 'designType', 'C', 'ctrlMode', 'C3');
[o2, P2] = sr_run('SR_Stage3', 'LHB', 'designType', 'C', 'ctrlMode', 'C2');
t = o3.az.Time;  k = t > 3;
pg = sr_sig(o3, 'Pgen', t);  cc = sr_sig(o3, 'ccmd', t);
R = [R; sr_check('C3: smart damper never needs bank power (min Pgen)', min(0, min(pg(:, k), [], 'all')), 2, 'W', ...
    'small negatives only from the current-loop lag')];
R = [R; sr_check('C3: damping command stays within 0..c_cap', ...
    max(0, max(cc, [], 'all') - P3.c_cap) + max(0, -min(cc, [], 'all')), 1e-3, 'N s/m')];
EB = sr_energy_balance(o3, P3);
R = [R; sr_check('C3: energy balance', 100 * max(abs(EB.rel)), 0.1, '%')];
R = [R; sr_check('Stage 3 rides the same rail as Stage 1 (train start position)', abs(P3.s0 - P0.s0), 0, 'm', ...
    sprintf('%.2f vs %.2f m', P3.s0, P0.s0))];
W0 = wz(o0, P0);  W2 = wz(o2, P2);  W3 = wz(o3, P3);
R = [R; sr_check('C2 rides better than today (Wz C2 - C0)', max(0, W2 - W0), 0, '', sprintf('%.3f vs %.3f', W2, W0))];
R = [R; sr_check('C3 rides at least as well as C2 (Wz C3 - C2)', max(0, W3 - W2), 0.005, '', sprintf('%.3f vs %.3f', W3, W2))];

% 3. robustness: late / early Train Brain warning and a wrong load estimate
for dt = [-0.02 0.02]
    [od, Pd] = sr_run('SR_Stage3', 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 'preview_dt', dt);
    R = [R; sr_check(sprintf('C3 with warning %+.0f ms off still better than today', 1e3 * dt), ...
        max(0, wz(od, Pd) - W0), 0, '', sprintf('%.3f vs today %.3f', wz(od, Pd), W0))]; %#ok<AGROW>
end
[oh0, Ph0] = sr_run('SR_Stage1', 'LHB', 'mload_t', 5.1);                     % half load: errors move the gains
for le = [-0.10 0.10]
    [ol, Pl] = sr_run('SR_Stage3', 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 'mload_t', 5.1, 'load_err', le);
    R = [R; sr_check(sprintf('C3 at half load with a %+.0f%% load estimate still better than today', 100 * le), ...
        max(0, wz(ol, Pl) - wz(oh0, Ph0)), 0, '', sprintf('%.3f vs today %.3f', wz(ol, Pl), wz(oh0, Ph0)))]; %#ok<AGROW>
end

% 4. fail-safe still works under the controller
[of, ~] = sr_run('SR_Stage3', 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 't_fault', 15);
tf = of.az.Time;  aft = tf > 15.05;
pt = sr_sig(of, 'Pterm', tf);
R = [R; sr_check('C3 fail-safe: harvesting stops after the fault', max(abs(pt(:, aft)), [], 'all'), 1e-6, 'W')];
end

function W = wz(o, P)
t = o.az.Time;  a = squeeze(o.az.Data);
W = sr_sperling(a(1, t > 3), 1 / P.Ts);
end

function CD = design_for(trainType) %#ok<INUSD,STOUT> outputs are set by the parameter scripts
designType = 'C'; ctrlMode = 'C3'; trackType = 'poor'; %#ok<NASGU>
sr_params;
sr_params_stage3;
end

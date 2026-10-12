function R = test_stage2()
%TEST_STAGE2 The smart damper and power chain against Stage 1 and against hand calculations.

R = [];
[o1, P1] = sr_run('SR_Stage1', 'LHB');
[oA, PA, DA] = sr_run('SR_Stage2', 'LHB', 'designType', 'A', 'cmdMode', 'match');
t = oA.az.Time;  k = t > 3;

% 1. same ride as today
a1 = squeeze(o1.az.Data);  a2 = squeeze(oA.az.Data);
R = [R; sr_check('EM copy of today''s damper: body acceleration vs Stage 1', ...
    100 * max(abs(a1(1, :) - a2(1, :))) / max(abs(a1(1, :))), 3, '% of peak', 'difference = 2 ms current loop')];
W1 = sr_sperling(a1(1, k), 1 / P1.Ts);  W2 = sr_sperling(a2(1, k), 1 / PA.Ts);
R = [R; sr_check('EM copy of today''s damper: Sperling Wz vs Stage 1', 100 * abs(W2 - W1) / W1, 0.5, '%', ...
    sprintf('%.3f vs %.3f', W2, W1))];

% 2. damping law F = c v
F = squeeze(oA.Fd.Data);  vr = squeeze(oA.vrel.Data);
c_fit = sum(F(:, k) .* vr(:, k), 'all') / sum(vr(:, k).^2, 'all');
R = [R; sr_check('Damping law: fitted c vs commanded', 100 * abs(c_fit - PA.c_cmd_emd) / PA.c_cmd_emd, 1, '%')];

% 3. hand calculations of the power chain
Pgen = sr_sig(oA, 'Pgen', t);  Pterm = sr_sig(oA, 'Pterm', t);  Pdc = sr_sig(oA, 'Pdc', t);
F1 = squeeze(o1.Fd.Data);  v1 = squeeze(o1.vrel.Data);
heat1 = mean(F1(:, k) .* v1(:, k), 'all');
R = [R; sr_check('Power into the damper = today''s damper heat', ...
    100 * abs(mean(Pgen(:, k), 'all') - heat1) / heat1, 1, '%', sprintf('%.1f vs %.1f W', mean(Pgen(:, k), 'all'), heat1))];
eta_e = mean(Pterm(:, k), 'all') / mean(Pgen(:, k), 'all');
eta_hand = 1 - PA.c_cmd_emd / PA.cmax_emd;
R = [R; sr_check('Coil efficiency vs 1 - c/c_max', 100 * abs(eta_e - eta_hand), 1, 'points', ...
    sprintf('%.3f vs %.3f', eta_e, eta_hand))];
eta_c = mean(Pdc(:, k), 'all') / mean(Pterm(:, k), 'all');
R = [R; sr_check('Converter chain vs 0.95 x 0.94', 100 * abs(eta_c - PA.eta_rect * PA.eta_dcdc), 0.5, 'points', ...
    sprintf('%.4f vs %.4f', eta_c, PA.eta_rect * PA.eta_dcdc))];
[oH, PH] = sr_run('SR_Stage2', 'LHB', 'designType', 'A', 'cmdMode', 'harvest');
th = oH.az.Time;
eh = mean(sr_sig(oH, 'Pterm', th), 'all') / mean(sr_sig(oH, 'Pgen', th), 'all');
R = [R; sr_check('Harvest setting: coil efficiency = 0.5 (load = coil resistance)', 100 * abs(eh - 0.5), 1, 'points', ...
    sprintf('%.3f', eh))];
c_fs = DA.nd * DA.Ke^2 / (DA.Rc + DA.R_fs);
R = [R; sr_check('Fail-safe resistor formula gives today''s damping', 100 * abs(c_fs - DA.c_today) / DA.c_today, 1e-6, '%')];

% 4. energy balance (designs A and C, and harvest)
for c = {{oA, PA, 'A match'}, {oH, PH, 'A harvest'}}
    EB = sr_energy_balance(c{1}{1}, c{1}{2});
    R = [R; sr_check(['Energy balance, design ' c{1}{3}], 100 * max(abs(EB.rel)), 0.1, '%')]; %#ok<AGROW>
end
[oC, PC] = sr_run('SR_Stage2', 'BOXN', 'designType', 'C', 'cmdMode', 'match');
EB = sr_energy_balance(oC, PC);
R = [R; sr_check('Energy balance, BOXN design C', 100 * max(abs(EB.rel)), 0.1, '%')];

% 5. fail-safe in the simulation
for dz = {'A', 'B'}
    [of, Pf] = sr_run('SR_Stage2', 'LHB', 'designType', dz{1}, 't_fault', 15);
    tf = of.az.Time;  aft = tf > 15.05;
    Ff = squeeze(of.Fd.Data);  vf = squeeze(of.vrel.Data);  pt = sr_sig(of, 'Pterm', tf);
    ca = sum(Ff(:, aft) .* vf(:, aft), 'all') / sum(vf(:, aft).^2, 'all');
    R = [R; sr_check(sprintf('Fail-safe design %s: damping after fault vs today', dz{1}), ...
        100 * abs(ca - Pf.c_today) / Pf.c_today, 0.5, '%')]; %#ok<AGROW>
    R = [R; sr_check(sprintf('Fail-safe design %s: harvesting after fault', dz{1}), ...
        max(abs(pt(:, aft)), [], 'all'), 1e-6, 'W')]; %#ok<AGROW>
end

% 6. no power drawn by the damper in normal running (passive by design)
R = [R; sr_check('Smart damper never needs bank power (min Pgen)', ...
    min(0, min(Pgen(:, k), [], 'all')), 1, 'W', 'small negatives only from the 2 ms current lag')];
end

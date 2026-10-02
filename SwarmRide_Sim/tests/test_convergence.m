function R = test_convergence()
%TEST_CONVERGENCE Results must not depend on the solver step size.
%   Each case is run at its normal step and at half of it; ride and power must agree.

R = [];
cases = { ...
    'SR_Stage1', 'LHB',  {},                       'Stage 1 LHB (1 ms vs 0.5 ms)'; ...
    'SR_Stage1', 'BOXN', {},                       'Stage 1 BOXN friction (0.5 ms vs 0.25 ms)'; ...
    'SR_Stage2', 'LHB',  {'designType', 'C'},      'Stage 2 LHB design C (1 ms vs 0.5 ms)'; ...
    'SR_Stage2', 'BOXN', {'designType', 'C'},      'Stage 2 BOXN design C (0.5 ms vs 0.25 ms)'};
for c = 1:size(cases, 1)
    [o1, P1] = sr_run(cases{c, 1}, cases{c, 2}, cases{c, 3}{:});
    [o2, P2] = sr_run(cases{c, 1}, cases{c, 2}, cases{c, 3}{:}, 'Ts_override', P1.Ts / 2);
    M1 = ride(o1, P1);  M2 = ride(o2, P2);
    R = [R; sr_check([cases{c, 4} ': Sperling Wz'], 100 * abs(M2.Wz - M1.Wz) / M1.Wz, 1, '%', ...
        sprintf('%.3f vs %.3f', M1.Wz, M2.Wz))]; %#ok<AGROW>
    R = [R; sr_check([cases{c, 4} ': body RMS'], 100 * abs(M2.rms - M1.rms) / M1.rms, 1, '%', ...
        sprintf('%.4f vs %.4f m/s^2', M1.rms, M2.rms))]; %#ok<AGROW>
    R = [R; sr_check([cases{c, 4} ': damper power'], 100 * abs(M2.P - M1.P) / M1.P, 2, '%', ...
        sprintf('%.1f vs %.1f W', M1.P, M2.P))]; %#ok<AGROW>
end
end

function M = ride(o, P)
t = o.az.Time;  k = t > 3;
a = squeeze(o.az.Data);  a = a(1, k);
M.rms = sqrt(mean(a.^2));
M.Wz = sr_sperling(a, 1 / P.Ts);
if any(strcmp(o.who, 'Pdc'))
    pd = sr_sig(o, 'Pdc', t);  M.P = mean(pd(:, k), 'all');           % power into the bank
else
    F = squeeze(o.Fd.Data);  vr = squeeze(o.vrel.Data);
    M.P = mean(F(:, k) .* vr(:, k), 'all');                          % heat in today's damper
end
end

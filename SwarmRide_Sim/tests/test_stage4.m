function R = test_stage4()
%TEST_STAGE4 Active push, journey bank model and health sensing.

R = [];
% 1. Stage 4 with its new parts off is exactly Stage 3
[o3, P3] = sr_run('SR_Stage3', 'LHB', 'designType', 'C', 'ctrlMode', 'C3');
[o4, ~]  = sr_run('SR_Stage4', 'LHB', 'designType', 'C', 'ctrlMode', 'C3');
a3 = squeeze(o3.az.Data);  a4 = squeeze(o4.az.Data);
R = [R; sr_check('Stage 4 with new parts off reproduces Stage 3', ...
    100 * max(abs(a3(1, :) - a4(1, :))) / max(abs(a3(1, :))), 1e-6, '% of peak')];

% 2. the journey bank model matches the Simulink bank on the same power
t = o3.az.Time;  pd = sr_sig(o3, 'Pdc', t);  pl = sr_sig(o3, 'Pload', t);  vsc = squeeze(o3.Vsc.Data);
Esc = P3.Esc0;  SOC = P3.SOC0;
for k = 1:numel(t) - 1
    [Esc, SOC] = sr_bank_step(Esc, SOC, pd(1, k), pl(1, k), P3, t(k + 1) - t(k));
end
R = [R; sr_check('Journey bank model vs Simulink bank (supercap voltage after 30 s)', ...
    abs(sqrt(2 * Esc / P3.Csc) - vsc(1, end)), 0.02, 'V')];

% 3. C4: pushes only inside its windows, pays from the bank, never runs it dry, and helps
[oc, Pc] = sr_run('SR_Stage4', 'LHB', 'designType', 'C', 'ctrlMode', 'C4', 'trackType', 'settlement');
[os, ~]  = sr_run('SR_Stage4', 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 'trackType', 'settlement');
tc = oc.az.Time;  pt = sr_sig(oc, 'Pterm', tc);  act = sr_sig(oc, 'act', tc);  un = sr_sig(oc, 'Punserved', tc);
EB = sr_energy_balance(oc, Pc);
R = [R; sr_check('C4: energy balance with active pushes (share of energy that flowed)', 100 * max(abs(EB.rel_flow)), 1, '%', ...
    sprintf('%.0f J flowed', sum(EB.flow)))];
R = [R; sr_check('C4: bank power drawn only inside the push windows', ...
    max(abs(min(pt(act < 0.5), 0)), [], 'all'), 2, 'W', 'small negatives only from the current-loop lag')];
R = [R; sr_check('C4: bogie loads always served', max(un, [], 'all'), 1e-9, 'W')];
ac = squeeze(oc.az.Data);  as = squeeze(os.az.Data);
R = [R; sr_check('C4 lowers the worst-seat peak at the settlement vs C3', ...
    max(0, max(abs(ac), [], 'all') - max(abs(as), [], 'all')), 0, 'm/s^2', ...
    sprintf('%.3f vs %.3f', max(abs(ac), [], 'all'), max(abs(as), [], 'all')))];
[op, ~] = sr_run('SR_Stage4', 'LHB', 'designType', 'C', 'ctrlMode', 'C4');            % no bad spots on this rail
ap = squeeze(op.az.Data);
R = [R; sr_check('C4 with no known bad spots behaves exactly like C3', ...
    100 * max(abs(ap(1, :) - a4(1, :))) / max(abs(a4(1, :))), 1e-6, '% of peak')];

% 4. health: the hot-axle model and the wheel-defect signature
H = sr_hot_axle();
R = [R; sr_check('Hot axle: on-bogie alarm before the failure temperature', ...
    max(0, H.self.T_detect - H.opt.T_fail), 0, 'C', sprintf('alarm at %.0f C', H.self.T_detect))];
[ow, Pw] = sr_run('SR_Stage4', 'LHB', 'designType', 'C', 'ctrlMode', 'C3', 'wheel_runout', 0.5e-3);
fw = Pw.v / (2 * pi * Pw.wheel_R);
amp = @(o, ch) peak_at(o, ch, fw, Pw);
R = [R; sr_check('Wheel defect raises the front-bogie coil signal at the wheel frequency (x times healthy)', ...
    max(0, 5 - amp(ow, 1) / amp(o4, 1)), 0, '', sprintf('x%.0f', amp(ow, 1) / amp(o4, 1)))];
end

function A = peak_at(o, ch, fw, P)
t = o.az.Time;  k = t > 3;  e = sr_sig(o, 'e_coil', t);  x = e(ch, k) - mean(e(ch, k));
n = numel(x);  X = abs(fft(x)) * 2 / n;  f = (0:n - 1) / (n * P.Ts);
A = max(X(abs(f - fw) < 0.3));
end

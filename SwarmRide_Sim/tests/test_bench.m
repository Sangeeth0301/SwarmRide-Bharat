function R = test_bench()
%TEST_BENCH Bench prototype: the bench model, the hardware sizing and the C firmware.
%   Needs results/bench_drive.mat (written by scripts/check_bench.m) and models/SR_Bench.slx.
%   The firmware host test runs only when gcc is found (PATH or C:\msys64\ucrt64\bin).
root = fileparts(fileparts(mfilename('fullpath')));
load_system(fullfile(root, 'models', 'SR_Bench.slx'));
BD = load(fullfile(root, 'results', 'bench_drive.mat'));
R = [];

% 1. hardware sizing: hand relations
o = bench('emf', 'real');  BP = evalin('base', 'BP');
R = [R; sr_check('Sizing: motor torque constant = Ke x lead / 2 pi', 100 * abs(BP.Kt / (BP.Ke * BP.lead / (2*pi)) - 1), 1e-9, '%')];
cfs = BP.Ke^2 / (BP.Rc + BP.R_fs);
R = [R; sr_check('Sizing: fail-safe resistors give today''s damping per damper', 100 * abs(cfs / BP.c_today - 1), 0.01, '%', ...
    sprintf('%.0f vs %.0f N s/m', cfs, BP.c_today))];

% 2. back-EMF test recovers Ke (zero current)
v = squeeze(o.v.Data);  u = squeeze(o.u.Data);  k = abs(v) > 0.095;
Ke = sum(u(k) .* v(k)) / sum(v(k).^2);
R = [R; sr_check('Bench model: back-EMF test recovers the machine constant', 100 * abs(Ke / BP.Ke - 1), 1, '%', ...
    sprintf('%.2f vs %.2f V s/m', Ke, BP.Ke))];

% 3. bench model simplified like the vehicle model = vehicle model (rough-track replay)
o = bench('replay_poor', 'simequiv');
t = o.F_lc.Time;  F = squeeze(o.F_lc.Data);  kk = t > 3 & t < t(end) - 0.01;
Fv = interp1(double(BD.DR.poor.t), double(BD.DR.poor.Fd), t);
d = 100 * max(abs(F(kk) - Fv(kk))) / max(abs(Fv(kk)));
R = [R; sr_check('Bench model (vehicle-model simplifications) = vehicle model damper force', d, 3, '% of peak')];

% 4. energy balance, real hardware
o = bench('replay_poor', 'real');  BP = evalin('base', 'BP');
E = squeeze(o.E.Data);  if size(E, 1) ~= 8, E = E.'; end;  E = E(:, end);
v = squeeze(o.v.Data);  i = squeeze(o.i.Data);
dKE = 0.5 * BP.b_in * (v(end)^2 - v(1)^2) + 0.5 * BP.L * (i(end)^2 - i(1)^2);
res = abs(E(1) - sum(E(2:5)) - dKE) + abs(E(5) - sum(E(6:8)));
R = [R; sr_check('Bench model: energy balance (rig work = losses + bank + stored)', 100 * res / sum(abs(E(1:5))), 0.5, '%', ...
    sprintf('%.0f J of rig work', E(1)))];
pb = mean(squeeze(o.Pbank.Data(kk)));  pv = mean(double(BD.DR.poor.Pdc(double(BD.DR.poor.t) > 3)));
R = [R; sr_check('Bench model with real losses: power into the bank vs vehicle model', 100 * abs(pb / pv - 1), 10, '%', ...
    sprintf('%.1f vs %.1f W', pb, pv))];

% 5. current loop: first-order with the designed time constant
o = bench('step', 'real', struct('Tlog', 1e-4));  BP = evalin('base', 'BP');
t = o.i.Time;  ii = squeeze(o.i.Data);  ir = squeeze(o.iref.Data);  k = t >= 0.298 & t < 0.348;
tau = trapz(t(k), ir(k) - ii(k)) / (BP.c_req * 0.05 / BP.Ke);
R = [R; sr_check('Drive: current loop time constant vs design', 100 * abs(tau / BP.tau_cl - 1), 25, '%', ...
    sprintf('%.3f vs %.3f ms', 1e3 * tau, 1e3 * BP.tau_cl))];

% 6. fail-safe: today's damping after the contactor drops, gap = contactor time
o = bench('failsafe', 'real');  BP = evalin('base', 'BP');
t = o.F_lc.Time;  F = squeeze(o.F_lc.Data);  v = squeeze(o.v.Data);  a = gradient(v, t);  md = squeeze(o.mode.Data);
af = t > 5.2;  th = [v(af), tanh(v(af) / BP.veps), a(af)] \ F(af);
R = [R; sr_check('Fail-safe: damping after the contactor drops = today''s damper', 100 * abs(th(1) / BP.c_today - 1), 2, '%', ...
    sprintf('%.0f vs %.0f N s/m', th(1), BP.c_today))];
gap = sum(md > 0.5 & md < 1.5) * (t(2) - t(1));
R = [R; sr_check('Fail-safe: time without electromagnetic force = contactor drop-out', 1e3 * abs(gap - BP.t_contactor), 2, 'ms', ...
    sprintf('%.0f ms', 1e3 * gap))];

% 7. damping law at 60 % of c_req
o = bench('damping', 'real');  BP = evalin('base', 'BP');
t = o.F_lc.Time;  F = squeeze(o.F_lc.Data);  v = squeeze(o.v.Data);  c = squeeze(o.c.Data);  a = gradient(v, t);
z = find(c == 0);  z = z(t(z) > 0.5);  th = [tanh(v(z) / BP.veps), a(z)] \ F(z);
lv = 0.6 * BP.c_req;  s = find(abs(c - lv) < 1);  s = s(t(s) > t(s(1)) + 0.5);
Fr = F(s) - th(1) * tanh(v(s) / BP.veps) - th(2) * a(s);
cf = (v(s)' * Fr) / (v(s)' * v(s));
R = [R; sr_check('Drive: measured damping = command (60 % of c_req)', 100 * abs(cf / lv - 1), 2, '%', ...
    sprintf('%.0f vs %.0f N s/m', cf, lv))];

% 8. firmware host test (double and float) against the MATLAB vectors
fw = fullfile(fileparts(root), 'Bench_Prototype', 'firmware');
gcc = find_gcc();
if isempty(gcc)
    warning('test_bench:gcc', 'gcc not found: the firmware host test was not run.');
else
    for fl = {'', '-DSR_USE_FLOAT'}
        exe = fullfile(tempdir, ['sr_host_test' strrep(fl{1}, '-DSR_USE_', '_') '.exe']);
        cmd = sprintf('"%s" -std=c99 -O2 -Wall -Wextra -pedantic %s -I"%s" -o "%s" %s "%s" -lm', gcc, fl{1}, ...
            fullfile(fw, 'include'), exe, strjoin(cellfun(@(f) ['"' fullfile(fw, 'src', f) '"'], ...
            {'sr_preview.c', 'sr_lpv.c', 'sr_semiactive.c', 'sr_drive.c', 'sr_bank.c', 'sr_ctrl.c'}, 'UniformOutput', false), ' '), ...
            fullfile(fw, 'test', 'host_test.c'));
        [st1, out1] = system(['set "PATH=' fileparts(gcc) ';%PATH%" && ' cmd]);
        [st2, out2] = system(sprintf('"%s" "%s"', exe, fullfile(fw, 'test', 'vectors')));
        tok = regexp(out2, '(\d+) of (\d+) checks passed', 'tokens', 'once');
        nfail = 99;  if ~isempty(tok), nfail = str2double(tok{2}) - str2double(tok{1}); end
        name = 'double';  if ~isempty(fl{1}), name = 'float'; end
        if isempty(tok), tok = {'0', '?'}; end
        note = sprintf('%s of %s host checks pass; compiler warnings: %d', tok{1}, tok{2}, numel(strfind(out1, 'warning')));
        R = [R; sr_check(sprintf('Firmware (C, %s) = MATLAB controller, drive and bank', name), nfail + (st1 ~= 0) + (st2 ~= 0), 0, 'fails', note)]; %#ok<AGROW>
    end
end
end

function o = bench(test, mode, ovr)
if nargin < 3, ovr = []; end
assignin('base', 'benchTest', test);
assignin('base', 'benchMode', mode);
assignin('base', 'BP_override', ovr);
o = sim('SR_Bench', 'EnablePacing', 'off');
assignin('base', 'BP_override', []);
end

function g = find_gcc()
g = '';
[st, out] = system('where gcc');
if st == 0
    g = strtrim(strtok(out, newline));
elseif isfile('C:\msys64\ucrt64\bin\gcc.exe')
    g = 'C:\msys64\ucrt64\bin\gcc.exe';
end
end

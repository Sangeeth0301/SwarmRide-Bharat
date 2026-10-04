function BX = bp_bench_profile(test, HW, DR)
%BP_BENCH_PROFILE Motion and commands the test rig plays into ONE damper for a bench test.
%   BX = bp_bench_profile(test, HW, DR)
%   The rig is a displacement-controlled actuator: it moves the damper (x, v, a) and the drive
%   receives the damping command c, the push force F, the push window act and a test fault.
%   DR holds the damper motion and commands recorded in the vehicle simulation (front bogie).
%
%   test          what it shows
%   'emf'         back-EMF constant: constant-speed strokes at +-0.1 m/s, drive commands zero current
%   'damping'     damping law: 1.5 Hz sine, 12 mm, damping command 0, then 20..100 % of c_req
%   'step'        current-loop speed: constant 0.05 m/s stroke, damping command stepped at 0.3 s
%   'vlimit'      voltage limit: 2 Hz sine growing from 2 to 30 mm at full design damping
%   'failsafe'    1.5 Hz sine at today's damping; a fault drops the contactor at 5 s
%   'replay_poor' / 'replay_good' / 'replay_settle'
%                 the damper's own motion and commands from the vehicle simulation (LHB crowded,
%                 160 km/h): rough track (C3), smooth track (C3), track settlement with push (C4)

dt = 1e-3;
switch test
    case 'emf'
        T = 4;  t = (0:dt:T)';  vp = 0.1;  per = 1;
        v = vp * sign(sin(2*pi*t/per + 1e-9));                 % triangle displacement: +-v
        v = smooth_edges(v, t, 0.02);
        c = zeros(size(t));
    case 'damping'
        lev = [0 0.2 0.4 0.6 0.8 1.0];  Tl = 4;  T = Tl * numel(lev);   % 0: friction and inertance alone
        t = (0:dt:T)';  A = 0.012;  f = 1.5;  w = 2*pi*f;
        v = A * w * cos(w * t);
        c = HW.c_req * lev(min(floor(t / Tl) + 1, numel(lev)))';
    case 'step'
        T = 1;  t = (0:dt:T)';  v = 0.05 * ones(size(t));
        c = HW.c_req * (t >= 0.3);
    case 'vlimit'
        T = 20;  t = (0:dt:T)';  f = 2;  w = 2*pi*f;
        A = 0.002 + 0.028 * t / T;                              % amplitude grows linearly
        x = A .* sin(w * t);
        v = gradient(x, dt);
        c = HW.c_req * ones(size(t));
    case 'failsafe'
        T = 10;  t = (0:dt:T)';  A = 0.012;  f = 1.5;  w = 2*pi*f;
        v = A * w * cos(w * t);
        c = HW.c_today * ones(size(t));
    case {'replay_poor', 'replay_good', 'replay_settle'}
        R = DR.(strrep(test, 'replay_', ''));
        t = double(R.t(:));  t = t - t(1);  T = t(end);
        BX = struct('test', test, 't', t, 'x', double(R.x(:)), 'v', double(R.v(:)), ...
            'a', gradient(double(R.v(:)), t), 'c', double(R.c(:)), 'F', double(R.F(:)), ...
            'act', double(R.act(:)), 'fault', zeros(size(t)), 'Tend', T);
        return
    otherwise
        error('bp_bench_profile:test', 'Unknown bench test ''%s''.', test);
end
if ~exist('x', 'var')
    x = cumtrapz(t, v);  x = x - (max(x) + min(x)) / 2;        % centred in the stroke
end
fault = double(strcmp(test, 'failsafe') & t >= 5);
BX = struct('test', test, 't', t, 'x', x, 'v', v, 'a', gradient(v, t), 'c', c, ...
    'F', zeros(size(t)), 'act', zeros(size(t)), 'fault', fault, 'Tend', T);
end

function v = smooth_edges(v, t, tr)
% rounds the speed reversals of a triangle stroke over tr seconds (a real rig cannot jump)
n = max(round(tr / (t(2) - t(1))), 1);
v = conv(v, ones(n, 1) / n, 'same');
end

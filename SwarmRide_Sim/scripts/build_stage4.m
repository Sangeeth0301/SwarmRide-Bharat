%% BUILD_STAGE4  Builds models/SR_Stage4.slx : active push at known bad spots + wheel-defect input
%   Starts from SR_Stage3 and adds:
%     1. Controller: "Active windows (known bad spots)": for C4, each bogie may push (draw bank power)
%        from act_window_s before a known bad spot until act_window_s after it.
%     2. Smart Damper: the H-bridge follows the ideal force F* inside a window (motoring), and the
%        damping law outside it, exactly as in Stage 3.
%     3. Wheel defect (out-of-round front wheelset) between the Track Input and the coach, for the
%        health-sensing demo; off by default.
%   Run from the SwarmRide_Sim folder:   >> run scripts/build_stage4

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'));
f3 = fullfile(root, 'models', 'SR_Stage3.slx');
if ~isfile(f3), run(fullfile(root, 'scripts', 'build_stage3.m')); end
mdl = 'SR_Stage4';
f = fullfile(root, 'models', [mdl '.slx']);
for m = {mdl, 'SR_Stage3'}
    if bdIsLoaded(m{1}), close_system(m{1}, 0); end
end
if isfile(f), delete(f); end
load_system(f3);
save_system('SR_Stage3', f);                       % the copy in memory is now SR_Stage4
set_param(mdl, 'InitFcn', 'sr_params; sr_params_stage3; sr_params_stage4; TR = sr_track(P, trackType);');
PLANT = 'Vehicle Plant (half-coach 4-DOF)';
SD  = 'Smart Damper (EM)';
CTL = 'SwarmRide Controller (LPV + preview)';
rt = sfroot;
script = @(path, code) set(rt.find('-isa', 'Stateflow.EMChart', 'Path', path), 'Script', code);

%% 1. Controller: preview for C3 and C4, plus the active windows
script([mdl '/' CTL '/LPV state feedback + preview (100 Hz)'], strjoin({ ...
    'function F_star = fcn(x, p, m_hat, P)'
    '% LPV: blend the gains of the two load-grid points around the measured load.'
    '% C2: F* = -Kx x.   C3 / C4: F* = -Kx x - Kp p  (Train Brain preview of the rail around the train).'
    'mg = P.Kgrid_m;  nL = numel(mg);'
    'i = 1;  a = 0;'
    'if m_hat >= mg(nL)'
    '    i = nL - 1;  a = 1;'
    'elseif m_hat > mg(1)'
    '    for k = 1:nL - 1'
    '        if m_hat >= mg(k) && m_hat <= mg(k + 1)'
    '            i = k;  a = (m_hat - mg(k)) / (mg(k + 1) - mg(k));'
    '        end'
    '    end'
    'end'
    'Kx = reshape((1 - a) * P.Kx(i, :) + a * P.Kx(i + 1, :), 2, 8);'
    'F_star = -Kx * x;'
    'if P.ctrl >= 3'
    '    np = size(P.Kp, 2) / 2;'
    '    Kp = reshape((1 - a) * P.Kp(i, :) + a * P.Kp(i + 1, :), 2, np);'
    '    F_star = F_star - Kp * p;'
    'end'}, newline));
s = [mdl '/' CTL];
add_block('simulink/Sources/Clock', [s '/Clock'], 'Position', [40 270 60 290]);
sr_mlfcn([s '/Active windows (known bad spots)'], [230 250 400 310], strjoin({ ...
    'function act = fcn(t, P)'
    '% C4 only: 1 while a bogie centre is within the window around a known bad spot from the'
    '% fleet track map; there the damper may push, using energy from the bogie bank.'
    'act = zeros(2, 1);'
    'if P.ctrl == 4'
    '    s  = P.s0 + P.v * t;                          % lead wheel position [m]'
    '    sb = s - [P.ab; 2 * P.lb + P.ab];             % front and rear bogie centres [m]'
    '    for b = 1:2'
    '        for k = 1:numel(P.bad_x)'
    '            if sb(b) >= P.bad_x(k) - P.act_before && sb(b) <= P.bad_x(k) + P.bad_len(k) + P.act_after'
    '                act(b) = 1;'
    '            end'
    '        end'
    '    end'
    'end'}, newline), {'P'}, {'act', '[2 1]'});
add_block('built-in/Outport', [s '/act'], 'Position', [980 273 1010 287]);
add_line(s, 'Clock/1', 'Active windows (known bad spots)/1');
add_line(s, 'Active windows (known bad spots)/1', 'act/1');
sr_add_log(s, 'Active windows (known bad spots)/1', 'act', [980 310 1060 334]);

%% 2. Smart Damper: force path inside the windows
s = [mdl '/' SD];
add_block('built-in/Inport', [s '/F_act'], 'Position', [30 323 60 337]);
add_block('built-in/Inport', [s '/act'],   'Position', [30 363 60 377]);
script([s '/H-bridge current reference'], strjoin({ ...
    'function iref = fcn(c_cmd, vrel, F_act, act, P)'
    '% Normal (semi-active): the current sets the damping, F = nd Ke i = c vrel, c in 0..Ke^2/Rc.'
    '% Inside a C4 window (act = 1): follow the ideal force F* directly. The H-bridge then runs the'
    '% coil as a motor when F* pushes, drawing power from the bank. Current is limited to the rating.'
    'c = min(max(c_cmd, 0), P.cmax_emd);'
    'iref = c .* vrel / (P.nd * P.Ke);'
    'iref = (1 - act) .* iref + act .* F_act / (P.nd * P.Ke);'
    'iref = min(max(iref, -P.imax), P.imax);'}, newline));
add_line(s, 'F_act/1', 'H-bridge current reference/3', 'autorouting', 'on');
add_line(s, 'act/1',   'H-bridge current reference/4', 'autorouting', 'on');
add_line(mdl, [CTL '/2'], [SD '/4'], 'autorouting', 'on');           % F* -> smart damper
add_line(mdl, [CTL '/3'], [SD '/5'], 'autorouting', 'on');           % active windows

%% 3. Wheel defect between the Track Input and the coach
delete_line(mdl, 'Track Input/1', [PLANT '/1']);
delete_line(mdl, 'Track Input/2', [PLANT '/2']);
add_block('simulink/Sources/Clock', [mdl '/Clock (wheel)'], 'Position', [250 330 270 350]);
sr_mlfcn([mdl '/Wheel defect (front wheelset)'], [260 150 320 260], strjoin({ ...
    'function [w2, wd2] = fcn(w, wd, t, P)'
    '% Out-of-round front wheelset: radial run-out of order n raises and lowers the wheel centre'
    '% n times per revolution. Off when P.wheel_runout = 0.'
    'w2 = w;  wd2 = wd;'
    'if P.wheel_runout > 0'
    '    s  = P.s0 + P.v * t;                          % rolling distance of the lead wheel [m]'
    '    ph = P.wheel_order * s / P.wheel_R;'
    '    w2(1)  = w(1) + P.wheel_runout * sin(ph);'
    '    wd2(1) = wd(1) + P.wheel_runout * P.wheel_order * P.v / P.wheel_R * cos(ph);'
    'end'}, newline), {'P'}, {'w2', '[4 1]'; 'wd2', '[4 1]'});
add_line(mdl, 'Track Input/1', 'Wheel defect (front wheelset)/1', 'autorouting', 'on');
add_line(mdl, 'Track Input/2', 'Wheel defect (front wheelset)/2', 'autorouting', 'on');
add_line(mdl, 'Clock (wheel)/1', 'Wheel defect (front wheelset)/3', 'autorouting', 'on');
add_line(mdl, 'Wheel defect (front wheelset)/1', [PLANT '/1'], 'autorouting', 'on');
add_line(mdl, 'Wheel defect (front wheelset)/2', [PLANT '/2'], 'autorouting', 'on');

%% 4. Note
try
    notes = find_system(mdl, 'FindAll', 'on', 'SearchDepth', 1, 'Type', 'annotation');
    for k = 1:numel(notes)
        if startsWith(get_param(notes(k), 'Text'), 'Stage 3'), delete(notes(k)); end
    end
catch
end
try
    nt = add_block('built-in/Note', [mdl '/Stage 4: ctrlMode = C4 adds an active push at known bad spots (bank-powered); wheel_runout > 0 adds an out-of-round front wheel']);
    set_param(nt, 'Position', [60 40 1000 70]);
catch
end

save_system(mdl, f);
close_system(mdl, 0);
fprintf('Built %s\n', f);

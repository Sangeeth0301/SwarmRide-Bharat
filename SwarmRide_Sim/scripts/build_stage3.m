%% BUILD_STAGE3  Builds models/SR_Stage3.slx : SwarmRide controllers (C1, C2 LPV, C3 LPV + preview)
%   Starts from SR_Stage2 (same track, coach, smart damper, power electronics and bank) and replaces
%   the fixed Damping Command with:
%     Train Brain (track preview) --p--> SwarmRide Controller --c_cmd--> Smart Damper
%     Vehicle Plant --x (states), vrel--^
%   Run from the SwarmRide_Sim folder:   >> run scripts/build_stage3

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'));
f2 = fullfile(root, 'models', 'SR_Stage2.slx');
if ~isfile(f2), run(fullfile(root, 'scripts', 'build_stage2.m')); end
mdl = 'SR_Stage3';
f = fullfile(root, 'models', [mdl '.slx']);
for m = {mdl, 'SR_Stage2'}
    if bdIsLoaded(m{1}), close_system(m{1}, 0); end
end
if isfile(f), delete(f); end
load_system(f2);
save_system('SR_Stage2', f);                       % the copy in memory is now SR_Stage3
K3 = sr_stage3_consts();
set_param(mdl, 'InitFcn', 'sr_params; sr_params_stage3; TR = sr_track(P, trackType);', ...
    'SolverMode', 'SingleTasking');
PLANT = 'Vehicle Plant (half-coach 4-DOF)';
SD = 'Smart Damper (EM)';
TBR = 'Train Brain (track preview)';
CTL = 'SwarmRide Controller (LPV + preview)';

%% 1. Coach states out of the Vehicle Plant (for state feedback)
pl = [mdl '/' PLANT];
add_block('simulink/Signal Routing/Vector Concatenate', [pl '/States'], 'NumInputs', '2', ...
    'Position', [560 210 570 250]);
add_block('built-in/Outport', [pl '/x'], 'Position', [740 223 770 237]);
add_line(pl, 'Positions/1', 'States/1', 'autorouting', 'on');
add_line(pl, 'Velocities/1', 'States/2', 'autorouting', 'on');
add_line(pl, 'States/1', 'x/1');

%% 2. Remove the fixed Damping Command
delete_line(mdl, 'Damping Command/1', [SD '/2']);
delete_block([mdl '/Damping Command']);

%% 3. Train Brain: rail heights from Nb samples behind to Na samples ahead of the lead wheel
s = [mdl '/' TBR];
add_block('built-in/Subsystem', s, 'Position', [60 270 220 320]);
set_param(s, 'Description', ['Rail profile around the lead wheel, from the fleet track map and the ' ...
    'locomotive''s lead bogie: one sample every Tc of travel, 1 s ahead. preview_dt shifts it in time.']);
add_block('simulink/Sources/Clock', [s '/Clock'], 'Position', [30 40 50 60]);
add_block('simulink/Math Operations/Gain', [s '/Speed v'], 'Gain', 'P.v', 'Position', [80 35 120 65]);
add_block('simulink/Math Operations/Bias', [s '/Lead wheel position (+ timing error)'], ...
    'Bias', 'P.s0 + P.v*P.preview_dt', 'Position', [150 35 200 65]);
add_block('simulink/Sources/Constant', [s '/Sample offsets'], 'Value', 'P.pj', 'Position', [150 100 200 130]);
add_block('simulink/Math Operations/Sum', [s '/Sample positions'], 'Inputs', '++', 'Position', [250 50 270 110]);
add_block('simulink/Discrete/Zero-Order Hold', [s '/Every Tc'], 'SampleTime', 'P.Tc', 'Position', [310 65 350 95]);
add_block('simulink/Lookup Tables/1-D Lookup Table', [s '/Rail ahead w(x)'], 'Table', 'TR.w', ...
    'BreakpointsForDimension1', 'TR.x', 'ExtrapMethod', 'Clip', 'Position', [390 50 470 110]);
add_block('built-in/Outport', [s '/p'], 'Position', [520 73 550 87]);
add_line(s, 'Clock/1', 'Speed v/1');
add_line(s, 'Speed v/1', 'Lead wheel position (+ timing error)/1');
add_line(s, 'Lead wheel position (+ timing error)/1', 'Sample positions/1');
add_line(s, 'Sample offsets/1', 'Sample positions/2');
add_line(s, 'Sample positions/1', 'Every Tc/1');
add_line(s, 'Every Tc/1', 'Rail ahead w(x)/1');
add_line(s, 'Rail ahead w(x)/1', 'p/1');

%% 4. SwarmRide Controller
s = [mdl '/' CTL];
add_block('built-in/Subsystem', s, 'Position', [60 345 220 425]);
set_param(s, 'Description', ['LPV state feedback (gains blended by measured load) plus Train Brain preview ' ...
    'feed-forward, converted to a damping command the damper can give (resist only, efficiency limit).']);
add_block('built-in/Inport', [s '/x'],    'Position', [30 43 60 57]);
add_block('built-in/Inport', [s '/p'],    'Position', [30 93 60 107]);
add_block('built-in/Inport', [s '/vrel'], 'Position', [30 223 60 237]);
add_block('simulink/Discrete/Zero-Order Hold', [s '/Sample states (Tc)'], 'SampleTime', 'P.Tc', ...
    'Position', [100 35 140 65]);
add_block('simulink/Sources/Constant', [s '/Load estimate (air-spring pressure)'], 'Value', 'P.m_hat', ...
    'SampleTime', 'P.Tc', 'Position', [40 140 170 170]);
sr_mlfcn([s '/LPV state feedback + preview (100 Hz)'], [230 30 400 170], strjoin({ ...
    'function F_star = fcn(x, p, m_hat, P)'
    '% LPV: blend the gains of the two load-grid points around the measured load.'
    '% C2: F* = -Kx x.   C3: F* = -Kx x - Kp p  (Train Brain preview of the rail around the train).'
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
    'if P.ctrl == 3'
    '    np = size(P.Kp, 2) / 2;'
    '    Kp = reshape((1 - a) * P.Kp(i, :) + a * P.Kp(i + 1, :), 2, np);'
    '    F_star = F_star - Kp * p;'
    'end'}, newline), {'P'}, {'F_star', '[2 1]'; 'p', sprintf('[%d 1]', K3.Np)});
sr_mlfcn([s '/Semi-active conversion (passivity + efficiency limits)'], [470 120 650 200], strjoin({ ...
    'function c_des = fcn(F_star, vrel, P)'
    '% The damper can only resist motion, so c = F*/v must be >= 0. It is kept at or below c_cap'
    '% so the coil stays efficient (efficiency >= 1 - c_cap/c_max), and at or above an optional'
    '% floor c_floor that trades comfort for power. C1 uses one fixed setting.'
    'if P.ctrl == 1'
    '    c_des = P.c_fix * ones(2, 1);'
    'else'
    '    c_des = F_star .* vrel ./ (vrel.^2 + P.eps_v^2) - P.c_oil;'
    '    c_des = min(max(c_des, P.c_floor), P.c_cap);'
    'end'}, newline), {'P'}, {'c_des', '[2 1]'});
add_block('simulink/Math Operations/Sum', [s '/Smoothing error'], 'Inputs', '+-', 'Position', [700 145 720 175]);
add_block('simulink/Math Operations/Gain', [s '/Command smoothing 1 over tau_c'], 'Gain', '1/P.tau_c', ...
    'Position', [760 145 810 175]);
add_block('simulink/Continuous/Integrator', [s '/Damping command'], 'InitialCondition', 'zeros(2,1)', ...
    'Position', [870 145 910 175]);
add_block('built-in/Outport', [s '/c_cmd'],  'Position', [980 153 1010 167]);
add_block('built-in/Outport', [s '/F_star'], 'Position', [980 73 1010 87]);
add_line(s, 'x/1', 'Sample states (Tc)/1');
add_line(s, 'Sample states (Tc)/1', 'LPV state feedback + preview (100 Hz)/1');
add_line(s, 'p/1', 'LPV state feedback + preview (100 Hz)/2');
add_line(s, 'Load estimate (air-spring pressure)/1', 'LPV state feedback + preview (100 Hz)/3', 'autorouting', 'on');
add_line(s, 'LPV state feedback + preview (100 Hz)/1', 'Semi-active conversion (passivity + efficiency limits)/1', 'autorouting', 'on');
add_line(s, 'vrel/1', 'Semi-active conversion (passivity + efficiency limits)/2', 'autorouting', 'on');
add_line(s, 'Semi-active conversion (passivity + efficiency limits)/1', 'Smoothing error/1');
add_line(s, 'Smoothing error/1', 'Command smoothing 1 over tau_c/1');
add_line(s, 'Command smoothing 1 over tau_c/1', 'Damping command/1');
add_line(s, 'Damping command/1', 'Smoothing error/2', 'autorouting', 'on');
add_line(s, 'Damping command/1', 'c_cmd/1');
add_line(s, 'LPV state feedback + preview (100 Hz)/1', 'F_star/1', 'autorouting', 'on');
sr_add_log(s, 'LPV state feedback + preview (100 Hz)/1', 'Fstar', [980 20 1060 44]);
sr_add_log(s, 'Damping command/1', 'ccmd', [980 210 1060 234]);

%% 5. Wiring
add_line(mdl, [PLANT '/4'], [CTL '/1'], 'autorouting', 'on');      % coach states
add_line(mdl, [TBR '/1'],   [CTL '/2'], 'autorouting', 'on');      % rail preview
add_line(mdl, [PLANT '/3'], [CTL '/3'], 'autorouting', 'on');      % stroke velocity
add_line(mdl, [CTL '/1'],   [SD '/2'],  'autorouting', 'on');      % damping command

%% 6. Scope and note
sr_add_scope(mdl, 'Scope 8 - Controller', {[CTL '/2'], [CTL '/1']}, ...
    {'Ideal damper force F* [N]: front, rear', 'Damping command to the smart damper [N s/m]: front, rear'}, ...
    [1180 620 1230 680]);
try
    notes = find_system(mdl, 'FindAll', 'on', 'SearchDepth', 1, 'Type', 'annotation');
    for k = 1:numel(notes)
        if startsWith(get_param(notes(k), 'Text'), 'Stage 2'), delete(notes(k)); end
    end
catch
end
try
    nt = add_block('built-in/Note', [mdl '/Stage 3: SwarmRide controllers. ctrlMode = C1 (fixed harvester), C2 (LPV load-adaptive) or C3 (LPV + Train Brain preview); designType = A, B or C']);
    set_param(nt, 'Position', [60 40 1000 70]);
catch
end

save_system(mdl, f);
close_system(mdl, 0);
fprintf('Built %s\n', f);

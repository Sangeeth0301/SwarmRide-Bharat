%% BUILD_STAGE1  Builds models/SR_Stage1.slx : Track Input + Vehicle Plant + passive damper (C0)
%   Run from the SwarmRide_Sim folder:   >> run scripts/build_stage1
%   The model is rebuilt from scratch each time, so edit this script, not the .slx.

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'));
mdl = 'SR_Stage1';
if bdIsLoaded(mdl), close_system(mdl, 0); end
f = fullfile(root, 'models', [mdl '.slx']);
if isfile(f), delete(f); end

new_system(mdl);
set_param(mdl, 'Solver', 'ode4', 'FixedStep', 'P.Ts', 'StopTime', 'P.Tend', ...
    'SaveOutput', 'off', 'ReturnWorkspaceOutputs', 'on', ...
    'InitFcn', 'sr_params; TR = sr_track(P, trackType);');

%% ---------------- 1. Track Input ----------------
tr = [mdl '/Track Input'];
add_block('built-in/Subsystem', tr, 'Position', [60 140 230 240]);
set_param(tr, 'Description', ['Generates the vertical rail irregularity under each of the 4 wheels. ' ...
    'Each wheel sees the same rail, delayed by its distance behind the lead wheel.']);
add_block('simulink/Sources/Clock',           [tr '/Clock'],              'Position', [30 60 50 80]);
add_block('simulink/Math Operations/Gain',    [tr '/Speed v'],            'Gain', 'P.v', 'Position', [90 55 130 85]);
add_block('simulink/Math Operations/Bias',    [tr '/Start position s0'],  'Bias', 'P.s0', 'Position', [160 55 210 85]);
add_block('simulink/Sources/Constant',        [tr '/Wheel offsets'],      'Value', '-P.dist', 'Position', [160 120 210 150]);
add_block('simulink/Math Operations/Sum',     [tr '/Wheel positions'],    'Inputs', '++', 'Position', [250 70 270 130]);
add_block('simulink/Lookup Tables/1-D Lookup Table', [tr '/Rail height w(x)'], ...
    'Table', 'TR.w', 'BreakpointsForDimension1', 'TR.x', 'ExtrapMethod', 'Clip', 'Position', [320 40 400 100]);
add_block('simulink/Lookup Tables/1-D Lookup Table', [tr '/Rail slope dw_dx'], ...
    'Table', 'TR.dwdx', 'BreakpointsForDimension1', 'TR.x', 'ExtrapMethod', 'Clip', 'Position', [320 140 400 200]);
add_block('simulink/Math Operations/Gain',    [tr '/x speed'],            'Gain', 'P.v', 'Position', [440 150 480 190]);
add_block('built-in/Outport', [tr '/w'],  'Position', [530 63 560 77]);
add_block('built-in/Outport', [tr '/wd'], 'Position', [530 163 560 177]);
add_line(tr, 'Clock/1', 'Speed v/1');
add_line(tr, 'Speed v/1', 'Start position s0/1');
add_line(tr, 'Start position s0/1', 'Wheel positions/1');
add_line(tr, 'Wheel offsets/1', 'Wheel positions/2');
add_line(tr, 'Wheel positions/1', 'Rail height w(x)/1', 'autorouting', 'on');
add_line(tr, 'Wheel positions/1', 'Rail slope dw_dx/1', 'autorouting', 'on');
add_line(tr, 'Rail height w(x)/1', 'w/1');
add_line(tr, 'Rail slope dw_dx/1', 'x speed/1');
add_line(tr, 'x speed/1', 'wd/1');

%% ---------------- 2. Vehicle Plant (half-coach, 4 DOF) ----------------
pl = [mdl '/Vehicle Plant (half-coach 4-DOF)'];
add_block('built-in/Subsystem', pl, 'Position', [330 120 520 260]);
set_param(pl, 'Description', ['Coach body (bounce + pitch) on two bogies. Secondary suspension = air spring ' ...
    '(inside the equations) + damper force Fd (input). Primary suspension = springs + dampers to 4 wheelsets.']);
add_block('built-in/Inport', [pl '/w'],  'Position', [30 40 60 54]);
add_block('built-in/Inport', [pl '/wd'], 'Position', [30 80 60 94]);
add_block('built-in/Inport', [pl '/Fd'], 'Position', [30 120 60 134]);
add_block('simulink/User-Defined Functions/MATLAB Function', [pl '/Equations of Motion']);
set_param([pl '/Equations of Motion'], 'Position', [160 30 300 170]);
add_block('simulink/Continuous/Integrator', [pl '/Velocities'], 'InitialCondition', 'zeros(4,1)', 'Position', [360 85 400 115]);
add_block('simulink/Continuous/Integrator', [pl '/Positions'],  'InitialCondition', 'zeros(4,1)', 'Position', [450 85 490 115]);
add_block('simulink/User-Defined Functions/MATLAB Function', [pl '/Body Accelerometers']);
set_param([pl '/Body Accelerometers'], 'Position', [560 20 680 70]);
add_block('simulink/User-Defined Functions/MATLAB Function', [pl '/Stroke Sensors']);
set_param([pl '/Stroke Sensors'], 'Position', [560 110 680 180]);
add_block('built-in/Outport', [pl '/az'],     'Position', [740 38 770 52]);
add_block('built-in/Outport', [pl '/stroke'], 'Position', [740 120 770 134]);
add_block('built-in/Outport', [pl '/vrel'],   'Position', [740 155 770 169]);

rt = sfroot;
setScript(rt, [pl '/Equations of Motion'], ...
    sprintf(['function acc = fcn(q, qd, w, wd, Fd, P)\n' ...
             '%% Newton''s law for body bounce, body pitch and the two bogie frames.\n' ...
             'acc = sr_eom(q, qd, w, wd, Fd, P);\n']));
setScript(rt, [pl '/Body Accelerometers'], ...
    sprintf(['function az = fcn(acc, P)\n' ...
             '%% Body acceleration at the centre and above each bogie (comfort).\n' ...
             'az = sr_measure(zeros(4,1), zeros(4,1), acc, P);\n']));
setScript(rt, [pl '/Stroke Sensors'], ...
    sprintf(['function [stroke, vrel] = fcn(q, qd, P)\n' ...
             '%% Suspension stroke (safety) and stroke velocity (what the damper feels).\n' ...
             '[~, stroke, vrel] = sr_measure(q, qd, zeros(4,1), P);\n']));
setParam(rt, [pl '/Equations of Motion'], 'P');
setParam(rt, [pl '/Body Accelerometers'], 'P');
setParam(rt, [pl '/Stroke Sensors'], 'P');
setSize(rt, [pl '/Equations of Motion'], 'acc', '[4 1]');
setSize(rt, [pl '/Body Accelerometers'], 'az', '[3 1]');
setSize(rt, [pl '/Stroke Sensors'], 'stroke', '[2 1]');
setSize(rt, [pl '/Stroke Sensors'], 'vrel', '[2 1]');

% Equations of Motion inputs: 1 q, 2 qd, 3 w, 4 wd, 5 Fd
add_line(pl, 'Positions/1',  'Equations of Motion/1', 'autorouting', 'on');
add_line(pl, 'Velocities/1', 'Equations of Motion/2', 'autorouting', 'on');
add_line(pl, 'w/1',  'Equations of Motion/3');
add_line(pl, 'wd/1', 'Equations of Motion/4');
add_line(pl, 'Fd/1', 'Equations of Motion/5');
add_line(pl, 'Equations of Motion/1', 'Velocities/1');
add_line(pl, 'Velocities/1', 'Positions/1');
% Body Accelerometers input: acc.   Stroke Sensors inputs: 1 q, 2 qd
add_line(pl, 'Equations of Motion/1', 'Body Accelerometers/1', 'autorouting', 'on');
add_line(pl, 'Positions/1',  'Stroke Sensors/1', 'autorouting', 'on');
add_line(pl, 'Velocities/1', 'Stroke Sensors/2', 'autorouting', 'on');
add_line(pl, 'Body Accelerometers/1', 'az/1');
add_line(pl, 'Stroke Sensors/1', 'stroke/1');
add_line(pl, 'Stroke Sensors/2', 'vrel/1');

%% ---------------- 3. Secondary dampers: C0 passive oil damper ----------------
dp = [mdl '/Secondary Dampers (C0 passive)'];
add_block('built-in/Subsystem', dp, 'Position', [330 330 520 400]);
set_param(dp, 'Description', ['Today''s damping. Coaches: oil damper, force = c_s x stroke velocity. ' ...
    'Casnub goods bogie: friction wedges, force = mu x load (smoothed). Replaced by the smart damper in Stage 2.']);
add_block('built-in/Inport',  [dp '/vrel'], 'Position', [30 40 60 54]);
add_block('simulink/User-Defined Functions/MATLAB Function', [dp '/Today''s damper']);
set_param([dp '/Today''s damper'], 'Position', [110 25 210 75]);
add_block('built-in/Outport', [dp '/Fd'], 'Position', [260 40 290 54]);
rt0 = sfroot;
setScript(rt0, [dp '/Today''s damper'], ...
    sprintf(['function Fd = fcn(vrel, P)\n' ...
             '%% Oil damper (viscous, c_s) + friction wedges (Casnub, F_fr). One of the two is zero.\n' ...
             'Fd = P.cs * vrel + P.Ffr * tanh(vrel / P.veps);\n']));
setParam(rt0, [dp '/Today''s damper'], 'P');
setSize(rt0, [dp '/Today''s damper'], 'Fd', '[2 1]');
add_line(dp, 'vrel/1', 'Today''s damper/1');
add_line(dp, 'Today''s damper/1', 'Fd/1');

%% ---------------- 4. Wiring + logging ----------------
add_line(mdl, 'Track Input/1', 'Vehicle Plant (half-coach 4-DOF)/1', 'autorouting', 'on');
add_line(mdl, 'Track Input/2', 'Vehicle Plant (half-coach 4-DOF)/2', 'autorouting', 'on');
add_line(mdl, 'Secondary Dampers (C0 passive)/1', 'Vehicle Plant (half-coach 4-DOF)/3', 'autorouting', 'on');
add_line(mdl, 'Vehicle Plant (half-coach 4-DOF)/3', 'Secondary Dampers (C0 passive)/1', 'autorouting', 'on');
names = {'az', 'stroke', 'vrel'};
for k = 1:3
    blk = [mdl '/Log ' names{k}];
    add_block('simulink/Sinks/To Workspace', blk, 'VariableName', names{k}, ...
        'SaveFormat', 'Timeseries', 'Position', [640 115 + 60*(k-1) 720 145 + 60*(k-1)]);
    add_line(mdl, sprintf('Vehicle Plant (half-coach 4-DOF)/%d', k), ['Log ' names{k} '/1'], 'autorouting', 'on');
end
add_block('simulink/Sinks/To Workspace', [mdl '/Log Fd'], 'VariableName', 'Fd', ...
    'SaveFormat', 'Timeseries', 'Position', [640 330 720 360]);
add_line(mdl, 'Secondary Dampers (C0 passive)/1', 'Log Fd/1', 'autorouting', 'on');

%% ---------------- 5. Live scopes (open when you press Run) ----------------
scopes = { ...
    'Scope 1 - Body vibration (comfort)',   'Vehicle Plant (half-coach 4-DOF)/1', 'Body acceleration [m/s^2]: centre, over front bogie, over rear bogie', [800 105 850 155];
    'Scope 2 - Suspension stroke (safety)', 'Vehicle Plant (half-coach 4-DOF)/2', 'Secondary stroke [m]: front, rear (limit about +/-0.04 m)',          [800 175 850 225];
    'Scope 3 - Damper force',               'Secondary Dampers (C0 passive)/1',   'Damper force [N]: front, rear',                                       [800 330 850 380];
    'Scope 4 - Rail under the wheels',      'Track Input/1',                      'Rail height [m] under wheels 1-4 (front bogie: 1,2  rear bogie: 3,4)', [120 300 170 350]};
for k = 1:size(scopes, 1)
    blk = [mdl '/' scopes{k, 1}];
    add_block('simulink/Sinks/Scope', blk, 'Position', scopes{k, 4});
    add_line(mdl, scopes{k, 2}, [scopes{k, 1} '/1'], 'autorouting', 'on');
    try
        cfg = get_param(blk, 'ScopeConfiguration');
        cfg.OpenAtSimulationStart = true;
        cfg.TimeSpan = '10';
        cfg.Title = scopes{k, 3};
        cfg.ShowLegend = true;
        cfg.ShowGrid = true;
    catch err
        warning('Scope settings not applied for %s: %s', scopes{k, 1}, err.message);
    end
end
% Play in real time when you press Run, so the scopes can be watched (batch checks switch this off).
try
    set_param(mdl, 'EnablePacing', 'on', 'PacingRate', 1);
catch err
    warning('Real-time pacing not set: %s', err.message);
end

try
    nt = add_block('built-in/Note', [mdl '/Stage 1b: Track -> Vehicle Plant <- today''s damper (oil or friction). Pick the train with trainType = LHB, VB, ICF or BOXN']);
    set_param(nt, 'Position', [60 40 700 70]);
catch
end

save_system(mdl, f);
fprintf('Built %s\n', f);

%% ---------------- helpers ----------------
function setScript(rt, path, code)
ch = rt.find('-isa', 'Stateflow.EMChart', 'Path', path);
ch.Script = code;
end

function setSize(rt, path, name, sz)
ch = rt.find('-isa', 'Stateflow.EMChart', 'Path', path);
d = ch.find('-isa', 'Stateflow.Data', 'Name', name);
d.Props.Array.Size = sz;
end

function setParam(rt, path, name)
ch = rt.find('-isa', 'Stateflow.EMChart', 'Path', path);
d = ch.find('-isa', 'Stateflow.Data', 'Name', name);
d.Scope = 'Parameter';
d.Tunable = false;
end

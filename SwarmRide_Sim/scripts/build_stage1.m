%% BUILD_STAGE1  Builds models/SR_Stage1.slx : Track Input + Vehicle Plant + passive damper (C0)
%   Run from the SwarmRide_Sim folder:   >> run scripts/build_stage1
%   The model is rebuilt from scratch each time, so edit this script, not the .slx.
%   Track Input and Vehicle Plant come from builders/, shared with every later stage.

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'));
mdl = 'SR_Stage1';
if bdIsLoaded(mdl), close_system(mdl, 0); end
f = fullfile(root, 'models', [mdl '.slx']);
if isfile(f), delete(f); end

new_system(mdl);
set_param(mdl, 'Solver', 'ode4', 'FixedStep', 'P.Ts', 'StopTime', 'P.Tend', ...
    'SaveOutput', 'off', 'ReturnWorkspaceOutputs', 'on', ...
    'InitFcn', 'sr_params; TR = sr_track(P, trackType);');

%% 1-2. Track Input and Vehicle Plant (shared builders)
sr_add_track(mdl, [60 140 230 240]);
sr_add_plant(mdl, [330 120 520 260]);

%% 3. Secondary dampers: C0 passive (oil damper or Casnub friction wedges)
dp = [mdl '/Secondary Dampers (C0 passive)'];
add_block('built-in/Subsystem', dp, 'Position', [330 330 520 400]);
set_param(dp, 'Description', ['Today''s damping. Coaches: oil damper, force = c_s x stroke velocity. ' ...
    'Casnub goods bogie: friction wedges, force = mu x load (smoothed). Replaced by the smart damper in Stage 2.']);
add_block('built-in/Inport',  [dp '/vrel'], 'Position', [30 40 60 54]);
sr_mlfcn([dp '/Today''s damper'], [110 25 210 75], strjoin({ ...
    'function Fd = fcn(vrel, P)'
    '% Oil damper (viscous, c_s) + friction wedges (Casnub, F_fr). One of the two is zero.'
    'Fd = P.cs * vrel + P.Ffr * tanh(vrel / P.veps);'}, newline), {'P'}, {'Fd', '[2 1]'});
add_block('built-in/Outport', [dp '/Fd'], 'Position', [260 40 290 54]);
add_line(dp, 'vrel/1', 'Today''s damper/1');
add_line(dp, 'Today''s damper/1', 'Fd/1');

%% 4. Wiring + logging
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

%% 5. Live scopes (open when you press Run)
sr_add_scope(mdl, 'Scope 1 - Body vibration (comfort)', {'Vehicle Plant (half-coach 4-DOF)/1'}, ...
    'Body acceleration [m/s^2]: centre, over front bogie, over rear bogie', [800 105 850 155]);
sr_add_scope(mdl, 'Scope 2 - Suspension stroke (safety)', {'Vehicle Plant (half-coach 4-DOF)/2'}, ...
    'Secondary stroke [m]: front, rear (limit about +/-0.04 m)', [800 175 850 225]);
sr_add_scope(mdl, 'Scope 3 - Damper force', {'Secondary Dampers (C0 passive)/1'}, ...
    'Damper force [N]: front, rear', [800 330 850 380]);
sr_add_scope(mdl, 'Scope 4 - Rail under the wheels', {'Track Input/1'}, ...
    'Rail height [m] under wheels 1-4 (front bogie: 1,2  rear bogie: 3,4)', [120 300 170 350]);
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

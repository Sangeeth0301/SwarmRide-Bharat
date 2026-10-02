function pl = sr_add_plant(mdl, pos)
%SR_ADD_PLANT Add the Vehicle Plant subsystem: half-coach, 4 DOF (body bounce, pitch, 2 bogies).
%   Inputs w, wd (4x1) and damper force Fd (2x1). Outputs az (3x1), stroke (2x1), vrel (2x1).
%   Shared by every stage, so only the damper changes between stages.

pl = [mdl '/Vehicle Plant (half-coach 4-DOF)'];
add_block('built-in/Subsystem', pl, 'Position', pos);
set_param(pl, 'Description', ['Coach body (bounce + pitch) on two bogies. Secondary suspension = air spring ' ...
    '(inside the equations) + damper force Fd (input). Primary suspension = springs + dampers to 4 wheelsets.']);
add_block('built-in/Inport', [pl '/w'],  'Position', [30 40 60 54]);
add_block('built-in/Inport', [pl '/wd'], 'Position', [30 80 60 94]);
add_block('built-in/Inport', [pl '/Fd'], 'Position', [30 120 60 134]);
sr_mlfcn([pl '/Equations of Motion'], [160 30 300 170], strjoin({ ...
    'function acc = fcn(q, qd, w, wd, Fd, P)'
    '% Newton''s law for body bounce, body pitch and the two bogie frames.'
    'acc = sr_eom(q, qd, w, wd, Fd, P);'}, newline), {'P'}, {'acc', '[4 1]'});
add_block('simulink/Continuous/Integrator', [pl '/Velocities'], 'InitialCondition', 'zeros(4,1)', 'Position', [360 85 400 115]);
add_block('simulink/Continuous/Integrator', [pl '/Positions'],  'InitialCondition', 'zeros(4,1)', 'Position', [450 85 490 115]);
sr_mlfcn([pl '/Body Accelerometers'], [560 20 680 70], strjoin({ ...
    'function az = fcn(acc, P)'
    '% Body acceleration at the centre and above each bogie (comfort).'
    'az = sr_measure(zeros(4,1), zeros(4,1), acc, P);'}, newline), {'P'}, {'az', '[3 1]'});
sr_mlfcn([pl '/Stroke Sensors'], [560 110 680 180], strjoin({ ...
    'function [stroke, vrel] = fcn(q, qd, P)'
    '% Suspension stroke (safety) and stroke velocity (what the damper feels).'
    '[~, stroke, vrel] = sr_measure(q, qd, zeros(4,1), P);'}, newline), {'P'}, {'stroke', '[2 1]'; 'vrel', '[2 1]'});
add_block('built-in/Outport', [pl '/az'],     'Position', [740 38 770 52]);
add_block('built-in/Outport', [pl '/stroke'], 'Position', [740 120 770 134]);
add_block('built-in/Outport', [pl '/vrel'],   'Position', [740 155 770 169]);

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
end

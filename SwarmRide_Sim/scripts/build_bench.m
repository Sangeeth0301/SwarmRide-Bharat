%% BUILD_BENCH  Builds models/SR_Bench.slx : one design-C smart damper on a test rig
%   The bench prototype as it will be tested in the lab, before it goes on a bogie:
%     Test Rig (moves the damper, sends commands) -> Drive Controller (firmware, 10 kHz)
%       -> Smart Damper hardware (3-phase servo machine as its equivalent DC machine,
%          changeover contactor, fail-safe resistors, ball screw) -> Power Electronics
%       -> Supercapacitor + electronic load;  Winding temperature;  Energy meters
%   Unlike the vehicle model, the drive has a real current controller with a voltage limit,
%   inverter losses, a contactor that takes 20 ms to drop, and a winding that heats up.
%   Run from the SwarmRide_Sim folder:   >> run scripts/build_bench

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'));
mdl = 'SR_Bench';
if bdIsLoaded(mdl), close_system(mdl, 0); end
f = fullfile(root, 'models', [mdl '.slx']);
if isfile(f), delete(f); end

new_system(mdl);
set_param(mdl, 'Solver', 'ode4', 'FixedStep', 'BP.Ts', 'StopTime', 'BP.Tend', ...
    'SaveOutput', 'off', 'ReturnWorkspaceOutputs', 'on', 'SolverMode', 'SingleTasking', ...
    'InitFcn', 'sr_params_bench;');
RIG = 'Test Rig (servo actuator + test profile)';
DRV = 'Drive Controller (firmware, 10 kHz)';
SD  = 'Smart Damper (design C hardware)';
PE  = 'Power Electronics (inverter + DC-DC)';
SC  = 'Supercapacitor + electronic load';
TH  = 'Winding temperature';
EM  = 'Energy meters';
lg  = 'BP.Tlog';

%% 1. Test Rig
s = [mdl '/' RIG];
add_block('built-in/Subsystem', s, 'Position', [40 120 230 330]);
set_param(s, 'Description', ['Displacement-controlled actuator that strokes the damper (x, v, a) and the test ' ...
    'computer that sends the drive its commands: damping c, push force F, push window act, test fault.']);
add_block('simulink/Sources/Clock', [s '/Clock'], 'Position', [30 190 50 210]);
sig = {'x', 'Stroke x [m]', 'Linear point-slope'; 'v', 'Stroke speed v [m per s]', 'Linear point-slope'; ...
       'a', 'Stroke acceleration a [m per s2]', 'Linear point-slope'; 'c', 'Damping command c [N s per m]', 'Linear point-slope'; ...
       'F', 'Push force command F [N]', 'Linear point-slope'; 'act', 'Push window act', 'Flat'; ...
       'fault', 'Test fault', 'Flat'};
for k = 1:size(sig, 1)
    y = 30 + 55 * (k - 1);
    add_block('simulink/Lookup Tables/1-D Lookup Table', [s '/' sig{k, 2}], 'Table', ['BX.' sig{k, 1}], ...
        'BreakpointsForDimension1', 'BX.t', 'ExtrapMethod', 'Clip', 'InterpMethod', sig{k, 3}, ...
        'Position', [140 y 230 y + 40]);
    add_block('built-in/Outport', [s '/' sig{k, 1}], 'Position', [300 y + 13 330 y + 27]);
    add_line(s, 'Clock/1', [sig{k, 2} '/1'], 'autorouting', 'on');
    add_line(s, [sig{k, 2} '/1'], [sig{k, 1} '/1']);
end

%% 2. Drive Controller (firmware)
s = [mdl '/' DRV];
add_block('built-in/Subsystem', s, 'Position', [330 120 520 330]);
set_param(s, 'Description', ['What the drive''s microcontroller does every 100 us: fail-safe supervisor, ' ...
    'current reference (damping law or push), PI current control with back-EMF feed-forward and voltage limit. ' ...
    'Same algorithms as the C firmware (functions/bp_*.m = firmware/src/*.c).']);
ins = {'v', 'c', 'F', 'act', 'fault', 'i', 'Vsc', 'Tw'};
for k = 1:numel(ins)
    y = 30 + 45 * (k - 1);
    add_block('built-in/Inport', [s '/' ins{k}], 'Position', [30 y 60 y + 14]);
    add_block('simulink/Discrete/Zero-Order Hold', [s '/Sample ' ins{k}], 'SampleTime', 'BP.Ti', ...
        'Position', [100 y - 5 130 y + 19]);
    add_line(s, [ins{k} '/1'], ['Sample ' ins{k} '/1']);
end
sr_mlfcn([s '/Drive firmware'], [220 30 400 400], strjoin({ ...
    'function [u, iref, z_next, latch_next, relay_cmd, sat, code] = fcn(v, c, F, act, fault, i, Vsc, Tw, z, latch, BP)'
    '% 1. Fail-safe supervisor (drops the contactor on a fault, latched).'
    '% 2. Current reference: damping law i = c v / Ke, or the push force inside a window.'
    '% 3. PI current control + back-EMF feed-forward, limited to the inverter voltage.'
    '[relay_cmd, latch_next, code] = bp_failsafe(fault, Vsc, Tw, i, latch, BP);'
    'iref = bp_current_ref(c, F, act, v, BP);'
    '[u, z_next, sat] = bp_current_ctrl(iref, i, v, z, BP);'
    'if relay_cmd > 0.5'
    '    u = 0;  z_next = 0;  iref = 0;  sat = 0;    % gates off: the contactor takes over'
    'end'}, newline), {'BP'}, {});
add_block('simulink/Discrete/Unit Delay', [s '/PI integrator state'], 'SampleTime', 'BP.Ti', ...
    'InitialCondition', '0', 'Position', [470 300 510 330]);
add_block('simulink/Discrete/Unit Delay', [s '/Fault latch'], 'SampleTime', 'BP.Ti', ...
    'InitialCondition', '0', 'Position', [470 350 510 380]);
add_block('simulink/Discrete/Delay', [s '/Contactor drop-out delay'], 'DelayLength', 'BP.n_delay', ...
    'SampleTime', 'BP.Ti', 'InitialCondition', '0', 'Position', [470 200 520 240]);
sr_mlfcn([s '/Coil connection mode'], [570 180 700 260], strjoin({ ...
    'function mode = fcn(relay_cmd, contactor)'
    '% 0 = inverter drives the coil.  1 = gates off, contactor still moving (coil open).'
    '% 2 = contactor dropped: coil on the fail-safe resistors (today''s passive damping).'
    'if contactor > 0.5'
    '    mode = 2;'
    'elseif relay_cmd > 0.5'
    '    mode = 1;'
    'else'
    '    mode = 0;'
    'end'}, newline), {}, {});
outs = {'u', 'mode', 'iref', 'sat', 'code'};
for k = 1:numel(outs)
    add_block('built-in/Outport', [s '/' outs{k}], 'Position', [780 40 + 50 * (k - 1) 810 54 + 50 * (k - 1)]);
end
for k = 1:numel(ins)
    add_line(s, ['Sample ' ins{k} '/1'], sprintf('Drive firmware/%d', k), 'autorouting', 'on');
end
add_line(s, 'PI integrator state/1', 'Drive firmware/9', 'autorouting', 'on');
add_line(s, 'Fault latch/1', 'Drive firmware/10', 'autorouting', 'on');
add_line(s, 'Drive firmware/3', 'PI integrator state/1', 'autorouting', 'on');
add_line(s, 'Drive firmware/4', 'Fault latch/1', 'autorouting', 'on');
add_line(s, 'Drive firmware/5', 'Contactor drop-out delay/1', 'autorouting', 'on');
add_line(s, 'Drive firmware/5', 'Coil connection mode/1', 'autorouting', 'on');
add_line(s, 'Contactor drop-out delay/1', 'Coil connection mode/2', 'autorouting', 'on');
add_line(s, 'Drive firmware/1', 'u/1', 'autorouting', 'on');
add_line(s, 'Coil connection mode/1', 'mode/1', 'autorouting', 'on');
add_line(s, 'Drive firmware/2', 'iref/1', 'autorouting', 'on');
add_line(s, 'Drive firmware/6', 'sat/1', 'autorouting', 'on');
add_line(s, 'Drive firmware/7', 'code/1', 'autorouting', 'on');

%% 3. Smart Damper hardware
s = [mdl '/' SD];
add_block('built-in/Subsystem', s, 'Position', [620 120 810 330]);
set_param(s, 'Description', ['Design-C damper: ball screw turns the 3-phase servo machine (modelled as its ' ...
    'equivalent DC machine: e = Ke v, F = Ke i, L di/dt = e - Rc i - u). The changeover contactor connects the ' ...
    'coil to the inverter (normal) or to the fail-safe resistors (dropped). Friction and rotor inertance add to the force.']);
dins = {'u', 'mode', 'v', 'a'};
for k = 1:numel(dins)
    add_block('built-in/Inport', [s '/' dins{k}], 'Position', [30 30 + 50 * (k - 1) 60 44 + 50 * (k - 1)]);
end
add_block('simulink/Continuous/Integrator', [s '/Coil current i'], 'InitialCondition', '0', ...
    'Position', [400 40 440 80]);
sr_mlfcn([s '/Machine and contactor'], [150 20 320 200], strjoin({ ...
    'function [didt, Fem, e, Pterm, Pcu, Pfs] = fcn(i, u, mode, v, BP)'
    '% Equivalent DC machine. Pterm: power delivered to the inverter terminals.'
    'e = BP.Ke * v;'
    'if mode > 1.5'
    '    didt = (e - (BP.Rc + BP.R_fs) * i) / BP.L;      % coil on the fail-safe resistors'
    '    Pterm = 0;  Pfs = BP.R_fs * i^2;'
    'elseif mode > 0.5'
    '    didt = -i / BP.tau_open;                          % gates off: current collapses through the diodes'
    '    Pterm = (e - BP.Rc * i - BP.L * didt) * i;  Pfs = 0;'
    'else'
    '    didt = (e - BP.Rc * i - u) / BP.L;                % inverter applies u'
    '    Pterm = u * i;  Pfs = 0;'
    'end'
    'Fem = BP.Ke * i;'
    'Pcu = BP.Rc * i^2;'}, newline), {'BP'}, {});
sr_mlfcn([s '/Ball screw and seals (friction, inertance)'], [150 240 320 320], strjoin({ ...
    'function [Fpas, Pfric] = fcn(v, a, BP)'
    'Ffr = BP.Fc * tanh(v / BP.veps);                     % screw + seal friction'
    'Fpas = Ffr + BP.b_in * a;                            % rotor + screw inertia seen at the rod'
    'Pfric = Ffr * v;'}, newline), {'BP'}, {});
add_block('simulink/Math Operations/Sum', [s '/Load-cell force'], 'Inputs', '++', 'Position', [500 150 520 260]);
douts = {'F_lc', 'F_em', 'i', 'e', 'Pterm', 'Pcu', 'Pfs', 'Pfric'};
for k = 1:numel(douts)
    add_block('built-in/Outport', [s '/' douts{k}], 'Position', [600 30 + 45 * (k - 1) 630 44 + 45 * (k - 1)]);
end
add_line(s, 'Coil current i/1', 'Machine and contactor/1', 'autorouting', 'on');
add_line(s, 'u/1', 'Machine and contactor/2', 'autorouting', 'on');
add_line(s, 'mode/1', 'Machine and contactor/3', 'autorouting', 'on');
add_line(s, 'v/1', 'Machine and contactor/4', 'autorouting', 'on');
add_line(s, 'Machine and contactor/1', 'Coil current i/1', 'autorouting', 'on');
add_line(s, 'v/1', 'Ball screw and seals (friction, inertance)/1', 'autorouting', 'on');
add_line(s, 'a/1', 'Ball screw and seals (friction, inertance)/2', 'autorouting', 'on');
add_line(s, 'Machine and contactor/2', 'Load-cell force/1', 'autorouting', 'on');
add_line(s, 'Ball screw and seals (friction, inertance)/1', 'Load-cell force/2', 'autorouting', 'on');
add_line(s, 'Load-cell force/1', 'F_lc/1', 'autorouting', 'on');
add_line(s, 'Machine and contactor/2', 'F_em/1', 'autorouting', 'on');
add_line(s, 'Coil current i/1', 'i/1', 'autorouting', 'on');
add_line(s, 'Machine and contactor/3', 'e/1', 'autorouting', 'on');
add_line(s, 'Machine and contactor/4', 'Pterm/1', 'autorouting', 'on');
add_line(s, 'Machine and contactor/5', 'Pcu/1', 'autorouting', 'on');
add_line(s, 'Machine and contactor/6', 'Pfs/1', 'autorouting', 'on');
add_line(s, 'Ball screw and seals (friction, inertance)/2', 'Pfric/1', 'autorouting', 'on');

%% 4. Power Electronics
s = [mdl '/' PE];
add_block('built-in/Subsystem', s, 'Position', [910 120 1090 210]);
set_param(s, 'Description', ['3-phase inverter (conduction and switching losses) and the bidirectional DC-DC ' ...
    'converter that holds the 60 V DC link and charges the supercapacitor (12-48 V).']);
add_block('built-in/Inport', [s '/Pterm'], 'Position', [30 33 60 47]);
add_block('built-in/Inport', [s '/i'],     'Position', [30 83 60 97]);
add_block('built-in/Inport', [s '/mode'],  'Position', [30 133 60 147]);
sr_mlfcn([s '/Inverter and DC-DC losses'], [130 20 300 160], strjoin({ ...
    'function [Pbank, Pinv, Pdcdc] = fcn(Pterm, i, mode, BP)'
    'Pinv = 0;'
    'if mode < 0.5'
    '    Pinv = BP.Ron * i^2 + BP.ksw * abs(i);            % conduction + switching'
    'end'
    'Plink = Pterm - Pinv;'
    'Pbank = BP.eta_dcdc * max(Plink, 0) + min(Plink, 0) / BP.eta_dcdc;'
    'Pdcdc = Plink - Pbank;'}, newline), {'BP'}, {});
pouts = {'Pbank', 'Pinv', 'Pdcdc'};
for k = 1:3
    add_block('built-in/Outport', [s '/' pouts{k}], 'Position', [360 33 + 50 * (k - 1) 390 47 + 50 * (k - 1)]);
    add_line(s, sprintf('Inverter and DC-DC losses/%d', k), [pouts{k} '/1']);
end
pins = {'Pterm', 'i', 'mode'};
for k = 1:3
    add_line(s, [pins{k} '/1'], sprintf('Inverter and DC-DC losses/%d', k));
end

%% 5. Supercapacitor + electronic load
s = [mdl '/' SC];
add_block('built-in/Subsystem', s, 'Position', [910 260 1090 340]);
set_param(s, 'Description', ['The bogie''s 10 F supercapacitor (one damper charges it on the bench) and an ' ...
    'electronic load drawing this damper''s half of the 8 W bogie electronics.']);
add_block('built-in/Inport', [s '/Pbank'], 'Position', [30 43 60 57]);
add_block('simulink/Continuous/Integrator', [s '/Supercap energy'], 'InitialCondition', 'BP.Esc0', ...
    'Position', [330 40 370 80]);
sr_mlfcn([s '/Supercap voltage'], [420 120 540 170], strjoin({ ...
    'function Vsc = fcn(E, BP)'
    'Vsc = sqrt(max(2 * E / BP.Csc, 0));'}, newline), {'BP'}, {});
sr_mlfcn([s '/Charge rules'], [110 20 270 120], strjoin({ ...
    'function [dE, Pdump] = fcn(Pbank, Vsc, E, BP)'
    'p = Pbank - BP.Pload;'
    'Pdump = 0;'
    'if Vsc >= BP.Vmax && p > 0'
    '    Pdump = p;  p = 0;                               % full: the surplus goes to a dump resistor'
    'end'
    'if E <= 0 && p < 0'
    '    p = 0;'
    'end'
    'dE = p;'}, newline), {'BP'}, {});
add_block('built-in/Outport', [s '/Vsc'],   'Position', [600 133 630 147]);
add_block('built-in/Outport', [s '/Pdump'], 'Position', [430 113 460 127]);
add_line(s, 'Pbank/1', 'Charge rules/1');
add_line(s, 'Supercap energy/1', 'Supercap voltage/1', 'autorouting', 'on');
add_line(s, 'Supercap voltage/1', 'Charge rules/2', 'autorouting', 'on');
add_line(s, 'Supercap energy/1', 'Charge rules/3', 'autorouting', 'on');
add_line(s, 'Charge rules/1', 'Supercap energy/1', 'autorouting', 'on');
add_line(s, 'Supercap voltage/1', 'Vsc/1', 'autorouting', 'on');
add_line(s, 'Charge rules/2', 'Pdump/1', 'autorouting', 'on');

%% 6. Winding temperature
s = [mdl '/' TH];
add_block('built-in/Subsystem', s, 'Position', [620 400 810 460]);
set_param(s, 'Description', 'First-order thermal model of the motor winding: copper loss in, heat out to ambient.');
add_block('built-in/Inport', [s '/Pcu'], 'Position', [30 43 60 57]);
add_block('simulink/Continuous/Integrator', [s '/Winding temperature Tw'], 'InitialCondition', 'BP.Tw0', ...
    'Position', [280 40 320 80]);
sr_mlfcn([s '/Heat balance'], [110 20 230 100], strjoin({ ...
    'function dT = fcn(Pcu, Tw, BP)'
    'dT = (Pcu - (Tw - BP.Tamb) / BP.Rth) / BP.Cth;'}, newline), {'BP'}, {});
add_block('built-in/Outport', [s '/Tw'], 'Position', [380 53 410 67]);
add_line(s, 'Pcu/1', 'Heat balance/1');
add_line(s, 'Winding temperature Tw/1', 'Heat balance/2', 'autorouting', 'on');
add_line(s, 'Heat balance/1', 'Winding temperature Tw/1', 'autorouting', 'on');
add_line(s, 'Winding temperature Tw/1', 'Tw/1', 'autorouting', 'on');

%% 7. Energy meters
s = [mdl '/' EM];
add_block('built-in/Subsystem', s, 'Position', [910 400 1090 520]);
set_param(s, 'Description', ['Integrates every power flow so the energy balance can be checked: rig work in = ' ...
    'friction + copper + fail-safe resistors + inverter + DC-DC + bank + stored (rotor, coil).']);
mins = {'Pmech', 'Pfric', 'Pcu', 'Pfs', 'Pterm', 'Pinv', 'Pdcdc', 'Pbank'};
for k = 1:numel(mins)
    add_block('built-in/Inport', [s '/' mins{k}], 'Position', [30 20 + 35 * (k - 1) 60 34 + 35 * (k - 1)]);
end
add_block('simulink/Signal Routing/Mux', [s '/Flows'], 'Inputs', num2str(numel(mins)), 'Position', [150 20 155 300]);
add_block('simulink/Continuous/Integrator', [s '/Energies'], 'InitialCondition', sprintf('zeros(%d,1)', numel(mins)), ...
    'Position', [220 140 260 180]);
add_block('built-in/Outport', [s '/E'], 'Position', [320 153 350 167]);
for k = 1:numel(mins)
    add_line(s, [mins{k} '/1'], sprintf('Flows/%d', k));
end
add_line(s, 'Flows/1', 'Energies/1');
add_line(s, 'Energies/1', 'E/1');

%% 8. Wiring
add_line(mdl, [RIG '/2'], [DRV '/1'], 'autorouting', 'on');      % v (encoder)
add_line(mdl, [RIG '/4'], [DRV '/2'], 'autorouting', 'on');      % c
add_line(mdl, [RIG '/5'], [DRV '/3'], 'autorouting', 'on');      % F
add_line(mdl, [RIG '/6'], [DRV '/4'], 'autorouting', 'on');      % act
add_line(mdl, [RIG '/7'], [DRV '/5'], 'autorouting', 'on');      % fault
add_line(mdl, [SD '/3'],  [DRV '/6'], 'autorouting', 'on');      % i (current sensors)
add_line(mdl, [SC '/1'],  [DRV '/7'], 'autorouting', 'on');      % Vsc
add_line(mdl, [TH '/1'],  [DRV '/8'], 'autorouting', 'on');      % Tw (winding sensor)
add_line(mdl, [DRV '/1'], [SD '/1'],  'autorouting', 'on');      % u
add_line(mdl, [DRV '/2'], [SD '/2'],  'autorouting', 'on');      % mode
add_line(mdl, [RIG '/2'], [SD '/3'],  'autorouting', 'on');      % v
add_line(mdl, [RIG '/3'], [SD '/4'],  'autorouting', 'on');      % a
add_line(mdl, [SD '/5'],  [PE '/1'],  'autorouting', 'on');      % Pterm
add_line(mdl, [SD '/3'],  [PE '/2'],  'autorouting', 'on');      % i
add_line(mdl, [DRV '/2'], [PE '/3'],  'autorouting', 'on');      % mode
add_line(mdl, [PE '/1'],  [SC '/1'],  'autorouting', 'on');      % Pbank
add_line(mdl, [SD '/6'],  [TH '/1'],  'autorouting', 'on');      % Pcu
% rig work: load-cell force x speed
add_block('simulink/Math Operations/Product', [mdl '/Rig work F v'], 'Position', [700 560 730 590]);
add_line(mdl, [SD '/1'],  'Rig work F v/1', 'autorouting', 'on');
add_line(mdl, [RIG '/2'], 'Rig work F v/2', 'autorouting', 'on');
add_line(mdl, 'Rig work F v/1', [EM '/1'], 'autorouting', 'on');
add_line(mdl, [SD '/8'],  [EM '/2'], 'autorouting', 'on');
add_line(mdl, [SD '/6'],  [EM '/3'], 'autorouting', 'on');
add_line(mdl, [SD '/7'],  [EM '/4'], 'autorouting', 'on');
add_line(mdl, [SD '/5'],  [EM '/5'], 'autorouting', 'on');
add_line(mdl, [PE '/2'],  [EM '/6'], 'autorouting', 'on');
add_line(mdl, [PE '/3'],  [EM '/7'], 'autorouting', 'on');
add_line(mdl, [PE '/1'],  [EM '/8'], 'autorouting', 'on');

%% 9. Data logger (what the lab DAQ records) and scopes
L = {RIG, 1, 'x'; RIG, 2, 'v'; SD, 1, 'F_lc'; SD, 2, 'F_em'; SD, 3, 'i'; DRV, 3, 'iref'; DRV, 1, 'u'; ...
     SD, 4, 'e'; SD, 5, 'Pterm'; PE, 1, 'Pbank'; SD, 6, 'Pcu'; TH, 1, 'Tw'; SC, 1, 'Vsc'; DRV, 2, 'mode'; ...
     DRV, 4, 'sat'; DRV, 5, 'code'; EM, 1, 'E'; 'Rig work F v', 1, 'Pmech'; RIG, 4, 'c'; RIG, 6, 'act'};
for k = 1:size(L, 1)
    sr_add_log(mdl, sprintf('%s/%d', L{k, 1}, L{k, 2}), L{k, 3}, ...
        [1200 + 110 * floor((k - 1) / 10), 120 + 45 * mod(k - 1, 10), 1280 + 110 * floor((k - 1) / 10), 144 + 45 * mod(k - 1, 10)], lg);
end
add_block('simulink/Signal Routing/Mux', [mdl '/Current and reference'], 'Inputs', '2', 'Position', [880 610 885 650]);
add_line(mdl, [SD '/3'],  'Current and reference/1', 'autorouting', 'on');
add_line(mdl, [DRV '/3'], 'Current and reference/2', 'autorouting', 'on');
sr_add_scope(mdl, 'Scope 1 - Rig', {[RIG '/1'], [SD '/1']}, ...
    {'Stroke x [m]', 'Load-cell force [N]'}, [1000 560 1040 600]);
sr_add_scope(mdl, 'Scope 2 - Drive', {'Current and reference/1', [DRV '/1']}, ...
    {'Coil current i and reference [A]', 'Inverter voltage u [V]'}, [1000 620 1040 660]);
sr_add_scope(mdl, 'Scope 3 - Power', {'Rig work F v/1', [PE '/1']}, ...
    {'Mechanical power in [W]', 'Power into the bank [W]'}, [1000 680 1040 720]);
sr_add_scope(mdl, 'Scope 4 - Temperature and bank', {[TH '/1'], [SC '/1']}, ...
    {'Winding temperature [C]', 'Supercapacitor voltage [V]'}, [1000 740 1040 780]);

try
    nt = add_block('built-in/Note', [mdl '/Bench prototype: one design-C smart damper on a test rig. benchTest = emf, damping, step, vlimit, failsafe, replay_poor, replay_good or replay_settle; benchMode = real or simequiv']);
    set_param(nt, 'Position', [40 40 1000 70]);
catch
end
save_system(mdl, f);
close_system(mdl, 0);
fprintf('Built %s\n', f);

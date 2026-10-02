%% BUILD_STAGE2  Builds models/SR_Stage2.slx : the SwarmRide smart damper and power chain
%   Same Track Input and Vehicle Plant as Stage 1 (shared builders). Today's damper is replaced by:
%     Damping Command -> Smart Damper (EM) -> Power Electronics -> Power Bank <- Bogie Loads
%                                 ^ Fail-safe Relay <-- bank status
%   Every signal is per bogie (2x1: front, rear).
%   Run from the SwarmRide_Sim folder:   >> run scripts/build_stage2

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'));
mdl = 'SR_Stage2';
if bdIsLoaded(mdl), close_system(mdl, 0); end
f = fullfile(root, 'models', [mdl '.slx']);
if isfile(f), delete(f); end

new_system(mdl);
set_param(mdl, 'Solver', 'ode4', 'FixedStep', 'P.Ts', 'StopTime', 'P.Tend', ...
    'SaveOutput', 'off', 'ReturnWorkspaceOutputs', 'on', ...
    'InitFcn', 'sr_params; TR = sr_track(P, trackType);');
PLANT = 'Vehicle Plant (half-coach 4-DOF)';
SD    = 'Smart Damper (EM)';
PE    = 'Power Electronics';
PB    = 'Power Bank (supercap + LiFePO4)';
LD    = 'Bogie Loads';
FS    = 'Fail-safe Relay';
CMD   = 'Damping Command';

%% 1-2. Track Input and Vehicle Plant (identical to Stage 1)
sr_add_track(mdl, [60 140 230 240]);
sr_add_plant(mdl, [330 120 520 260]);

%% 3. Damping Command (Stage 2: fixed; Stage 3 replaces it with the LPV + preview controller)
s = [mdl '/' CMD];
add_block('built-in/Subsystem', s, 'Position', [60 360 220 410]);
set_param(s, 'Description', ['Damping the smart damper should give, per bogie. Stage 2 uses a fixed value: ' ...
    '''match'' = today''s damping, ''harvest'' = coil load equal to coil resistance.']);
add_block('simulink/Sources/Constant', [s '/Damping command c* (fixed)'], 'Value', 'P.c_cmd_emd*[1;1]', ...
    'SampleTime', 'P.Ts', 'Position', [40 30 180 60]);
add_block('built-in/Outport', [s '/c_cmd'], 'Position', [240 38 270 52]);
add_line(s, 'Damping command c* (fixed)/1', 'c_cmd/1');

%% 4. Fail-safe Relay
s = [mdl '/' FS];
add_block('built-in/Subsystem', s, 'Position', [60 450 220 500]);
set_param(s, 'Description', ['Drops the relay (coil connected to the fail-safe resistor) on a fault or when the ' ...
    'power bank cannot run the controller. The damper then behaves like today''s passive damper.']);
add_block('built-in/Inport', [s '/bankOK'], 'Position', [30 103 60 117]);
add_block('simulink/Sources/Step', [s '/Fault test (at t_fault)'], 'Time', 'P.t_fault', 'Before', '0', ...
    'After', '1', 'Position', [30 30 70 70]);
sr_mlfcn([s '/Relay logic'], [130 40 250 120], strjoin({ ...
    'function relay = fcn(fault, bankOK)'
    '% 1 = relay dropped: coil on the fail-safe resistor (passive damper). 0 = normal (converter).'
    'relay = double((fault > 0.5) | (bankOK < 0.5));'}, newline), {}, {'relay', '[2 1]'});
add_block('built-in/Outport', [s '/relay'], 'Position', [300 73 330 87]);
add_line(s, 'Fault test (at t_fault)/1', 'Relay logic/1');
add_line(s, 'bankOK/1', 'Relay logic/2');
add_line(s, 'Relay logic/1', 'relay/1');
sr_add_log(s, 'Relay logic/1', 'relay', [300 120 380 144]);

%% 5. Smart Damper (EM): machine + H-bridge current control + relay + passive part
s = [mdl '/' SD];
add_block('built-in/Subsystem', s, 'Position', [330 340 520 520]);
set_param(s, 'Description', ['Electromagnetic damper per bogie: e = Ke v, F = Ke i. The H-bridge sets the coil ' ...
    'current, and the current sets the damping. Plus the passive part (oil, friction, inertance).']);
add_block('built-in/Inport', [s '/vrel'],  'Position', [30 103 60 117]);
add_block('built-in/Inport', [s '/c_cmd'], 'Position', [30 43 60 57]);
add_block('built-in/Inport', [s '/relay'], 'Position', [30 213 60 227]);
sr_mlfcn([s '/H-bridge current reference'], [120 30 260 90], strjoin({ ...
    'function iref = fcn(c_cmd, vrel, P)'
    '% The current sets the damping: F = nd Ke i = c vrel  ->  i = c vrel / (nd Ke).'
    '% Damping is limited to 0..Ke^2/Rc (no power drawn from the bank) and current to the rating.'
    'c = min(max(c_cmd, 0), P.cmax_emd);'
    'iref = c .* vrel / (P.nd * P.Ke);'
    'iref = min(max(iref, -P.imax), P.imax);'}, newline), {'P'}, {'iref', '[2 1]'});
add_block('simulink/Math Operations/Sum', [s '/Current error'], 'Inputs', '+-', 'Position', [290 45 310 75]);
add_block('simulink/Math Operations/Gain', [s '/Current loop gain (1 over tau_i)'], 'Gain', '1/P.tau_i', 'Position', [420 45 470 75]);
add_block('simulink/Continuous/Integrator', [s '/Coil current (converter)'], 'InitialCondition', 'zeros(2,1)', ...
    'Position', [620 45 660 75]);
sr_mlfcn([s '/Fail-safe relay (coil to resistor)'], [720 30 860 110], strjoin({ ...
    'function i = fcn(i_conv, vrel, relay, P)'
    '% Normal: the converter sets the current. Relay dropped: the coil drives the fail-safe resistor.'
    'i_fs = P.Ke * vrel / (P.Rc + P.R_fs);'
    'i = (1 - relay) .* i_conv + relay .* i_fs;'}, newline), {'P'}, {'i', '[2 1]'});
sr_mlfcn([s '/Electromagnetic machine'], [940 30 1100 170], strjoin({ ...
    'function [Femd, e, Pgen, Pterm, Pheat] = fcn(i, vrel, relay, P)'
    '% Faraday: e = Ke v.  Lorentz: F = Ke i.  nd dampers per bogie.'
    'e     = P.Ke * vrel;                       % back-EMF of one damper [V]'
    'Femd  = P.nd * P.Ke * i;                   % force per bogie [N]'
    'Pgen  = Femd .* vrel;                      % mechanical power converted [W]'
    'Pcu   = P.nd * P.Rc * i.^2;                % coil copper loss [W]'
    'Pfs   = relay .* (P.nd * P.R_fs * i.^2);   % fail-safe resistor heat [W]'
    'Pterm = (1 - relay) .* (Pgen - Pcu);       % electrical power to the converter [W]'
    'Pheat = Pcu + Pfs;'}, newline), {'P'}, ...
    {'Femd', '[2 1]'; 'e', '[2 1]'; 'Pgen', '[2 1]'; 'Pterm', '[2 1]'; 'Pheat', '[2 1]'});
add_block('simulink/Math Operations/Sum', [s '/Filter error'], 'Inputs', '+-', 'Position', [290 260 310 290]);
add_block('simulink/Math Operations/Gain', [s '/Relative acceleration (filtered)'], 'Gain', '1/P.tau_d', ...
    'Position', [420 260 470 290]);
add_block('simulink/Continuous/Integrator', [s '/Filter state'], 'InitialCondition', 'zeros(2,1)', ...
    'Position', [560 340 600 370]);
sr_mlfcn([s '/Passive part (oil, friction, inertance)'], [720 230 880 310], strjoin({ ...
    'function [Fpas, Ppas] = fcn(vrel, arel, P)'
    '% Design B: half-size oil damper or Casnub wedges. Design C: screw friction + rotor inertance.'
    'Fdis = P.c_oil * vrel + (P.Ffr2 + P.nd * P.Fc) * tanh(vrel / P.veps);'
    'Fpas = Fdis + P.nd * P.b_in * arel;'
    'Ppas = Fdis .* vrel;                       % heat in the passive part [W]'}, newline), {'P'}, ...
    {'Fpas', '[2 1]'; 'Ppas', '[2 1]'});
add_block('simulink/Math Operations/Sum', [s '/Total damper force'], 'Inputs', '++', 'Position', [1160 150 1180 230]);
outs = {'Fd', 'e', 'i', 'Pgen', 'Pterm'};
for k = 1:numel(outs)
    add_block('built-in/Outport', [s '/' outs{k}], 'Position', [1240 33 + 40*(k-1) 1270 47 + 40*(k-1)]);
end
add_line(s, 'c_cmd/1', 'H-bridge current reference/1');
add_line(s, 'vrel/1',  'H-bridge current reference/2', 'autorouting', 'on');
add_line(s, 'H-bridge current reference/1', 'Current error/1');
add_line(s, 'Current error/1', 'Current loop gain (1 over tau_i)/1');
add_line(s, 'Current loop gain (1 over tau_i)/1', 'Coil current (converter)/1');
add_line(s, 'Coil current (converter)/1', 'Current error/2', 'autorouting', 'on');
add_line(s, 'Coil current (converter)/1', 'Fail-safe relay (coil to resistor)/1');
add_line(s, 'vrel/1',  'Fail-safe relay (coil to resistor)/2', 'autorouting', 'on');
add_line(s, 'relay/1', 'Fail-safe relay (coil to resistor)/3', 'autorouting', 'on');
add_line(s, 'Fail-safe relay (coil to resistor)/1', 'Electromagnetic machine/1');
add_line(s, 'vrel/1',  'Electromagnetic machine/2', 'autorouting', 'on');
add_line(s, 'relay/1', 'Electromagnetic machine/3', 'autorouting', 'on');
add_line(s, 'vrel/1',  'Filter error/1', 'autorouting', 'on');
add_line(s, 'Filter error/1', 'Relative acceleration (filtered)/1');
add_line(s, 'Relative acceleration (filtered)/1', 'Filter state/1', 'autorouting', 'on');
add_line(s, 'Filter state/1', 'Filter error/2', 'autorouting', 'on');
add_line(s, 'vrel/1', 'Passive part (oil, friction, inertance)/1', 'autorouting', 'on');
add_line(s, 'Relative acceleration (filtered)/1', 'Passive part (oil, friction, inertance)/2', 'autorouting', 'on');
add_line(s, 'Electromagnetic machine/1', 'Total damper force/1', 'autorouting', 'on');
add_line(s, 'Passive part (oil, friction, inertance)/1', 'Total damper force/2', 'autorouting', 'on');
add_line(s, 'Total damper force/1', 'Fd/1', 'autorouting', 'on');
add_line(s, 'Electromagnetic machine/2', 'e/1', 'autorouting', 'on');
add_line(s, 'Fail-safe relay (coil to resistor)/1', 'i/1', 'autorouting', 'on');
add_line(s, 'Electromagnetic machine/3', 'Pgen/1', 'autorouting', 'on');
add_line(s, 'Electromagnetic machine/4', 'Pterm/1', 'autorouting', 'on');
% logs (out.<name>)
lg = {'Total damper force/1', 'Fd'; 'Electromagnetic machine/2', 'e_coil'; 'Fail-safe relay (coil to resistor)/1', 'i_coil'; ...
      'Electromagnetic machine/3', 'Pgen'; 'Electromagnetic machine/4', 'Pterm'; 'Electromagnetic machine/5', 'Pheat'; ...
      'Passive part (oil, friction, inertance)/2', 'Ppas'};
for k = 1:size(lg, 1)
    sr_add_log(s, lg{k, 1}, lg{k, 2}, [1340 30 + 40*(k-1) 1420 54 + 40*(k-1)]);
end

%% 6. Power Electronics: active rectifier (H-bridge) + DC-DC converter (average models)
s = [mdl '/' PE];
add_block('built-in/Subsystem', s, 'Position', [640 400 800 450]);
set_param(s, 'Description', ['Average models of the power stages. The rectifier turns the coil''s AC into DC; ' ...
    'the DC-DC converter raises the voltage to charge the bank. Each loses a few percent; neither adds energy.']);
add_block('built-in/Inport', [s '/Pterm'], 'Position', [30 43 60 57]);
sr_mlfcn([s '/Active rectifier (H-bridge)'], [110 30 250 70], strjoin({ ...
    'function Prect = fcn(Pterm, P)'
    '% Power out of the rectifier; when power flows backwards (current lag) the losses are on the other side.'
    'Prect = P.eta_rect * max(Pterm, 0) + min(Pterm, 0) / P.eta_rect;'}, newline), {'P'}, {'Prect', '[2 1]'});
sr_mlfcn([s '/DC-DC converter'], [300 30 440 70], strjoin({ ...
    'function Pdc = fcn(Prect, P)'
    '% Raises the voltage to the bank voltage. Power out = efficiency x power in (voltage up, current down).'
    'Pdc = P.eta_dcdc * max(Prect, 0) + min(Prect, 0) / P.eta_dcdc;'}, newline), {'P'}, {'Pdc', '[2 1]'});
add_block('simulink/Math Operations/Sum', [s '/Losses'], 'Inputs', '+-', 'Position', [480 100 500 130]);
add_block('built-in/Outport', [s '/Pdc'],   'Position', [540 43 570 57]);
add_line(s, 'Pterm/1', 'Active rectifier (H-bridge)/1');
add_line(s, 'Active rectifier (H-bridge)/1', 'DC-DC converter/1');
add_line(s, 'DC-DC converter/1', 'Pdc/1');
add_line(s, 'Pterm/1', 'Losses/1', 'autorouting', 'on');
add_line(s, 'DC-DC converter/1', 'Losses/2', 'autorouting', 'on');
sr_add_log(s, 'DC-DC converter/1', 'Pdc', [540 150 620 174]);
sr_add_log(s, 'Losses/1', 'Ppe_loss', [540 100 620 124]);

%% 7. Bogie Loads: what the power bank must supply
s = [mdl '/' LD];
add_block('built-in/Subsystem', s, 'Position', [640 500 800 550]);
set_param(s, 'Description', 'Electrical loads on each bogie, supplied by the power bank.');
lds = {'Safety sensors (bearing, vibration, wheel)', 'P.P_sens'; 'Bogie controller', 'P.P_mcu'; ...
       'Radio to Train Brain', 'P.P_radio'; 'Gate drivers and housekeeping', 'P.P_aux'};
for k = 1:size(lds, 1)
    add_block('simulink/Sources/Constant', [s '/' lds{k, 1}], 'Value', [lds{k, 2} '*[1;1]'], ...
        'SampleTime', 'P.Ts', 'Position', [40 20 + 50*(k-1) 220 45 + 50*(k-1)]);
end
add_block('simulink/Math Operations/Sum', [s '/Total load'], 'Inputs', '++++', 'Position', [280 40 300 170]);
add_block('built-in/Outport', [s '/Pload'], 'Position', [340 98 370 112]);
for k = 1:size(lds, 1)
    add_line(s, [lds{k, 1} '/1'], sprintf('Total load/%d', k), 'autorouting', 'on');
end
add_line(s, 'Total load/1', 'Pload/1');
sr_add_log(s, 'Total load/1', 'Pload', [340 160 420 184]);

%% 8. Power Bank: supercapacitor + LiFePO4 battery + energy supervisor
s = [mdl '/' PB];
add_block('built-in/Subsystem', s, 'Position', [900 400 1080 560]);
set_param(s, 'Description', ['Supercapacitor catches the short power bursts; the LiFePO4 battery stores energy; ' ...
    'the energy supervisor decides where the power goes (instead of a Stateflow chart).']);
add_block('built-in/Inport', [s '/Pdc'],   'Position', [30 43 60 57]);
add_block('built-in/Inport', [s '/Pload'], 'Position', [30 83 60 97]);
sr_mlfcn([s '/Energy supervisor'], [120 30 290 190], strjoin({ ...
    'function [Psc, dSOC, Pdump, Punserved, Pbloss] = fcn(Pdc, Pload, Esc, SOC, P)'
    '% Rules, per bogie:'
    '%  1. Loads and harvested power meet on the supercapacitor (DC link).'
    '%  2. Supercap high (> Vchg): charge the battery.  Supercap low (< Vdis): battery supports.'
    '%  3. Supercap full and battery full: dump the surplus (resistor).'
    '%  4. Supercap empty and battery empty: loads cannot be served.'
    'Psc = zeros(2,1); dSOC = zeros(2,1); Pdump = zeros(2,1); Punserved = zeros(2,1); Pbloss = zeros(2,1);'
    'for b = 1:2'
    '    V = sqrt(max(2 * Esc(b) / P.Csc, 0));'
    '    Pch = 0; Pdis = 0;'
    '    if V > P.Vchg && SOC(b) < P.SOCmax'
    '        Pch = min(P.Pch_max, P.Kv * (V - P.Vchg));'
    '    elseif V < P.Vdis && SOC(b) > P.SOCmin'
    '        Pdis = min(P.Pdis_max, P.Kv * (P.Vdis - V));'
    '    end'
    '    p = Pdc(b) - Pload(b) - Pch + Pdis;'
    '    if V >= P.Vmax && p > 0, Pdump(b) = p; p = 0; end'
    '    if V <= P.Vmin && p < 0, Punserved(b) = -p; p = 0; end'
    '    Psc(b) = p;'
    '    dSOC(b) = (P.eta_ch * Pch - Pdis / P.eta_dis) / (P.Ebat_Wh * 3600);'
    '    Pbloss(b) = (1 - P.eta_ch) * Pch + (1 / P.eta_dis - 1) * Pdis;'
    'end'}, newline), {'P'}, ...
    {'Psc', '[2 1]'; 'dSOC', '[2 1]'; 'Pdump', '[2 1]'; 'Punserved', '[2 1]'; 'Pbloss', '[2 1]'});
add_block('simulink/Continuous/Integrator', [s '/Supercapacitor energy'], 'InitialCondition', 'P.Esc0*[1;1]', ...
    'Position', [360 35 400 65]);
add_block('simulink/Continuous/Integrator', [s '/LiFePO4 state of charge'], 'InitialCondition', 'P.SOC0*[1;1]', ...
    'Position', [360 85 400 115]);
sr_mlfcn([s '/Bank status'], [460 30 600 120], strjoin({ ...
    'function [Vsc, bankOK] = fcn(Esc, SOC, P)'
    '% Supercap voltage from its energy (E = C V^2 / 2); bank OK while either store can run the loads.'
    'Vsc = sqrt(max(2 * Esc / P.Csc, 0));'
    'bankOK = double((Vsc > P.Vmin) | (SOC > P.SOCmin));'}, newline), {'P'}, {'Vsc', '[2 1]'; 'bankOK', '[2 1]'});
outs = {'Vsc', 'SOC', 'bankOK'};
for k = 1:numel(outs)
    add_block('built-in/Outport', [s '/' outs{k}], 'Position', [680 33 + 40*(k-1) 710 47 + 40*(k-1)]);
end
add_line(s, 'Pdc/1',   'Energy supervisor/1');
add_line(s, 'Pload/1', 'Energy supervisor/2');
add_line(s, 'Supercapacitor energy/1',   'Energy supervisor/3', 'autorouting', 'on');
add_line(s, 'LiFePO4 state of charge/1', 'Energy supervisor/4', 'autorouting', 'on');
add_line(s, 'Energy supervisor/1', 'Supercapacitor energy/1', 'autorouting', 'on');
add_line(s, 'Energy supervisor/2', 'LiFePO4 state of charge/1', 'autorouting', 'on');
add_line(s, 'Supercapacitor energy/1',   'Bank status/1', 'autorouting', 'on');
add_line(s, 'LiFePO4 state of charge/1', 'Bank status/2', 'autorouting', 'on');
add_line(s, 'Bank status/1', 'Vsc/1', 'autorouting', 'on');
add_line(s, 'LiFePO4 state of charge/1', 'SOC/1', 'autorouting', 'on');
add_line(s, 'Bank status/2', 'bankOK/1', 'autorouting', 'on');
lg = {'Bank status/1', 'Vsc'; 'LiFePO4 state of charge/1', 'SOC'; 'Energy supervisor/1', 'Psc'; ...
      'Energy supervisor/3', 'Pdump'; 'Energy supervisor/4', 'Punserved'; 'Energy supervisor/5', 'Pbloss'};
for k = 1:size(lg, 1)
    sr_add_log(s, lg{k, 1}, lg{k, 2}, [800 30 + 40*(k-1) 880 54 + 40*(k-1)]);
end

%% 9. Top-level wiring
add_line(mdl, 'Track Input/1', [PLANT '/1'], 'autorouting', 'on');
add_line(mdl, 'Track Input/2', [PLANT '/2'], 'autorouting', 'on');
add_line(mdl, [PLANT '/3'], [SD '/1'], 'autorouting', 'on');          % vrel -> smart damper
add_line(mdl, [CMD '/1'],   [SD '/2'], 'autorouting', 'on');          % damping command
add_line(mdl, [FS '/1'],    [SD '/3'], 'autorouting', 'on');          % relay
add_line(mdl, [SD '/1'],    [PLANT '/3'], 'autorouting', 'on');       % Fd -> coach
add_line(mdl, [SD '/5'],    [PE '/1'], 'autorouting', 'on');          % Pterm -> power electronics
add_line(mdl, [PE '/1'],    [PB '/1'], 'autorouting', 'on');          % Pdc -> bank
add_line(mdl, [LD '/1'],    [PB '/2'], 'autorouting', 'on');          % loads -> bank
add_line(mdl, [PB '/3'],    [FS '/1'], 'autorouting', 'on');          % bank status -> relay

%% 10. Logging: coach signals here; every other block logs its own signals inside
sr_add_log(mdl, [PLANT '/1'], 'az',     [640 100 720 124]);
sr_add_log(mdl, [PLANT '/2'], 'stroke', [640 160 720 184]);
sr_add_log(mdl, [PLANT '/3'], 'vrel',   [640 220 720 244]);

%% 11. Live scopes
sr_add_scope(mdl, 'Scope 1 - Body vibration (comfort)', {[PLANT '/1']}, ...
    'Body acceleration [m/s^2]: centre, over front bogie, over rear bogie', [1180 100 1230 150]);
sr_add_scope(mdl, 'Scope 2 - Suspension stroke (safety)', {[PLANT '/2']}, ...
    'Secondary stroke [m]: front, rear (limit about +/-0.04 m)', [1180 180 1230 230]);
sr_add_scope(mdl, 'Scope 3 - Damper force', {[SD '/1']}, ...
    'Smart damper force [N]: front, rear', [1180 260 1230 310]);
sr_add_scope(mdl, 'Scope 4 - Rail under the wheels', {'Track Input/1'}, ...
    'Rail height [m] under wheels 1-4', [120 560 170 610]);
sr_add_scope(mdl, 'Scope 5 - Coil voltage and current', {[SD '/2'], [SD '/3']}, ...
    {'Coil voltage e = Ke v [V]: front, rear', 'Coil current [A]: front, rear'}, [1180 340 1230 400]);
sr_add_scope(mdl, 'Scope 6 - Power flow', {[SD '/4'], [PE '/1'], [LD '/1']}, ...
    {'Mechanical power into the generator [W]', 'Power into the bank after converters [W]', ...
     'Bogie loads [W]'}, [1180 430 1230 500]);
sr_add_scope(mdl, 'Scope 7 - Power bank', {[PB '/1'], [PB '/2']}, ...
    {'Supercapacitor voltage [V]: front, rear', 'Battery state of charge [0-1]: front, rear'}, [1180 530 1230 590]);
try
    set_param(mdl, 'EnablePacing', 'on', 'PacingRate', 1);
catch err
    warning('Real-time pacing not set: %s', err.message);
end

try
    nt = add_block('built-in/Note', [mdl '/Stage 2: the SwarmRide smart damper. Choose designType = A, B or C and cmdMode = match or harvest (t_fault = time of a test fault)']);
    set_param(nt, 'Position', [60 40 900 70]);
catch
end

save_system(mdl, f);
fprintf('Built %s\n', f);

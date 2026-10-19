function build_control_diagram()
%BUILD_CONTROL_DIAGRAM Draws the SwarmRide control system as a Simulink block diagram.
%   models/SR_ControlDiagram.slx and results/control_system_design.png: the whole control
%   architecture with summing junctions, gains, transfer functions, saturations and switches.
%   It is a documentation diagram; the working controllers are in SR_Stage3/4 and SR_Bench.
%     Outer loop (vehicle controller, 100 Hz): LPV-LQR state feedback Kx(m) + Train Brain preview
%       feed-forward Kp(m) -> ideal force F* -> semi-active conversion -> current reference
%       (damping law, or the push at a known bad spot, controller C4)
%     Inner loop (damper drive, 10 kHz): PI current control + back-EMF feed-forward -> inverter
%       limit -> contactor (inverter or fail-safe resistors) -> coil 1/(L s + Rc) -> F = Ke i
%     Plant: half-coach 4-DOF vehicle driven by the damper force and the track
%   Run from the SwarmRide_Sim folder:   >> build_control_diagram

root = fileparts(fileparts(mfilename('fullpath')));
mdl = 'SR_ControlDiagram';
if bdIsLoaded(mdl), close_system(mdl, 0); end
f = fullfile(root, 'models', [mdl '.slx']);
if isfile(f), delete(f); end
new_system(mdl);

teal = '[0.83 0.94 0.92]';  orng = '[1.00 0.90 0.80]';  grey = '[0.93 0.94 0.95]';
red  = '[1.00 0.88 0.87]';  blue = '[0.86 0.91 0.98]';  yell = '[1.00 0.97 0.84]';

%% Train Brain and the vehicle controller (100 Hz)
inp('Track irregularity w(t)',             [30 73 60 87]);
blk('simulink/Continuous/Transport Delay', 'Train Brain preview (rail ahead, t = d ÷ v)', [130 60 250 100], blue, 'DelayTime', 'd/v');
inp('Load estimate m (air-spring pressure)', [30 233 60 247]);
sub('Preview feed-forward Kp(m)',          [330 50 450 110], teal, {'p', 'm'}, {'Kp p'});
sub('LPV-LQR state feedback Kx(m)',        [330 190 450 250], teal, {'x', 'm'}, {'Kx x'});
sumb('Ideal force F* = -Kx x - Kp p',      [520 135 550 165], '--');
sub('Semi-active conversion c* = F* v ÷ (v^2 + eps^2), clip [c_floor, c_cap]', [620 125 760 185], teal, {'F*', 'v'}, {'c*'});
sub('Damping law i* = c* v ÷ (nd Ke)',     [830 130 950 180], teal, {'c*', 'v'}, {'i*'});
blk('simulink/Math Operations/Gain', 'Push at a known bad spot i* = F* ÷ (nd Ke)', [830 40 950 80], orng, 'Gain', '1/(nd*Ke)');
inp('Push window act (C4)',                [830 243 860 257]);
blk('simulink/Signal Routing/Switch', 'C4 push window', [1010 70 1050 190], orng, 'Criteria', 'u2 > Threshold', 'Threshold', '0.5');
blk('simulink/Discontinuities/Saturation', 'Current limit +-i_lim', [1100 115 1160 145], grey, 'UpperLimit', 'i_lim', 'LowerLimit', '-i_lim');

%% Damper drive (10 kHz)
sumb('Current error',                      [60 435 90 465], '+-');
blk('simulink/Continuous/Transfer Fcn', 'PI current controller (L s + Rc) ÷ (tau s)', [150 425 280 475], yell, 'Numerator', '[L Rc]', 'Denominator', '[tau 0]');
blk('simulink/Math Operations/Gain', 'Back-EMF feed-forward Ke', [150 530 280 570], yell, 'Gain', 'Ke');
sumb('Inverter u',                   [340 435 370 465], '++');
blk('simulink/Discontinuities/Saturation', 'Inverter voltage limit +-0.866 Vdc', [430 435 500 465], grey, 'UpperLimit', 'Umax', 'LowerLimit', '-Umax');
blk('simulink/Math Operations/Gain', 'Fail-safe resistors R_fs i', [420 600 490 640], red, 'Gain', 'R_fs');
inp('Fault in', [340 693 370 707]);
blk('simulink/Discontinuities/Relay', 'Fail-safe supervisor (latched)', [420 680 490 720], red, 'OnSwitchValue', '0.5', 'OffSwitchValue', '0.5');
blk('simulink/Signal Routing/Switch', 'Contactor (inverter or fail-safe resistors)', [560 420 600 660], red, 'Criteria', 'u2 > Threshold', 'Threshold', '0.5');

%% Smart damper hardware and the vehicle
sumb('Coil voltage',                       [660 470 690 500], '+-');
blk('simulink/Math Operations/Gain', 'Back-EMF e = Ke v', [640 560 740 600], grey, 'Gain', 'Ke');
blk('simulink/Continuous/Transfer Fcn', 'Coil 1 ÷ (L s + Rc)', [750 460 860 510], grey, 'Numerator', '1', 'Denominator', '[L Rc]');
blk('simulink/Math Operations/Gain', 'Machine constant F = nd Ke i', [920 465 1020 505], grey, 'Gain', 'nd*Ke');
sub('Ball screw: friction + inertance',   [920 560 1050 610], grey, {'v'}, {'F_pas'});
sumb('Damper force',                       [1090 470 1120 500], '++');
sub('Half-coach vehicle (4-DOF): x'' = A(m) x + B_F F_d + B_w w', [1180 420 1380 580], blue, {'F_d', 'w'}, {'body acceleration', 'x', 'v'});
blk('simulink/Sinks/Scope', 'Ride comfort (Sperling Wz)', [1460 425 1500 465], '');
sub('State observer (accelerometers + motor encoder)', [1180 680 1360 740], teal, {'x'}, {'x hat'});
blk('simulink/Math Operations/Product', 'Harvested power P = u i', [660 680 700 720], yell);
sub('Power electronics + bank (supercap + LiFePO4)', [760 670 940 730], yell, {'P'}, {'bank OK'});

%% Wiring
ln('Track irregularity w(t)/1', 'Train Brain preview (rail ahead, t = d ÷ v)/1');
ln('Train Brain preview (rail ahead, t = d ÷ v)/1', 'Preview feed-forward Kp(m)/1', 'p');
ln('Load estimate m (air-spring pressure)/1', 'Preview feed-forward Kp(m)/2');
ln('Load estimate m (air-spring pressure)/1', 'LPV-LQR state feedback Kx(m)/2', 'm');
ln('Preview feed-forward Kp(m)/1', 'Ideal force F* = -Kx x - Kp p/1');
ln('LPV-LQR state feedback Kx(m)/1', 'Ideal force F* = -Kx x - Kp p/2');
ln('Ideal force F* = -Kx x - Kp p/1', 'Semi-active conversion c* = F* v ÷ (v^2 + eps^2), clip [c_floor, c_cap]/1', 'F*');
ln('Ideal force F* = -Kx x - Kp p/1', 'Push at a known bad spot i* = F* ÷ (nd Ke)/1');
ln('Semi-active conversion c* = F* v ÷ (v^2 + eps^2), clip [c_floor, c_cap]/1', 'Damping law i* = c* v ÷ (nd Ke)/1', 'c*');
ln('Push at a known bad spot i* = F* ÷ (nd Ke)/1', 'C4 push window/1');
ln('Push window act (C4)/1', 'C4 push window/2', 'act');
ln('Damping law i* = c* v ÷ (nd Ke)/1', 'C4 push window/3');
ln('C4 push window/1', 'Current limit +-i_lim/1');
ln('Current limit +-i_lim/1', 'Current error/1', 'i*');
ln('Current error/1', 'PI current controller (L s + Rc) ÷ (tau s)/1');
ln('PI current controller (L s + Rc) ÷ (tau s)/1', 'Inverter u/1');
ln('Back-EMF feed-forward Ke/1', 'Inverter u/2');
ln('Inverter u/1', 'Inverter voltage limit +-0.866 Vdc/1');
ln('Inverter voltage limit +-0.866 Vdc/1', 'Contactor (inverter or fail-safe resistors)/3', 'u');
ln('Fault in/1', 'Fail-safe supervisor (latched)/1');
ln('Fail-safe supervisor (latched)/1', 'Contactor (inverter or fail-safe resistors)/2', 'relay');
ln('Fail-safe resistors R_fs i/1', 'Contactor (inverter or fail-safe resistors)/1');
ln('Contactor (inverter or fail-safe resistors)/1', 'Coil voltage/2');
ln('Back-EMF e = Ke v/1', 'Coil voltage/1', 'e');
ln('Coil voltage/1', 'Coil 1 ÷ (L s + Rc)/1');
ln('Coil 1 ÷ (L s + Rc)/1', 'Machine constant F = nd Ke i/1', 'i');
ln('Coil 1 ÷ (L s + Rc)/1', 'Current error/2');
ln('Coil 1 ÷ (L s + Rc)/1', 'Fail-safe resistors R_fs i/1');
ln('Coil 1 ÷ (L s + Rc)/1', 'Harvested power P = u i/2');
ln('Inverter voltage limit +-0.866 Vdc/1', 'Harvested power P = u i/1');
ln('Harvested power P = u i/1', 'Power electronics + bank (supercap + LiFePO4)/1');
ln('Machine constant F = nd Ke i/1', 'Damper force/1', 'F_em');
ln('Ball screw: friction + inertance/1', 'Damper force/2');
ln('Damper force/1', 'Half-coach vehicle (4-DOF): x'' = A(m) x + B_F F_d + B_w w/1', 'F_d');
ln('Track irregularity w(t)/1', 'Half-coach vehicle (4-DOF): x'' = A(m) x + B_F F_d + B_w w/2');
ln('Half-coach vehicle (4-DOF): x'' = A(m) x + B_F F_d + B_w w/1', 'Ride comfort (Sperling Wz)/1');
ln('Half-coach vehicle (4-DOF): x'' = A(m) x + B_F F_d + B_w w/2', 'State observer (accelerometers + motor encoder)/1', 'x');
ln('State observer (accelerometers + motor encoder)/1', 'LPV-LQR state feedback Kx(m)/1');
ln('Half-coach vehicle (4-DOF): x'' = A(m) x + B_F F_d + B_w w/3', 'Semi-active conversion c* = F* v ÷ (v^2 + eps^2), clip [c_floor, c_cap]/2', 'v');
ln('Half-coach vehicle (4-DOF): x'' = A(m) x + B_F F_d + B_w w/3', 'Damping law i* = c* v ÷ (nd Ke)/2');
ln('Half-coach vehicle (4-DOF): x'' = A(m) x + B_F F_d + B_w w/3', 'Back-EMF feed-forward Ke/1');
ln('Half-coach vehicle (4-DOF): x'' = A(m) x + B_F F_d + B_w w/3', 'Back-EMF e = Ke v/1');
ln('Half-coach vehicle (4-DOF): x'' = A(m) x + B_F F_d + B_w w/3', 'Ball screw: friction + inertance/1');

%% Region labels
note('VEHICLE CONTROLLER (100 Hz): Train Brain preview + LPV-LQR, semi-active conversion, C4 push', [130 0]);
note('DAMPER DRIVE (10 kHz): PI current loop + back-EMF feed-forward, fail-safe', [60 380]);
note('SMART DAMPER + HALF-COACH VEHICLE', [660 380]);

save_system(mdl, f);
print(['-s' mdl], '-dpng', '-r200', fullfile(root, 'results', 'control_system_design.png'));
close_system(mdl, 0);
fprintf('Built %s and results/control_system_design.png\n', f);

    function b = blk(lib, name, pos, bg, varargin)
        b = [mdl '/' name];
        add_block(lib, b, 'Position', pos, varargin{:});
        if ~isempty(bg), set_param(b, 'BackgroundColor', bg); end
    end
    function inp(name, pos)
        add_block('built-in/Inport', [mdl '/' name], 'Position', pos);
    end
    function sub(name, pos, bg, ins, outs)
        b = [mdl '/' name];
        add_block('built-in/Subsystem', b, 'Position', pos, 'BackgroundColor', bg);
        for k = 1:numel(ins)
            add_block('built-in/Inport', [b '/' ins{k}], 'Position', [20 20 + 40*k 50 34 + 40*k]);
        end
        for k = 1:numel(outs)
            add_block('built-in/Outport', [b '/' outs{k}], 'Position', [200 20 + 40*k 230 34 + 40*k]);
            add_line(b, [ins{min(k, numel(ins))} '/1'], [outs{k} '/1']);
        end
        set_param(b, 'ContentPreviewEnabled', 'off');
    end
    function ln(a, b, label)
        h = add_line(mdl, a, b, 'autorouting', 'on');
        if nargin > 2, set_param(h, 'Name', label); end
    end
    function sumb(name, pos, signs)
        add_block('simulink/Math Operations/Sum', [mdl '/' name], 'Position', pos, ...
            'IconShape', 'round', 'Inputs', ['|' signs]);
    end
    function note(txt, xy)
        a = Simulink.Annotation([mdl '/' txt]);
        a.Position = [xy(1) xy(2)];
        a.FontSize = 14;  a.FontWeight = 'bold';
    end
end

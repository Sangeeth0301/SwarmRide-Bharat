%% SR_PARAMS_BENCH  Parameters of the bench-prototype model (models/SR_Bench.slx), one damper.
%
% Inputs (set in the workspace before running, otherwise defaults are used):
%   benchTest  'emf' | 'damping' | 'step' | 'vlimit' | 'failsafe' |
%              'replay_poor' | 'replay_good' | 'replay_settle'        (see functions/bp_bench_profile.m)
%   benchMode  'real'     : the hardware as designed (fast current loop, voltage limit, inverter
%                           losses, contactor delay)
%              'simequiv' : the same simplifications as the vehicle simulation (2 ms current loop,
%                           no voltage limit, no inverter or contactor detail), used to check the
%                           bench model against the vehicle model
%   BP_override  struct of BP fields to change (e.g. struct('Vdc', 48))
%
% The prototype is the LHB design-C damper (crowded coach, 160 km/h). The damper motion of the
% replay tests and the duty U come from the vehicle simulation (results/bench_drive.mat,
% written by scripts/check_bench.m).

if ~exist('benchTest', 'var'), benchTest = 'replay_poor'; end
if ~exist('benchMode', 'var'), benchMode = 'real';        end
trainType = 'LHB';  designType = 'C';  trackType = 'poor';
v_kmh = 160;  mload_t = 12;
sr_params;                                            % vehicle and damper parameters (P, D)

drv = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results', 'bench_drive.mat');
if ~isfile(drv)
    error('sr_params_bench:drive', 'results/bench_drive.mat is missing: run scripts/check_bench.m first.');
end
BD = load(drv);                                       % DR (recorded damper motion), U (duty)
HW = bp_hardware(D, P, BD.U);

BP = HW;                                              % numbers only (goes into Simulink blocks)
BP.Ts        = HW.Ti;                                 % solver step = current-control period [s]
BP.Tlog      = 1e-3;                                  % data-logger rate [s]
BP.b_in      = D.b_in;                                % inertance (rotor + screw) [kg]
BP.veps      = P.veps;                                % friction smoothing speed [m/s]
BP.tau_open  = 1e-4;                                  % current decay with the inverter switched off [s]
BP.Vbank_min = P.Vmin;                                % below this the controller supply is at risk [V]
BP.Vmax      = P.Vmax;                                % supercapacitor full [V]
BP.Csc       = P.Csc;
BP.Esc0      = 0.5 * P.Csc * 30^2;                    % supercapacitor starts at 30 V [J]
BP.Pload     = (P.P_sens + P.P_mcu + P.P_radio + P.P_aux) / P.nd;   % half of one bogie's loads [W]
BP.Tw0       = HW.Tamb;                               % winding starts at ambient [C]
BP.n_delay   = max(round(HW.t_contactor / HW.Ti), 1); % contactor drop-out delay [samples]

if strcmp(benchMode, 'simequiv')
    BP.tau_cl = P.tau_i;                              % the vehicle model's 2 ms current loop
    BP.Umax   = 1e9;                                  % no voltage limit
    BP.Ron    = 0;   BP.ksw = 0;                      % converter losses counted later as efficiencies
    BP.n_delay = 1;                                   % contactor acts at once
    BP.i_lim  = D.imax;                               % the vehicle model's current limit
end
if exist('BP_override', 'var') && isstruct(BP_override)
    fo = fieldnames(BP_override);
    for ko = 1:numel(fo), BP.(fo{ko}) = BP_override.(fo{ko}); end
end

BX = bp_bench_profile(benchTest, BP, BD.DR);
BP.Tend = BX.Tend;
clear BD drv fo ko

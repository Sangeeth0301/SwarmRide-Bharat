%% SR_PARAMS  SwarmRide Bharat - model parameters for one scenario
%
% Scenario inputs - set these in the workspace before running, otherwise defaults are used:
%   trainType  'LHB' | 'VB' | 'ICF' | 'BOXN' | 'GENERIC'   (today's Indian rolling stock)
%   v_kmh      train speed                    [km/h]
%   mload_t    passenger / cargo load          [t]
%   trackType  'good' | 'poor' | 'bump'
%
% Base values per vehicle come from functions/sr_trains.m, which notes the source of
% every number. Values marked "assumed" must be replaced with RDSO / manufacturer data.

if ~exist('trainType', 'var'), trainType = 'LHB';                end
TB = sr_trains(trainType);
if ~exist('v_kmh', 'var'),     v_kmh = max(TB.speeds);           end
if ~exist('mload_t', 'var'),   mload_t = max(TB.loads_t);        end
if ~exist('trackType', 'var'), trackType = 'poor';               end

P = struct();
Pinfo = struct('trainName', TB.name, 'springType', TB.springType);   % text kept outside P (P goes into Simulink blocks)

%% 1. Coach / wagon body (sprung mass: body + passengers or cargo)
P.m_tare = TB.m_tare;                              % empty body mass                       [kg]
P.m_load = mload_t * 1e3;                          % passenger / cargo load                [kg]
P.m      = P.m_tare + P.m_load;                    % total body mass                       [kg]
P.I      = P.m * TB.Lbody^2 / 12;                  % body pitch inertia (uniform-bar estimate) [kg m^2]

%% 2. Geometry
P.lb = TB.lb;                                      % half distance between bogie centres   [m]
P.ab = TB.ab;                                      % half bogie wheelbase                  [m]

%% 3. Bogie frames (sprung on the primary suspension)
P.mbg = TB.mbg;                                    % per bogie                             [kg]

%% 4. Secondary suspension, per bogie
P.ks   = sr_spring_rate(TB, P.m_load);             % air: rises with load; coil: constant; Casnub: two-stage

P.cs   = TB.cs;                                    % today's viscous damper                [N s/m]
P.Ffr  = TB.mu_fric * P.m * 9.81 / 2;              % friction-wedge force (Casnub only)    [N]
P.veps = 0.02;                                     % friction smoothing velocity           [m/s]
P.sag  = P.m * 9.81 / (2 * P.ks);                  % static secondary deflection           [m]
if strcmp(TB.springType, 'air'), P.sag = 0; end    % air springs: levelling valves hold floor height

%% 5. Primary suspension, per wheelset
P.kp = TB.kp;                                      %                                       [N/m]
P.cp = TB.cp;                                      %                                       [N s/m]

%% 6. Operating point and wheel positions
P.v    = v_kmh / 3.6;                              % speed                                 [m/s]
P.dist = [0; 2*P.ab; 2*P.lb; 2*P.lb + 2*P.ab];     % wheel distance behind the lead wheel  [m]
P.s0   = 150;                                      % start position on the track           [m]

%% 7. Track irregularity (vertical track spectrum)
P.Av_good   = 4.032e-7;                            % roughness constant, good track        [m rad]
P.Av_poor   = 1.08e-6;                             % roughness constant, poor track        [m rad]
P.trackSeed = 7;                                   % same random track for every controller

%% 8. Simulation settings
P.Ts   = TB.Ts;                                    % fixed step                            [s]
if exist('Ts_override', 'var') && ~isempty(Ts_override)
    P.Ts = Ts_override;                            % step-size convergence checks only
end
P.Tend = 30;                                       % simulated time                        [s]

%% 9. Stage 2: SwarmRide smart damper (sized per vehicle in functions/sr_damper_design.m)
%   designType  'A' direct-drive linear | 'B' hybrid | 'C' geared rotary
%   cmdMode     'match'   : electromagnetic copy of today's damping (same ride, plus energy)
%               'harvest' : fixed-load harvester, coil load = coil resistance (most power per speed)
%   t_fault     time of a test fault that drops the fail-safe relay [s] (Inf = no fault)
if ~exist('designType', 'var'), designType = 'C';     end    % C = lead design (Stage 2)
if ~exist('cmdMode', 'var'),    cmdMode = 'match';    end
if ~exist('t_fault', 'var'),    t_fault = Inf;        end
D = sr_damper_design(TB, P, designType);
Pinfo.designName = D.name;
Pinfo.cmdMode    = cmdMode;

P.nd       = D.nd;                                 % EM dampers per bogie
P.Ke       = D.Ke;                                 % machine constant per damper           [V s/m = N/A]
P.Rc       = D.Rc;                                 % coil resistance per damper            [ohm]
P.cmax_emd = D.cmax_emd;                           % most EM damping per bogie (coil shorted) [N s/m]
P.c_oil    = D.c_oil;                              % passive oil damper kept (design B)    [N s/m]
P.Ffr2     = D.keepFriction * P.Ffr;               % Casnub wedge friction kept (design B) [N]
P.Fc       = D.Fc;                                 % ball-screw friction per damper (C)    [N]
P.b_in     = D.b_in;                               % inertance per damper (C)              [kg]
P.imax     = D.imax;                               % current limit per damper              [A]
P.R_fs     = D.R_fs;                               % fail-safe resistor                    [ohm]
P.c_today  = D.c_today;                            % today's damping, per bogie            [N s/m]
P.tau_i    = 2e-3;                                 % converter current-loop time constant  [s]
P.tau_d    = 2e-3;                                 % filter for relative acceleration      [s]
P.t_fault  = min(t_fault, 1e6);                    % test fault time                       [s]
switch cmdMode
    case 'match',   P.c_cmd_emd = D.c_match_emd;   % same total damping as today
    case 'harvest', P.c_cmd_emd = D.cmax_emd / 2;  % load resistance = coil resistance
    otherwise, error('sr_params:cmdMode', 'cmdMode must be match or harvest');
end

%% 10. Stage 2: power electronics, power bank and bogie loads (per bogie)
P.eta_rect = 0.95;                                 % active rectifier (H-bridge) efficiency
P.eta_dcdc = 0.94;                                 % DC-DC converter efficiency
P.Csc      = 10;                                   % supercapacitor                        [F]
P.Vmax     = 48;  P.Vmin = 12;                     % supercapacitor voltage window          [V]
P.Vchg     = 40;  P.Vdis = 20;                     % charge battery above / support from battery below [V]
P.Esc0     = 0.5 * P.Csc * 30^2;                   % start at 30 V                         [J]
P.Ebat_Wh  = 120;                                  % LiFePO4, 24 V x 5 Ah                  [Wh]
P.SOC0     = 0.6;  P.SOCmin = 0.10;  P.SOCmax = 0.95;
P.eta_ch   = 0.95; P.eta_dis = 0.95;               % battery charge / discharge efficiency
P.Pch_max  = 300;  P.Pdis_max = 100;               % battery power limits                  [W]
P.Kv       = 50;                                   % supervisor gain                       [W/V]
P.P_sens   = 4;                                    % safety sensors: bearing temp, vibration, wheel [W]
P.P_mcu    = 2;                                    % bogie controller                      [W]
P.P_radio  = 1;                                    % radio link to the Train Brain         [W]
P.P_aux    = 1;                                    % gate drivers, housekeeping            [W]

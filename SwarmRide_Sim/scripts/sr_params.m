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
switch TB.springType
    case 'air'      % air spring stiffens in proportion to load (constant bounce frequency)
        P.ks = TB.ks0 * P.m / P.m_tare;
    case 'coil'     % steel coil springs: constant stiffness, coach sags and softens relatively
        P.ks = TB.ks0;
    case 'casnub'   % two-stage spring nest: inner springs take part as the wagon is loaded
        frac = min(P.m_load / (max(TB.loads_t) * 1e3), 1);
        P.ks = TB.ks0 + frac * (TB.ks_loaded - TB.ks0);
end

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
P.Tend = 30;                                       % simulated time                        [s]

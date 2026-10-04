%% SR_PARAMS_STAGE3  Controller parameters for Stage 3 (run after sr_params).
%
% Scenario inputs (set in the workspace before running, otherwise defaults are used):
%   ctrlMode    'C1' fixed-load harvester | 'C2' LPV load-adaptive | 'C3' LPV + Train Brain preview
%               | 'C4' C3 + active push at known bad spots (Stage 4 model only)
%               (C0, today's damper, is the Stage 1 model)
%   load_err    load-estimate error as a fraction (e.g. 0.05 = estimate 5 % heavy)
%   preview_dt  timing error of the Train Brain warning [s] (+ = warning arrives late)
%   rw          LQR force weight (3 = best comfort found in the Stage 3 sweep)
%   c_floor_frac minimum EM damping as a fraction of c_req (0 = best comfort; higher = more power)

if ~exist('ctrlMode', 'var'),   ctrlMode = 'C3';   end
if ~exist('load_err', 'var'),   load_err = 0.02;   end    % air-spring weighing error (assumed 2 %)
if ~exist('preview_dt', 'var'), preview_dt = 0;    end
if ~exist('rw', 'var'),         rw = 3;            end
if ~exist('c_floor_frac', 'var'), c_floor_frac = 0; end
K3 = sr_stage3_consts();
modes = {'C1', 'C2', 'C3', 'C4'};
P.ctrl = find(strcmp(ctrlMode, modes));
if isempty(P.ctrl), error('sr_params_stage3:mode', 'ctrlMode must be C1, C2, C3 or C4'); end
Pinfo.ctrlMode = ctrlMode;

%% 1. Controller timing and preview window
P.Tc   = K3.Tc;                                   % controller sample time            [s]
P.Na   = K3.Na;  P.Nb = K3.Nb;                    % preview samples ahead / behind the lead wheel
P.pj   = (-K3.Nb:K3.Na)' * P.v * K3.Tc;           % rail sample positions from the lead wheel [m]
P.preview_dt = preview_dt;                        % warning timing error              [s]

%% 2. Load estimate (air-spring pressure or spring deflection)
P.m_hat = P.m * (1 + load_err);                   % body mass the controller believes [kg]

%% 3. LQR weights (normalised: acceleration, stroke, force)
P.a_ref = 0.1;                                    % reference body acceleration       [m/s^2]
P.s_ref = 0.02;                                   % reference stroke (not P.s0, the start position) [m]
P.F_ref = 5e3;                                    % reference damper force            [N]
P.rw = rw;                                        % force weight

%% 4. Semi-active conversion: the damper can only resist motion
P.eps_v = 0.005;                                  % velocity smoothing near zero      [m/s]
P.c_cap = D.c_req;                                % efficiency limit: EM damping at most c_req (zeta 0.25)
P.c_floor = c_floor_frac * D.c_req;               % damping floor: trades comfort for power
P.c_fix = 0.5 * P.cmax_emd;                       % C1: fixed load = coil resistance
if exist('c_fix_override', 'var') && ~isempty(c_fix_override), P.c_fix = c_fix_override; end   % C1 sweeps
P.tau_c = 0.005;                                  % command smoothing                 [s]

%% 5. LPV gains (load grid) for this vehicle and speed
%   The design depends only on the vehicle, speed and weights, so it is cached in work/ and reused.
key = jsonencode(struct('TB', TB, 'v', P.v, 'dist', P.dist, 'kp', P.kp, 'cp', P.cp, 'mbg', P.mbg, ...
    'w', [P.a_ref P.s_ref P.F_ref P.rw], 'K3', K3));
md = java.security.MessageDigest.getInstance('MD5');
md.update(uint8(key));
hash = sprintf('%02x', typecast(md.digest(), 'uint8'));
cachedir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'work', 'controller_cache');
cachefile = fullfile(cachedir, ['ctrl_' hash '.mat']);
if isfile(cachefile)
    CD = load(cachefile);  CD = CD.CD;
else
    CD = sr_controller_design(TB, P);
    if ~isfolder(cachedir), mkdir(cachedir); end
    save(cachefile, 'CD');
end
P.Kgrid_m = CD.m;                                 % body mass at each grid point      [kg]
P.Kx = CD.Kx;                                     % feedback gains (nL x 16)
P.Kp = CD.Kp;                                     % preview gains (nL x 2 Np)

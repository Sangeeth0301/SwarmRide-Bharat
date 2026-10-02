function D = sr_damper_design(TB, P, design)
%SR_DAMPER_DESIGN Sizes the SwarmRide smart damper for one vehicle (Stage 2).
%   D = sr_damper_design(TB, P, 'A' | 'B' | 'C')
%   The hardware is sized once, at FULL load, because it cannot change with the passengers.
%
%   Sizing target: damping ratio zeta_hi = 0.25 on the body mode at full load (c_req, per bogie).
%   Today's damping c_today: the coach's oil damper; for the BOXN wagon (friction wedges, no oil
%   damper) a viscous equivalent at zeta = 0.10 is assumed.
%
%   A  direct-drive linear machine : EM damper does all the damping (1.25 x c_req)
%   B  hybrid                      : coaches keep a half-size oil damper; BOXN keeps its friction
%                                    wedges and adds a smaller EM damper
%   C  geared rotary (ball screw)  : compact high-speed generator, large damping range,
%                                    but adds inertance (rotor inertia) and screw friction
%
%   Machine relations (per damper, nd dampers per bogie):
%     e = Ke v,  F = Ke i,  c_max = Ke^2 / Rc  (coil short-circuited: most damping, no harvest)
%     at damping c: electrical efficiency = 1 - c / c_max
%   Linear machine copper estimate: c_max = B^2 V_cu / rho  ->  V_cu = c_max rho / B^2

nd = 2;                                    % vertical secondary dampers per bogie (one per side)
zeta_hi = 0.25;

% vehicle at full load, without friction (linear model)
Pm = P;
Pm.m_load = max(TB.loads_t) * 1e3;
Pm.m = Pm.m_tare + Pm.m_load;
Pm.I = Pm.m * TB.Lbody^2 / 12;
Pm.ks = sr_spring_rate(TB, Pm.m_load);
cg = logspace(3, 6.5, 300);
zg = arrayfun(@(c) zeta_body(Pm, c), cg);
[~, ipk] = max(zg);                        % damping beyond the peak locks the secondary suspension
[zu, iu] = unique(zg(1:ipk));
cu = cg(1:ipk);
c_at = @(zt) interp1(zu, cu(iu), zt);

D.design  = design;
D.nd      = nd;
D.zeta_hi = zeta_hi;
D.c_req   = c_at(zeta_hi);                 % per bogie [N s/m]
if TB.cs > 0
    D.c_today = TB.cs;
else
    D.c_today = c_at(0.10);                % assumed viscous equivalent of friction wedges
end
casnub = strcmp(TB.springType, 'casnub');
D.keepFriction = false;
D.c_oil = 0;  D.Fc = 0;  D.b_in = 0;  D.lead = NaN;  D.J = 0;

switch upper(design)
    case 'A'
        D.name     = 'A: direct-drive linear';
        D.cmax_emd = 1.25 * D.c_req;
        D.Rc       = 1.0;                   % coil resistance per damper [ohm] (assumed winding)
    case 'B'
        D.name = 'B: hybrid (passive + linear EM)';
        D.Rc   = 1.0;
        if casnub
            D.keepFriction = true;          % Casnub wedges stay; EM damper added in parallel
            D.cmax_emd = 0.5 * D.c_req;
        else
            D.c_oil    = 0.5 * D.c_today;   % half-size oil damper stays
            D.cmax_emd = 1.25 * D.c_req - D.c_oil;
        end
    case 'C'
        D.name     = 'C: geared rotary (ball screw)';
        D.cmax_emd = 2.5 * D.c_req;
        D.Rc       = 0.25;                  % phase resistance of a compact servo generator [ohm]
        D.lead     = 0.010;                 % ball-screw lead [m/rev]
        D.J        = 1.5e-4;                % rotor + screw inertia [kg m^2] (assumed)
        D.b_in     = D.J * (2*pi / D.lead)^2;   % inertance per damper [kg]
        D.Fc       = 150;                   % screw + seal friction per damper [N] (assumed)
    otherwise
        error('sr_damper_design:type', 'designType must be A, B or C');
end

D.Ke = sqrt(D.cmax_emd / nd * D.Rc);       % per damper [V s/m] = [N/A]
if casnub, D.F_rated = 40e3; else, D.F_rated = 15e3; end   % rated force per damper [N]
D.imax = D.F_rated / D.Ke;                 % current limit per damper [A]

% 'match' command: an electromagnetic copy of today's damper
if D.keepFriction
    D.c_match_emd = D.cmax_emd / 2;        % wedges already give today's damping; EM part harvests
else
    D.c_match_emd = min(max(D.c_today - D.c_oil, 0), D.cmax_emd);
end

% Fail-safe resistor: on power loss the relay puts this resistor across the coil, so the
% damper falls back to today's passive damping.
c_fs = D.c_today - D.c_oil;
if D.keepFriction || c_fs <= 0
    D.R_fs = 1e6;                          % open circuit
elseif c_fs >= D.cmax_emd
    D.R_fs = 0;                            % short circuit (the most the coil can give)
else
    D.R_fs = nd * D.Ke^2 / c_fs - D.Rc;
end
D.c_failsafe = D.c_oil + nd * D.Ke^2 / (D.Rc + D.R_fs);

% size indicators
rho_cu = 1.72e-8;  B_eff = 0.6;            % copper resistivity, effective air-gap flux density [T]
if strcmpi(design, 'C')
    D.cu_kg  = NaN;
    D.T_peak = D.F_rated / (2*pi / D.lead) / 0.9;   % generator peak torque [N m]
else
    D.cu_kg  = (D.cmax_emd / nd) * rho_cu / B_eff^2 * 8960;   % copper per damper [kg]
    D.T_peak = NaN;
end
end

function z = zeta_body(P, c)
% damping ratio of the lowest-frequency vibration mode (body mode)
[~, ~, ~, info] = sr_linear_model(P, c);
if isempty(info.zeta), z = 1; else, z = info.zeta(1); end
end

function H = sr_hot_axle(opt)
%SR_HOT_AXLE Hot-axle detection: self-powered on-bogie sensor vs trackside checkpoints.
%   H = sr_hot_axle(opt)   (all fields of opt optional; values are ILLUSTRATIVE assumptions)
%
%   Bearing temperature:  tau dT/dt = dT0 * q(t) - (T - Tamb),   q = 1 before the fault and
%   q(t) = exp((t - tf) / tau_g) after it (a developing bearing fault generates more and more heat).
%   On-bogie sensor (SwarmRide): reads every ts seconds, alarm when T >= T_alarm.
%   Trackside checkpoints: the train passes one every spacing_km at speed v_kmh; alarm only if
%   T >= T_alarm at the moment it passes. Monte Carlo over where the fault starts between checkpoints.
%   Failure (bearing seizure risk) when T >= T_fail.

d = struct('Tamb', 35, 'dT0', 25, 'tau_min', 20, 'tau_g_min', 30, 'T_alarm', 90, 'T_fail', 180, ...
    'ts', 10, 'spacing_km', 250, 'v_kmh', 100, 'n_mc', 2000, 'seed', 1);
if nargin < 1, opt = struct(); end
f = fieldnames(d);
for k = 1:numel(f)
    if ~isfield(opt, f{k}), opt.(f{k}) = d.(f{k}); end
end
H.opt = opt;

% temperature after the fault starts (fault at t = 0, bearing at its normal running temperature)
dt = 1;  t = (0:dt:6 * 3600)';
T = zeros(size(t));  T(1) = opt.Tamb + opt.dT0;
tau = opt.tau_min * 60;  tg = opt.tau_g_min * 60;
for k = 2:numel(t)
    q = exp(t(k - 1) / tg);
    T(k) = T(k - 1) + dt / tau * (opt.dT0 * q - (T(k - 1) - opt.Tamb));
end
i_al = find(T >= opt.T_alarm, 1);  i_f = find(T >= opt.T_fail, 1);
H.t = t;  H.T = T;
H.t_alarm = t(i_al);                      % when the bearing first reaches the alarm temperature [s]
H.t_fail  = t(i_f);                       % when it reaches the failure temperature [s]

% on-bogie sensor: worst case, the alarm is seen one reading interval after the crossing
H.self.delay_max = opt.ts;                % detection within one reading interval [s]
H.self.T_detect  = interp1(t, T, H.t_alarm + opt.ts);

% trackside: checkpoint passing times = phase + k * gap, phase uniform in [0, gap)
gap = opt.spacing_km / opt.v_kmh * 3600;
rng(opt.seed);
phase = rand(opt.n_mc, 1) * gap;
tdet = phase + ceil(max(H.t_alarm - phase, 0) / gap) * gap;   % first check at or after the alarm crossing
H.track.gap_h    = gap / 3600;
H.track.delay    = tdet - H.t_alarm;                           % [s]
H.track.T_detect = interp1(t, T, min(tdet, t(end)));
H.track.missed   = tdet > H.t_fail;                            % failure before any check sees it
H.track.p_missed = mean(H.track.missed);
end

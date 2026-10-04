%% SR_PARAMS_STAGE4  Stage 4 settings (run after sr_params and sr_params_stage3).
%
% Scenario inputs (set in the workspace before running, otherwise defaults are used):
%   ctrlMode = 'C4'    C3 + active push near known bad spots (the damper may draw bank power there)
%   bad_x              positions of known bad spots on the route [m] (default: the event on the track)
%   act_window_s       how long before and after a bad spot the push is allowed [s]
%   wheel_runout       radial run-out of the front wheelset [m] (0 = healthy; e.g. 0.5e-3)
%   wheel_order        out-of-round order (1 = eccentric, 3 = three-lobed polygon)

%% 1. Known bad spots (from the fleet track map) for C4
nb = 4;                                            % fixed list length (unused entries are NaN)
if ~exist('bad_x', 'var') || isempty(bad_x)
    switch trackType
        case 'settlement', bad_x = 300;  bad_len = 20;
        case 'bump',       bad_x = 200;  bad_len = 4;
        otherwise,         bad_x = [];   bad_len = [];
    end
elseif ~exist('bad_len', 'var') || numel(bad_len) ~= numel(bad_x)
    bad_len = 20 * ones(size(bad_x));
end
P.bad_x   = [bad_x(:); nan(nb - numel(bad_x), 1)];
P.bad_len = [bad_len(:); nan(nb - numel(bad_len), 1)];
if ~exist('act_window_s', 'var'), act_window_s = 1.0; end
P.act_before = P.v * act_window_s;                 % push allowed from this distance before the spot [m]
P.act_after  = P.v * act_window_s;                 % ... until this distance after its end [m]
clear bad_x bad_len                                % a custom list applies to one run only

%% 2. Wheel defect for the health-sensing demo
if ~exist('wheel_runout', 'var'), wheel_runout = 0;   end
if ~exist('wheel_order', 'var'),  wheel_order = 1;    end
P.wheel_runout = wheel_runout;                     % radial run-out, front wheelset [m]
P.wheel_order  = wheel_order;                      % lobes per revolution
P.wheel_R      = 0.4575;                           % wheel radius, 915 mm wheel [m]

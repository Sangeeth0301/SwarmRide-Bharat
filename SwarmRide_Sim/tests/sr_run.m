function [o, P, D] = sr_run(mdl, train, varargin)
%SR_RUN Run one scenario of a SwarmRide model and return its output and parameters.
%   [o, P, D] = sr_run('SR_Stage2', 'LHB', 'designType', 'C', 'trackType', 'good')
%   Defaults: design A, match, poor track, no fault, top speed, full load, normal step size.
%   Scenario variables are placed in the base workspace, where the model's InitFcn reads them.

TB = sr_trains(train);
v = struct('trainType', train, 'designType', 'A', 'cmdMode', 'match', 'trackType', 'poor', ...
    't_fault', Inf, 'v_kmh', max(TB.speeds), 'mload_t', max(TB.loads_t), 'Ts_override', []);
for k = 1:2:numel(varargin)
    v.(varargin{k}) = varargin{k + 1};
end
evalin('base', 'clear ctrlMode load_err preview_dt rw c_fix_override c_floor_frac bad_x bad_len act_window_s wheel_runout wheel_order');   % Stage 3 options fall back to their defaults
f = fieldnames(v);
for k = 1:numel(f)
    assignin('base', f{k}, v.(f{k}));
end
o = sim(mdl, 'EnablePacing', 'off');
P = evalin('base', 'P');
D = evalin('base', 'D');
assignin('base', 'Ts_override', []);
end

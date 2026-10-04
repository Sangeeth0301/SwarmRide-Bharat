function sr_add_log(sys, src, var, pos, ts)
%SR_ADD_LOG Save a signal to the workspace (out.<var>) as a timeseries.
%   sys : system that contains the source block (model or subsystem)
%   src : source port, e.g. 'Electromagnetic machine/2'
%   var : variable name in the simulation output
%   ts  : sample time expression (default 'P.Ts'; the bench model logs at 'BP.Tlog')
if nargin < 5, ts = 'P.Ts'; end
add_block('simulink/Sinks/To Workspace', [sys '/Log ' var], 'VariableName', var, ...
    'SaveFormat', 'Timeseries', 'SampleTime', ts, 'Position', pos);
add_line(sys, src, ['Log ' var '/1'], 'autorouting', 'on');
end

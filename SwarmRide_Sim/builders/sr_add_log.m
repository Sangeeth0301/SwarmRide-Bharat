function sr_add_log(sys, src, var, pos)
%SR_ADD_LOG Save a signal to the workspace (out.<var>) as a timeseries, sampled every P.Ts.
%   sys : system that contains the source block (model or subsystem)
%   src : source port, e.g. 'Electromagnetic machine/2'
%   var : variable name in the simulation output
add_block('simulink/Sinks/To Workspace', [sys '/Log ' var], 'VariableName', var, ...
    'SaveFormat', 'Timeseries', 'SampleTime', 'P.Ts', 'Position', pos);
add_line(sys, src, ['Log ' var '/1'], 'autorouting', 'on');
end

function sr_mlfcn(path, pos, code, params, sizes)
%SR_MLFCN Add a MATLAB Function block with its code, parameter arguments and output sizes.
%   path   : full block path
%   pos    : block position [left top right bottom]
%   code   : function code (char)
%   params : cell of argument names that are block parameters, e.g. {'P'}
%   sizes  : cell {name, size; ...} for signals whose size must be fixed, e.g. {'Fd', '[2 1]'}

if nargin < 4, params = {}; end
if nargin < 5, sizes = cell(0, 2); end
add_block('simulink/User-Defined Functions/MATLAB Function', path, 'Position', pos);
rt = sfroot;
ch = rt.find('-isa', 'Stateflow.EMChart', 'Path', path);
ch.Script = code;
for k = 1:numel(params)
    d = ch.find('-isa', 'Stateflow.Data', 'Name', params{k});
    d.Scope = 'Parameter';
    d.Tunable = true;                      % new scenarios run without regenerating code
end
for k = 1:size(sizes, 1)
    d = ch.find('-isa', 'Stateflow.Data', 'Name', sizes{k, 1});
    d.Props.Array.Size = sizes{k, 2};
end
end

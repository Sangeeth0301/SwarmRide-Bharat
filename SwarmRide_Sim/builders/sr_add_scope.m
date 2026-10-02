function sr_add_scope(mdl, name, srcs, titles, pos)
%SR_ADD_SCOPE Add a scope that opens on Run, wired to one or more signals.
%   srcs   : cell of source ports, e.g. {'Vehicle Plant (half-coach 4-DOF)/1'}
%   titles : one title (char) or one title per input (cell); several inputs get stacked axes

if ischar(srcs), srcs = {srcs}; end
if ischar(titles), titles = {titles}; end
n = numel(srcs);
blk = [mdl '/' name];
add_block('simulink/Sinks/Scope', blk, 'Position', pos);
try
    cfg = get_param(blk, 'ScopeConfiguration');
    if n > 1
        cfg.NumInputPorts = num2str(n);
        cfg.LayoutDimensions = [n 1];
    end
    cfg.OpenAtSimulationStart = true;
    cfg.TimeSpan = '10';
    for k = 1:n
        if n > 1, cfg.ActiveDisplay = k; end
        cfg.Title = titles{min(k, numel(titles))};
        cfg.ShowLegend = true;
        cfg.ShowGrid = true;
    end
catch err
    warning('Scope settings not applied for %s: %s', name, err.message);
end
for k = 1:n
    add_line(mdl, srcs{k}, sprintf('%s/%d', name, k), 'autorouting', 'on');
end
end

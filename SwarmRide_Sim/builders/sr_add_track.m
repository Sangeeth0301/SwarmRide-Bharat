function tr = sr_add_track(mdl, pos)
%SR_ADD_TRACK Add the Track Input subsystem: rail height w and wheel speed wd under the 4 wheels.
%   Each wheel sees the same rail, delayed by its distance behind the lead wheel.
%   Shared by every stage, so every damper is tested on the identical rail.

tr = [mdl '/Track Input'];
add_block('built-in/Subsystem', tr, 'Position', pos);
set_param(tr, 'Description', ['Generates the vertical rail irregularity under each of the 4 wheels. ' ...
    'Each wheel sees the same rail, delayed by its distance behind the lead wheel.']);
add_block('simulink/Sources/Clock',           [tr '/Clock'],              'Position', [30 60 50 80]);
add_block('simulink/Math Operations/Gain',    [tr '/Speed v'],            'Gain', 'P.v', 'Position', [90 55 130 85]);
add_block('simulink/Math Operations/Bias',    [tr '/Start position s0'],  'Bias', 'P.s0', 'Position', [160 55 210 85]);
add_block('simulink/Sources/Constant',        [tr '/Wheel offsets'],      'Value', '-P.dist', 'Position', [160 120 210 150]);
add_block('simulink/Math Operations/Sum',     [tr '/Wheel positions'],    'Inputs', '++', 'Position', [250 70 270 130]);
add_block('simulink/Lookup Tables/1-D Lookup Table', [tr '/Rail height w(x)'], ...
    'Table', 'TR.w', 'BreakpointsForDimension1', 'TR.x', 'ExtrapMethod', 'Clip', 'Position', [320 40 400 100]);
add_block('simulink/Lookup Tables/1-D Lookup Table', [tr '/Rail slope dw_dx'], ...
    'Table', 'TR.dwdx', 'BreakpointsForDimension1', 'TR.x', 'ExtrapMethod', 'Clip', 'Position', [320 140 400 200]);
add_block('simulink/Math Operations/Gain',    [tr '/x speed'],            'Gain', 'P.v', 'Position', [440 150 480 190]);
add_block('built-in/Outport', [tr '/w'],  'Position', [530 63 560 77]);
add_block('built-in/Outport', [tr '/wd'], 'Position', [530 163 560 177]);
add_line(tr, 'Clock/1', 'Speed v/1');
add_line(tr, 'Speed v/1', 'Start position s0/1');
add_line(tr, 'Start position s0/1', 'Wheel positions/1');
add_line(tr, 'Wheel offsets/1', 'Wheel positions/2');
add_line(tr, 'Wheel positions/1', 'Rail height w(x)/1', 'autorouting', 'on');
add_line(tr, 'Wheel positions/1', 'Rail slope dw_dx/1', 'autorouting', 'on');
add_line(tr, 'Rail height w(x)/1', 'w/1');
add_line(tr, 'Rail slope dw_dx/1', 'x speed/1');
add_line(tr, 'x speed/1', 'wd/1');
end

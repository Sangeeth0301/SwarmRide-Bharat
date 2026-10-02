function r = sr_check(name, value, limit, unit, note)
%SR_CHECK One verification result: passes when |value| <= limit.
if nargin < 5, note = ''; end
r = struct('name', name, 'value', value, 'limit', limit, 'unit', unit, ...
    'pass', abs(value) <= limit, 'note', note);
end

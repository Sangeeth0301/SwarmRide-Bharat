function d = sr_sig(o, name, t)
%SR_SIG Logged signal as [channels x samples] on the time base t.
%   Signals from MATLAB Function blocks are logged as channels x 1 x samples, while plain
%   vector signals (e.g. the bogie loads) are logged as samples x channels. Both are returned
%   as channels x samples; a signal logged only once (constant) is expanded to every sample.
n = numel(t);
d = squeeze(o.(name).Data);
if size(d, 2) ~= n && size(d, 1) == n
    d = d.';                                   % samples x channels -> channels x samples
elseif size(d, 2) ~= n
    d = repmat(d(:, end), 1, n);               % constant logged once
end
end

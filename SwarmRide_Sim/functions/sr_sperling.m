function Wz = sr_sperling(a, fs)
%SR_SPERLING Sperling ride index for vertical body acceleration (frequency-domain method).
%   a : acceleration [m/s^2]   fs : sample rate [Hz]
%   Depends on record length: use the same length for every case.
%   Check against EN 12299 / RDSO practice before external use.
a  = a(:) - mean(a);
N  = numel(a);
A  = abs(fft(a)) * 2 / N;
f  = (0:N-1)' * fs / N;
k  = f >= 0.5 & f <= 30;
f  = f(k);  acm = A(k) * 100;                 % [cm/s^2]
F  = ones(size(f));
F(f < 5.9)           = 0.325 * f(f < 5.9).^2;
F(f >= 5.9 & f < 20) = 400 ./ f(f >= 5.9 & f < 20).^2;
Wi = 0.896 * (acm.^3 .* F ./ f).^(1/10);
Wz = sum(Wi.^10)^(1/10);
end

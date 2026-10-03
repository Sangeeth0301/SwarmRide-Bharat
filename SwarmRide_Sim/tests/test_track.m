function R = test_track()
%TEST_TRACK The generated rail must follow the vertical track spectrum it was built from.
%   The power of the generated rail in each wavelength band (from its FFT) is compared with
%   the integral of the spectrum S(Omega) over the same band.

R = [];
P.v = 44.44; P.Tend = 30; P.s0 = 150; P.lb = 7.45; P.ab = 1.28;
P.Av_good = 4.032e-7; P.Av_poor = 1.08e-6; P.trackSeed = 7;
Oc = 0.8246; Or = 0.0206;
bands = [100 30; 30 10; 10 3; 3 1];                       % wavelength bands [m]
for tt = {'good', 'poor'}
    TR = sr_track(P, tt{1});
    if strcmp(tt{1}, 'good'), Av = P.Av_good; else, Av = P.Av_poor; end
    S = @(Om) Av * Oc^2 ./ ((Om.^2 + Or^2) .* (Om.^2 + Oc^2));
    dx = TR.x(2) - TR.x(1);
    w = TR.w(1:round(TR.period / dx));                     % exactly one period of the rail
    w = w - mean(w);
    N = numel(w);
    W = fft(w);
    Om = 2*pi * (0:N-1)' / (N * dx);                       % spatial frequency [rad/m]
    pw = 2 * abs(W).^2 / N^2;                              % power of each one-sided bin [m^2]
    dk = Om(2);                                            % FFT bin width [rad/m]
    for b = 1:size(bands, 1)
        lo = 2*pi / bands(b, 1);  hi = 2*pi / bands(b, 2);
        % half-bin shift: a sine lying exactly on a band edge (e.g. the 100 m wave) is counted once
        k = Om >= lo - dk/2 & Om < hi - dk/2 & (1:N)' <= N/2;
        got = sum(pw(k));
        want = integral(S, lo, hi);
        R = [R; sr_check(sprintf('Track %s, %g-%g m band power vs spectrum', tt{1}, bands(b, 1), bands(b, 2)), ...
            100 * abs(got - want) / want, 5, '%', sprintf('RMS in band %.2f vs %.2f mm', 1e3*sqrt(got), 1e3*sqrt(want)))]; %#ok<AGROW>
    end
    R = [R; sr_check(sprintf('Track %s, overall RMS (information)', tt{1}), 0, 1, 'mm', ...
        sprintf('RMS %.2f mm, peak %.1f mm', 1e3 * std(w), 1e3 * max(abs(w))))]; %#ok<AGROW>
end
end

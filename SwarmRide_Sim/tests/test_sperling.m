function R = test_sperling()
%TEST_SPERLING The Sperling ride index of a pure sine must equal the closed-form value.
%   For a sine of amplitude a [cm/s^2] at frequency f:  Wz = 0.896 (a^3 F(f) / f)^(1/10)
%   with the vertical weighting F(f) = 0.325 f^2 (f < 5.9 Hz), 400 / f^2 (5.9-20 Hz), 1 above.

fs = 1000;
t = (0:1/fs:20 - 1/fs)';
R = [];
for f = [1 4 8 12]
    a = 0.2;                                         % [m/s^2]
    Wz = sr_sperling(a * sin(2*pi*f*t), fs);
    acm = 100 * a;
    if f < 5.9, F = 0.325 * f^2; elseif f < 20, F = 400 / f^2; else, F = 1; end
    Wref = 0.896 * (acm^3 * F / f)^(1/10);
    R = [R; sr_check(sprintf('Sperling Wz, %g Hz sine vs closed form', f), ...
        100 * abs(Wz - Wref) / Wref, 0.5, '%', sprintf('Wz %.3f vs %.3f', Wz, Wref))]; %#ok<AGROW>
end
end

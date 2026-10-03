function TR = sr_track(P, trackType)
%SR_TRACK Vertical track irregularity w(x) used by the Track Input subsystem.
%   'good' / 'poor' : random track from the vertical track spectrum (sum of sines)
%   'bump'          : flat track with one 10 mm, 4 m long dip at x = 200 m
%   Returns TR.x [m], TR.w [m], TR.dwdx [-] (slope, used for wheel velocity) and
%   TR.period [m] (the random rail repeats every TR.period metres).
%
%   Random rail: one sine on every harmonic of a fixed 2000 m period with wavelength 1-100 m
%   (1981 sines), amplitude sqrt(2 S dOmega), random phase. Harmonics of one period are
%   exactly independent over that period, so the rail carries the spectrum's power in every
%   band; the fixed period gives every train and speed the identical rail.
%   Check the PSD convention against your source and compare RMS with literature.

Lper = 2000;                                              % period of the random rail [m]
L  = P.s0 + P.v * P.Tend + 2 * P.lb + 2 * P.ab + 100;     % track length needed [m]
dx = 0.05;
x  = (0:dx:max(L, Lper))';

switch trackType
    case {'good', 'poor'}
        if strcmp(trackType, 'good'), Av = P.Av_good; else, Av = P.Av_poor; end
        rng(P.trackSeed);
        Oc = 0.8246;  Or = 0.0206;                         % [rad/m]
        dOm = 2*pi / Lper;
        Om = (ceil(Lper / 100):floor(Lper / 1)) * dOm;     % wavelengths 100 m .. 1 m
        S  = Av * Oc^2 ./ ((Om.^2 + Or^2) .* (Om.^2 + Oc^2));
        A  = sqrt(2 * S * dOm);
        ph = 2 * pi * rand(size(Om));
        w  = zeros(size(x));
        for k = 1:numel(Om)
            w = w + A(k) * sin(Om(k) * x + ph(k));
        end
    case 'bump'
        w  = zeros(size(x));
        at = 200;  len = 4;  depth = 0.010;
        k  = x >= at & x <= at + len;
        w(k) = -depth * 0.5 * (1 - cos(2*pi*(x(k) - at)/len));
    otherwise
        error('sr_track:type', 'trackType must be good, poor or bump');
end

TR.x      = x;
TR.w      = w;
TR.dwdx   = gradient(w, dx);
TR.period = Lper;
end

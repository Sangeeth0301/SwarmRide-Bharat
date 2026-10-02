function [A, Bw, Bf, info] = sr_linear_model(P, c)
%SR_LINEAR_MODEL State-space form of the half-coach, built from sr_eom (same equations).
%   x = [q; qd] (8 states).   xdot = A x + Bw [w; wd] + Bf Fd
%   With c given, the passive damper Fd = c*vrel is closed into A (Bf then unused).
%   (Fd and vrel use the same sign convention, so a damper always has Fd*vrel >= 0.)
%   info: natural frequencies [Hz] and damping ratios of each mode.

if nargin < 2, c = []; end
n = 4;
f = @(x, u, Fd) [x(n+1:end); sr_eom(x(1:n), x(n+1:end), u(1:4), u(5:8), Fd, P)];

A = zeros(2*n);  Bw = zeros(2*n, 8);  Bf = zeros(2*n, 2);
for k = 1:2*n
    e = zeros(2*n, 1); e(k) = 1;
    Fd = zeros(2, 1);
    if ~isempty(c)
        [~, ~, vr] = sr_measure(e(1:n), e(n+1:end), zeros(n, 1), P);
        Fd = c * vr;
    end
    A(:, k) = f(e, zeros(8, 1), Fd);
end
for k = 1:8
    u = zeros(8, 1); u(k) = 1;
    Bw(:, k) = f(zeros(2*n, 1), u, zeros(2, 1));
end
for k = 1:2
    Fd = zeros(2, 1); Fd(k) = 1;
    Bf(:, k) = f(zeros(2*n, 1), zeros(8, 1), Fd);
end

lam = eig(A);
lam = lam(imag(lam) > 0);
info.f_hz = abs(lam) / (2*pi);
info.zeta = -real(lam) ./ abs(lam);
[info.f_hz, idx] = sort(info.f_hz);
info.zeta = info.zeta(idx);
end

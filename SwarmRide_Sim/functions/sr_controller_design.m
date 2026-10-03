function CD = sr_controller_design(TB, P)
%SR_CONTROLLER_DESIGN LPV (load-scheduled) LQR with Train Brain preview for the smart damper.
%   CD = sr_controller_design(TB, P)
%
%   At each point of a load grid (empty .. full) the half-coach is linearised WITHOUT a
%   secondary damper (the controller supplies all secondary damping) and discretised at Tc.
%   The rail ahead and behind the lead wheel is held in a shift register p = [p_-Nb .. p_Na],
%   sampled every Tc of travel; the 8 wheel inputs (height and speed under each wheel) are a
%   fixed linear map of p (u = G p). LQR on the augmented system [x; p] gives
%       F* = -Kx x - Kp p
%   Kx is the feedback (C2, LPV); Kp is the preview feed-forward (C3).
%   Cost: body acceleration over both bogies (comfort, includes pitch), secondary stroke
%   (safety) and damper force (effort):
%       J = sum( (az_f/a0)^2 + (az_r/a0)^2 + (d1/s0)^2 + (d2/s0)^2 + rw (|F|/F0)^2 )
%   Returns CD.m (load grid, total body mass [kg]), CD.Kx (nL x 16), CD.Kp (nL x 2 Np),
%   CD.rho (closed-loop spectral radius, < 1 = stable) and CD.G (wheel-input map).

K3 = sr_stage3_consts();
Tc = K3.Tc;  Np = K3.Np;
j  = (-K3.Nb:K3.Na)';                                   % sample offsets of p from the lead wheel
loads = linspace(0, max(TB.loads_t) * 1e3, K3.nL);

% wheel-input map u = [w1..w4; wd1..wd4] = G p  (linear interpolation between samples)
G = zeros(8, Np);
for i = 1:4
    ji = -P.dist(i) / (P.v * Tc);                       % wheel position in samples
    if ji - 0.5 < j(1)
        error('sr_controller_design:speed', 'Speed too low for the preview window (increase Nb).');
    end
    G(i, :)     = interp_row(ji, j);
    G(i + 4, :) = (interp_row(ji + 0.5, j) - interp_row(ji - 0.5, j)) / Tc;   % rail speed under wheel i
end
S = diag(ones(Np - 1, 1), 1);                           % p_j(k+1) = p_{j+1}(k); newest sample enters at the end

CD.m = zeros(1, K3.nL);  CD.Kx = zeros(K3.nL, 16);  CD.Kp = zeros(K3.nL, 2 * Np);  CD.rho = zeros(1, K3.nL);
for l = 1:K3.nL
    Pm = P;
    Pm.m_load = loads(l);
    Pm.m  = P.m_tare + loads(l);
    Pm.I  = Pm.m * TB.Lbody^2 / 12;
    Pm.ks = sr_spring_rate(TB, loads(l));
    [A, Bw, Bf] = sr_linear_model(Pm, []);              % springs only, no secondary damper
    sd  = c2d(ss(A, [Bf Bw], eye(8), 0), Tc, 'zoh');
    Ad  = sd.A;  Bfd = sd.B(:, 1:2);  Bud = sd.B(:, 3:10);

    Ac = A(5:8, :);  Bc = Bf(5:8, :);                   % accelerations
    Cy = [Ac(1, :) + Pm.lb * Ac(2, :);  Ac(1, :) - Pm.lb * Ac(2, :); ...
          1  Pm.lb -1 0 0 0 0 0;        1 -Pm.lb 0 -1 0 0 0 0];
    Dy = [Bc(1, :) + Pm.lb * Bc(2, :);  Bc(1, :) - Pm.lb * Bc(2, :);  0 0;  0 0];
    Qy = diag([1 / P.a0^2, 1 / P.a0^2, 1 / P.s0^2, 1 / P.s0^2]);
    Q  = Cy' * Qy * Cy;   N = Cy' * Qy * Dy;   R = Dy' * Qy * Dy + P.rw / P.F0^2 * eye(2);

    Aa = [Ad, Bud * G; zeros(Np, 8), S];
    Ba = [Bfd; zeros(Np, 2)];
    Qa = blkdiag(Q, zeros(Np));
    Na = [N; zeros(Np, 2)];
    K  = dlqr(Aa, Ba, Qa, R, Na);

    CD.m(l)     = Pm.m;
    CD.Kx(l, :) = reshape(K(:, 1:8), 1, []);
    CD.Kp(l, :) = reshape(K(:, 9:end), 1, []);
    CD.rho(l)   = max(abs(eig(Ad - Bfd * K(:, 1:8))));
end
CD.G = G;
end

function r = interp_row(ji, j)
% row vector that linearly interpolates the sample sequence at the fractional offset ji
r = zeros(1, numel(j));
k = floor(ji);  a = ji - k;
i0 = k - j(1) + 1;
r(i0) = 1 - a;
if a > 0, r(i0 + 1) = a; end
end

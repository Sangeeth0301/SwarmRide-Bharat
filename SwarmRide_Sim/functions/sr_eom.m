function acc = sr_eom(q, qd, w, wd, Fd, P) %#codegen
%SR_EOM Equations of motion of the half-coach (4 DOF, 8 states).
%   q  = [z; theta; z1; z2]   body bounce [m], body pitch [rad], front / rear bogie bounce [m]
%   qd = time derivatives of q
%   w, wd = wheel displacements / velocities (4x1): front bogie wheels 1-2, rear 3-4
%   Fd = secondary damper forces (2x1), positive when the stroke is extending
%   acc = [zdd; thetadd; z1dd; z2dd]
%   Used both by the Simulink model and by sr_linear_model, so there is one source of truth.

z = q(1); th = q(2); z1 = q(3); z2 = q(4);
z1d = qd(3); z2d = qd(4);               % body speeds enter through the damper force Fd

% Secondary suspension: air spring + damper between body and each bogie
d1 = (z + P.lb*th) - z1;                 % front stroke
d2 = (z - P.lb*th) - z2;                 % rear stroke
S1 = P.ks*d1 + Fd(1);
S2 = P.ks*d2 + Fd(2);

% Coach body: bounce and pitch
zdd  = -(S1 + S2) / P.m;
thdd = (-P.lb*S1 + P.lb*S2) / P.I;

% Primary suspension: springs + dampers between each bogie and its two wheelsets
Pr1 = P.kp*((z1 - w(1)) + (z1 - w(2))) + P.cp*((z1d - wd(1)) + (z1d - wd(2)));
Pr2 = P.kp*((z2 - w(3)) + (z2 - w(4))) + P.cp*((z2d - wd(3)) + (z2d - wd(4)));

% Bogie frames
z1dd = (S1 - Pr1) / P.mbg;
z2dd = (S2 - Pr2) / P.mbg;

acc = [zdd; thdd; z1dd; z2dd];
end

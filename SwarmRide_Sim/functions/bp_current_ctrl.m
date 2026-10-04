function [u, z_next, sat] = bp_current_ctrl(iref, i_meas, v, z, HW)
%BP_CURRENT_CTRL Current controller of the drive, one 10 kHz step (firmware: sr_current_ctrl).
%   PI on the current error plus back-EMF feed-forward, in the equivalent-DC frame of the
%   simulation (the real drive does this on the q axis of a field-oriented controller).
%   The coil obeys  L di/dt = Ke v - Rc i - u   (u: voltage the inverter applies).
%   Choosing Kp = L / tau_cl and Ki = Rc / tau_cl cancels the coil's own pole, so the current
%   follows its reference as a first-order lag of time constant tau_cl.
%   u is limited to Umax = (sqrt 3 / 2) Vdc; while limited the integrator is frozen (anti-windup).
%   z : integrator state [V].  sat : 1 when the inverter runs out of voltage.
Kp = HW.L / HW.tau_cl;
Ki = HW.Rc / HW.tau_cl;
err = iref - i_meas;
u = HW.Ke * v - (Kp * err + z);
sat = double(abs(u) > HW.Umax);
u = min(max(u, -HW.Umax), HW.Umax);
if sat > 0.5
    z_next = z;
else
    z_next = z + Ki * HW.Ti * err;
end
end

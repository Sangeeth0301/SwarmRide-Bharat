function iref = bp_current_ref(c_cmd, F_cmd, act, v, HW)
%BP_CURRENT_REF Coil current the drive must produce, for ONE damper (firmware: sr_current_ref).
%   c_cmd : damping command for this damper [N s/m]  (bogie command / dampers per bogie)
%   F_cmd : ideal force for this damper [N]           (used only inside a push window)
%   act   : 1 inside a push window at a known bad spot (Stage 4, C4), else 0
%   v     : measured stroke speed from the motor encoder [m/s]
%   Outside a window the current follows the damping law i = c v / Ke, with c kept within
%   0 .. Ke^2/Rc so no bank power is needed. Inside a window it follows F_cmd directly, so the
%   machine can motor (push). The current is always limited to the drive rating.
c = min(max(c_cmd, 0), HW.cmax);
i_damp = c * v / HW.Ke;
i_push = F_cmd / HW.Ke;
iref = (1 - act) * i_damp + act * i_push;
iref = min(max(iref, -HW.i_lim), HW.i_lim);
end

function [relay, latch_next, code] = bp_failsafe(test_fault, Vbank, Tw, i_meas, latch, HW)
%BP_FAILSAFE Fail-safe supervisor of one damper drive (firmware: sr_failsafe).
%   Drops the changeover contactor (coil onto the fail-safe resistors = today's passive damping)
%   on any of these faults, and keeps it dropped (latched) until a manual reset:
%     1 test / external fault input      2 bank voltage below the minimum (controller supply at risk)
%     3 winding over-temperature         4 over-current (20 % above the current limit)
%   In the real unit the contactor coil is powered only while the microcontroller's heartbeat,
%   the bank-OK comparator and the gate-driver enable are all present, so a crashed or unpowered
%   controller also drops it (hardware, not software).
%   relay : 1 = dropped (passive fail-safe), 0 = normal.   code : first fault found (0 = none)
code = 0;
if test_fault > 0.5
    code = 1;
elseif Vbank < HW.Vbank_min
    code = 2;
elseif Tw > HW.T_trip
    code = 3;
elseif abs(i_meas) > 1.2 * HW.i_lim
    code = 4;
end
latch_next = double(latch > 0.5 || code > 0);
relay = latch_next;
end

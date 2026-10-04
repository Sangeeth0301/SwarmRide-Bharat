/* sr_drive.c - damper drive, one 10 kHz period per damper.
 * Ports of SwarmRide_Sim/functions/bp_current_ref.m, bp_current_ctrl.m and bp_failsafe.m.
 * The equivalent-DC current here is the q-axis current of the field-oriented motor control. */
#include <math.h>
#include "swarmride.h"

static sr_real clamp(sr_real x, sr_real lo, sr_real hi)
{
    return x < lo ? lo : (x > hi ? hi : x);
}

sr_real sr_current_ref(sr_real c_cmd, sr_real F_cmd, int act, sr_real v)
{
    sr_real c = clamp(c_cmd, 0, (sr_real)SR_CMAX);
    sr_real i_damp = c * v / (sr_real)SR_KE;            /* damping law: F = c v */
    sr_real i_push = F_cmd / (sr_real)SR_KE;            /* push: F = F_cmd (motoring allowed) */
    sr_real iref = act ? i_push : i_damp;
    return clamp(iref, -(sr_real)SR_I_LIM, (sr_real)SR_I_LIM);
}

/* L di/dt = Ke v - Rc i - u.  Kp = L / tau_cl, Ki = Rc / tau_cl cancel the coil's pole, so the
 * current follows its reference as a first-order lag of tau_cl. Integrator frozen while saturated. */
sr_real sr_current_ctrl(sr_real iref, sr_real i_meas, sr_real v, sr_real *z, int *sat)
{
    const sr_real Kp = (sr_real)(SR_L / SR_TAU_CL);
    const sr_real Ki = (sr_real)(SR_RC / SR_TAU_CL);
    sr_real err = iref - i_meas;
    sr_real u = (sr_real)SR_KE * v - (Kp * err + *z);
    *sat = fabs((double)u) > SR_UMAX;
    u = clamp(u, -(sr_real)SR_UMAX, (sr_real)SR_UMAX);
    if (!*sat) *z += Ki * (sr_real)SR_TI * err;
    return u;
}

/* Fault codes: 1 test/external, 2 bank voltage low, 3 winding over-temperature, 4 over-current.
 * Hardware backs this up: the contactor coil is powered only while the heartbeat, the bank-OK
 * comparator and the gate-driver enable are all present. */
int sr_failsafe(int test_fault, sr_real vbank, sr_real t_winding, sr_real i_meas, int *latch, int *code)
{
    *code = 0;
    if (test_fault)                                         *code = 1;
    else if (vbank < (sr_real)SR_VBANK_MIN)                 *code = 2;
    else if (t_winding > (sr_real)SR_T_TRIP)                *code = 3;
    else if (fabs((double)i_meas) > 1.2 * SR_I_LIM)         *code = 4;
    *latch = (*latch || *code > 0);
    return *latch;
}

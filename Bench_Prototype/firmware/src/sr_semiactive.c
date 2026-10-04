/* sr_semiactive.c - from ideal force to a damping command the smart damper can give.
 * Port of the Simulink block "Semi-active conversion (passivity + efficiency limits)"
 * (SwarmRide_Sim/scripts/build_stage3.m) and of its command smoothing.
 * The damper resists motion only (c >= c_floor >= 0) and stays efficient (c <= c_cap). */
#include <math.h>
#include "swarmride.h"

void sr_semiactive(const sr_real F[2], const sr_real v[2], sr_real c[2])
{
    int r;
    for (r = 0; r < 2; r++) {
        sr_real cd = F[r] * v[r] / (v[r] * v[r] + (sr_real)(SR_EPS_V * SR_EPS_V)) - (sr_real)SR_C_OIL;
        if (cd < (sr_real)SR_C_FLOOR) cd = (sr_real)SR_C_FLOOR;
        if (cd > (sr_real)SR_C_CAP) cd = (sr_real)SR_C_CAP;
        c[r] = cd;
    }
}

/* Simulink smooths the command continuously (dc/dt = (c* - c) / tau_c); the drive does the
 * exact discrete equivalent every current-control period. */
sr_real sr_cmd_smooth(sr_real c, sr_real c_target)
{
    return c_target + (c - c_target) * (sr_real)exp(-(double)SR_TI / (double)SR_TAU_C);
}

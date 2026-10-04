/* sr_lpv.c - LPV (load-scheduled) state feedback + Train Brain preview, 100 Hz.
 * Port of the Simulink block "LPV state feedback + preview (100 Hz)" (SwarmRide_Sim/scripts/build_stage3.m):
 *   the gains of the two load-grid points around the measured load are blended linearly, then
 *   F* = -Kx x  (C2)   or   F* = -Kx x - Kp p  (C3). */
#define SR_PARAMS_DEFINE_TABLES
#include "swarmride.h"

void sr_lpv_force(const sr_real x[8], const sr_real *p, sr_real m_hat, int use_preview, sr_real F[2])
{
    int i = 0, k, r, c, j;
    sr_real a = 0;

    if (m_hat >= SR_KGRID_M[SR_NL - 1]) {
        i = SR_NL - 2;  a = 1;
    } else if (m_hat > SR_KGRID_M[0]) {
        for (k = 0; k < SR_NL - 1; k++) {          /* MATLAB keeps the last bracket that matches */
            if (m_hat >= SR_KGRID_M[k] && m_hat <= SR_KGRID_M[k + 1]) {
                i = k;
                a = (m_hat - SR_KGRID_M[k]) / (SR_KGRID_M[k + 1] - SR_KGRID_M[k]);
            }
        }
    }
    for (r = 0; r < 2; r++) {
        sr_real s = 0;
        for (c = 0; c < 8; c++)
            s += ((1 - a) * SR_KX[i][r + 2 * c] + a * SR_KX[i + 1][r + 2 * c]) * x[c];
        if (use_preview)
            for (j = 0; j < SR_NP; j++)
                s += ((1 - a) * SR_KP[i][r + 2 * j] + a * SR_KP[i + 1][r + 2 * j]) * p[j];
        F[r] = -s;
    }
}

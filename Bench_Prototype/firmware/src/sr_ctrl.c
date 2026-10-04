/* sr_ctrl.c - scheduler of one vehicle's SwarmRide control.
 *   100 Hz (vehicle controller): new Train Brain rail sample, LPV + preview force, damping command.
 *   10 kHz (each damper drive):  command smoothing, current reference, current control, fail-safe.
 * The state estimate x (body bounce and pitch, bogie frames, and their speeds) comes from the
 * accelerometers and the motor encoders through an observer; that observer is the next firmware
 * module and is not part of this version. */
#include "swarmride.h"

void sr_ctrl_init(sr_ctrl_t *s)
{
    int b, d;
    sr_preview_init(&s->pv);
    for (b = 0; b < 2; b++) {
        s->c_target[b] = 0;  s->F_star[b] = 0;  s->c_cmd[b] = 0;
        for (d = 0; d < SR_ND; d++) { s->z[b][d] = 0;  s->latch[b][d] = 0; }
    }
}

void sr_ctrl_step_100hz(sr_ctrl_t *s, const sr_real x[8], const sr_real v[2], sr_real m_hat,
                        sr_real rail_sample, int use_preview)
{
    sr_preview_push(&s->pv, rail_sample);
    sr_lpv_force(x, sr_preview_window(&s->pv), m_hat, use_preview, s->F_star);
    sr_semiactive(s->F_star, v, s->c_target);
}

sr_real sr_drive_step_10khz(sr_ctrl_t *s, int bogie, int damper, sr_real v, sr_real i_meas, int act,
                            int test_fault, sr_real vbank, sr_real t_winding, int *relay)
{
    int sat, code;
    sr_real iref, u;
    if (damper == 0)                               /* one smoothing per bogie command */
        s->c_cmd[bogie] = sr_cmd_smooth(s->c_cmd[bogie], s->c_target[bogie]);
    *relay = sr_failsafe(test_fault, vbank, t_winding, i_meas, &s->latch[bogie][damper], &code);
    if (*relay) {                                  /* gates off; the contactor takes over */
        s->z[bogie][damper] = 0;
        return 0;
    }
    iref = sr_current_ref(s->c_cmd[bogie] / SR_ND, s->F_star[bogie] / SR_ND, act, v);
    u = sr_current_ctrl(iref, i_meas, v, &s->z[bogie][damper], &sat);
    return u;
}

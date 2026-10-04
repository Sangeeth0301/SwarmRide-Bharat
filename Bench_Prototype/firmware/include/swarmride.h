/* swarmride.h - SwarmRide bogie firmware: controller (100 Hz) and damper drive (10 kHz).
 *
 * Every function here is a line-by-line port of the MATLAB code the simulation runs, and the
 * host test (test/host_test.c) checks each one against vectors that MATLAB computed:
 *   sr_lpv_force      SwarmRide_Sim/scripts/build_stage3.m  block "LPV state feedback + preview"
 *   sr_semiactive     SwarmRide_Sim/scripts/build_stage3.m  block "Semi-active conversion"
 *   sr_current_ref    SwarmRide_Sim/functions/bp_current_ref.m
 *   sr_current_ctrl   SwarmRide_Sim/functions/bp_current_ctrl.m
 *   sr_failsafe       SwarmRide_Sim/functions/bp_failsafe.m
 *   sr_bank_step      SwarmRide_Sim/functions/sr_bank_step.m
 * Units: SI throughout (m, s, N, A, V, W, J). Forces and damping per bogie in the controller,
 * per damper in the drive.
 */
#ifndef SWARMRIDE_H
#define SWARMRIDE_H

#include "sr_types.h"
#include "sr_params_lhb.h"

/* ---- Train Brain preview: rail samples around the train (shift register) ---- */
typedef struct {
    sr_real buf[2 * SR_NP];   /* every sample stored twice, so the window is always contiguous */
    int head;                 /* slot of the next sample */
} sr_preview_t;

void sr_preview_init(sr_preview_t *pv);
void sr_preview_push(sr_preview_t *pv, sr_real newest);       /* once per controller period */
const sr_real *sr_preview_window(const sr_preview_t *pv);       /* SR_NP samples, oldest first */

/* ---- 100 Hz controller (per vehicle, both bogies) ---- */
/* F = -Kx x - Kp p, gains blended between the two load-grid points around m_hat.
 * x: coach states [zb, theta, zf1, zf2, and their speeds]; p: preview window; F: ideal force per bogie. */
void sr_lpv_force(const sr_real x[8], const sr_real *p, sr_real m_hat, int use_preview, sr_real F[2]);
/* Damping command the damper can give: c = F v / (v^2 + eps^2) - c_oil, within [c_floor, c_cap]. */
void sr_semiactive(const sr_real F[2], const sr_real v[2], sr_real c[2]);

/* ---- 10 kHz damper drive (per damper) ---- */
/* First-order smoothing of the damping command (time constant SR_TAU_C), one drive period. */
sr_real sr_cmd_smooth(sr_real c, sr_real c_target);
/* Coil current reference: damping law, or the push force inside a window (act = 1). */
sr_real sr_current_ref(sr_real c_cmd, sr_real F_cmd, int act, sr_real v);
/* PI current control with back-EMF feed-forward and voltage limit; returns the inverter voltage.
 * z: integrator state (kept by the caller); sat: set to 1 while out of voltage. */
sr_real sr_current_ctrl(sr_real iref, sr_real i_meas, sr_real v, sr_real *z, int *sat);
/* Fail-safe supervisor; returns 1 = drop the contactor (latched in *latch). code: first fault. */
int sr_failsafe(int test_fault, sr_real vbank, sr_real t_winding, sr_real i_meas, int *latch, int *code);

/* ---- power bank supervisor (per bogie) ---- */
typedef struct { sr_real Psc, Pch, Pdis, Pdump, Punserved, Pbloss; } sr_bank_flows_t;
void sr_bank_step(sr_real *Esc, sr_real *SOC, sr_real Pdc, sr_real Pload, sr_real dt, sr_bank_flows_t *f);

/* ---- one bogie: scheduler state ---- */
typedef struct {
    sr_preview_t pv;
    sr_real c_target[2];      /* damping per bogie from the 100 Hz controller [N s/m] */
    sr_real F_star[2];        /* ideal force per bogie [N] */
    sr_real c_cmd[2];         /* smoothed damping per bogie [N s/m] */
    sr_real z[2][SR_ND];      /* current-loop integrators, per damper */
    int latch[2][SR_ND];      /* fail-safe latches, per damper */
} sr_ctrl_t;

void sr_ctrl_init(sr_ctrl_t *s);
void sr_ctrl_step_100hz(sr_ctrl_t *s, const sr_real x[8], const sr_real v[2], sr_real m_hat,
                        sr_real rail_sample, int use_preview);
/* One damper, one 10 kHz period. Returns the inverter voltage; *relay = 1 drops its contactor. */
sr_real sr_drive_step_10khz(sr_ctrl_t *s, int bogie, int damper, sr_real v, sr_real i_meas, int act,
                            int test_fault, sr_real vbank, sr_real t_winding, int *relay);

#endif

/* sr_preview.c - Train Brain preview: the rail around the train as a shift register.
 * MATLAB: p_j(k+1) = p_{j+1}(k), the newest sample (SR_NA ahead of the lead wheel) enters at the end
 * (sr_controller_design.m). Each sample is stored twice so the window is one contiguous array. */
#include "swarmride.h"

void sr_preview_init(sr_preview_t *pv)
{
    int k;
    for (k = 0; k < 2 * SR_NP; k++) pv->buf[k] = 0;
    pv->head = 0;
}

void sr_preview_push(sr_preview_t *pv, sr_real newest)
{
    pv->buf[pv->head] = newest;
    pv->buf[pv->head + SR_NP] = newest;
    pv->head = (pv->head + 1) % SR_NP;
}

const sr_real *sr_preview_window(const sr_preview_t *pv)
{
    return &pv->buf[pv->head];          /* oldest sample first, newest last */
}

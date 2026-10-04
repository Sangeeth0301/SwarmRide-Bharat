/* sr_bank.c - power bank supervisor of one bogie (supercapacitor + LiFePO4 battery).
 * Port of SwarmRide_Sim/functions/sr_bank_step.m (= the Simulink "Energy supervisor"):
 *   1. harvested power and loads meet on the supercapacitor
 *   2. supercap above Vchg: charge the battery;  below Vdis: the battery supports the loads
 *   3. supercap full and battery full: dump the surplus;  both empty: loads are not served */
#include <math.h>
#include "swarmride.h"

static sr_real minr(sr_real a, sr_real b) { return a < b ? a : b; }
static sr_real maxr(sr_real a, sr_real b) { return a > b ? a : b; }

void sr_bank_step(sr_real *Esc, sr_real *SOC, sr_real Pdc, sr_real Pload, sr_real dt, sr_bank_flows_t *f)
{
    sr_real V = (sr_real)sqrt((double)maxr(2 * *Esc / (sr_real)SR_CSC, 0));
    sr_real Pch = 0, Pdis = 0, p, Pdump = 0, Pun = 0;

    if (V > (sr_real)SR_VCHG && *SOC < (sr_real)SR_SOCMAX)
        Pch = minr((sr_real)SR_PCH_MAX, (sr_real)SR_KV * (V - (sr_real)SR_VCHG));
    else if (V < (sr_real)SR_VDIS && *SOC > (sr_real)SR_SOCMIN)
        Pdis = minr((sr_real)SR_PDIS_MAX, (sr_real)SR_KV * ((sr_real)SR_VDIS - V));
    p = Pdc - Pload - Pch + Pdis;
    if (V >= (sr_real)SR_VMAX && p > 0) { Pdump = p; p = 0; }
    if (V <= (sr_real)SR_VMIN && p < 0) { Pun = -p;  p = 0; }
    *Esc = minr(maxr(*Esc + p * dt, 0), (sr_real)(0.5 * SR_CSC * SR_VMAX * SR_VMAX));
    *SOC = minr(maxr(*SOC + ((sr_real)SR_ETA_CH * Pch - Pdis / (sr_real)SR_ETA_DIS) * dt
                        / (sr_real)(SR_EBAT_WH * 3600.0), 0), 1);
    f->Psc = p;  f->Pch = Pch;  f->Pdis = Pdis;  f->Pdump = Pdump;  f->Punserved = Pun;
    f->Pbloss = (1 - (sr_real)SR_ETA_CH) * Pch + (1 / (sr_real)SR_ETA_DIS - 1) * Pdis;
}

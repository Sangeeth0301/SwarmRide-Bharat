/* host_test.c - checks every firmware function against the numbers MATLAB computed.
 * Vectors: test/vectors/*.csv, written by SwarmRide_Sim/scripts/bench_export.m.
 * Build and run (from the firmware folder):  make test
 * The double build must match MATLAB to rounding; the float build (-DSR_USE_FLOAT, as on a
 * Cortex-M4F) must match within the tolerances below, which are far below sensor accuracy. */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "swarmride.h"

#ifdef SR_USE_FLOAT
#define BUILD "float"
static const double REL = 2e-4;
#else
#define BUILD "double"
static const double REL = 1e-9;
#endif

static int n_pass = 0, n_fail = 0;

static void check(const char *name, int ok, const char *detail)
{
    if (ok) n_pass++;
    else n_fail++;
    printf("%s  %-62s %s\n", ok ? "PASS" : "FAIL", name, detail);
}

/* reads a numeric CSV (no header) into a malloc'd row-major array */
static double *read_csv(const char *path, int *rows, int *cols)
{
    static char line[1 << 17];
    static double tmp[4096];
    FILE *fh = fopen(path, "r");
    int r = 0, ncol = -1, cap = 0;
    double *M = NULL;
    if (!fh) { printf("cannot open %s
", path); return NULL; }
    while (fgets(line, (int)sizeof line, fh)) {
        int c = 0;
        char *tok = strtok(line, ",
");
        while (tok && c < 4096) { tmp[c++] = strtod(tok, NULL); tok = strtok(NULL, ",
"); }
        if (c == 0) continue;
        if (ncol < 0) ncol = c;
        if (c != ncol) { fclose(fh); free(M); return NULL; }
        if ((r + 1) * ncol > cap) {
            cap = cap ? 2 * cap : 64 * ncol;
            M = (double *)realloc(M, sizeof(double) * (size_t)cap);
        }
        memcpy(M + (size_t)r * ncol, tmp, sizeof(double) * (size_t)ncol);
        r++;
    }
    fclose(fh);
    *rows = r;  *cols = ncol;
    return M;
}

static int close_to(double got, double want, double abs_tol)
{
    return fabs(got - want) <= abs_tol + REL * fabs(want);
}

static void path_join(char *out, const char *dir, const char *file)
{
    sprintf(out, "%s/%s", dir, file);
}

static void test_lpv(const char *dir)
{
    char p[512], msg[160];
    int rows, cols, n, k, bad = 0;
    double worst = 0;
    double *M;
    path_join(p, dir, "lpv.csv");
    M = read_csv(p, &rows, &cols);
    if (!M || cols != 1 + 8 + SR_NP + 2) { check("LPV vectors readable", 0, p); return; }
    for (n = 0; n < rows; n++) {
        const double *row = M + n * cols;
        sr_real x[8], pv[SR_NP], F[2];
        for (k = 0; k < 8; k++) x[k] = (sr_real)row[1 + k];
        for (k = 0; k < SR_NP; k++) pv[k] = (sr_real)row[9 + k];
        sr_lpv_force(x, pv, (sr_real)row[0], 1, F);
        for (k = 0; k < 2; k++) {
            double want = row[9 + SR_NP + k], err = fabs(F[k] - want);
#ifdef SR_USE_FLOAT
            double tol = 1.0;          /* N: 442 float products of a few kN each */
#else
            double tol = 1e-6;
#endif
            if (err > worst) worst = err;
            if (!close_to(F[k], want, tol)) bad++;
        }
    }
    sprintf(msg, "%d cases, worst %.3g N", rows, worst);
    check("LPV + preview force matches MATLAB (loads across and beyond the grid)", bad == 0, msg);
    free(M);
}

static void test_semiactive(const char *dir)
{
    char p[512], msg[160];
    int rows, cols, n, k, bad = 0;
    double *M;
    path_join(p, dir, "semiactive.csv");
    M = read_csv(p, &rows, &cols);
    if (!M || cols != 6) { check("semi-active vectors readable", 0, p); return; }
    for (n = 0; n < rows; n++) {
        const double *row = M + n * cols;
        sr_real F[2] = {(sr_real)row[0], (sr_real)row[1]}, v[2] = {(sr_real)row[2], (sr_real)row[3]}, c[2];
        sr_semiactive(F, v, c);
        for (k = 0; k < 2; k++) if (!close_to(c[k], row[4 + k], 1e-3)) bad++;
    }
    sprintf(msg, "%d cases", rows);
    check("semi-active damping command matches MATLAB (resist only, cap, floor)", bad == 0, msg);
    free(M);
}

static void test_drive(const char *dir)
{
    char p[512], msg[160];
    int rows, cols, n, bad_ref = 0, bad_u = 0, bad_flags = 0;
    double *M;
    path_join(p, dir, "drive.csv");
    M = read_csv(p, &rows, &cols);
    if (!M || cols != 17) { check("drive vectors readable", 0, p); return; }
    for (n = 0; n < rows; n++) {
        const double *r = M + n * cols;
        sr_real z = (sr_real)r[5];
        int sat, latch = (int)r[9], code, relay;
        sr_real iref = sr_current_ref((sr_real)r[0], (sr_real)r[1], (int)r[2], (sr_real)r[3]);
        sr_real u = sr_current_ctrl(iref, (sr_real)r[4], (sr_real)r[3], &z, &sat);
        relay = sr_failsafe((int)r[6], (sr_real)r[7], (sr_real)r[8], (sr_real)r[4], &latch, &code);
        if (!close_to(iref, r[10], 1e-4)) bad_ref++;
        if (!close_to(u, r[11], 1e-3) || !close_to(z, r[12], 1e-3) || sat != (int)r[13]) bad_u++;
        if (relay != (int)r[14] || latch != (int)r[15] || code != (int)r[16]) bad_flags++;
    }
    sprintf(msg, "%d cases", rows);
    check("current reference matches MATLAB (damping law, push, limits)", bad_ref == 0, msg);
    check("current controller matches MATLAB (PI, feed-forward, voltage limit)", bad_u == 0, msg);
    check("fail-safe supervisor matches MATLAB (faults, latch, codes)", bad_flags == 0, msg);
    free(M);
}

static void test_bank(const char *dir)
{
    char p[512], msg[160];
    int rows, cols, n, bad = 0;
    double *M;
    path_join(p, dir, "bank.csv");
    M = read_csv(p, &rows, &cols);
    if (!M || cols != 13) { check("bank vectors readable", 0, p); return; }
    for (n = 0; n < rows; n++) {
        const double *r = M + n * cols;
        sr_real Esc = (sr_real)r[0], SOC = (sr_real)r[1];
        sr_bank_flows_t f;
        sr_bank_step(&Esc, &SOC, (sr_real)r[2], (sr_real)r[3], (sr_real)r[4], &f);
        if (!close_to(Esc, r[5], 1e-3) || !close_to(SOC, r[6], 1e-7) || !close_to(f.Psc, r[7], 1e-3) ||
            !close_to(f.Pch, r[8], 1e-3) || !close_to(f.Pdis, r[9], 1e-3) || !close_to(f.Pdump, r[10], 1e-3) ||
            !close_to(f.Punserved, r[11], 1e-3) || !close_to(f.Pbloss, r[12], 1e-3)) bad++;
    }
    sprintf(msg, "%d cases", rows);
    check("power bank supervisor matches MATLAB (charge, support, dump, unserved)", bad == 0, msg);
    free(M);
}

static void test_preview(void)
{
    static sr_preview_t pv;
    const sr_real *w;
    int k, ok = 1;
    sr_preview_init(&pv);
    for (k = 1; k <= SR_NP + 5; k++) sr_preview_push(&pv, (sr_real)k);
    w = sr_preview_window(&pv);
    for (k = 0; k < SR_NP; k++) if (w[k] != (sr_real)(k + 6)) ok = 0;
    check("preview window: oldest first, newest last, after wrap-around", ok, "");
}

static void test_smooth(void)
{
    sr_real c = 0;
    int k, n = 50;
    char msg[160];
    double want = 1000.0 * (1 - exp(-n * SR_TI / SR_TAU_C));
    for (k = 0; k < n; k++) c = sr_cmd_smooth(c, 1000);
    sprintf(msg, "%.4f vs %.4f", (double)c, want);
    check("command smoothing = exact first-order lag (tau_c)", fabs(c - want) < 1e-3, msg);
}

static void test_scheduler(void)
{
    static sr_ctrl_t s;
    sr_real x[8] = {0}, v[2] = {0.05, -0.05};
    int relay, k, ok_quiet = 1, ok_latch;
    sr_real u = 0;
    sr_ctrl_init(&s);
    for (k = 0; k < 10; k++) sr_ctrl_step_100hz(&s, x, v, (sr_real)50000, 0, 1);
    for (k = 0; k < 100; k++) {
        u = sr_drive_step_10khz(&s, 0, 0, (sr_real)0.05, 0, 0, 0, 30, 60, &relay);
        if (relay || u != u) ok_quiet = 0;
    }
    check("scheduler: still coach and rail give no damping and no fault", ok_quiet && s.c_target[0] == (sr_real)SR_C_FLOOR, "");
    sr_drive_step_10khz(&s, 0, 1, (sr_real)0.05, 0, 0, 1, 30, 60, &relay);        /* test fault */
    ok_latch = relay;
    sr_drive_step_10khz(&s, 0, 1, (sr_real)0.05, 0, 0, 0, 30, 60, &relay);        /* fault gone */
    ok_latch = ok_latch && relay && s.latch[0][0] == 0;
    check("scheduler: a fault drops only that damper's contactor, and it stays dropped", ok_latch, "");
}

int main(int argc, char **argv)
{
    const char *dir = argc > 1 ? argv[1] : "test/vectors";
    printf("SwarmRide firmware host test (%s build), vectors in %s\n\n", BUILD, dir);
    test_lpv(dir);
    test_semiactive(dir);
    test_drive(dir);
    test_bank(dir);
    test_preview();
    test_smooth();
    test_scheduler();
    printf("\n%d of %d checks passed.\n", n_pass, n_pass + n_fail);
    return n_fail ? 1 : 0;
}

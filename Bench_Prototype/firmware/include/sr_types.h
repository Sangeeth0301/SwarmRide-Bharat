/* sr_types.h - number type of the SwarmRide firmware.
 * Default: double (host tests against MATLAB). Build with -DSR_USE_FLOAT for a microcontroller
 * with a single-precision FPU (e.g. Cortex-M4F); the host test then checks float accuracy. */
#ifndef SR_TYPES_H
#define SR_TYPES_H

#ifdef SR_USE_FLOAT
typedef float sr_real;
#else
typedef double sr_real;
#endif

#endif

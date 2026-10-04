function HW = bp_hardware(D, P, U)
%BP_HARDWARE Turns the simulated design-C smart damper into bench-prototype hardware ratings.
%   HW = bp_hardware(D, P, U)
%   D : damper design (sr_damper_design, design C), P : vehicle parameters (sr_params)
%   U : duty of ONE damper measured in the vehicle simulation (fields v_max, v_rms, F_max, F_rms,
%       i_max, i_rms, P_push, stroke_max), from check_bench section A
%
%   The simulation models the rotary machine as an equivalent DC machine (e = Ke v, F = Ke i,
%   copper loss Rc i^2). A real machine is a 3-phase permanent-magnet servo motor driven by a
%   3-phase inverter with field-oriented control. With amplitude-invariant dq quantities:
%     torque T = Kt iq,      Kt = Ke lead / (2 pi)          [N m / A]
%     copper loss = 1.5 Rph iq^2 = Rc iq^2   ->  Rph = Rc / 1.5
%     line-to-line back-EMF (peak) = 2/sqrt(3) Kt w,   inverter limit (SVPWM): <= Vdc
%     so the equivalent DC voltage the inverter can apply is Umax = (sqrt(3)/2) Vdc.
%   Everything per damper (two dampers per bogie).

HW.lead    = D.lead;                            % ball-screw lead [m/rev]
HW.eta_bs  = 0.90;                              % ball-screw efficiency (typical, ground screw)
HW.Ke      = D.Ke;                              % linear machine constant [V s/m = N/A]
HW.Rc      = D.Rc;                              % equivalent DC resistance [ohm]
HW.cmax    = D.Ke^2 / D.Rc;                     % most EM damping per damper (coil shorted) [N s/m]
HW.c_req   = D.c_req / D.nd;                    % design damping per damper (zeta 0.25) [N s/m]
HW.c_today = D.c_today / D.nd;                  % today's damping per damper [N s/m]

%% motor
HW.Kt       = D.Ke * D.lead / (2*pi);           % [N m / A] (per amp of q-axis current amplitude)
HW.Kt_rms   = HW.Kt * sqrt(2);                  % [N m / A rms] (datasheet convention)
HW.Ke_ll    = HW.Kt_rms / sqrt(3) * 2*pi*1000/60;   % line-to-line back-EMF [V rms per 1000 rpm]
HW.Rph      = D.Rc / 1.5;                       % phase resistance [ohm]
HW.Rll      = 2 * HW.Rph;                       % line-to-line resistance (what an ohm-meter reads) [ohm]
HW.Lph      = 0.4e-3;                           % phase inductance [H] (typical 48 V servo; assumed)
HW.L        = 1.5 * HW.Lph;                     % equivalent DC inductance [H]
HW.Km       = HW.Kt / sqrt(D.Rc);               % motor constant [N m / sqrt(W)]
HW.J_sim    = D.J;                              % rotor + screw inertia assumed in the simulation
HW.v_design = 0.30;                             % fastest stroke speed the drive must control [m/s]
HW.n_max    = HW.v_design / D.lead * 60;        % [rpm]
HW.F_peak   = ceil(1.3 * U.F_max / 1e3) * 1e3;  % peak force rating, 30 % above the simulated peak [N]
HW.F_cont   = ceil(2 * U.F_rms / 100) * 100;    % continuous force rating, 2 x the rough-track RMS [N]
HW.T_peak   = HW.F_peak * D.lead / (2*pi * HW.eta_bs);   % motor peak torque [N m]
HW.T_cont   = HW.F_cont * D.lead / (2*pi * HW.eta_bs);   % motor continuous torque [N m]
HW.i_lim    = HW.F_peak / D.Ke;                 % current limit (q-axis amplitude) [A]
HW.P_rated  = HW.T_cont * HW.n_max * 2*pi/60;   % continuous shaft power at the top speed [W]

%% ball screw
HW.screw_d   = 0.025;                           % screw diameter [m] (25 mm, 10 mm lead)
HW.stroke    = 0.080;                           % mechanical stroke, +-40 mm (bump stops) [m]
HW.screw_L   = 0.30;                            % screw length [m]
HW.J_screw   = 7850 * pi * HW.screw_L * HW.screw_d^4 / 32;   % steel screw inertia [kg m^2]
HW.J_rotor_max = D.J - HW.J_screw;              % rotor inertia that keeps the simulated total [kg m^2]
HW.Fc        = D.Fc;                            % screw + seal friction assumed in the simulation [N]

%% inverter, DC link, fail-safe
HW.Vdc     = 60;                                % DC link, held by the bidirectional DC-DC [V]
HW.Umax    = sqrt(3)/2 * HW.Vdc;                % largest equivalent voltage the inverter can apply [V]
HW.v_ctrl  = HW.Umax / D.Ke;                    % stroke speed above which braking current is no longer controlled [m/s]
HW.V_fet   = 100;                               % MOSFET voltage rating [V]
HW.i_ph_pk = HW.i_lim;                          % phase current amplitude at peak force [A]
HW.i_ph_cont = U.i_rms / sqrt(2);               % phase current RMS on rough track (sine phases of amplitude iq) [A]
HW.Ron     = 1.5 * 4e-3;                        % inverter conduction resistance, equivalent DC (4 mOhm FETs) [ohm]
HW.ksw     = 0.18;                              % inverter switching loss per amp (60 V, 20 kHz, 100 ns) [W/A]
HW.f_pwm   = 20e3;                              % PWM frequency [Hz]
HW.Ti      = 1e-4;                              % current-control period (10 kHz) [s]
HW.tau_cl  = 0.5e-3;                            % designed current-loop time constant [s]
HW.R_fs    = D.R_fs;                            % fail-safe resistance, equivalent DC [ohm]
HW.R_fs_ph = D.R_fs / 1.5;                      % one resistor per phase, star connected [ohm]
HW.t_contactor = 0.020;                         % changeover contactor drop-out time [s]
HW.fs_v_peak = 0.30;                            % stroke speed for the resistor's pulse rating [m/s]
HW.P_fs_pulse = HW.c_today * HW.fs_v_peak^2 * D.R_fs / (D.Rc + D.R_fs) / 3;  % per resistor, short pulse [W]

%% power bank (per bogie, the bench uses one)
HW.eta_dcdc = 0.94;
HW.P_dcdc   = ceil(2 * U.P_push / 100) * 100;   % DC-DC rating: both dampers of a bogie pushing [W]
HW.Csc      = P.Csc;                            % supercapacitor [F]
HW.sc_cells = ceil(P.Vmax / 2.7);               % 2.7 V cells in series
HW.sc_cellF = HW.Csc * HW.sc_cells;             % capacitance of each cell [F]
HW.bat_S    = 8;                                % LiFePO4 cells in series (25.6 V nominal)
HW.bat_Ah   = ceil(P.Ebat_Wh / (HW.bat_S * 3.2));   % [Ah]

%% winding temperature (first-order; assumed for a 1-1.5 kW frame without a fan)
HW.Rth  = 0.8;                                  % winding to ambient [K/W]
HW.Cth  = 1500;                                 % thermal capacity [J/K]
HW.Tamb = 35;                                   % Indian summer ambient [C]
HW.T_trip = 120;                                % over-temperature trip (class F insulation 155 C) [C]
end

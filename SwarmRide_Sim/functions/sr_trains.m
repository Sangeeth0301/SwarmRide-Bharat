function T = sr_trains(trainType)
%SR_TRAINS Today's Indian rolling stock: base suspension parameters per vehicle type.
%   T = sr_trains('LHB' | 'VB' | 'ICF' | 'BOXN' | 'GENERIC')
%   Every value carries a source note. "assumed" = engineering estimate to be replaced
%   with RDSO / manufacturer data before results are shown outside the team.
%
%   Sources:
%   [IRIMEE-B]  IRIMEE, "Introduction to Trainset bogie" (FIAT / Train-18 / EMU bogie comparison table)
%   [IRIMEE-T]  IRIMEE, "Introduction of Train 18" (160 km/h, max design axle load 17 t)
%   [LHB-RG]    "Dynamic Response of LHB Rail Coach Considering Suspended Equipments" (ResearchGate):
%               coach tare 41,600 kg, gross 46,720 kg
%   [CASNUB-RG] "Parametric Study of Suspension Elements for Ride Index Analysis of an Indian
%               Railway Freight Vehicle" (ResearchGate): Casnub spring rates, wedge damping 0.1,
%               body tare 12,000 kg, loaded wagon 79,254 kg

T = struct('name', '', 'springType', 'air', 'm_tare', 0, 'loads_t', [0 0 0], ...
    'lb', 0, 'ab', 0, 'mbg', 0, 'ks0', 0, 'ks_loaded', NaN, 'cs', 0, 'mu_fric', 0, ...
    'kp', 0, 'cp', 0, 'Lbody', 0, 'speeds', [], 'Ts', 1e-3, 'notes', '');

switch upper(trainType)
    case 'LHB'   % LHB coach, FIAT bogie, air springs (AC variants)
        T.name       = 'LHB coach (FIAT bogie)';
        T.springType = 'air';
        T.m_tare     = 41.6e3 - 2*6.635e3;   % body tare = coach tare [LHB-RG] - 2 bogies [IRIMEE-B]
        T.loads_t    = [0 5.1 12];           % 5.1 t = gross-tare [LHB-RG]; 12 t crowded (assumed)
        T.lb         = 14.9/2;               % bogie centres 14.9 m (assumed, same as Train 18)
        T.ab         = 2.560/2;              % wheelbase 2560 mm [IRIMEE-B]
        T.mbg        = 6.635e3 - 3.10e3;     % bogie 6.635 t minus unsprung 3.10 t [IRIMEE-B]
        T.ks0        = 0.60e6;               % per bogie, ~1 Hz body bounce (assumed)
        T.cs         = 35e3;                 % 2 vertical dampers per bogie (assumed)
        T.kp         = 1.3e6;  T.cp = 20e3;  % per wheelset (assumed)
        T.Lbody      = 23.5;                 % car body length (assumed)
        T.speeds     = [110 130 160];        % FIAT bogie 160 km/h [IRIMEE-B]
    case 'VB'    % Vande Bharat trailer coach, Train-18 bogie, air springs
        T.name       = 'Vande Bharat trailer coach';
        T.springType = 'air';
        T.m_tare     = 46e3;                 % assumed: 4 x 17 t axle load [IRIMEE-T] - 2 x 7.21 t bogies [IRIMEE-B] = 53.6 t max body
        T.loads_t    = [0 3.8 7.6];          % 7.6 t = max design - tare (derived)
        T.lb         = 14.9/2;               % centre pivots 14,900 mm (IRIMEE)
        T.ab         = 2.700/2;              % wheelbase 2700 mm [IRIMEE-B]
        T.mbg        = 7.21e3 - 3.765e3;     % TC bogie 7.21 t minus unsprung 3.765 t [IRIMEE-B]
        T.ks0        = 0.90e6;               % per bogie, ~1 Hz (assumed)
        T.cs         = 50e3;                 % (assumed)
        T.kp         = 1.3e6;  T.cp = 20e3;  % (assumed)
        T.Lbody      = 24.0;                 % 24 m car body [IRIMEE-T]
        T.speeds     = [130 160];            % 160 km/h service [IRIMEE-T]
    case 'ICF'   % ICF general / sleeper coach, coil-spring (bolster) secondary
        T.name       = 'ICF coach (coil springs)';
        T.springType = 'coil';               % stiffness does NOT rise with load
        T.m_tare     = 33e3;                 % (assumed)
        T.loads_t    = [0 7.5 15];           % crowded general coach (assumed)
        T.lb         = 14.783/2;             % (assumed, typical ICF bogie centres)
        T.ab         = 2.896/2;              % 2896 mm, ICF / EMU bogie wheelbase [IRIMEE-B]
        T.mbg        = 3.0e3;                % (assumed)
        T.ks0        = 1.1e6;                % bolster springs per bogie, constant (assumed)
        T.cs         = 30e3;                 % (assumed)
        T.kp         = 1.3e6;  T.cp = 15e3;  % axle-box springs + dashpots (assumed)
        T.Lbody      = 21.3;                 % (assumed)
        T.speeds     = [80 110];             % ICF bogie 110 km/h [IRIMEE-B]
    case 'BOXN'  % BOXN open wagon, Casnub bogie: spring nest + friction wedges, no oil damper
        T.name       = 'BOXN wagon (Casnub bogie)';
        T.springType = 'casnub';             % two-stage nest: inner springs engage when loaded
        T.m_tare     = 12e3;                 % body tare [CASNUB-RG]
        T.loads_t    = [0 33.6 67.25];       % loaded wagon 79.25 t [CASNUB-RG]
        T.lb         = 6.5/2;                % bogie centres ~6.5 m (assumed)
        T.ab         = 2.0/2;                % Casnub wheelbase ~2.0 m (assumed)
        T.mbg        = 1.2e3;                % two side frames (assumed)
        T.ks0        = (12*269 + 4*196) * 1e3;           % outer + snubber springs [CASNUB-RG], per bogie (assumed grouping)
        T.ks_loaded  = (12*269 + 8*340 + 4*196) * 1e3;   % + inner springs when loaded [CASNUB-RG]
        T.cs         = 0;                    % no viscous damper
        T.mu_fric    = 0.1;                  % wedge friction force / vertical load [CASNUB-RG]
        T.kp         = 2 * 49e6;  T.cp = 50e3;  % elastomeric pads 49,000 N/mm [CASNUB-RG]; damping assumed
        T.Lbody      = 10.0;                 % (assumed)
        T.speeds     = [75 100];             % (assumed typical)
        T.Ts         = 0.5e-3;               % stiffer system, smaller time step
    case 'GENERIC'
        T.name = 'Generic coach (Stage 1)';  T.springType = 'air';
        T.m_tare = 40e3; T.loads_t = [0 7.5 15]; T.lb = 7.5; T.ab = 1.28; T.mbg = 3.0e3;
        T.ks0 = 0.8e6; T.cs = 40e3; T.kp = 1.2e6; T.cp = 15e3; T.Lbody = 24; T.speeds = [130 160];
    otherwise
        error('sr_trains:type', 'Unknown trainType "%s". Use LHB, VB, ICF, BOXN or GENERIC.', trainType);
end
end

function J = sr_journey(route, ptab, P, dt, opt)
%SR_JOURNEY Energy of one bogie's power bank over a whole journey (hours), step dt (default 1 s).
%   route : struct array of legs with fields
%             km     leg length [km]
%             v      speed [km/h]
%             track  'good' | 'poor'
%             stop   standstill after the leg [min]
%             load   (optional) label, e.g. 'loaded' / 'empty', to pick the power table
%   ptab  : power into the bank [W] measured in Simulink (Stage 3, controller C3), as a struct
%             ptab.v      speeds [km/h]
%             ptab.<load>.good, ptab.<load>.poor   power at those speeds [W]
%             ptab.load   default load label
%   P     : parameters (bank, loads) from sr_params
%   opt   : (optional) standby rule for the bogie electronics
%             opt.Pstandby        load when parked [W] (default: the full load, i.e. no standby)
%             opt.standby_after   minutes stationary before standby (default 5)
%   J     : time [h], Vsc [V], SOC [-], Pdc [W], load [W], energies [Wh]
%
%   Power at other speeds is interpolated linearly (zero at standstill).

if nargin < 4 || isempty(dt), dt = 1; end
Pfull = P.P_sens + P.P_mcu + P.P_radio + P.P_aux;
if nargin < 5, opt = struct(); end
if ~isfield(opt, 'Pstandby'), opt.Pstandby = Pfull; end
if ~isfield(opt, 'standby_after'), opt.standby_after = 5; end

% power-vs-time profile; stops are flagged so the standby rule can apply
seg = [];
for k = 1:numel(route)
    r = route(k);
    lab = ptab.load;
    if isfield(r, 'load') && ~isempty(r.load), lab = r.load; end
    pv = ptab.(lab).(r.track);
    pw = interp1([0 ptab.v], [0 pv], r.v, 'linear', 'extrap');
    seg = [seg; r.km / r.v * 3600, max(pw, 0), 0]; %#ok<AGROW>
    if r.stop > 0, seg = [seg; r.stop * 60, 0, 1]; end %#ok<AGROW>
end
n = round(sum(seg(:, 1)) / dt);
Pdc = zeros(n, 1);  Pl = Pfull * ones(n, 1);  i0 = 1;
for k = 1:size(seg, 1)
    m = round(seg(k, 1) / dt);
    idx = i0:min(i0 + m - 1, n);
    Pdc(idx) = seg(k, 2);
    if seg(k, 3) == 1                               % parked: standby after the delay
        idx_sb = idx((idx - i0) * dt >= opt.standby_after * 60);
        Pl(idx_sb) = opt.Pstandby;
    end
    i0 = i0 + m;
end
% integrate the bank
Esc = P.Esc0;  SOC = P.SOC0;
J.t = (0:n - 1)' * dt / 3600;
J.Vsc = zeros(n, 1);  J.SOC = zeros(n, 1);  J.Pdc = Pdc;  J.Pload = Pl;
Eun = 0;  Edump = 0;
for k = 1:n
    [Esc, SOC, fl] = sr_bank_step(Esc, SOC, Pdc(k), Pl(k), P, dt);
    J.Vsc(k) = sqrt(2 * Esc / P.Csc);  J.SOC(k) = SOC;
    Eun = Eun + fl.Punserved * dt;  Edump = Edump + fl.Pdump * dt;
end
J.E_harvest  = sum(Pdc) * dt / 3600;           % [Wh]
J.E_used     = sum(Pl) * dt / 3600;            % [Wh] (demanded)
J.E_unserved = Eun / 3600;                     % [Wh]
J.E_dumped   = Edump / 3600;                   % [Wh]
J.SOC_min    = min(J.SOC);
J.SOC_end    = J.SOC(end);
J.hours      = n * dt / 3600;
J.Pfull      = Pfull;
J.Pstandby   = opt.Pstandby;
end

function [Esc, SOC, f] = sr_bank_step(Esc, SOC, Pdc, Pload, P, dt)
%SR_BANK_STEP One step of the bogie power bank: the same rules as the Simulink "Energy supervisor".
%   Esc  supercapacitor energy [J],  SOC  battery state of charge [0-1]
%   Pdc  power into the bank after the converters [W],  Pload  bogie loads [W],  dt  step [s]
%   f    flows of this step [W]: Psc (into the supercap), Pch (to battery), Pdis (from battery),
%        Pdump, Punserved, Pbloss (battery conversion losses)
%   Rules:
%     1. harvested power and loads meet on the supercapacitor (DC link)
%     2. supercap above Vchg: charge the battery;  below Vdis: the battery supports the loads
%     3. supercap full and battery full: dump the surplus;  both empty: loads are not served

V = sqrt(max(2 * Esc / P.Csc, 0));
Pch = 0;  Pdis = 0;
if V > P.Vchg && SOC < P.SOCmax
    Pch = min(P.Pch_max, P.Kv * (V - P.Vchg));
elseif V < P.Vdis && SOC > P.SOCmin
    Pdis = min(P.Pdis_max, P.Kv * (P.Vdis - V));
end
p = Pdc - Pload - Pch + Pdis;
Pdump = 0;  Punserved = 0;
if V >= P.Vmax && p > 0, Pdump = p;  p = 0; end
if V <= P.Vmin && p < 0, Punserved = -p;  p = 0; end
Esc = min(max(Esc + p * dt, 0), 0.5 * P.Csc * P.Vmax^2);
SOC = min(max(SOC + (P.eta_ch * Pch - Pdis / P.eta_dis) * dt / (P.Ebat_Wh * 3600), 0), 1);
f = struct('Psc', p, 'Pch', Pch, 'Pdis', Pdis, 'Pdump', Pdump, 'Punserved', Punserved, ...
    'Pbloss', (1 - P.eta_ch) * Pch + (1 / P.eta_dis - 1) * Pdis);
end

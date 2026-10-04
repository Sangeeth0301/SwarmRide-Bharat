function EB = sr_energy_balance(o, P)
%SR_ENERGY_BALANCE Energy bookkeeping per bogie for a whole Stage 2 run.
%   Energy converted by the generator must equal the sum of where it went:
%     coil heat + converter losses + loads served + dump + battery losses
%     + change in supercapacitor energy + change in battery energy
%   EB fields are 2x1 (front, rear) in joules; EB.rel is the residual as a fraction of E_gen.
%   EB.rel_flow is the residual as a fraction of all energy that flowed through the generator
%   (|Pgen| integrated): the fair measure when the damper also pushes (motoring) and the net is small.

t   = o.az.Time;
I   = @(name) trapz(t, sr_sig(o, name, t), 2);
Vsc = squeeze(o.Vsc.Data);
SOC = squeeze(o.SOC.Data);

EB.gen     = I('Pgen');
EB.heat    = I('Pheat');
EB.pe_loss = I('Ppe_loss');
EB.load    = I('Pload') - I('Punserved');
EB.dump    = I('Pdump');
EB.bloss   = I('Pbloss');
EB.dsc     = 0.5 * P.Csc * (Vsc(:, end).^2 - Vsc(:, 1).^2);
EB.dbat    = (SOC(:, end) - SOC(:, 1)) * P.Ebat_Wh * 3600;
EB.out     = EB.heat + EB.pe_loss + EB.load + EB.dump + EB.bloss + EB.dsc + EB.dbat;
EB.residual = EB.gen - EB.out;
EB.rel     = EB.residual ./ max(abs(EB.gen), eps);
EB.flow    = trapz(t, abs(sr_sig(o, 'Pgen', t)), 2);
EB.rel_flow = EB.residual ./ max(EB.flow, eps);
end

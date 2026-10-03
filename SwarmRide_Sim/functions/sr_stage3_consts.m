function C = sr_stage3_consts()
%SR_STAGE3_CONSTS Fixed sizes of the Stage 3 controller (shared by the parameters and the model builder).
%   Tc : controller sample time [s] (100 Hz, a realistic bogie microcontroller rate)
%   Na : preview samples ahead of the lead wheel (Na x Tc = 1 s of rail ahead)
%   Nb : samples behind the lead wheel, covering the rear wheels down to about 50 km/h
%   nL : load grid points of the LPV (gain-scheduled) controller
C.Tc = 0.01;
C.Na = 100;
C.Nb = 120;
C.Np = C.Na + C.Nb + 1;
C.nL = 5;
end

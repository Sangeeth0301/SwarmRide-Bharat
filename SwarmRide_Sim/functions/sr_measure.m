function [az, stroke, vrel] = sr_measure(q, qd, acc, P) %#codegen
%SR_MEASURE What the sensors on the coach would see.
%   az     = body vertical acceleration [centre; above front bogie; above rear bogie]  [m/s^2]
%   stroke = secondary suspension stroke [front; rear]                                 [m]
%   vrel   = stroke velocity = speed through the damper [front; rear]                  [m/s]

az     = [acc(1); acc(1) + P.lb*acc(2); acc(1) - P.lb*acc(2)];
stroke = [q(1) + P.lb*q(2) - q(3);  q(1) - P.lb*q(2) - q(4)];
vrel   = [qd(1) + P.lb*qd(2) - qd(3); qd(1) - P.lb*qd(2) - qd(4)];
end

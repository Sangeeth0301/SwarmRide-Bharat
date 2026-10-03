%% SR_SETUP  Run this first every time you open the SwarmRide project in MATLAB.
%   >> sr_setup              opens the newest model (Stage 3: SwarmRide controllers)
%   >> stage = 1; sr_setup   opens the Stage 1 model (today's damper); stage = 2 the smart damper
%   Adds the project folders to the path, keeps Simulink's build files in /work,
%   and opens the model.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'), ...
    fullfile(root, 'models'));
if ~isfolder(fullfile(root, 'work')), mkdir(fullfile(root, 'work')); end
Simulink.fileGenControl('set', 'CacheFolder', fullfile(root, 'work'), ...
    'CodeGenFolder', fullfile(root, 'work'), 'createDir', true);
cd(root);
if ~exist('stage', 'var'), stage = 3; end
open_system(fullfile(root, 'models', sprintf('SR_Stage%d.slx', stage)));
fprintf(['\nSwarmRide ready (Stage %d). Pick a train and scenario, then press Run in Simulink:\n' ...
         '   trainType = ''LHB'';   %% LHB | VB | ICF | BOXN\n' ...
         '   v_kmh = 160;  mload_t = 12;  trackType = ''poor'';   %% good | poor | bump\n'], stage);
if stage == 2
    fprintf(['   designType = ''C'';  cmdMode = ''match'';   %% A | B | C,  match | harvest\n' ...
             '   t_fault = Inf;                          %% e.g. 15 to test the fail-safe relay\n']);
elseif stage >= 3
    fprintf(['   designType = ''C'';  ctrlMode = ''C3'';     %% C1 fixed harvester | C2 LPV | C3 LPV + preview\n' ...
             '   load_err = 0.02;  preview_dt = 0;  t_fault = Inf;   %% load-estimate error, warning timing error, test fault\n']);
end
fprintf('The scope windows open and the 30 s run plays in real time.\n\n');

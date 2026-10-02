%% SR_SETUP  Run this first every time you open the SwarmRide project in MATLAB.
%   >> sr_setup
%   Adds the project folders to the path, keeps Simulink's build files in /work,
%   and opens the model.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'models'));
if ~isfolder(fullfile(root, 'work')), mkdir(fullfile(root, 'work')); end
Simulink.fileGenControl('set', 'CacheFolder', fullfile(root, 'work'), ...
    'CodeGenFolder', fullfile(root, 'work'), 'createDir', true);
cd(root);
open_system(fullfile(root, 'models', 'SR_Stage1.slx'));
fprintf(['\nSwarmRide ready. Pick a train and scenario, then press Run in Simulink:\n' ...
         '   trainType = ''LHB'';   %% LHB | VB | ICF | BOXN\n' ...
         '   v_kmh = 160;  mload_t = 12;  trackType = ''poor'';   %% good | poor | bump\n' ...
         'Four scope windows open and the 30 s run plays in real time.\n\n']);

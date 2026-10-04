%% REGENERATE_ALL  Rebuilds every model, result, figure and the verification report.
%   Run after any change to the physics, track or parameters (about 1.5 hours):
%     >> run scripts/regenerate_all
%   Order: build models -> Stage 1 checks -> Stage 1b baseline -> Stage 1 scope views -> Stage 2 study
%          -> Stage 3 study -> Stage 4 study -> verification.

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'), ...
    fullfile(root, 'models'), fullfile(root, 'tests'));
if ~isfolder(fullfile(root, 'work')), mkdir(fullfile(root, 'work')); end
Simulink.fileGenControl('set', 'CacheFolder', fullfile(root, 'work'), ...
    'CodeGenFolder', fullfile(root, 'work'), 'createDir', true);
t0 = tic;
steps = {'build_stage1', 'build_stage2', 'build_stage3', 'build_stage4', 'check_stage1', 'check_stage1b', ...
         'plot_scopes_stage1', 'check_stage2', 'check_stage3', 'check_stage4', 'run_all_checks'};
for k = 1:numel(steps)
    fprintf('\n######## %s  (%.0f s)\n', steps{k}, toc(t0));
    run(fullfile(root, 'scripts', [steps{k} '.m']));
end
fprintf('\n######## all done in %.0f s\n', toc(t0));

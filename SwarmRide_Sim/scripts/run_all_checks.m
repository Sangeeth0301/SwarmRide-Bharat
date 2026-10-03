%% RUN_ALL_CHECKS  Runs every SwarmRide verification test and writes a PASS/FAIL report.
%   Tests (folder tests/):
%     test_sperling        ride index against its closed-form value
%     test_track           generated rail against the track spectrum
%     test_stage1_physics  coach model against hand formulas and an independent model
%     test_convergence     results independent of the solver step size
%     test_stage2          smart damper and power chain against Stage 1 and hand calculations
%     test_stage3          controllers: stable, passive, energy-consistent, fail-safe, better than today
%   Output: results/verification_report.txt.   Takes about 5-10 minutes.
%   Run from the SwarmRide_Sim folder:   >> run scripts/run_all_checks

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'scripts'), fullfile(root, 'functions'), fullfile(root, 'builders'), ...
    fullfile(root, 'models'), fullfile(root, 'tests'));
load_system(fullfile(root, 'models', 'SR_Stage1.slx'));
load_system(fullfile(root, 'models', 'SR_Stage2.slx'));
if isfile(fullfile(root, 'models', 'SR_Stage3.slx')), load_system(fullfile(root, 'models', 'SR_Stage3.slx')); end

tests = {@test_sperling, @test_track, @test_stage1_physics, @test_convergence, @test_stage2, @test_stage3};
T = [];
for k = 1:numel(tests)
    fprintf('Running %s ...\n', func2str(tests{k}));
    r = tests{k}();
    [r.test] = deal(func2str(tests{k}));
    T = [T; r(:)]; %#ok<AGROW>
end

fid = fopen(fullfile(root, 'results', 'verification_report.txt'), 'w');
say = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
say('SwarmRide verification report  (%s, MATLAB %s)\n\n', datestr(now, 'yyyy-mm-dd HH:MM'), version('-release'));
cur = '';
for k = 1:numel(T)
    if ~strcmp(T(k).test, cur)
        cur = T(k).test;  say('--- %s ---\n', cur);
    end
    if T(k).pass, st = 'PASS'; else, st = 'FAIL'; end
    say('%-4s  %-72s %10.4g %-10s (limit %g)  %s\n', st, T(k).name, T(k).value, T(k).unit, T(k).limit, T(k).note);
end
np = sum([T.pass]);
say('\n%d of %d checks passed.\n', np, numel(T));
fclose(fid);

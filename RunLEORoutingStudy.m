projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'src'));

cfg = ThesisConfig.default();
result = ThesisScenarioRunner.runSnapshot(cfg);
timeSeries = ThesisScenarioRunner.runTimeSeries(cfg);
validation = ThesisValidation.runBasicChecks();

disp('LEO routing thesis smoke run');
disp(result.Graph);
disp(result.Baseline);
disp(result.Reliable);
disp(timeSeries.Summary);
disp(validation);

smokeMatrix = struct();
smokeMatrix.Constellations = [4 8];
smokeMatrix.ContactDutyCycles = 0.65;
smokeMatrix.ShortcutRiskAvailabilities = 0.35;
smokeMatrix.ReliabilityWeights = [0.3 0.9];
smokeMatrix.TimeSteps = 4;
smokeMatrix.Seeds = cfg.Seed;

disp('Compact experiment suite smoke run');
disp(ThesisExperimentSuite.runMatrix(smokeMatrix));

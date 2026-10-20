projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'src'));

if ~exist('outputDir', 'var') || isempty(outputDir)
    outputDir = fullfile(projectRoot, 'outputs');
end

if ~exist('csvPath', 'var') || isempty(csvPath)
    csvPath = fullfile(outputDir, 'experiment_results.csv');
end

if ~isfile(csvPath)
    error('Experiment results CSV not found. Run RunExperimentSuite first.');
end

results = readtable(csvPath);
summary = ThesisResultsAnalysis.summarize(results);

figuresDir = fullfile(outputDir, 'figures');
figurePaths = ThesisResultsAnalysis.writeFigures(results, figuresDir);

seedResultsPath = fullfile(outputDir, 'robustness_seed_results.csv');
routePairResultsPath = fullfile(outputDir, 'robustness_route_pair_results.csv');
robustnessSummary = [];
hasSeedResults = isfile(seedResultsPath);
hasRoutePairResults = isfile(routePairResultsPath);
if xor(hasSeedResults, hasRoutePairResults)
    error('ThesisAnalysis:IncompleteRobustnessInputs', ...
        'Both robustness CSV files are required when robustness analysis is requested.');
end
if hasSeedResults && hasRoutePairResults
    seedResults = readtable(seedResultsPath);
    routePairResults = readtable(routePairResultsPath);
    robustnessSummary = ThesisResultsAnalysis.summarizeRobustness( ...
        results, seedResults, routePairResults);
    figurePaths.RobustnessSummary = ThesisResultsAnalysis.writeRobustnessFigure( ...
        results, seedResults, routePairResults, figuresDir);
end

timeHorizonResultsPath = fullfile(outputDir, 'time_horizon_sensitivity_results.csv');
timeHorizonSummary = [];
if isfile(timeHorizonResultsPath)
    timeHorizonResults = readtable(timeHorizonResultsPath);
    timeHorizonSummary = ThesisResultsAnalysis.summarizeTimeHorizon(timeHorizonResults);
end

controlledConstellationResultsPath = fullfile( ...
    outputDir, 'controlled_constellation_sensitivity_results.csv');
controlledConstellationAnalysis = [];
if isfile(controlledConstellationResultsPath)
    controlledConstellationResults = readtable(controlledConstellationResultsPath);
    controlledConstellationAnalysis = ...
        ThesisResultsAnalysis.summarizeControlledConstellation( ...
        controlledConstellationResults);
end

topologyOnlyAblationResultsPath = fullfile( ...
    outputDir, 'topology_only_ablation_results.csv');
topologyOnlyAblationAnalysis = [];
if isfile(topologyOnlyAblationResultsPath)
    topologyOnlyAblationResults = readtable(topologyOnlyAblationResultsPath);
    topologyOnlyAblationAnalysis = ...
        ThesisResultsAnalysis.summarizeTopologyOnlyAblation( ...
        topologyOnlyAblationResults);
end

reliabilityStressAblationResultsPath = fullfile( ...
    outputDir, 'reliability_stress_ablation_results.csv');
reliabilityStressAblationAnalysis = [];
if isfile(reliabilityStressAblationResultsPath)
    reliabilityStressAblationResults = readtable( ...
        reliabilityStressAblationResultsPath);
    reliabilityStressAblationAnalysis = ...
        ThesisResultsAnalysis.summarizeReliabilityStressAblation( ...
        reliabilityStressAblationResults);
    figurePaths.ReliabilityStressAblation = ...
        ThesisResultsAnalysis.writeReliabilityStressAblationFigure( ...
        reliabilityStressAblationResults, figuresDir);
end

notesPath = fullfile(outputDir, 'results_notes.md');
ThesisResultsAnalysis.writeNotes( ...
    summary, notesPath, robustnessSummary, timeHorizonSummary, ...
    controlledConstellationAnalysis, topologyOnlyAblationAnalysis, ...
    reliabilityStressAblationAnalysis);
summaryMatPath = fullfile(outputDir, 'analysis_summary.mat');
save(summaryMatPath, 'summary', 'robustnessSummary', ...
    'timeHorizonSummary', 'controlledConstellationAnalysis', ...
    'topologyOnlyAblationAnalysis', 'reliabilityStressAblationAnalysis', ...
    'figurePaths');

disp('LEO routing results analysis completed');
disp(['Rows analyzed: ', num2str(summary.RowCount)]);
disp(['Mean availability gain: ', num2str(summary.MeanAvailabilityGain)]);
disp(['Mean effective latency improvement (ms): ', num2str(summary.MeanEffectiveLatencyImprovementMs)]);
disp(['Notes: ', notesPath]);
disp(['Analysis MAT: ', summaryMatPath]);
disp('Figures:');
disp(['- ', figurePaths.ReliabilityWeightSensitivity]);
disp(['- ', figurePaths.EffectiveLatencyByRisk]);
disp(['- ', figurePaths.LatencyTradeoff]);
disp(['- ', figurePaths.RouteChangesComparison]);
if isfield(figurePaths, 'RobustnessSummary')
    disp(['- ', figurePaths.RobustnessSummary]);
end
if isfield(figurePaths, 'ReliabilityStressAblation')
    disp(['- ', figurePaths.ReliabilityStressAblation]);
end

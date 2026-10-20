projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'src'));

if ~exist('seedMatrix', 'var') || isempty(seedMatrix)
    seedMatrix = ThesisExperimentSuite.defaultMatrix();
    seedMatrix.Seeds = [11 23 42 77 101];
end

if ~exist('outputDir', 'var') || isempty(outputDir)
    outputDir = fullfile(projectRoot, 'outputs');
end

if ~isfolder(outputDir)
    mkdir(outputDir);
end

results = ThesisExperimentSuite.runMatrix(seedMatrix);
seedCsvPath = fullfile(outputDir, 'robustness_seed_results.csv');
seedMatPath = fullfile(outputDir, 'robustness_seed_results.mat');

ThesisExperimentSuite.writeTable(results, seedCsvPath);
save(seedMatPath, 'results', 'seedMatrix');

seedSummary = groupsummary(results, 'Seed', 'mean', { ...
    'ReliableAvailabilityGain', ...
    'ReliableLatencyPenaltyMs', ...
    'EffectiveLatencyImprovementMs', ...
    'BaselineRouteChanges', ...
    'ReliableRouteChanges'});

disp('LEO routing seed-sensitivity suite completed');
disp(['Rows: ', num2str(height(results))]);
disp(['Seeds: ', mat2str(seedMatrix.Seeds)]);
disp(['CSV: ', seedCsvPath]);
disp(['MAT: ', seedMatPath]);
disp(seedSummary);

if ~exist('routePairMatrix', 'var') || isempty(routePairMatrix)
    routePairMatrix = ThesisExperimentSuite.defaultMatrix();
    routePairMatrix.RoutePairs = [ ...
        1 16; ...
        2 17; ...
        4 20; ...
        8 24; ...
        12 28];
end

routePairResults = ThesisExperimentSuite.runMatrix(routePairMatrix);
routePairCsvPath = fullfile(outputDir, 'robustness_route_pair_results.csv');
routePairMatPath = fullfile(outputDir, 'robustness_route_pair_results.mat');

ThesisExperimentSuite.writeTable(routePairResults, routePairCsvPath);
save(routePairMatPath, 'routePairResults', 'routePairMatrix');

routePairSummary = groupsummary(routePairResults, {'SourceNode', 'DestinationNode'}, 'mean', { ...
    'ReliableAvailabilityGain', ...
    'ReliableLatencyPenaltyMs', ...
    'EffectiveLatencyImprovementMs', ...
    'BaselineRouteChanges', ...
    'ReliableRouteChanges'});

disp('LEO routing source-destination sensitivity suite completed');
disp(['Rows: ', num2str(height(routePairResults))]);
disp(['CSV: ', routePairCsvPath]);
disp(['MAT: ', routePairMatPath]);
disp(routePairSummary);

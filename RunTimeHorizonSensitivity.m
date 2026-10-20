projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'src'));

if ~exist('timeHorizonMatrix', 'var') || isempty(timeHorizonMatrix)
    timeHorizonMatrix = ThesisExperimentSuite.defaultMatrix();
end

if ~exist('timeHorizons', 'var') || isempty(timeHorizons)
    timeHorizons = [12 50 100];
end
timeHorizons = ThesisExperimentSuite.validateSweepVector( ...
    timeHorizons, 'TimeHorizons', 2, inf, true);

if ~exist('outputDir', 'var') || isempty(outputDir)
    outputDir = fullfile(projectRoot, 'outputs');
end
if ~isfolder(outputDir)
    mkdir(outputDir);
end

timeHorizonResults = table();
for timeHorizon = timeHorizons
    currentMatrix = timeHorizonMatrix;
    currentMatrix.TimeSteps = timeHorizon;
    currentResults = ThesisExperimentSuite.runMatrix(currentMatrix);
    timeHorizonResults = [timeHorizonResults; currentResults]; %#ok<AGROW>
end

timeHorizonCsvPath = fullfile(outputDir, 'time_horizon_sensitivity_results.csv');
timeHorizonMatPath = fullfile(outputDir, 'time_horizon_sensitivity_results.mat');
ThesisExperimentSuite.writeTable(timeHorizonResults, timeHorizonCsvPath);
save(timeHorizonMatPath, 'timeHorizonResults', 'timeHorizonMatrix', 'timeHorizons');

timeHorizonSummary = ThesisResultsAnalysis.summarizeTimeHorizon(timeHorizonResults);

disp('LEO routing time-horizon sensitivity suite completed');
disp(['Rows: ', num2str(height(timeHorizonResults))]);
disp(['Time steps: ', mat2str(timeHorizons)]);
disp(['CSV: ', timeHorizonCsvPath]);
disp(['MAT: ', timeHorizonMatPath]);
disp(timeHorizonSummary.ByTimeSteps);

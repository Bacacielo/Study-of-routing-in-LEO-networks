projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'src'));

if ~exist('matrix', 'var') || isempty(matrix)
    matrix = ThesisExperimentSuite.defaultMatrix();
end

if ~exist('outputDir', 'var') || isempty(outputDir)
    outputDir = fullfile(projectRoot, 'outputs');
end

if ~isfolder(outputDir)
    mkdir(outputDir);
end

results = ThesisExperimentSuite.runMatrix(matrix);
csvPath = fullfile(outputDir, 'experiment_results.csv');
matPath = fullfile(outputDir, 'experiment_results.mat');

ThesisExperimentSuite.writeTable(results, csvPath);
save(matPath, 'results', 'matrix');

disp('LEO routing experiment suite completed');
disp(['Rows: ', num2str(height(results))]);
disp(['CSV: ', csvPath]);
disp(['MAT: ', matPath]);
previewRows = min(10, height(results));
disp(results(1:previewRows, :));
if height(results) > previewRows
    disp(['Preview shown: ', num2str(previewRows), ' of ', num2str(height(results)), ' rows.']);
end

projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'src'));

if ~exist('outputDir', 'var') || isempty(outputDir)
    outputDir = fullfile(projectRoot, 'outputs');
end
if ~isfolder(outputDir)
    mkdir(outputDir);
end

if ~exist('reliabilityStressSweep', 'var') || isempty(reliabilityStressSweep)
    reliabilityStressSweep = ThesisReliabilityStressStudy.defaultSweep();
end

reliabilityStressAblationResults = ...
    ThesisReliabilityStressStudy.run(reliabilityStressSweep);
reliabilityStressAblationAnalysis = ...
    ThesisResultsAnalysis.summarizeReliabilityStressAblation( ...
    reliabilityStressAblationResults);

reliabilityStressAblationCsvPath = fullfile( ...
    outputDir, 'reliability_stress_ablation_results.csv');
reliabilityStressAblationMatPath = fullfile( ...
    outputDir, 'reliability_stress_ablation_results.mat');
ThesisExperimentSuite.writeTable( ...
    reliabilityStressAblationResults, reliabilityStressAblationCsvPath);
save(reliabilityStressAblationMatPath, ...
    'reliabilityStressAblationResults', ...
    'reliabilityStressAblationAnalysis', ...
    'reliabilityStressSweep');

disp('Reliability-stress ablation completed');
disp(['Rows: ', num2str(height(reliabilityStressAblationResults))]);
disp(['CSV: ', reliabilityStressAblationCsvPath]);
disp(['MAT: ', reliabilityStressAblationMatPath]);
disp(reliabilityStressAblationAnalysis.ByShortcutRiskAvailability);

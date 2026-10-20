function artifacts = RunHypatiaValidation(outputDirectory)
% RUNHYPATIAVALIDATION Validate the official Hypatia ECDF data in MATLAB.

projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'src'));
if nargin < 1 || isempty(outputDirectory)
    outputDirectory = fullfile(projectRoot, 'outputs', 'hypatia_validation');
end

hypatiaValidationSummary = ThesisHypatiaValidation.analyze();
artifacts = ThesisHypatiaValidation.export( ...
    hypatiaValidationSummary, outputDirectory);
artifacts.Summary = hypatiaValidationSummary;

disp('Hypatia validation completed');
disp(hypatiaValidationSummary.Table);
disp(['CSV: ', artifacts.SummaryCsvPath]);
disp(['Figure: ', artifacts.EcdfFigurePath]);
end

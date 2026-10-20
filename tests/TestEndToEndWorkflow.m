classdef TestEndToEndWorkflow < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(testDir);
            addpath(projectRoot);
            addpath(fullfile(projectRoot, 'src'));
        end
    end

    methods (Test)
        function fullStudyEntryPointProducesDeliveryArtifacts(testCase)
            outputDir = fullfile(tempdir, ['leo-end-to-end-', char(java.util.UUID.randomUUID())]);
            cleanup = onCleanup(@() TestEndToEndWorkflow.removeDirIfPresent(outputDir));

            compactStabilityDesign = struct( ...
                'Seeds', 11, ...
                'RoutePairs', [1 19], ...
                'ContactDutyCycles', 0.65, ...
                'ReliabilityWeights', 0.60, ...
                'HysteresisTolerances', [0 0.10], ...
                'TimeSteps', 6);
            artifacts = RunFullThesisStudy( ...
                outputDir, compactStabilityDesign);

            testCase.verifyEqual(artifacts.MainRowCount, 81);
            testCase.verifyEqual(artifacts.SeedRowCount, 405);
            testCase.verifyEqual(artifacts.RoutePairRowCount, 405);
            testCase.verifyEqual(artifacts.TimeHorizonRowCount, 243);
            testCase.verifyEqual(artifacts.ControlledConstellationRowCount, 81);
            testCase.verifyEqual(artifacts.TopologyOnlyAblationRowCount, 20);
            testCase.verifyEqual(artifacts.ReliabilityStressAblationRowCount, 216);
            testCase.verifyEqual(artifacts.Summary.RowCount, 81);
            testCase.verifyTrue(isfile(artifacts.MainResultsPath));
            testCase.verifyTrue(isfile(artifacts.SeedResultsPath));
            testCase.verifyTrue(isfile(artifacts.RoutePairResultsPath));
            testCase.verifyTrue(isfile(artifacts.TimeHorizonResultsPath));
            testCase.verifyTrue(isfile(artifacts.ControlledConstellationResultsPath));
            testCase.verifyTrue(isfile(artifacts.TopologyOnlyAblationResultsPath));
            testCase.verifyTrue(isfile(artifacts.ReliabilityStressAblationResultsPath));
            testCase.verifyTrue(isfile( ...
                artifacts.HypatiaValidation.SummaryCsvPath));
            testCase.verifyTrue(isfile( ...
                artifacts.HypatiaValidation.EcdfFigurePath));
            testCase.verifyTrue( ...
                artifacts.HypatiaValidation.Summary. ...
                PaperAnchorsVerified);
            testCase.verifyEqual( ...
                artifacts.StabilityAwareAblation.RowCount, 2);
            testCase.verifyTrue(isfile( ...
                artifacts.StabilityAwareAblation.ResultsPath));
            testCase.verifyTrue(isfile( ...
                artifacts.StabilityAwareAblation.SummaryPath));
            testCase.verifyTrue(isfile( ...
                artifacts.StabilityAwareAblation.FigurePath));
            testCase.verifyTrue(isfile(artifacts.FigurePaths.ReliabilityWeightSensitivity));
            testCase.verifyTrue(isfile(artifacts.FigurePaths.EffectiveLatencyByRisk));
            testCase.verifyTrue(isfile(artifacts.FigurePaths.LatencyTradeoff));
            testCase.verifyTrue(isfile(artifacts.FigurePaths.RouteChangesComparison));
            testCase.verifyTrue(isfile(artifacts.FigurePaths.RobustnessSummary));
            testCase.verifyTrue(isfile( ...
                artifacts.FigurePaths.ReliabilityStressAblation));
            testCase.verifyTrue(isfile(artifacts.NotesPath));
            testCase.verifyTrue(isfile(artifacts.AnalysisSummaryPath));
            testCase.verifyFalse(isempty(artifacts.RobustnessSummary));
            testCase.verifyFalse(isempty(artifacts.TimeHorizonSummary));
            testCase.verifyFalse(isempty(artifacts.ControlledConstellationAnalysis));
            testCase.verifyFalse(isempty(artifacts.TopologyOnlyAblationAnalysis));
            testCase.verifyFalse(isempty( ...
                artifacts.ReliabilityStressAblationAnalysis));
            clear cleanup;
        end
    end

    methods (Static)
        function removeDirIfPresent(pathToRemove)
            if isfolder(pathToRemove)
                rmdir(pathToRemove, 's');
            end
        end
    end
end

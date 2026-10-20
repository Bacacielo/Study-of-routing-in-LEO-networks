classdef TestRunStabilityAwareAblationScript < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addProjectPath(~)
            testDirectory = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(testDirectory);
            addpath(projectRoot);
            addpath(fullfile(projectRoot, 'src'));
        end
    end

    methods (Test)
        function compactDesignProducesExpectedArtifacts(testCase)
            outputDirectory = fullfile( ...
                tempdir, ['stability-ablation-', ...
                char(java.util.UUID.randomUUID())]);
            cleanup = onCleanup(@() ...
                TestRunStabilityAwareAblationScript. ...
                removeDirIfPresent(outputDirectory));
            design = struct( ...
                'Seeds', 11, ...
                'RoutePairs', [1 19], ...
                'ContactDutyCycles', 0.65, ...
                'ReliabilityWeights', 0.60, ...
                'HysteresisTolerances', [0 0.10], ...
                'TimeSteps', 6);

            artifacts = RunStabilityAwareAblation( ...
                outputDirectory, design);

            testCase.verifyEqual(artifacts.RowCount, 2);
            testCase.verifyTrue(isfile(artifacts.ResultsPath));
            testCase.verifyTrue(isfile(artifacts.SummaryPath));
            testCase.verifyTrue(isfile(artifacts.MatPath));
            testCase.verifyTrue(isfile(artifacts.FigurePath));
            testCase.verifyTrue( ...
                artifacts.Summary.AllCasesRespectHysteresisBound);
            clear cleanup;
        end

        function unknownDesignFieldIsRejected(testCase)
            testCase.verifyError( ...
                @() RunStabilityAwareAblation( ...
                tempdir, struct('Unknown', 1)), ...
                'StabilityAblation:UnknownDesignField');
        end
    end

    methods (Static, Access = private)
        function removeDirIfPresent(pathToRemove)
            if isfolder(pathToRemove)
                rmdir(pathToRemove, 's');
            end
        end
    end
end

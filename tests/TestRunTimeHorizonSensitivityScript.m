classdef TestRunTimeHorizonSensitivityScript < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function scriptWritesTimeHorizonArtifacts(testCase)
            testDir = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(testDir); %#ok<NASGU>
            outputDir = fullfile(tempdir, ...
                ['leo-time-horizon-', char(java.util.UUID.randomUUID())]);
            cleanup = onCleanup(@() ...
                TestRunTimeHorizonSensitivityScript.removeDirIfPresent(outputDir));

            timeHorizonMatrix = struct( ...
                'Constellations', [4 8], ...
                'ContactDutyCycles', 0.65, ...
                'ShortcutRiskAvailabilities', 0.35, ...
                'ReliabilityWeights', [0.3 0.9], ...
                'Seeds', 5, ...
                'RoutePairs', [1 16]); %#ok<NASGU>
            timeHorizons = [2 4]; %#ok<NASGU>

            evalc("run(fullfile(projectRoot, 'RunTimeHorizonSensitivity.m'))");

            csvPath = fullfile(outputDir, 'time_horizon_sensitivity_results.csv');
            matPath = fullfile(outputDir, 'time_horizon_sensitivity_results.mat');
            testCase.verifyTrue(isfile(csvPath));
            testCase.verifyTrue(isfile(matPath));
            testCase.verifyEqual(height(timeHorizonResults), 4);
            testCase.verifyEqual(unique(timeHorizonResults.TimeSteps), [2; 4]);
            testCase.verifyEqual(height(timeHorizonSummary.ByTimeSteps), 2);
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

classdef TestRunControlledConstellationSensitivityScript < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function scriptWritesControlledConstellationArtifacts(testCase)
            testDir = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(testDir); %#ok<NASGU>
            outputDir = fullfile(tempdir, ...
                ['leo-controlled-constellation-', char(java.util.UUID.randomUUID())]);
            cleanup = onCleanup(@() ...
                TestRunControlledConstellationSensitivityScript.removeDirIfPresent(outputDir));

            controlledConstellationMatrix = struct( ...
                'Constellations', [4 8; 6 12], ...
                'ContactDutyCycles', 0.65, ...
                'ShortcutRiskAvailabilities', 0.35, ...
                'ReliabilityWeights', 0.6, ...
                'TimeSteps', 3, ...
                'Seeds', 11, ...
                'RoutePairs', [1 16]); %#ok<NASGU>

            evalc("run(fullfile(projectRoot, 'RunControlledConstellationSensitivity.m'))");

            csvPath = fullfile(outputDir, ...
                'controlled_constellation_sensitivity_results.csv');
            matPath = fullfile(outputDir, ...
                'controlled_constellation_sensitivity_results.mat');
            testCase.verifyTrue(isfile(csvPath));
            testCase.verifyTrue(isfile(matPath));
            testCase.verifyEqual(height(controlledConstellationResults), 2);
            testCase.verifyEqual(controlledConstellationResults.DestinationNode, [13; 19]);
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

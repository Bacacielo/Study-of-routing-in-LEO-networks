classdef TestRunExperimentSuiteScript < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function scriptWritesCsvAndMatArtifacts(testCase)
            testDir = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(testDir); %#ok<NASGU>
            outputDir = fullfile(tempdir, ['leo-suite-', char(java.util.UUID.randomUUID())]);
            cleanup = onCleanup(@() TestRunExperimentSuiteScript.removeDirIfPresent(outputDir));

            matrix = struct();
            matrix.Constellations = [4 8];
            matrix.ContactDutyCycles = 0.65;
            matrix.ShortcutRiskAvailabilities = 0.35;
            matrix.ReliabilityWeights = [0.3 0.9];
            matrix.TimeSteps = 2;
            matrix.Seeds = 5; %#ok<STRNU>

            evalc("run(fullfile(projectRoot, 'RunExperimentSuite.m'))");

            csvPath = fullfile(outputDir, 'experiment_results.csv');
            matPath = fullfile(outputDir, 'experiment_results.mat');

            testCase.verifyTrue(isfile(csvPath));
            testCase.verifyTrue(isfile(matPath));
            testCase.verifyGreaterThan(dir(csvPath).bytes, 0);
            testCase.verifyGreaterThan(dir(matPath).bytes, 0);
            testCase.verifyEqual(height(results), 2);
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

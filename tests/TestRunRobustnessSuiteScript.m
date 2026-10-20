classdef TestRunRobustnessSuiteScript < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function scriptWritesSeedSensitivityArtifacts(testCase)
            testDir = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(testDir); %#ok<NASGU>
            outputDir = fullfile(tempdir, ['leo-robustness-', char(java.util.UUID.randomUUID())]);
            cleanup = onCleanup(@() TestRunRobustnessSuiteScript.removeDirIfPresent(outputDir));

            seedMatrix = struct();
            seedMatrix.Constellations = [4 8];
            seedMatrix.ContactDutyCycles = 0.65;
            seedMatrix.ShortcutRiskAvailabilities = 0.35;
            seedMatrix.ReliabilityWeights = [0.3 0.9];
            seedMatrix.Seeds = [5 7];
            seedMatrix.TimeSteps = 2; %#ok<STRNU>

            evalc("run(fullfile(projectRoot, 'RunRobustnessSuite.m'))");

            csvPath = fullfile(outputDir, 'robustness_seed_results.csv');
            matPath = fullfile(outputDir, 'robustness_seed_results.mat');

            testCase.verifyTrue(isfile(csvPath));
            testCase.verifyTrue(isfile(matPath));
            testCase.verifyGreaterThan(dir(csvPath).bytes, 0);
            testCase.verifyGreaterThan(dir(matPath).bytes, 0);
            testCase.verifyEqual(height(results), 4);
            testCase.verifyEqual(unique(results.Seed), [5; 7]);
            testCase.verifyTrue(isfile(fullfile(outputDir, 'robustness_route_pair_results.csv')));
            testCase.verifyTrue(isfile(fullfile(outputDir, 'robustness_route_pair_results.mat')));
            clear cleanup;
        end

        function defaultSeedSensitivityIgnoresPriorExperimentMatrix(testCase)
            testDir = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(testDir); %#ok<NASGU>
            outputDir = fullfile(tempdir, ['leo-robustness-default-', char(java.util.UUID.randomUUID())]);
            cleanup = onCleanup(@() TestRunRobustnessSuiteScript.removeDirIfPresent(outputDir));
            matrix = ThesisExperimentSuite.defaultMatrix(); %#ok<NASGU>

            evalc("run(fullfile(projectRoot, 'RunRobustnessSuite.m'))");

            testCase.verifyEqual(height(results), 405);
            testCase.verifyEqual(unique(results.Seed), [11; 23; 42; 77; 101]);
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

classdef TestRunReliabilityStressAblationScript < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function scriptWritesStressAblationArtifacts(testCase)
            testDir = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(testDir); %#ok<NASGU>
            outputDir = fullfile(tempdir, ...
                ['leo-stress-ablation-', char(java.util.UUID.randomUUID())]);
            cleanup = onCleanup(@() ...
                TestRunReliabilityStressAblationScript.removeDirIfPresent(outputDir));
            reliabilityStressSweep = ...
                ThesisReliabilityStressStudy.defaultSweep();
            reliabilityStressSweep.Constellations = [4 8];
            reliabilityStressSweep.ContactDutyCycles = 0.65;
            reliabilityStressSweep.ShortcutRiskAvailabilities = [0.20 0.90];
            reliabilityStressSweep.ReliabilityWeights = 0.60;
            reliabilityStressSweep.TimeSteps = 3;

            evalc("run(fullfile(projectRoot, 'RunReliabilityStressAblation.m'))");

            csvPath = fullfile( ...
                outputDir, 'reliability_stress_ablation_results.csv');
            matPath = fullfile( ...
                outputDir, 'reliability_stress_ablation_results.mat');
            testCase.verifyTrue(isfile(csvPath));
            testCase.verifyTrue(isfile(matPath));
            testCase.verifyEqual(height(reliabilityStressAblationResults), 3);
            testCase.verifyEqual(sum( ...
                reliabilityStressAblationResults.StressEnabled), 2);
            testCase.verifyEqual(sum(~ ...
                reliabilityStressAblationResults.StressEnabled), 1);
            csvResults = readtable(csvPath);
            csvSummary = ThesisResultsAnalysis. ...
                summarizeReliabilityStressAblation(csvResults);
            testCase.verifyEqual(csvSummary.RowCount, 3);
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

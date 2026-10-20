classdef TestRunTopologyOnlyAblationScript < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function scriptWritesTopologyOnlyArtifacts(testCase)
            testDir = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(testDir); %#ok<NASGU>
            outputDir = fullfile(tempdir, ...
                ['leo-topology-ablation-', char(java.util.UUID.randomUUID())]);
            cleanup = onCleanup(@() ...
                TestRunTopologyOnlyAblationScript.removeDirIfPresent(outputDir));
            topologyAblationSeeds = [5 11]; %#ok<NASGU>
            topologyAblationDutyCycles = [0.65 1.00]; %#ok<NASGU>
            topologyAblationTimeSteps = 12; %#ok<NASGU>

            evalc("run(fullfile(projectRoot, 'RunTopologyOnlyAblation.m'))");

            csvPath = fullfile(outputDir, 'topology_only_ablation_results.csv');
            matPath = fullfile(outputDir, 'topology_only_ablation_results.mat');
            testCase.verifyTrue(isfile(csvPath));
            testCase.verifyTrue(isfile(matPath));
            testCase.verifyEqual(height(topologyOnlyAblationResults), 4);
            staticRows = topologyOnlyAblationResults.ContactDutyCycle == 1;
            testCase.verifyEqual( ...
                topologyOnlyAblationResults.BaselineRouteChangeRate(staticRows), zeros(2, 1));
            testCase.verifyEqual( ...
                topologyOnlyAblationResults.ReliableRouteChangeRate(staticRows), zeros(2, 1));
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

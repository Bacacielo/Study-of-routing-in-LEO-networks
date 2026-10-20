classdef TestThesisExperimentSuite < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function defaultMatrixExposesThesisSweepParameters(testCase)
            matrix = ThesisExperimentSuite.defaultMatrix();

            testCase.verifyEqual(matrix.Constellations, [4 8; 6 12; 8 20]);
            testCase.verifyEqual(matrix.ContactDutyCycles, [0.45 0.65 0.85]);
            testCase.verifyEqual(matrix.ShortcutRiskAvailabilities, [0.20 0.35 0.50]);
            testCase.verifyEqual(matrix.ReliabilityWeights, [0.3 0.6 0.9]);
            testCase.verifyEqual(matrix.Seeds, 42);
            testCase.verifyEqual(matrix.RoutePairs, [1 16]);
        end

        function runMatrixReturnsOneRowPerParameterCombination(testCase)
            matrix = struct();
            matrix.Constellations = [4 8; 6 12];
            matrix.ContactDutyCycles = 0.65;
            matrix.ShortcutRiskAvailabilities = [0.25 0.50];
            matrix.ReliabilityWeights = 0.9;
            matrix.TimeSteps = 3;
            matrix.Seeds = [7 13];
            matrix.RoutePairs = [1 16; 2 17];

            results = ThesisExperimentSuite.runMatrix(matrix);

            testCase.verifyEqual(height(results), 16);
            requiredColumns = { ...
                'Seed', ...
                'SourceNode', ...
                'DestinationNode', ...
                'PlaneCount', ...
                'SatellitesPerPlane', ...
                'NodeCount', ...
                'ContactDutyCycle', ...
                'ShortcutRiskAvailability', ...
                'ReliabilityWeight', ...
                'TimeSteps', ...
                'BaselineMeanLatencyMs', ...
                'ReliableMeanLatencyMs', ...
                'ReliableLatencyPenaltyMs', ...
                'BaselineMeanEffectiveLatencyMs', ...
                'ReliableMeanEffectiveLatencyMs', ...
                'EffectiveLatencyImprovementMs', ...
                'BaselineMeanAvailability', ...
                'ReliableMeanAvailability', ...
                'ReliableAvailabilityGain', ...
                'BaselineRouteChanges', ...
                'ReliableRouteChanges'};

            testCase.verifyTrue(all(ismember(requiredColumns, results.Properties.VariableNames)));
            testCase.verifyEqual(unique(results.Seed), [7; 13]);
            testCase.verifyEqual(unique(results.SourceNode), [1; 2]);
            testCase.verifyEqual(unique(results.DestinationNode), [16; 17]);
            testCase.verifyEqual(unique(results.TimeSteps), 3);
            testCase.verifyEqual(results.NodeCount, results.PlaneCount .* results.SatellitesPerPlane);
            testCase.verifyTrue(all(results.ReliableMeanAvailability >= 0));
            testCase.verifyTrue(all(results.ReliableMeanAvailability <= 1));
            testCase.verifyTrue(all(results.BaselineMeanEffectiveLatencyMs >= results.BaselineMeanLatencyMs));
            testCase.verifyTrue(all(results.ReliableMeanEffectiveLatencyMs >= results.ReliableMeanLatencyMs));
        end

        function legacySeedAliasControlsRunSeed(testCase)
            matrix = struct();
            matrix.Constellations = [4 8];
            matrix.ContactDutyCycles = 0.65;
            matrix.ShortcutRiskAvailabilities = 0.35;
            matrix.ReliabilityWeights = 0.9;
            matrix.TimeSteps = 2;
            matrix.Seed = 11;

            results = ThesisExperimentSuite.runMatrix(matrix);

            testCase.verifyEqual(unique(results.Seed), 11);
        end

        function columnSweepVectorsAreCanonicalized(testCase)
            matrix = struct();
            matrix.Constellations = [4; 8];
            matrix.ContactDutyCycles = [0.45; 0.65];
            matrix.ShortcutRiskAvailabilities = [0.20; 0.35];
            matrix.ReliabilityWeights = [0.3; 0.9];
            matrix.Seeds = [7; 13];
            matrix.RoutePairs = [1; 16];
            matrix.TimeSteps = 2;

            results = ThesisExperimentSuite.runMatrix(matrix);

            testCase.verifyEqual(height(results), 16);
            testCase.verifyEqual(unique(results.ContactDutyCycle), [0.45; 0.65]);
            testCase.verifyEqual(unique(results.ReliabilityWeight), [0.3; 0.9]);
            testCase.verifyEqual(unique(results.Seed), [7; 13]);
        end

        function outOfRangeSweepValuesAreRejected(testCase)
            matrix = struct('ReliabilityWeights', 1.1);

            testCase.verifyError(@() ThesisExperimentSuite.runMatrix(matrix), ...
                'ThesisExperimentSuite:InvalidSweepValues');
        end

        function routePairsMustExistInEveryConstellation(testCase)
            matrix = struct( ...
                'Constellations', [4 8; 6 12], ...
                'RoutePairs', [1 33]);

            testCase.verifyError(@() ThesisExperimentSuite.runMatrix(matrix), ...
                'ThesisExperimentSuite:InvalidRoutePairs');
        end

        function unknownMatrixFieldsAreRejected(testCase)
            matrix = struct('ReliabilityWeight', 0.9);

            testCase.verifyError(@() ThesisExperimentSuite.runMatrix(matrix), ...
                'ThesisExperimentSuite:InvalidMatrixField');
        end

        function defaultMatrixReproducesMainExperimentSummary(testCase)
            results = ThesisExperimentSuite.runMatrix(ThesisExperimentSuite.defaultMatrix());
            summary = ThesisResultsAnalysis.summarize(results);

            testCase.verifyEqual(height(results), 81);
            testCase.verifyEqual(summary.MeanAvailabilityGain, 0.0672866745331446, 'AbsTol', 1e-12);
            testCase.verifyEqual(summary.MeanReliableLatencyPenaltyMs, 1.18603527069044, 'AbsTol', 1e-12);
            testCase.verifyEqual(summary.MeanEffectiveLatencyImprovementMs, 5.32676076687069, 'AbsTol', 1e-12);
            testCase.verifyEqual(sum(results.EffectiveLatencyImprovementMs > 0), 44);
            testCase.verifyEqual(sum(results.EffectiveLatencyImprovementMs == 0), 27);
            testCase.verifyEqual(sum(results.EffectiveLatencyImprovementMs < 0), 10);
        end

        function writeTableCreatesCsvFile(testCase)
            matrix = struct();
            matrix.Constellations = [4 8];
            matrix.ContactDutyCycles = 0.65;
            matrix.ShortcutRiskAvailabilities = 0.35;
            matrix.ReliabilityWeights = 0.9;
            matrix.TimeSteps = 2;
            matrix.Seeds = 9;
            results = ThesisExperimentSuite.runMatrix(matrix);
            outputPath = [tempname, '.csv'];
            cleanup = onCleanup(@() delete(outputPath));

            ThesisExperimentSuite.writeTable(results, outputPath);
            fileInfo = dir(outputPath);

            testCase.verifyNotEmpty(fileInfo);
            testCase.verifyGreaterThan(fileInfo.bytes, 0);
            clear cleanup;
        end
    end
end

classdef TestThesisScenarioRunner < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function snapshotProducesBaselineAndReliableResults(testCase)
            cfg = ThesisConfig.withOverrides(struct('Seed', 11));

            result = ThesisScenarioRunner.runSnapshot(cfg);

            testCase.verifyEqual(result.Config.Profile, 'WalkerLEO');
            testCase.verifyGreaterThan(result.Graph.NodeCount, 0);
            testCase.verifyGreaterThan(result.Baseline.LatencyMs, 0);
            testCase.verifyGreaterThan(result.Reliable.LatencyMs, 0);
            testCase.verifyGreaterThanOrEqual(result.Baseline.Availability, 0);
            testCase.verifyLessThanOrEqual(result.Baseline.Availability, 1);
            testCase.verifyGreaterThanOrEqual(result.Reliable.Availability, 0);
            testCase.verifyLessThanOrEqual(result.Reliable.Availability, 1);
        end

        function timeSeriesProducesSnapshotsAndSummary(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'Seed', 11, ...
                'TimeSteps', 4));

            result = ThesisScenarioRunner.runTimeSeries(cfg);

            testCase.verifyEqual(numel(result.Snapshots), cfg.TimeSteps);
            testCase.verifyEqual(result.Summary.TimeSteps, cfg.TimeSteps);
            testCase.verifyGreaterThan(result.Summary.BaselineMeanLatencyMs, 0);
            testCase.verifyGreaterThan(result.Summary.ReliableMeanLatencyMs, 0);
            testCase.verifyGreaterThanOrEqual(result.Summary.BaselineMeanAvailability, 0);
            testCase.verifyLessThanOrEqual(result.Summary.BaselineMeanAvailability, 1);
            testCase.verifyGreaterThanOrEqual(result.Summary.ReliableMeanAvailability, 0);
            testCase.verifyLessThanOrEqual(result.Summary.ReliableMeanAvailability, 1);
            testCase.verifyGreaterThanOrEqual(result.Summary.BaselineRouteChanges, 0);
            testCase.verifyGreaterThanOrEqual(result.Summary.ReliableRouteChanges, 0);
            testCase.verifyTrue(isfield(result.Summary, 'ReliableAvailabilityGain'));
            testCase.verifyTrue(isfield(result.Summary, 'ReliableLatencyPenaltyMs'));
            testCase.verifyTrue(isfield(result.Summary, 'BaselineMeanEffectiveLatencyMs'));
            testCase.verifyTrue(isfield(result.Summary, 'ReliableMeanEffectiveLatencyMs'));
            testCase.verifyTrue(isfield(result.Summary, 'EffectiveLatencyImprovementMs'));
        end

        function stressedScenarioShowsReliabilityAvailabilityGain(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'PlaneCount', 4, ...
                'SatellitesPerPlane', 8, ...
                'Seed', 21, ...
                'TimeSteps', 6, ...
                'ReliabilityWeight', 0.9, ...
                'ContactDutyCycle', 1, ...
                'ShortcutRiskAvailability', 0.25));

            result = ThesisScenarioRunner.runTimeSeries(cfg);

            testCase.verifyGreaterThanOrEqual(result.Summary.ReliableAvailabilityGain, 0);
            testCase.verifyGreaterThanOrEqual(result.Summary.EffectiveLatencyImprovementMs, 0);
        end

        function identicalEndpointsAreRejected(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'SourceNode', 32, ...
                'DestinationNode', 32));

            testCase.verifyError(@() ThesisScenarioRunner.runSnapshot(cfg), ...
                'ThesisScenarioRunner:IdenticalEndpoints');
        end

        function outOfRangeSourceNodeIsRejected(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'SourceNode', 33, ...
                'DestinationNode', 16));

            testCase.verifyError(@() ThesisScenarioRunner.runSnapshot(cfg), ...
                'ThesisScenarioRunner:InvalidSourceNode');
        end

        function nonIntegerTimeStepsAreRejected(testCase)
            cfg = ThesisConfig.withOverrides(struct('TimeSteps', 2.5));

            testCase.verifyError(@() ThesisScenarioRunner.runTimeSeries(cfg), ...
                'ThesisScenarioRunner:InvalidTimeSteps');
        end

        function invalidDestinationNodeIsRejected(testCase)
            cfg = ThesisConfig.withOverrides(struct('DestinationNode', 33));

            testCase.verifyError(@() ThesisScenarioRunner.runSnapshot(cfg), ...
                'ThesisScenarioRunner:InvalidDestinationNode');
        end

        function unsupportedProfileIsRejected(testCase)
            cfg = ThesisConfig.withOverrides(struct('Profile', 'Unsupported'));

            testCase.verifyError(@() ThesisScenarioRunner.runSnapshot(cfg), ...
                'ThesisScenarioRunner:UnsupportedProfile');
            testCase.verifyError(@() ThesisScenarioRunner.runTimeSeries(cfg), ...
                'ThesisScenarioRunner:UnsupportedProfile');
        end
    end
end

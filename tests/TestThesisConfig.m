classdef TestThesisConfig < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function defaultConfigIsProviderNeutral(testCase)
            cfg = ThesisConfig.default();

            testCase.verifyEqual(cfg.Profile, 'WalkerLEO');
            testCase.verifyEqual(cfg.LinkModel, 'ControlledGraphWeights');
            testCase.verifyEqual(cfg.Routing.Baseline, 'ShortestPath');
            testCase.verifyEqual(cfg.Routing.Main, 'ReliabilityAware');
            testCase.verifyEqual(cfg.PrimaryMetrics, ...
                {'LatencyMs', 'Availability', 'EffectiveLatencyMs', 'RouteChanges'});
            testCase.verifyEqual(cfg.TimeSteps, 12);
            testCase.verifyEqual(cfg.PlaneCount, 4);
            testCase.verifyEqual(cfg.SatellitesPerPlane, 8);
            testCase.verifyTrue(cfg.InterPlaneLinks);
            testCase.verifyEqual(cfg.NodeCount, cfg.PlaneCount * cfg.SatellitesPerPlane);
            testCase.verifyEqual(cfg.ContactWindowModel, 'DeterministicInterPlane');
            testCase.verifyEqual(cfg.LinkQualityTimeMode, 'TimeVarying');
            testCase.verifyEqual(cfg.ContactDutyCycle, 0.65);
            testCase.verifyEqual(cfg.ReliabilityStressMode, 'InterPlaneShortcutRisk');
            testCase.verifyEqual(cfg.ShortcutRiskAvailability, 0.35);
        end

        function overrideConfigChangesOnlyRequestedFields(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'NodeCount', 24, ...
                'PlaneCount', 3, ...
                'SatellitesPerPlane', 8, ...
                'ContactDutyCycle', 0.5, ...
                'ShortcutRiskAvailability', 0.25, ...
                'ReliabilityWeight', 0.7, ...
                'TimeSteps', 5));

            testCase.verifyEqual(cfg.NodeCount, 24);
            testCase.verifyEqual(cfg.PlaneCount, 3);
            testCase.verifyEqual(cfg.SatellitesPerPlane, 8);
            testCase.verifyEqual(cfg.ContactDutyCycle, 0.5);
            testCase.verifyEqual(cfg.ShortcutRiskAvailability, 0.25);
            testCase.verifyEqual(cfg.ReliabilityWeight, 0.7);
            testCase.verifyEqual(cfg.TimeSteps, 5);
            testCase.verifyEqual(cfg.Profile, 'WalkerLEO');
        end
    end
end

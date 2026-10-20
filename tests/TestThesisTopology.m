classdef TestThesisTopology < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function walkerTopologyUsesPlaneAndSatelliteCounts(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'PlaneCount', 3, ...
                'SatellitesPerPlane', 5));

            G = ThesisTopology.buildWalkerLEOSnapshot(cfg, 1);

            testCase.verifyEqual(numnodes(G), 15);
        end

        function walkerTopologyClosesEachPlaneRing(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'PlaneCount', 2, ...
                'SatellitesPerPlane', 4, ...
                'InterPlaneLinks', false));

            G = ThesisTopology.buildWalkerLEOSnapshot(cfg, 1);

            testCase.verifyGreaterThan(findedge(G, 1, 2), 0);
            testCase.verifyGreaterThan(findedge(G, 2, 3), 0);
            testCase.verifyGreaterThan(findedge(G, 3, 4), 0);
            testCase.verifyGreaterThan(findedge(G, 4, 1), 0);
            testCase.verifyGreaterThan(findedge(G, 5, 6), 0);
            testCase.verifyGreaterThan(findedge(G, 8, 5), 0);
        end

        function walkerTopologyConnectsAdjacentPlanes(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'PlaneCount', 3, ...
                'SatellitesPerPlane', 4, ...
                'InterPlaneLinks', true, ...
                'ContactDutyCycle', 1));

            G = ThesisTopology.buildWalkerLEOSnapshot(cfg, 1);

            testCase.verifyGreaterThan(findedge(G, 1, 5), 0);
            testCase.verifyGreaterThan(findedge(G, 5, 9), 0);
            testCase.verifyGreaterThan(findedge(G, 9, 1), 0);
        end

        function twoPlaneTopologyDoesNotDuplicateInterPlaneEdges(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'PlaneCount', 2, ...
                'SatellitesPerPlane', 4, ...
                'InterPlaneLinks', true, ...
                'ContactDutyCycle', 1));

            G = ThesisTopology.buildWalkerLEOSnapshot(cfg, 1);
            uniqueEndNodes = unique(sort(G.Edges.EndNodes, 2), 'rows');

            testCase.verifyEqual(numedges(G), 12);
            testCase.verifyEqual(size(uniqueEndNodes, 1), numedges(G));
        end

        function contactWindowsChangeInterPlaneEdgeCountAcrossTime(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'PlaneCount', 4, ...
                'SatellitesPerPlane', 8, ...
                'InterPlaneLinks', true, ...
                'ContactDutyCycle', 0.5, ...
                'Seed', 13));

            first = ThesisTopology.buildWalkerLEOSnapshot(cfg, 1);
            second = ThesisTopology.buildWalkerLEOSnapshot(cfg, 2);
            intraEdgeCount = cfg.PlaneCount * cfg.SatellitesPerPlane;

            firstInterPlaneEdges = numedges(first) - intraEdgeCount;
            secondInterPlaneEdges = numedges(second) - intraEdgeCount;

            testCase.verifyNotEqual(firstInterPlaneEdges, secondInterPlaneEdges);
        end

        function contactWindowsPreserveIntraPlaneRings(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'PlaneCount', 2, ...
                'SatellitesPerPlane', 4, ...
                'InterPlaneLinks', true, ...
                'ContactDutyCycle', 0.25, ...
                'Seed', 13));

            G = ThesisTopology.buildWalkerLEOSnapshot(cfg, 2);

            testCase.verifyGreaterThan(findedge(G, 1, 2), 0);
            testCase.verifyGreaterThan(findedge(G, 2, 3), 0);
            testCase.verifyGreaterThan(findedge(G, 3, 4), 0);
            testCase.verifyGreaterThan(findedge(G, 4, 1), 0);
            testCase.verifyGreaterThan(findedge(G, 5, 6), 0);
            testCase.verifyGreaterThan(findedge(G, 8, 5), 0);
        end

        function reliabilityStressCreatesRiskyShortcutLinks(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'PlaneCount', 4, ...
                'SatellitesPerPlane', 8, ...
                'ContactDutyCycle', 1, ...
                'ShortcutRiskAvailability', 0.35, ...
                'Seed', 21));

            G = ThesisTopology.buildWalkerLEOSnapshot(cfg, 1);

            testCase.verifyTrue(any(G.Edges.Availability <= cfg.ShortcutRiskAvailability));
        end

        function walkerSnapshotIsDeterministicForSameTimeIndex(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'PlaneCount', 3, ...
                'SatellitesPerPlane', 4, ...
                'NodeCount', 12, ...
                'Seed', 7));

            first = ThesisTopology.buildWalkerLEOSnapshot(cfg, 3);
            second = ThesisTopology.buildWalkerLEOSnapshot(cfg, 3);

            testCase.verifyEqual(first.Edges.EndNodes, second.Edges.EndNodes);
            testCase.verifyEqual(first.Edges.LatencyMs, second.Edges.LatencyMs);
            testCase.verifyEqual(first.Edges.Availability, second.Edges.Availability);
        end

        function walkerSnapshotChangesLinkQualityAcrossTime(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'PlaneCount', 3, ...
                'SatellitesPerPlane', 4, ...
                'NodeCount', 12, ...
                'Seed', 7));

            first = ThesisTopology.buildWalkerLEOSnapshot(cfg, 1);
            second = ThesisTopology.buildWalkerLEOSnapshot(cfg, 2);

            sameLatency = isequal(first.Edges.LatencyMs, second.Edges.LatencyMs);
            sameAvailability = isequal(first.Edges.Availability, second.Edges.Availability);
            testCase.verifyFalse(sameLatency && sameAvailability);
        end

        function staticLinkQualityPreservesSharedEdgeWeights(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'PlaneCount', 4, ...
                'SatellitesPerPlane', 8, ...
                'NodeCount', 32, ...
                'ContactDutyCycle', 0.65, ...
                'LinkQualityTimeMode', 'StaticByEdge', ...
                'Seed', 7));

            first = ThesisTopology.buildWalkerLEOSnapshot(cfg, 1);
            second = ThesisTopology.buildWalkerLEOSnapshot(cfg, 2);
            firstEdges = sort(first.Edges.EndNodes, 2);
            secondEdges = sort(second.Edges.EndNodes, 2);
            [sharedEdges, firstIdx, secondIdx] = intersect( ...
                firstEdges, secondEdges, 'rows');

            testCase.verifyNotEmpty(sharedEdges);
            testCase.verifyEqual(first.Edges.LatencyMs(firstIdx), ...
                second.Edges.LatencyMs(secondIdx), 'AbsTol', 1e-12);
            testCase.verifyEqual(first.Edges.Availability(firstIdx), ...
                second.Edges.Availability(secondIdx), 'AbsTol', 1e-12);
        end

        function walkerSnapshotPreservesCallerRandomState(testCase)
            originalState = rng;
            cleanup = onCleanup(@() rng(originalState));
            rng(123);
            expectedState = rng;

            ThesisTopology.buildWalkerLEOSnapshot(ThesisConfig.default(), 1);

            testCase.verifyEqual(rng, expectedState);
            clear cleanup;
        end

        function inconsistentNodeCountIsRejected(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'PlaneCount', 4, ...
                'SatellitesPerPlane', 8, ...
                'NodeCount', 16));

            testCase.verifyError(@() ThesisTopology.buildWalkerLEOSnapshot(cfg, 1), ...
                'ThesisTopology:InconsistentNodeCount');
        end

        function invalidContactDutyCycleIsRejected(testCase)
            cfg = ThesisConfig.withOverrides(struct('ContactDutyCycle', 1.1));

            testCase.verifyError(@() ThesisTopology.buildWalkerLEOSnapshot(cfg, 1), ...
                'ThesisTopology:InvalidContactDutyCycle');
        end

        function invalidShortcutAvailabilityIsRejected(testCase)
            cfg = ThesisConfig.withOverrides(struct('ShortcutRiskAvailability', 1));

            testCase.verifyError(@() ThesisTopology.buildWalkerLEOSnapshot(cfg, 1), ...
                'ThesisTopology:InvalidShortcutRiskAvailability');
        end

        function invalidSeedIsRejected(testCase)
            cfg = ThesisConfig.withOverrides(struct('Seed', -1));

            testCase.verifyError(@() ThesisTopology.buildWalkerLEOSnapshot(cfg, 1), ...
                'ThesisTopology:InvalidSeed');
        end

        function invalidLinkQualityTimeModeIsRejected(testCase)
            cfg = ThesisConfig.withOverrides(struct( ...
                'LinkQualityTimeMode', 'UnsupportedMode'));

            testCase.verifyError(@() ThesisTopology.buildWalkerLEOSnapshot(cfg, 1), ...
                'ThesisTopology:InvalidLinkQualityTimeMode');
        end
    end
end

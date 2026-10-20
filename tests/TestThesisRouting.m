classdef TestThesisRouting < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function reliabilityAwareRoutingCanAvoidRiskyShortcut(testCase)
            G = graph([1 1 2], [2 3 3]);
            G.Edges.LatencyMs = [1; 3; 1];
            G.Edges.Availability = [0.50; 0.99; 0.99];

            shortest = ThesisRouting.shortestPath(G, 1, 3);
            reliable = ThesisRouting.reliabilityAwarePath(G, 1, 3, 0.9);

            testCase.verifyEqual(shortest, [1 2 3]);
            testCase.verifyEqual(reliable, [1 3]);
        end

        function normalizedReliabilityCostAvoidsFastVeryRiskyPath(testCase)
            G = graph([1 2 1 3], [2 4 3 4]);
            G.Edges.LatencyMs = [1; 1; 40; 40];
            G.Edges.Availability = [0.10; 0.99; 0.99; 0.99];

            shortest = ThesisRouting.shortestPath(G, 1, 4);
            reliable = ThesisRouting.reliabilityAwarePath(G, 1, 4, 0.9);

            testCase.verifyEqual(shortest, [1 2 4]);
            testCase.verifyEqual(reliable, [1 3 4]);
        end

        function pathMetricsExposePrimaryThesisQuantities(testCase)
            G = graph([1 2], [2 3]);
            G.Edges.LatencyMs = [4; 6];
            G.Edges.Availability = [0.9; 0.8];

            metrics = ThesisMetrics.evaluatePath(G, [1 2 3]);

            testCase.verifyEqual(metrics.LatencyMs, 10);
            testCase.verifyEqual(metrics.Availability, 0.72, 'AbsTol', 1e-12);
            testCase.verifyEqual(metrics.EffectiveLatencyMs, 10 / 0.72, 'AbsTol', 1e-12);
            testCase.verifyEqual(metrics.HopCount, 2);
        end

        function unreachableDestinationProducesNoRouteError(testCase)
            G = graph([1 3], [2 4]);
            G.Edges.LatencyMs = [1; 1];
            G.Edges.Availability = [0.95; 0.95];

            testCase.verifyError(@() ThesisRouting.shortestPath(G, 1, 4), ...
                'ThesisRouting:NoRoute');
            testCase.verifyError(@() ThesisRouting.reliabilityAwarePath(G, 1, 4, 0.5), ...
                'ThesisRouting:NoRoute');
        end

        function reliabilityWeightOutsideUnitIntervalIsRejected(testCase)
            G = graph([1 2], [2 3]);
            G.Edges.LatencyMs = [1; 1];
            G.Edges.Availability = [0.95; 0.95];

            testCase.verifyError(@() ThesisRouting.reliabilityAwarePath(G, 1, 3, 1.1), ...
                'ThesisRouting:InvalidReliabilityWeight');
        end

        function stabilityAwareRoutingKeepsNearOptimalPreviousPath(testCase)
            G = graph([1 2 1 3], [2 4 3 4]);
            G.Edges.LatencyMs = zeros(numedges(G), 1);
            G.Edges.LatencyMs(findedge(G, 1, 2)) = 1;
            G.Edges.LatencyMs(findedge(G, 2, 4)) = 1;
            G.Edges.LatencyMs(findedge(G, 1, 3)) = 1.05;
            G.Edges.LatencyMs(findedge(G, 3, 4)) = 1.05;
            G.Edges.Availability = [0.99; 0.99; 0.99; 0.99];

            [path, decision] = ThesisRouting.stabilityAwarePath( ...
                G, 1, 4, 0, [1 3 4], 0.10);

            testCase.verifyEqual(path, [1 3 4]);
            testCase.verifyTrue(decision.KeptPreviousPath);
            testCase.verifyEqual(decision.Reason, "WithinHysteresis");
            testCase.verifyGreaterThan(decision.RelativeCostGap, 0);
        end

        function stabilityAwareRoutingSwitchesWhenCostGapIsLarge(testCase)
            G = graph([1 2 1 3], [2 4 3 4]);
            G.Edges.LatencyMs = zeros(numedges(G), 1);
            G.Edges.LatencyMs(findedge(G, 1, 2)) = 1;
            G.Edges.LatencyMs(findedge(G, 2, 4)) = 1;
            G.Edges.LatencyMs(findedge(G, 1, 3)) = 2;
            G.Edges.LatencyMs(findedge(G, 3, 4)) = 2;
            G.Edges.Availability = [0.99; 0.99; 0.99; 0.99];

            [path, decision] = ThesisRouting.stabilityAwarePath( ...
                G, 1, 4, 0, [1 3 4], 0.10);

            testCase.verifyEqual(path, [1 2 4]);
            testCase.verifyFalse(decision.KeptPreviousPath);
            testCase.verifyEqual(decision.Reason, "CostGapExceeded");
        end

        function stabilityAwareRoutingSwitchesWhenOldRouteBreaks(testCase)
            G = graph([1 2 3], [2 4 4]);
            G.Edges.LatencyMs = [1; 1; 1];
            G.Edges.Availability = [0.99; 0.99; 0.99];

            [path, decision] = ThesisRouting.stabilityAwarePath( ...
                G, 1, 4, 0.5, [1 3 4], 0.50);

            testCase.verifyEqual(path, [1 2 4]);
            testCase.verifyFalse(decision.KeptPreviousPath);
            testCase.verifyEqual( ...
                decision.Reason, "PreviousPathUnavailable");
        end

        function invalidHysteresisToleranceIsRejected(testCase)
            G = graph([1 2], [2 3]);
            G.Edges.LatencyMs = [1; 1];
            G.Edges.Availability = [0.95; 0.95];

            testCase.verifyError( ...
                @() ThesisRouting.stabilityAwarePath( ...
                G, 1, 3, 0.5, [1 2 3], -0.01), ...
                'ThesisRouting:InvalidHysteresisTolerance');
        end
    end
end

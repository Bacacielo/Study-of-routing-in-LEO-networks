classdef TestThesisMetrics < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function repeatedRoutesHaveNoRouteChanges(testCase)
            paths = {[1 2 3], [1 2 3], [1 2 3]};

            changes = ThesisMetrics.countRouteChanges(paths);

            testCase.verifyEqual(changes, 0);
        end

        function changedRouteIncrementsRouteChanges(testCase)
            paths = {[1 2 3], [1 2 3], [1 4 3]};

            changes = ThesisMetrics.countRouteChanges(paths);

            testCase.verifyEqual(changes, 1);
        end

        function pathWithFewerThanTwoNodesIsRejected(testCase)
            G = graph([1 2], [2 3]);
            G.Edges.LatencyMs = [1; 1];
            G.Edges.Availability = [0.9; 0.9];

            testCase.verifyError(@() ThesisMetrics.evaluatePath(G, 1), ...
                'ThesisMetrics:InvalidPath');
        end

        function pathContainingMissingEdgeIsRejected(testCase)
            G = graph([1 2], [2 3]);
            G.Edges.LatencyMs = [1; 1];
            G.Edges.Availability = [0.9; 0.9];

            testCase.verifyError(@() ThesisMetrics.evaluatePath(G, [1 3]), ...
                'ThesisMetrics:InvalidPath');
        end
    end
end

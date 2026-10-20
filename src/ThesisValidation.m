classdef ThesisValidation
    % THESISVALIDATION - Lightweight validation checks for the thesis workflow.

    methods (Static)
        function summary = runBasicChecks()
            result = ThesisScenarioRunner.runSnapshot(ThesisConfig.default());

            checks = [
                result.Graph.NodeCount > 0
                result.Graph.EdgeCount > 0
                result.Baseline.LatencyMs > 0
                result.Reliable.LatencyMs > 0
                result.Baseline.Availability >= 0 && result.Baseline.Availability <= 1
                result.Reliable.Availability >= 0 && result.Reliable.Availability <= 1
            ];

            summary = struct();
            summary.Passed = sum(checks);
            summary.Total = numel(checks);
            summary.AllPassed = all(checks);
        end
    end
end

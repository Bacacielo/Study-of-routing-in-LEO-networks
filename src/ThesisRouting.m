classdef ThesisRouting
    % THESISROUTING - Routing algorithms used by the thesis experiments.

    methods (Static)
        function path = shortestPath(G, sourceNode, destinationNode)
            workGraph = G;
            workGraph.Edges.Weight = G.Edges.LatencyMs;
            path = shortestpath(workGraph, sourceNode, destinationNode);
            if isempty(path)
                error('ThesisRouting:NoRoute', ...
                    'No route exists between the requested source and destination nodes.');
            end
        end

        function path = reliabilityAwarePath(G, sourceNode, destinationNode, reliabilityWeight)
            if nargin < 4 || isempty(reliabilityWeight)
                reliabilityWeight = 0.5;
            end

            edgeWeights = ThesisRouting.reliabilityAwareEdgeWeights( ...
                G, reliabilityWeight);
            workGraph = G;
            workGraph.Edges.Weight = edgeWeights;
            path = shortestpath(workGraph, sourceNode, destinationNode);
            if isempty(path)
                error('ThesisRouting:NoRoute', ...
                    'No route exists between the requested source and destination nodes.');
            end
        end

        function [path, decision] = stabilityAwarePath( ...
                G, sourceNode, destinationNode, reliabilityWeight, ...
                previousPath, hysteresisTolerance)
            if nargin < 4 || isempty(reliabilityWeight)
                reliabilityWeight = 0.5;
            end
            if nargin < 5
                previousPath = [];
            end
            if nargin < 6 || isempty(hysteresisTolerance)
                hysteresisTolerance = 0.10;
            end
            if ~isnumeric(hysteresisTolerance) || ...
                    ~isreal(hysteresisTolerance) || ...
                    ~isscalar(hysteresisTolerance) || ...
                    ~isfinite(hysteresisTolerance) || ...
                    hysteresisTolerance < 0
                error('ThesisRouting:InvalidHysteresisTolerance', ...
                    ['Hysteresis tolerance must be a finite ' ...
                    'nonnegative scalar.']);
            end

            edgeWeights = ThesisRouting.reliabilityAwareEdgeWeights( ...
                G, reliabilityWeight);
            workGraph = G;
            workGraph.Edges.Weight = edgeWeights;
            optimalPath = shortestpath( ...
                workGraph, sourceNode, destinationNode);
            if isempty(optimalPath)
                error('ThesisRouting:NoRoute', ...
                    'No route exists between the requested source and destination nodes.');
            end
            optimalCost = ThesisRouting.pathCost( ...
                G, optimalPath, edgeWeights);

            decision = struct( ...
                'KeptPreviousPath', false, ...
                'Reason', "InitialOptimal", ...
                'OptimalPath', optimalPath, ...
                'OptimalCost', optimalCost, ...
                'PreviousCost', NaN, ...
                'RelativeCostGap', NaN);
            if isempty(previousPath)
                path = optimalPath;
                return;
            end

            if ~isnumeric(previousPath) || ~isreal(previousPath) || ...
                    ~isvector(previousPath) || ...
                    any(~isfinite(previousPath)) || ...
                    any(previousPath ~= floor(previousPath)) || ...
                    numel(previousPath) < 2 || ...
                    previousPath(1) ~= sourceNode || ...
                    previousPath(end) ~= destinationNode
                error('ThesisRouting:InvalidPreviousPath', ...
                    ['Previous path must be an integer route with the ' ...
                    'requested source and destination endpoints.']);
            end
            previousPath = previousPath(:)';
            previousEdgeIds = ThesisRouting.pathEdgeIds( ...
                G, previousPath);
            if any(previousEdgeIds == 0)
                path = optimalPath;
                decision.Reason = "PreviousPathUnavailable";
                decision.PreviousCost = Inf;
                decision.RelativeCostGap = Inf;
                return;
            end

            previousCost = sum(edgeWeights(previousEdgeIds));
            relativeCostGap = ...
                (previousCost - optimalCost) / max(optimalCost, realmin);
            decision.PreviousCost = previousCost;
            decision.RelativeCostGap = relativeCostGap;

            comparisonTolerance = 10 * eps(max(previousCost, optimalCost));
            if previousCost <= ...
                    (1 + hysteresisTolerance) * optimalCost + ...
                    comparisonTolerance
                path = previousPath;
                decision.KeptPreviousPath = true;
                decision.Reason = "WithinHysteresis";
            else
                path = optimalPath;
                decision.Reason = "CostGapExceeded";
            end
        end

        function edgeWeights = reliabilityAwareEdgeWeights( ...
                G, reliabilityWeight)
            if ~isnumeric(reliabilityWeight) || ...
                    ~isreal(reliabilityWeight) || ...
                    ~isscalar(reliabilityWeight) || ...
                    ~isfinite(reliabilityWeight) || ...
                    reliabilityWeight < 0 || reliabilityWeight > 1
                error('ThesisRouting:InvalidReliabilityWeight', ...
                    'Reliability weight must be a finite scalar in [0, 1].');
            end
            latency = G.Edges.LatencyMs;
            availability = min(max(G.Edges.Availability, realmin), 1);
            risk = -log(availability);
            latencyTerm = ThesisRouting.normalizePositive(latency);
            riskTerm = ThesisRouting.normalizePositive(risk);
            edgeWeights = ...
                (1 - reliabilityWeight) .* latencyTerm + ...
                reliabilityWeight .* riskTerm;
        end

        function values = normalizePositive(values)
            scale = median(values(values > 0));
            if isempty(scale) || ~isfinite(scale) || scale <= 0
                scale = 1;
            end

            values = values ./ scale;
        end

        function cost = pathCost(G, path, edgeWeights)
            edgeIds = ThesisRouting.pathEdgeIds(G, path);
            if any(edgeIds == 0)
                cost = Inf;
            else
                cost = sum(edgeWeights(edgeIds));
            end
        end

        function edgeIds = pathEdgeIds(G, path)
            edgeIds = zeros(numel(path) - 1, 1);
            for pathIndex = 1:numel(edgeIds)
                edgeIds(pathIndex) = findedge( ...
                    G, path(pathIndex), path(pathIndex + 1));
            end
        end
    end
end

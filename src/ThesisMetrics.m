classdef ThesisMetrics
    % THESISMETRICS - Primary metrics for LEO routing thesis comparisons.

    methods (Static)
        function metrics = evaluatePath(G, path)
            if numel(path) < 2
                error('ThesisMetrics:InvalidPath', 'A route must contain at least two nodes.');
            end

            edgeIds = zeros(numel(path) - 1, 1);
            for idx = 1:numel(edgeIds)
                edgeIds(idx) = findedge(G, path(idx), path(idx + 1));
            end

            if any(edgeIds == 0)
                error('ThesisMetrics:InvalidPath', 'Route contains a hop that is not an edge.');
            end

            metrics = struct();
            metrics.Path = path;
            metrics.HopCount = numel(path) - 1;
            metrics.LatencyMs = sum(G.Edges.LatencyMs(edgeIds));
            metrics.Availability = prod(G.Edges.Availability(edgeIds));
            metrics.EffectiveLatencyMs = metrics.LatencyMs / max(metrics.Availability, realmin);
        end

        function routeChanges = countRouteChanges(paths)
            if isempty(paths)
                routeChanges = 0;
                return;
            end

            routeChanges = 0;
            previousPath = paths{1};
            for idx = 2:numel(paths)
                currentPath = paths{idx};
                if numel(currentPath) ~= numel(previousPath) || any(currentPath ~= previousPath)
                    routeChanges = routeChanges + 1;
                end
                previousPath = currentPath;
            end
        end
    end
end

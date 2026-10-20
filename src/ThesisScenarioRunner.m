classdef ThesisScenarioRunner
    % THESISSCENARIORUNNER - Small experiment runner for the thesis core.

    methods (Static)
        function result = runSnapshot(cfg)
            if nargin < 1 || isempty(cfg)
                cfg = ThesisConfig.default();
            end

            switch cfg.Profile
                case 'WalkerLEO'
                    G = ThesisTopology.buildWalkerLEO(cfg);
                otherwise
                    error('ThesisScenarioRunner:UnsupportedProfile', ...
                        'Unsupported profile "%s". Active profile is WalkerLEO.', cfg.Profile);
            end

            [sourceNode, destinationNode] = ThesisScenarioRunner.resolveRouteEndpoints( ...
                cfg, numnodes(G));

            baselinePath = ThesisRouting.shortestPath(G, sourceNode, destinationNode);
            reliablePath = ThesisRouting.reliabilityAwarePath( ...
                G, sourceNode, destinationNode, cfg.ReliabilityWeight);

            result = struct();
            result.Config = cfg;
            result.Graph = struct( ...
                'NodeCount', numnodes(G), ...
                'EdgeCount', numedges(G), ...
                'SourceNode', sourceNode, ...
                'DestinationNode', destinationNode);
            result.Baseline = ThesisMetrics.evaluatePath(G, baselinePath);
            result.Reliable = ThesisMetrics.evaluatePath(G, reliablePath);
        end

        function result = runTimeSeries(cfg)
            if nargin < 1 || isempty(cfg)
                cfg = ThesisConfig.default();
            end

            if ~isfield(cfg, 'TimeSteps') || ~isnumeric(cfg.TimeSteps) || ...
                    ~isreal(cfg.TimeSteps) || ~isscalar(cfg.TimeSteps) || ...
                    ~isfinite(cfg.TimeSteps) || cfg.TimeSteps < 1 || ...
                    cfg.TimeSteps ~= floor(cfg.TimeSteps)
                error('ThesisScenarioRunner:InvalidTimeSteps', ...
                    'TimeSteps must be a positive integer scalar.');
            end
            timeSteps = cfg.TimeSteps;
            firstSnapshot = ThesisScenarioRunner.runSnapshotAtTime(cfg, 1);
            snapshots = repmat(firstSnapshot, 1, timeSteps);
            baselinePaths = cell(1, timeSteps);
            reliablePaths = cell(1, timeSteps);

            for timeIndex = 1:timeSteps
                if timeIndex == 1
                    snapshot = firstSnapshot;
                else
                    snapshot = ThesisScenarioRunner.runSnapshotAtTime(cfg, timeIndex);
                    snapshots(timeIndex) = snapshot;
                end
                baselinePaths{timeIndex} = snapshot.Baseline.Path;
                reliablePaths{timeIndex} = snapshot.Reliable.Path;
            end

            baselineLatency = arrayfun(@(item) item.Baseline.LatencyMs, snapshots);
            reliableLatency = arrayfun(@(item) item.Reliable.LatencyMs, snapshots);
            baselineEffectiveLatency = arrayfun(@(item) item.Baseline.EffectiveLatencyMs, snapshots);
            reliableEffectiveLatency = arrayfun(@(item) item.Reliable.EffectiveLatencyMs, snapshots);
            baselineAvailability = arrayfun(@(item) item.Baseline.Availability, snapshots);
            reliableAvailability = arrayfun(@(item) item.Reliable.Availability, snapshots);

            result = struct();
            result.Config = cfg;
            result.Snapshots = snapshots;
            result.Summary = struct( ...
                'TimeSteps', timeSteps, ...
                'BaselineMeanLatencyMs', mean(baselineLatency), ...
                'ReliableMeanLatencyMs', mean(reliableLatency), ...
                'BaselineMeanAvailability', mean(baselineAvailability), ...
                'ReliableMeanAvailability', mean(reliableAvailability), ...
                'ReliableAvailabilityGain', mean(reliableAvailability) - mean(baselineAvailability), ...
                'ReliableLatencyPenaltyMs', mean(reliableLatency) - mean(baselineLatency), ...
                'BaselineMeanEffectiveLatencyMs', mean(baselineEffectiveLatency), ...
                'ReliableMeanEffectiveLatencyMs', mean(reliableEffectiveLatency), ...
                'EffectiveLatencyImprovementMs', mean(baselineEffectiveLatency) - mean(reliableEffectiveLatency), ...
                'BaselineRouteChanges', ThesisMetrics.countRouteChanges(baselinePaths), ...
                'ReliableRouteChanges', ThesisMetrics.countRouteChanges(reliablePaths));
        end

        function result = runSnapshotAtTime(cfg, timeIndex)
            switch cfg.Profile
                case 'WalkerLEO'
                    G = ThesisTopology.buildWalkerLEOSnapshot(cfg, timeIndex);
                otherwise
                    error('ThesisScenarioRunner:UnsupportedProfile', ...
                        'Unsupported profile "%s". Active profile is WalkerLEO.', cfg.Profile);
            end

            [sourceNode, destinationNode] = ThesisScenarioRunner.resolveRouteEndpoints( ...
                cfg, numnodes(G));

            baselinePath = ThesisRouting.shortestPath(G, sourceNode, destinationNode);
            reliablePath = ThesisRouting.reliabilityAwarePath( ...
                G, sourceNode, destinationNode, cfg.ReliabilityWeight);

            result = struct();
            result.TimeIndex = timeIndex;
            result.Graph = struct( ...
                'NodeCount', numnodes(G), ...
                'EdgeCount', numedges(G), ...
                'SourceNode', sourceNode, ...
                'DestinationNode', destinationNode);
            result.Baseline = ThesisMetrics.evaluatePath(G, baselinePath);
            result.Reliable = ThesisMetrics.evaluatePath(G, reliablePath);
        end
    end

    methods (Static, Access = private)
        function [sourceNode, destinationNode] = resolveRouteEndpoints(cfg, nodeCount)
            sourceNode = cfg.SourceNode;
            destinationNode = cfg.DestinationNode;

            if ~isnumeric(sourceNode) || ~isscalar(sourceNode) || ~isfinite(sourceNode) || ...
                    sourceNode ~= floor(sourceNode) || sourceNode < 1 || sourceNode > nodeCount
                error('ThesisScenarioRunner:InvalidSourceNode', ...
                    'SourceNode must be an integer in the current topology.');
            end
            if ~isnumeric(destinationNode) || ~isscalar(destinationNode) || ~isfinite(destinationNode) || ...
                    destinationNode ~= floor(destinationNode) || destinationNode < 1 || destinationNode > nodeCount
                error('ThesisScenarioRunner:InvalidDestinationNode', ...
                    'DestinationNode must be an integer in the current topology.');
            end
            if sourceNode == destinationNode
                error('ThesisScenarioRunner:IdenticalEndpoints', ...
                    'SourceNode and DestinationNode must be different.');
            end
        end
    end
end

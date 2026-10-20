classdef ThesisReliabilityStressStudy
    % THESISRELIABILITYSTRESSSTUDY - Reliability-stress ablation experiments.

    methods (Static)
        function sweep = defaultSweep()
            sweep = ThesisExperimentSuite.defaultMatrix();
            sweep.ShortcutRiskAvailabilities = [0.20 0.35 0.50 0.60 0.70 0.80 0.90];
            sweep.IncludeNoStressControl = true;
        end

        function results = run(sweep)
            if nargin < 1 || isempty(sweep)
                sweep = ThesisReliabilityStressStudy.defaultSweep();
            end
            sweep = ThesisReliabilityStressStudy.validateSweep(sweep);

            stressRowCount = size(sweep.Constellations, 1) * ...
                numel(sweep.ContactDutyCycles) * ...
                numel(sweep.ShortcutRiskAvailabilities) * ...
                numel(sweep.ReliabilityWeights) * ...
                numel(sweep.Seeds) * ...
                size(sweep.RoutePairs, 1);
            controlRowCount = 0;
            if sweep.IncludeNoStressControl
                controlRowCount = size(sweep.Constellations, 1) * ...
                    numel(sweep.ContactDutyCycles) * ...
                    numel(sweep.ReliabilityWeights) * ...
                    numel(sweep.Seeds) * ...
                    size(sweep.RoutePairs, 1);
            end

            rows = repmat( ...
                ThesisReliabilityStressStudy.emptyResultRow(), ...
                stressRowCount + controlRowCount, 1);
            rowIndex = 1;

            for constellationIdx = 1:size(sweep.Constellations, 1)
                planeCount = sweep.Constellations(constellationIdx, 1);
                satsPerPlane = sweep.Constellations(constellationIdx, 2);
                for dutyCycle = sweep.ContactDutyCycles
                    for reliabilityWeight = sweep.ReliabilityWeights
                        for seed = sweep.Seeds
                            for routePairIdx = 1:size(sweep.RoutePairs, 1)
                                routePair = sweep.RoutePairs(routePairIdx, :);
                                for riskAvailability = sweep.ShortcutRiskAvailabilities
                                    cfg = ThesisReliabilityStressStudy.configuration( ...
                                        planeCount, satsPerPlane, dutyCycle, ...
                                        riskAvailability, reliabilityWeight, seed, ...
                                        routePair, sweep.TimeSteps, true);
                                    rows(rowIndex) = ...
                                        ThesisReliabilityStressStudy.runConfiguration(cfg, true);
                                    rowIndex = rowIndex + 1;
                                end

                                if sweep.IncludeNoStressControl
                                    cfg = ThesisReliabilityStressStudy.configuration( ...
                                        planeCount, satsPerPlane, dutyCycle, ...
                                        NaN, reliabilityWeight, seed, ...
                                        routePair, sweep.TimeSteps, false);
                                    rows(rowIndex) = ...
                                        ThesisReliabilityStressStudy.runConfiguration(cfg, false);
                                    rowIndex = rowIndex + 1;
                                end
                            end
                        end
                    end
                end
            end

            results = struct2table(rows);
        end

        function sweep = validateSweep(sweep)
            if ~isstruct(sweep) || ~isscalar(sweep)
                error('ThesisReliabilityStressStudy:InvalidSweep', ...
                    'Reliability-stress sweep must be a scalar struct.');
            end

            includeNoStressControl = true;
            if isfield(sweep, 'IncludeNoStressControl')
                includeNoStressControl = sweep.IncludeNoStressControl;
                sweep = rmfield(sweep, 'IncludeNoStressControl');
            end
            if ~(islogical(includeNoStressControl) && isscalar(includeNoStressControl))
                error('ThesisReliabilityStressStudy:InvalidControlFlag', ...
                    'IncludeNoStressControl must be a logical scalar.');
            end

            sweep = ThesisExperimentSuite.withMatrixDefaults(sweep);
            sweep.IncludeNoStressControl = includeNoStressControl;
        end
    end

    methods (Static, Access = private)
        function cfg = configuration(planeCount, satsPerPlane, dutyCycle, ...
                riskAvailability, reliabilityWeight, seed, routePair, ...
                timeSteps, stressEnabled)
            if stressEnabled
                stressMode = 'InterPlaneShortcutRisk';
            else
                stressMode = 'None';
            end

            cfg = ThesisConfig.withOverrides(struct( ...
                'PlaneCount', planeCount, ...
                'SatellitesPerPlane', satsPerPlane, ...
                'NodeCount', planeCount * satsPerPlane, ...
                'ContactDutyCycle', dutyCycle, ...
                'ReliabilityStressMode', stressMode, ...
                'ShortcutRiskAvailability', riskAvailability, ...
                'ReliabilityWeight', reliabilityWeight, ...
                'TimeSteps', timeSteps, ...
                'Seed', seed, ...
                'SourceNode', routePair(1), ...
                'DestinationNode', routePair(2)));
        end

        function row = runConfiguration(cfg, stressEnabled)
            runResult = ThesisScenarioRunner.runTimeSeries(cfg);
            baseRow = ThesisExperimentSuite.resultRowFromSummary( ...
                cfg, runResult.Summary);
            diagnostics = ThesisReliabilityStressStudy.snapshotDiagnostics( ...
                cfg, runResult.Snapshots, stressEnabled);

            row = ThesisReliabilityStressStudy.emptyResultRow();
            baseNames = fieldnames(baseRow);
            for idx = 1:numel(baseNames)
                name = baseNames{idx};
                row.(name) = baseRow.(name);
            end
            row.StressEnabled = stressEnabled;
            row.StressMode = string(cfg.ReliabilityStressMode);
            row.SnapshotCount = diagnostics.SnapshotCount;
            row.PathDifferenceSnapshotCount = diagnostics.PathDifferenceSnapshotCount;
            row.PathDifferenceRate = diagnostics.PathDifferenceRate;
            row.BaselineRiskyPathSnapshotCount = ...
                diagnostics.BaselineRiskyPathSnapshotCount;
            row.BaselineRiskyPathRate = diagnostics.BaselineRiskyPathRate;
            row.ReliableRiskyPathSnapshotCount = ...
                diagnostics.ReliableRiskyPathSnapshotCount;
            row.ReliableRiskyPathRate = diagnostics.ReliableRiskyPathRate;
            row.MeanEffectiveImprovementWhenBaselineRiskyMs = ...
                diagnostics.MeanEffectiveImprovementWhenBaselineRiskyMs;
            row.MeanEffectiveImprovementWhenBaselineNotRiskyMs = ...
                diagnostics.MeanEffectiveImprovementWhenBaselineNotRiskyMs;
        end

        function diagnostics = snapshotDiagnostics(cfg, snapshots, stressEnabled)
            snapshotCount = numel(snapshots);
            pathDifference = false(snapshotCount, 1);
            baselineRisky = false(snapshotCount, 1);
            reliableRisky = false(snapshotCount, 1);
            effectiveImprovement = zeros(snapshotCount, 1);

            for timeIndex = 1:snapshotCount
                snapshot = snapshots(timeIndex);
                baselinePath = snapshot.Baseline.Path;
                reliablePath = snapshot.Reliable.Path;
                pathDifference(timeIndex) = ~isequal(baselinePath, reliablePath);
                effectiveImprovement(timeIndex) = ...
                    snapshot.Baseline.EffectiveLatencyMs - ...
                    snapshot.Reliable.EffectiveLatencyMs;

                if stressEnabled
                    G = ThesisTopology.buildWalkerLEOSnapshot(cfg, timeIndex);
                    riskyEdges = G.Edges.IsInterPlane & ...
                        G.Edges.Availability <= cfg.ShortcutRiskAvailability + 1e-12;
                    baselineRisky(timeIndex) = ...
                        ThesisReliabilityStressStudy.pathUsesEdges( ...
                        G, baselinePath, riskyEdges);
                    reliableRisky(timeIndex) = ...
                        ThesisReliabilityStressStudy.pathUsesEdges( ...
                        G, reliablePath, riskyEdges);
                end
            end

            diagnostics = struct();
            diagnostics.SnapshotCount = snapshotCount;
            diagnostics.PathDifferenceSnapshotCount = sum(pathDifference);
            diagnostics.PathDifferenceRate = mean(pathDifference);
            diagnostics.BaselineRiskyPathSnapshotCount = sum(baselineRisky);
            diagnostics.BaselineRiskyPathRate = mean(baselineRisky);
            diagnostics.ReliableRiskyPathSnapshotCount = sum(reliableRisky);
            diagnostics.ReliableRiskyPathRate = mean(reliableRisky);
            diagnostics.MeanEffectiveImprovementWhenBaselineRiskyMs = ...
                ThesisReliabilityStressStudy.conditionalMean( ...
                effectiveImprovement, baselineRisky);
            diagnostics.MeanEffectiveImprovementWhenBaselineNotRiskyMs = ...
                ThesisReliabilityStressStudy.conditionalMean( ...
                effectiveImprovement, ~baselineRisky);
        end

        function usesSelectedEdge = pathUsesEdges(G, path, selectedEdges)
            edgeIds = zeros(numel(path) - 1, 1);
            for idx = 1:numel(edgeIds)
                edgeIds(idx) = findedge(G, path(idx), path(idx + 1));
            end
            usesSelectedEdge = any(selectedEdges(edgeIds));
        end

        function value = conditionalMean(values, condition)
            if any(condition)
                value = mean(values(condition));
            else
                value = NaN;
            end
        end

        function row = emptyResultRow()
            row = ThesisExperimentSuite.emptyResultRow();
            row.StressEnabled = false;
            row.StressMode = "";
            row.SnapshotCount = 0;
            row.PathDifferenceSnapshotCount = 0;
            row.PathDifferenceRate = 0;
            row.BaselineRiskyPathSnapshotCount = 0;
            row.BaselineRiskyPathRate = 0;
            row.ReliableRiskyPathSnapshotCount = 0;
            row.ReliableRiskyPathRate = 0;
            row.MeanEffectiveImprovementWhenBaselineRiskyMs = NaN;
            row.MeanEffectiveImprovementWhenBaselineNotRiskyMs = NaN;
        end
    end
end

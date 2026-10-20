classdef ThesisExperimentSuite
    % THESISEXPERIMENTSUITE - Repeatable parameter sweeps for thesis results.

    methods (Static)
        function matrix = defaultMatrix()
            matrix = struct();
            matrix.Constellations = [4 8; 6 12; 8 20];
            matrix.ContactDutyCycles = [0.45 0.65 0.85];
            matrix.ShortcutRiskAvailabilities = [0.20 0.35 0.50];
            matrix.ReliabilityWeights = [0.3 0.6 0.9];
            matrix.Seeds = 42;
            matrix.RoutePairs = [1 16];
            matrix.TimeSteps = 12;
        end

        function results = runMatrix(matrix)
            if nargin < 1 || isempty(matrix)
                matrix = ThesisExperimentSuite.defaultMatrix();
            end

            matrix = ThesisExperimentSuite.withMatrixDefaults(matrix);
            rowCount = size(matrix.Constellations, 1) * ...
                numel(matrix.ContactDutyCycles) * ...
                numel(matrix.ShortcutRiskAvailabilities) * ...
                numel(matrix.ReliabilityWeights) * ...
                numel(matrix.Seeds) * ...
                size(matrix.RoutePairs, 1);
            rows = repmat(ThesisExperimentSuite.emptyResultRow(), rowCount, 1);
            rowIndex = 1;

            for constellationIdx = 1:size(matrix.Constellations, 1)
                planeCount = matrix.Constellations(constellationIdx, 1);
                satsPerPlane = matrix.Constellations(constellationIdx, 2);

                for dutyCycle = matrix.ContactDutyCycles
                    for riskAvailability = matrix.ShortcutRiskAvailabilities
                        for reliabilityWeight = matrix.ReliabilityWeights
                            for seed = matrix.Seeds
                                for routePairIdx = 1:size(matrix.RoutePairs, 1)
                                    routePair = matrix.RoutePairs(routePairIdx, :);
                                    cfg = ThesisConfig.withOverrides(struct( ...
                                        'PlaneCount', planeCount, ...
                                        'SatellitesPerPlane', satsPerPlane, ...
                                        'NodeCount', planeCount * satsPerPlane, ...
                                        'ContactDutyCycle', dutyCycle, ...
                                        'ShortcutRiskAvailability', riskAvailability, ...
                                        'ReliabilityWeight', reliabilityWeight, ...
                                        'TimeSteps', matrix.TimeSteps, ...
                                        'Seed', seed, ...
                                        'SourceNode', routePair(1), ...
                                        'DestinationNode', routePair(2)));
                                    runResult = ThesisScenarioRunner.runTimeSeries(cfg);
                                    rows(rowIndex) = ThesisExperimentSuite.resultRowFromSummary( ...
                                        cfg, runResult.Summary);
                                    rowIndex = rowIndex + 1;
                                end
                            end
                        end
                    end
                end
            end

            results = struct2table(rows);
        end

        function outputPath = writeTable(results, outputPath)
            outputDir = fileparts(outputPath);
            if ~isempty(outputDir) && ~isfolder(outputDir)
                mkdir(outputDir);
            end

            writetable(results, outputPath);
        end

        function matrix = withMatrixDefaults(matrix)
            if ~isstruct(matrix) || ~isscalar(matrix)
                error('ThesisExperimentSuite:InvalidMatrix', ...
                    'Experiment matrix must be a scalar struct.');
            end

            allowedNames = [fieldnames(ThesisExperimentSuite.defaultMatrix()); {'Seed'}];
            unknownNames = setdiff(fieldnames(matrix), allowedNames);
            if ~isempty(unknownNames)
                error('ThesisExperimentSuite:InvalidMatrixField', ...
                    'Unknown experiment matrix field: %s.', unknownNames{1});
            end

            if isfield(matrix, 'Seeds') && isfield(matrix, 'Seed') && ...
                    ~isequal(matrix.Seeds, matrix.Seed)
                error('ThesisExperimentSuite:ConflictingSeedFields', ...
                    'Seed and Seeds must not specify different values.');
            end
            if ~isfield(matrix, 'Seeds') && isfield(matrix, 'Seed')
                matrix.Seeds = matrix.Seed;
            end
            if isfield(matrix, 'Seed')
                matrix = rmfield(matrix, 'Seed');
            end

            defaults = ThesisExperimentSuite.defaultMatrix();
            defaultNames = fieldnames(defaults);
            for idx = 1:numel(defaultNames)
                name = defaultNames{idx};
                if ~isfield(matrix, name)
                    matrix.(name) = defaults.(name);
                end
            end

            if isvector(matrix.Constellations) && numel(matrix.Constellations) == 2
                matrix.Constellations = reshape(matrix.Constellations, 1, 2);
            end
            if ~isnumeric(matrix.Constellations) || ~isreal(matrix.Constellations) || ...
                    isempty(matrix.Constellations) || size(matrix.Constellations, 2) ~= 2 || ...
                    any(~isfinite(matrix.Constellations), 'all') || ...
                    any(matrix.Constellations ~= floor(matrix.Constellations), 'all') || ...
                    any(matrix.Constellations(:, 1) < 2) || any(matrix.Constellations(:, 2) < 3)
                error('ThesisExperimentSuite:InvalidConstellations', ...
                    ['Constellations must be a nonempty Nx2 numeric matrix with at least ', ...
                    'two planes and three satellites per plane.']);
            end

            matrix.ContactDutyCycles = ThesisExperimentSuite.validateSweepVector( ...
                matrix.ContactDutyCycles, 'ContactDutyCycles', 0, 1, false);
            matrix.ShortcutRiskAvailabilities = ThesisExperimentSuite.validateSweepVector( ...
                matrix.ShortcutRiskAvailabilities, 'ShortcutRiskAvailabilities', 0.01, 0.99, false);
            matrix.ReliabilityWeights = ThesisExperimentSuite.validateSweepVector( ...
                matrix.ReliabilityWeights, 'ReliabilityWeights', 0, 1, false);
            matrix.Seeds = ThesisExperimentSuite.validateSweepVector( ...
                matrix.Seeds, 'Seeds', 0, 2^32 - 1, true);

            if isvector(matrix.RoutePairs) && numel(matrix.RoutePairs) == 2
                matrix.RoutePairs = reshape(matrix.RoutePairs, 1, 2);
            end
            if ~isnumeric(matrix.RoutePairs) || ~isreal(matrix.RoutePairs) || ...
                    isempty(matrix.RoutePairs) || size(matrix.RoutePairs, 2) ~= 2 || ...
                    any(~isfinite(matrix.RoutePairs), 'all') || ...
                    any(matrix.RoutePairs ~= floor(matrix.RoutePairs), 'all') || ...
                    any(matrix.RoutePairs < 1, 'all') || ...
                    any(matrix.RoutePairs(:, 1) == matrix.RoutePairs(:, 2))
                error('ThesisExperimentSuite:InvalidRoutePairs', ...
                    'RoutePairs must be a nonempty Nx2 matrix of distinct positive integer endpoints.');
            end

            minimumNodeCount = min(prod(matrix.Constellations, 2));
            if any(matrix.RoutePairs > minimumNodeCount, 'all')
                error('ThesisExperimentSuite:InvalidRoutePairs', ...
                    'Every route endpoint must exist in every requested constellation.');
            end

            if ~isnumeric(matrix.TimeSteps) || ~isreal(matrix.TimeSteps) || ...
                    ~isscalar(matrix.TimeSteps) || ~isfinite(matrix.TimeSteps) || ...
                    matrix.TimeSteps < 1 || matrix.TimeSteps ~= floor(matrix.TimeSteps)
                error('ThesisExperimentSuite:InvalidTimeSteps', ...
                    'TimeSteps must be a positive integer scalar.');
            end
        end

        function values = validateSweepVector(values, fieldName, minimumValue, maximumValue, requireInteger)
            if ~isnumeric(values) || ~isreal(values) || isempty(values) || ~isvector(values) || ...
                    any(~isfinite(values), 'all') || any(values < minimumValue, 'all') || ...
                    any(values > maximumValue, 'all') || ...
                    (requireInteger && any(values ~= floor(values), 'all'))
                error('ThesisExperimentSuite:InvalidSweepValues', ...
                    '%s must be a nonempty finite numeric vector in [%g, %g].', ...
                    fieldName, minimumValue, maximumValue);
            end

            values = reshape(values, 1, []);
        end

        function row = emptyResultRow()
            row = struct( ...
                'Seed', 0, ...
                'SourceNode', 0, ...
                'DestinationNode', 0, ...
                'PlaneCount', 0, ...
                'SatellitesPerPlane', 0, ...
                'NodeCount', 0, ...
                'ContactDutyCycle', 0, ...
                'ShortcutRiskAvailability', 0, ...
                'ReliabilityWeight', 0, ...
                'TimeSteps', 0, ...
                'BaselineMeanLatencyMs', 0, ...
                'ReliableMeanLatencyMs', 0, ...
                'ReliableLatencyPenaltyMs', 0, ...
                'BaselineMeanEffectiveLatencyMs', 0, ...
                'ReliableMeanEffectiveLatencyMs', 0, ...
                'EffectiveLatencyImprovementMs', 0, ...
                'BaselineMeanAvailability', 0, ...
                'ReliableMeanAvailability', 0, ...
                'ReliableAvailabilityGain', 0, ...
                'BaselineRouteChanges', 0, ...
                'ReliableRouteChanges', 0);
        end

        function row = resultRowFromSummary(cfg, summary)
            row = ThesisExperimentSuite.emptyResultRow();
            row.Seed = cfg.Seed;
            row.SourceNode = cfg.SourceNode;
            row.DestinationNode = cfg.DestinationNode;
            row.PlaneCount = cfg.PlaneCount;
            row.SatellitesPerPlane = cfg.SatellitesPerPlane;
            row.NodeCount = cfg.NodeCount;
            row.ContactDutyCycle = cfg.ContactDutyCycle;
            row.ShortcutRiskAvailability = cfg.ShortcutRiskAvailability;
            row.ReliabilityWeight = cfg.ReliabilityWeight;
            row.TimeSteps = cfg.TimeSteps;
            row.BaselineMeanLatencyMs = summary.BaselineMeanLatencyMs;
            row.ReliableMeanLatencyMs = summary.ReliableMeanLatencyMs;
            row.ReliableLatencyPenaltyMs = summary.ReliableLatencyPenaltyMs;
            row.BaselineMeanEffectiveLatencyMs = summary.BaselineMeanEffectiveLatencyMs;
            row.ReliableMeanEffectiveLatencyMs = summary.ReliableMeanEffectiveLatencyMs;
            row.EffectiveLatencyImprovementMs = summary.EffectiveLatencyImprovementMs;
            row.BaselineMeanAvailability = summary.BaselineMeanAvailability;
            row.ReliableMeanAvailability = summary.ReliableMeanAvailability;
            row.ReliableAvailabilityGain = summary.ReliableAvailabilityGain;
            row.BaselineRouteChanges = summary.BaselineRouteChanges;
            row.ReliableRouteChanges = summary.ReliableRouteChanges;
        end
    end
end

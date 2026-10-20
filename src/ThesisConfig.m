classdef ThesisConfig
    % THESISCONFIG - Provider-neutral defaults for the LEO routing thesis.

    methods (Static)
        function cfg = default()
            cfg = struct();
            cfg.Profile = 'WalkerLEO';
            cfg.PlaneCount = 4;
            cfg.SatellitesPerPlane = 8;
            cfg.InterPlaneLinks = true;
            cfg.NodeCount = cfg.PlaneCount * cfg.SatellitesPerPlane;
            cfg.Seed = 42;
            cfg.LinkModel = 'ControlledGraphWeights';
            cfg.LinkQualityTimeMode = 'TimeVarying';
            cfg.ContactWindowModel = 'DeterministicInterPlane';
            cfg.ContactDutyCycle = 0.65;
            cfg.ReliabilityStressMode = 'InterPlaneShortcutRisk';
            cfg.ShortcutRiskAvailability = 0.35;
            cfg.ReliabilityWeight = 0.5;
            cfg.SourceNode = 1;
            cfg.DestinationNode = 16;
            cfg.TimeSteps = 12;
            cfg.Routing = struct( ...
                'Baseline', 'ShortestPath', ...
                'Main', 'ReliabilityAware');
            cfg.PrimaryMetrics = {'LatencyMs', 'Availability', 'EffectiveLatencyMs', 'RouteChanges'};
        end

        function cfg = withOverrides(overrides)
            cfg = ThesisConfig.default();
            if nargin < 1 || isempty(overrides)
                return;
            end

            names = fieldnames(overrides);
            for idx = 1:numel(names)
                cfg.(names{idx}) = overrides.(names{idx});
            end

            if (isfield(overrides, 'PlaneCount') || isfield(overrides, 'SatellitesPerPlane')) && ...
                    ~isfield(overrides, 'NodeCount')
                cfg.NodeCount = cfg.PlaneCount * cfg.SatellitesPerPlane;
            end
        end
    end
end

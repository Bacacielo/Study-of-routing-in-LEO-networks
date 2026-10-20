classdef ThesisTopology
    % THESISTOPOLOGY - Minimal generated LEO graph models for thesis experiments.

    methods (Static)
        function G = buildWalkerLEO(cfg)
            G = ThesisTopology.buildWalkerLEOSnapshot(cfg, 1);
        end

        function G = buildWalkerLEOSnapshot(cfg, timeIndex)
            arguments
                cfg struct
                timeIndex (1, 1) double {mustBeInteger, mustBePositive}
            end

            if ~isfield(cfg, 'Seed') || ~isnumeric(cfg.Seed) || ~isreal(cfg.Seed) || ...
                    ~isscalar(cfg.Seed) || ~isfinite(cfg.Seed) || cfg.Seed < 0 || ...
                    cfg.Seed ~= floor(cfg.Seed) || cfg.Seed > 2^32 - 1
                error('ThesisTopology:InvalidSeed', ...
                    'Seed must be an integer scalar in [0, 2^32 - 1].');
            end
            derivedSeed = mod(double(cfg.Seed) + 997 * double(timeIndex), 2^32);
            callerRandomState = rng;
            randomStateCleanup = onCleanup(@() rng(callerRandomState));
            rng(derivedSeed);
            planeCount = cfg.PlaneCount;
            satsPerPlane = cfg.SatellitesPerPlane;
            if ~isnumeric(planeCount) || ~isscalar(planeCount) || ~isfinite(planeCount) || ...
                    planeCount < 1 || planeCount ~= floor(planeCount)
                error('ThesisTopology:InvalidPlaneCount', ...
                    'PlaneCount must be a positive integer.');
            end
            if ~isnumeric(satsPerPlane) || ~isscalar(satsPerPlane) || ~isfinite(satsPerPlane) || ...
                    satsPerPlane < 3 || satsPerPlane ~= floor(satsPerPlane)
                error('ThesisTopology:InvalidSatellitesPerPlane', ...
                    'SatellitesPerPlane must be an integer greater than or equal to 3.');
            end
            if isfield(cfg, 'InterPlaneLinks') && cfg.InterPlaneLinks && planeCount < 2
                error('ThesisTopology:InvalidPlaneCount', ...
                    'At least two planes are required when InterPlaneLinks is enabled.');
            end

            expectedNodeCount = planeCount * satsPerPlane;
            if isfield(cfg, 'NodeCount') && ...
                    (~isnumeric(cfg.NodeCount) || ~isscalar(cfg.NodeCount) || ...
                    ~isfinite(cfg.NodeCount) || cfg.NodeCount ~= expectedNodeCount)
                error('ThesisTopology:InconsistentNodeCount', ...
                    'NodeCount must equal PlaneCount multiplied by SatellitesPerPlane.');
            end

            [intraS, intraT] = ThesisTopology.buildIntraPlaneEdges(planeCount, satsPerPlane);
            if isfield(cfg, 'InterPlaneLinks') && cfg.InterPlaneLinks
                [interS, interT] = ThesisTopology.buildInterPlaneEdges(planeCount, satsPerPlane, cfg, timeIndex);
            else
                interS = zeros(0, 1);
                interT = zeros(0, 1);
            end

            s = [intraS; interS];
            t = [intraT; interT];
            G = graph(s, t);

            linkQualityTimeMode = ThesisTopology.linkQualityTimeMode(cfg);
            if strcmp(linkQualityTimeMode, 'StaticByEdge')
                [latencyMs, availability] = ThesisTopology.staticLinkQuality(G, cfg);
            else
                edgeCount = numedges(G);
                edgePhase = (1:edgeCount)' + timeIndex;
                timeDrift = 0.5 * sin(edgePhase / 3);
                latencyMs = 4 + timeDrift + 3 * rand(edgeCount, 1);
                availability = 0.90 + 0.09 * rand(edgeCount, 1);
            end

            G.Edges.LatencyMs = latencyMs;
            G.Edges.Availability = availability;
            G.Edges.Availability = min(max(G.Edges.Availability, 0.01), 0.999);
            G.Edges.IsInterPlane = ThesisTopology.findInterPlaneEdges(G, satsPerPlane);
            G = ThesisTopology.applyReliabilityStress(G, cfg, timeIndex);
            clear randomStateCleanup;
        end

        function [s, t] = buildIntraPlaneEdges(planeCount, satsPerPlane)
            edgeCount = planeCount * satsPerPlane;
            s = zeros(edgeCount, 1);
            t = zeros(edgeCount, 1);
            edgeIndex = 1;

            for planeIdx = 1:planeCount
                for satIdx = 1:satsPerPlane
                    nextSatIdx = mod(satIdx, satsPerPlane) + 1;
                    s(edgeIndex) = ThesisTopology.nodeId(planeIdx, satIdx, satsPerPlane);
                    t(edgeIndex) = ThesisTopology.nodeId(planeIdx, nextSatIdx, satsPerPlane);
                    edgeIndex = edgeIndex + 1;
                end
            end
        end

        function [s, t] = buildInterPlaneEdges(planeCount, satsPerPlane, cfg, timeIndex)
            maxEdges = planeCount * satsPerPlane;
            s = zeros(maxEdges, 1);
            t = zeros(maxEdges, 1);
            edgeIndex = 1;
            dutyCycle = ThesisTopology.contactDutyCycle(cfg);

            for planeIdx = 1:planeCount
                if planeCount == 2 && planeIdx == 2
                    continue;
                end

                nextPlaneIdx = mod(planeIdx, planeCount) + 1;
                firstEdgeForPair = edgeIndex;
                for satIdx = 1:satsPerPlane
                    if ThesisTopology.isInterPlaneContactAvailable( ...
                            cfg, planeIdx, satIdx, satsPerPlane, timeIndex, dutyCycle)
                        s(edgeIndex) = ThesisTopology.nodeId(planeIdx, satIdx, satsPerPlane);
                        t(edgeIndex) = ThesisTopology.nodeId(nextPlaneIdx, satIdx, satsPerPlane);
                        edgeIndex = edgeIndex + 1;
                    end
                end

                if dutyCycle > 0 && edgeIndex == firstEdgeForPair
                    fallbackSatIdx = mod(cfg.Seed + timeIndex + planeIdx - 1, satsPerPlane) + 1;
                    s(edgeIndex) = ThesisTopology.nodeId(planeIdx, fallbackSatIdx, satsPerPlane);
                    t(edgeIndex) = ThesisTopology.nodeId(nextPlaneIdx, fallbackSatIdx, satsPerPlane);
                    edgeIndex = edgeIndex + 1;
                end
            end

            s = s(1:edgeIndex - 1);
            t = t(1:edgeIndex - 1);
        end

        function dutyCycle = contactDutyCycle(cfg)
            if isfield(cfg, 'ContactDutyCycle')
                dutyCycle = cfg.ContactDutyCycle;
            else
                dutyCycle = 1;
            end

            if ~isnumeric(dutyCycle) || ~isreal(dutyCycle) || ~isscalar(dutyCycle) || ...
                    ~isfinite(dutyCycle) || dutyCycle < 0 || dutyCycle > 1
                error('ThesisTopology:InvalidContactDutyCycle', ...
                    'ContactDutyCycle must be a finite scalar in [0, 1].');
            end
        end

        function isAvailable = isInterPlaneContactAvailable(cfg, planeIdx, satIdx, satsPerPlane, timeIndex, dutyCycle)
            if dutyCycle >= 1
                isAvailable = true;
                return;
            end

            if dutyCycle <= 0
                isAvailable = false;
                return;
            end

            baseActiveCount = max(1, floor(dutyCycle * satsPerPlane));
            timeExtra = double(mod(timeIndex + planeIdx, 3) == 0);
            activeCount = min(satsPerPlane, baseActiveCount + timeExtra);
            windowStart = mod(cfg.Seed + timeIndex + planeIdx - 2, satsPerPlane) + 1;
            offset = mod(satIdx - windowStart, satsPerPlane);

            isAvailable = offset < activeCount;
        end

        function isInterPlane = findInterPlaneEdges(G, satsPerPlane)
            endNodes = G.Edges.EndNodes;
            sourcePlane = ceil(endNodes(:, 1) ./ satsPerPlane);
            targetPlane = ceil(endNodes(:, 2) ./ satsPerPlane);
            isInterPlane = sourcePlane ~= targetPlane;
        end

        function G = applyReliabilityStress(G, cfg, timeIndex)
            if ~isfield(cfg, 'ReliabilityStressMode') || ...
                    ~strcmp(cfg.ReliabilityStressMode, 'InterPlaneShortcutRisk')
                return;
            end

            riskAvailability = 0.35;
            if isfield(cfg, 'ShortcutRiskAvailability')
                riskAvailability = cfg.ShortcutRiskAvailability;
            end
            if ~isnumeric(riskAvailability) || ~isreal(riskAvailability) || ...
                    ~isscalar(riskAvailability) || ~isfinite(riskAvailability) || ...
                    riskAvailability < 0.01 || riskAvailability > 0.99
                error('ThesisTopology:InvalidShortcutRiskAvailability', ...
                    'ShortcutRiskAvailability must be a finite scalar in [0.01, 0.99].');
            end

            interPlaneEdges = find(G.Edges.IsInterPlane);
            if isempty(interPlaneEdges)
                return;
            end

            if strcmp(ThesisTopology.linkQualityTimeMode(cfg), 'StaticByEdge')
                endNodes = sort(G.Edges.EndNodes(interPlaneEdges, :), 2);
                edgePhase = mod(3 * endNodes(:, 1) + 5 * endNodes(:, 2) + cfg.Seed, 4);
                riskyEdges = interPlaneEdges(edgePhase == 0);
            else
                edgePhase = mod(interPlaneEdges + cfg.Seed + 2 * timeIndex, 4);
                riskyEdges = interPlaneEdges(edgePhase == 0);
                if isempty(riskyEdges)
                    riskyEdges = interPlaneEdges(1);
                end
            end

            G.Edges.Availability(riskyEdges) = min(G.Edges.Availability(riskyEdges), riskAvailability);
        end

        function mode = linkQualityTimeMode(cfg)
            mode = 'TimeVarying';
            if isfield(cfg, 'LinkQualityTimeMode')
                mode = cfg.LinkQualityTimeMode;
            end
            if ~(ischar(mode) || (isstring(mode) && isscalar(mode)))
                error('ThesisTopology:InvalidLinkQualityTimeMode', ...
                    'LinkQualityTimeMode must be TimeVarying or StaticByEdge.');
            end
            mode = char(mode);
            if ~ismember(mode, {'TimeVarying', 'StaticByEdge'})
                error('ThesisTopology:InvalidLinkQualityTimeMode', ...
                    'LinkQualityTimeMode must be TimeVarying or StaticByEdge.');
            end
        end

        function [latencyMs, availability] = staticLinkQuality(G, cfg)
            endNodes = sort(G.Edges.EndNodes, 2);
            latencyUnit = ThesisTopology.deterministicUnit(endNodes, cfg.Seed, 17);
            availabilityUnit = ThesisTopology.deterministicUnit(endNodes, cfg.Seed, 53);
            edgePhase = endNodes(:, 1) + endNodes(:, 2);

            latencyMs = 4 + 0.5 * sin(edgePhase / 3) + 3 * latencyUnit;
            availability = 0.90 + 0.09 * availabilityUnit;
        end

        function values = deterministicUnit(endNodes, seed, salt)
            modulus = 2147483647;
            keys = mod(104729 * endNodes(:, 1) + 130363 * endNodes(:, 2) + ...
                1009 * double(seed) + salt, modulus);
            values = keys ./ modulus;
        end

        function id = nodeId(planeIdx, satIdx, satsPerPlane)
            id = (planeIdx - 1) * satsPerPlane + satIdx;
        end
    end
end

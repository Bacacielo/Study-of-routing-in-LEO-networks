projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'src'));

if ~exist('outputDir', 'var') || isempty(outputDir)
    outputDir = fullfile(projectRoot, 'outputs');
end
if ~isfolder(outputDir)
    mkdir(outputDir);
end

if ~exist('controlledConstellationMatrix', 'var') || ...
        isempty(controlledConstellationMatrix)
    controlledConstellationMatrix = ThesisExperimentSuite.defaultMatrix();
end

baseMatrix = controlledConstellationMatrix;
constellations = baseMatrix.Constellations;
controlledConstellationResults = table();

for constellationIdx = 1:size(constellations, 1)
    planeCount = constellations(constellationIdx, 1);
    satsPerPlane = constellations(constellationIdx, 2);
    sourceNode = 1;
    destinationSatellite = floor(satsPerPlane / 2) + 1;
    destinationNode = satsPerPlane + destinationSatellite;

    matrix = baseMatrix;
    matrix.Constellations = [planeCount, satsPerPlane];
    matrix.RoutePairs = [sourceNode, destinationNode];
    constellationResults = ThesisExperimentSuite.runMatrix(matrix);
    controlledConstellationResults = [controlledConstellationResults; constellationResults]; %#ok<AGROW>
end

controlledConstellationCsvPath = fullfile( ...
    outputDir, 'controlled_constellation_sensitivity_results.csv');
controlledConstellationMatPath = fullfile( ...
    outputDir, 'controlled_constellation_sensitivity_results.mat');

ThesisExperimentSuite.writeTable( ...
    controlledConstellationResults, controlledConstellationCsvPath);
save(controlledConstellationMatPath, ...
    'controlledConstellationResults', 'baseMatrix', 'constellations');

controlledConstellationSummary = groupsummary( ...
    controlledConstellationResults, ...
    {'PlaneCount', 'SatellitesPerPlane', 'SourceNode', 'DestinationNode'}, ...
    {'mean', 'std'}, { ...
    'ReliableAvailabilityGain', ...
    'ReliableLatencyPenaltyMs', ...
    'EffectiveLatencyImprovementMs', ...
    'BaselineRouteChanges', ...
    'ReliableRouteChanges'});

disp('Controlled constellation-size sensitivity completed');
disp(['Rows: ', num2str(height(controlledConstellationResults))]);
disp(['CSV: ', controlledConstellationCsvPath]);
disp(['MAT: ', controlledConstellationMatPath]);
disp(controlledConstellationSummary);

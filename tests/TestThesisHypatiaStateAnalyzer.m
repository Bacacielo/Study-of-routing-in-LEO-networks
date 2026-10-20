classdef TestThesisHypatiaStateAnalyzer < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDirectory = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(testDirectory);
            addpath(fullfile(projectRoot, 'src'));
        end
    end

    methods (Test)
        function reconstructsRouteChangesFromDeltaState(testCase)
            fixtureDirectory = ...
                TestThesisHypatiaStateAnalyzer.fixtureDirectory();
            result = ThesisHypatiaStateAnalyzer.analyzeRouteChanges( ...
                fixtureDirectory, 100, 1);

            testCase.verifyEqual(result.SatelliteCount, 2);
            testCase.verifyEqual(result.GroundStationCount, 3);
            testCase.verifyEqual(result.SnapshotCount, 10);
            testCase.verifyEqual( ...
                result.PairTable.RouteChanges, [2; 1; 1]);
            testCase.verifyEqual( ...
                result.SortedRouteChanges, [1; 1; 2]);
            testCase.verifyEqual(result.MedianRouteChanges, 1);
        end

        function calculatedEcdfMatchesReference(testCase)
            result = ThesisHypatiaStateAnalyzer.analyzeRouteChanges( ...
                TestThesisHypatiaStateAnalyzer.fixtureDirectory(), ...
                100, 1);
            referencePath = fullfile( ...
                TestThesisHypatiaStateAnalyzer.fixtureDirectory(), ...
                'reference_route_changes_ecdf.txt');
            comparison = ...
                ThesisHypatiaStateAnalyzer.compareRouteChangeEcdf( ...
                result, referencePath);

            testCase.verifyTrue(comparison.MatchesExactly);
            testCase.verifyEqual(comparison.MismatchCount, 0);
            testCase.verifyEqual(comparison.CalculatedPairCount, 3);
        end

        function missingSnapshotIsRejected(testCase)
            fixtureDirectory = ...
                TestThesisHypatiaStateAnalyzer.fixtureDirectory();
            temporaryDirectory = fullfile( ...
                tempdir, ['hypatia-state-', ...
                char(java.util.UUID.randomUUID())]);
            cleanup = onCleanup(@() ...
                TestThesisHypatiaStateAnalyzer.removeDirIfPresent( ...
                temporaryDirectory));
            copyfile(fixtureDirectory, temporaryDirectory);
            delete(fullfile(temporaryDirectory, ...
                'dynamic_state_100ms_for_1s', ...
                'fstate_900000000.txt'));

            testCase.verifyError( ...
                @() ThesisHypatiaStateAnalyzer.analyzeRouteChanges( ...
                temporaryDirectory, 100, 1), ...
                'ThesisHypatiaStateAnalyzer:IncompleteTimeSeries');
            clear cleanup;
        end
    end

    methods (Static, Access = private)
        function pathValue = fixtureDirectory()
            testDirectory = fileparts(mfilename('fullpath'));
            pathValue = fullfile( ...
                testDirectory, 'fixtures', 'hypatia_state_small');
        end

        function removeDirIfPresent(pathToRemove)
            if isfolder(pathToRemove)
                rmdir(pathToRemove, 's');
            end
        end
    end
end

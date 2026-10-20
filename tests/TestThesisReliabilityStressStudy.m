classdef TestThesisReliabilityStressStudy < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function defaultStudyFindsBoundedBenefitRegion(testCase)
            results = ThesisReliabilityStressStudy.run( ...
                ThesisReliabilityStressStudy.defaultSweep());
            summary = ThesisResultsAnalysis.summarizeReliabilityStressAblation( ...
                results);

            testCase.verifyEqual(height(results), 216);
            testCase.verifyEqual(summary.StressRowCount, 189);
            testCase.verifyEqual(summary.NoStressRowCount, 27);
            testCase.verifyTrue(summary.ObservedSignReversal);
            testCase.verifyEqual( ...
                summary.SignReversalLowerAvailability, 0.60, 'AbsTol', 1e-12);
            testCase.verifyEqual( ...
                summary.SignReversalUpperAvailability, 0.70, 'AbsTol', 1e-12);
            testCase.verifyGreaterThan( ...
                summary.NoStressOutcomeCounts.Negative, ...
                summary.NoStressOutcomeCounts.Positive);
            testCase.verifyLessThan( ...
                summary.NoStressEffectiveLatencyImprovement.Mean, 0);
            testCase.verifyGreaterThan( ...
                summary.SnapshotDiagnostics.MeanImprovementWhenBaselineRiskyMs, 0);
            testCase.verifyLessThan( ...
                summary.SnapshotDiagnostics.MeanImprovementWhenBaselineNotRiskyMs, 0);
        end

        function writeFigureCreatesReliabilityStressArtifact(testCase)
            sweep = ThesisReliabilityStressStudy.defaultSweep();
            sweep.Constellations = [4 8];
            sweep.ContactDutyCycles = 0.65;
            sweep.ShortcutRiskAvailabilities = [0.20 0.70 0.90];
            sweep.ReliabilityWeights = [0.30 0.90];
            sweep.TimeSteps = 3;
            results = ThesisReliabilityStressStudy.run(sweep);
            outputDir = tempname;
            mkdir(outputDir);
            cleanup = onCleanup(@() rmdir(outputDir, 's'));

            outputPath = ...
                ThesisResultsAnalysis.writeReliabilityStressAblationFigure( ...
                results, outputDir);

            testCase.verifyTrue(isfile(outputPath));
            testCase.verifyGreaterThan(dir(outputPath).bytes, 0);
            clear cleanup;
        end
    end
end

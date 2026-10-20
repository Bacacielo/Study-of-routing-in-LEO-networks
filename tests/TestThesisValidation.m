classdef TestThesisValidation < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addSourcePath(~)
            testDir = fileparts(mfilename('fullpath'));
            addpath(fullfile(fileparts(testDir), 'src'));
        end
    end

    methods (Test)
        function basicValidationChecksPass(testCase)
            summary = ThesisValidation.runBasicChecks();

            testCase.verifyEqual(summary.Passed, 6);
            testCase.verifyEqual(summary.Total, 6);
            testCase.verifyTrue(summary.AllPassed);
        end
    end
end

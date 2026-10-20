testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
addpath(fullfile(projectRoot, 'src'));

results = runtests(testDir);
disp(table(results));

assert(~any([results.Failed]), 'One or more tests failed.');
assert(~any([results.Incomplete]), 'One or more tests were incomplete.');

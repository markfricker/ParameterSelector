classdef testParameterSelectorRunSweep < matlab.unittest.TestCase
%TESTPARAMETERSELECTORRUNSWEEP  End-to-end smoke test: a tiny synthetic
%image + ground-truth skeleton run through the real enhance -> skeleton ->
%ROC pipeline via the ParameterSelector_sandbox engine, exercising it
%exactly the way the future .mlapp UI will (Phase 2), before any UI exists.
%
% USAGE
%   results = runtests('tests/testParameterSelectorRunSweep');
%   table(results)
%
% DEPENDENCIES (siblings under the same "Matlab Projects" parent folder;
% tests SKIP -- via tc.assumeTrue -- rather than fail if a sibling repo
% isn't checked out on this machine):
%   AnalyzERproject_sandbox/core   -- funcEnhanceRun/funcEnhanceDispatcher,
%                                      erSkeletonRun/funcSkeletonRun/funcSkeletonDispatcher
%   CurvilinearFilters_sandbox     -- hessian2DFilters (vesselness, legacyFlag=0)
%   Skeletonization_sandbox        -- hysteresisSkeletonize, skeletonPostProcess
%   NetworkCommon_sandbox          -- analyzerRocAnalysis
%
% Deliberately picks the cheapest real method pair (vesselness / hysteresis)
% and disables every optional stage (h-minima, junction repair, cisternae,
% guided filter, GCC) so the smoke test exercises the sweep engine's
% plumbing without pulling in the rest of the algorithm library.

    methods (TestClassSetup)
        function addPaths(tc)
            siblingRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

            deps = { ...
                fullfile(siblingRoot, 'AnalyzERproject_sandbox', 'core'), ...
                fullfile(siblingRoot, 'CurvilinearFilters_sandbox'), ...
                fullfile(siblingRoot, 'Skeletonization_sandbox'), ...
                fullfile(siblingRoot, 'NetworkCommon_sandbox')};
            for k = 1:numel(deps)
                tc.assumeTrue(isfolder(deps{k}), ...
                    sprintf('Sibling dependency not found, skipping: %s', deps{k}));
            end
            for k = 1:3
                addpath(genpath(deps{k}));
            end
            addpath(deps{4});
        end
    end

    methods (Test)
        function testSweepRanksCombosAndAppliesTheWinner(tc)
            n = 48;
            im = zeros(n, n, 'single');
            im(20:22, 5:43) = 1;
            im = single(mat2gray(imgaussfilt(im, 1)));

            gt = false(n, n);
            gt(21, 5:43) = true;

            roiMask = true(n, n);
            cisterna = [];
            erMask = true(n, n);
            erFenestrations = [];
            cellBoundary = [];
            imBackground = [];

            enhanceCurrent = struct( ...
                'use', true, 'method', 'vesselness', 'methodPrevious', 'vesselness', ...
                'guidedFilterUse', false, 'useParfor', false, ...
                'vesselness', struct('sigmaMin', 1, 'sigmaStep', 1, 'sigmaMax', 2, 'beta', 0.5, 'c', 0.15));
            enhanceDefaults = enhanceCurrent;

            skeletonCurrent = struct( ...
                'method', 'hysteresis', 'methodPrevious', 'hysteresis', ...
                'pruneLength', 0, 'minArea', 1, 'gccUse', false, 'maskUse', true, ...
                'hminUse', false, 'hmin', 0, 'repairUse', false, ...
                'hysteresis', struct('threshHigh', 0.5, 'threshLow', 0.3, 'threshold', 0.3));
            skeletonDefaults = skeletonCurrent;

            enhanceFields  = parameterSelectorMethodFields(enhanceDefaults, enhanceCurrent, 'vesselness');
            skeletonFields = parameterSelectorMethodFields(skeletonDefaults, skeletonCurrent, 'hysteresis');

            rows = [ ...
                tc.makeRows('enhance', 'vesselness', enhanceFields, 'sigmaMax', true, 2, 1, 3), ...
                tc.makeRows('skeleton', 'hysteresis', skeletonFields, 'threshHigh', true, 0.3, 0.2, 0.5)];

            combos = parameterSelectorExpandCombos(rows, {'vesselness'}, {'hysteresis'});
            tc.verifyEqual(numel(combos), 2 * 2);

            results = parameterSelectorRunSweep(im, gt, roiMask, cisterna, erMask, erFenestrations, ...
                cellBoundary, imBackground, enhanceCurrent, skeletonCurrent, combos, 2, 4, 'smoke-test');

            tc.verifyEqual(height(results), 4);
            tc.verifyTrue(all(results.F1 >= 0 & results.F1 <= 1));

            [~, iBest] = max(results.F1);
            winner = combos(results.combo(iBest));

            appliedEnhance = parameterSelectorApplyToParams( ...
                enhanceDefaults, enhanceCurrent, winner.enhanceMethod, winner.enhanceValues);
            tc.verifyEqual(appliedEnhance.method, winner.enhanceMethod);
            tc.verifyEqual(appliedEnhance.vesselness.sigmaMax, winner.enhanceValues.sigmaMax);

            appliedSkeleton = parameterSelectorApplyToParams( ...
                skeletonDefaults, skeletonCurrent, winner.skeletonMethod, winner.skeletonValues);
            tc.verifyEqual(appliedSkeleton.method, winner.skeletonMethod);
            tc.verifyEqual(appliedSkeleton.hysteresis.threshHigh, winner.skeletonValues.threshHigh);
        end
    end

    methods (Static, Access = private)
        function rows = makeRows(step, method, fields, tunedName, tune, mn, inc, mx)
            rows = struct('step', {}, 'method', {}, 'parameter', {}, ...
                'current', {}, 'tune', {}, 'min', {}, 'inc', {}, 'max', {});
            for i = 1:numel(fields)
                r = struct('step', step, 'method', method, 'parameter', fields(i).name, ...
                    'current', fields(i).current, 'tune', false, ...
                    'min', fields(i).current, 'inc', 1, 'max', fields(i).current);
                if strcmp(fields(i).name, tunedName)
                    r.tune = tune; r.min = mn; r.inc = inc; r.max = mx;
                end
                rows(end + 1) = r; %#ok<AGROW>
            end
        end
    end
end

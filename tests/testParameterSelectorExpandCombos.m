classdef testParameterSelectorExpandCombos < matlab.unittest.TestCase
%TESTPARAMETERSELECTOREXPANDCOMBOS  Unit tests for parameterSelectorExpandCombos.m.
%
% USAGE
%   results = runtests('tests/testParameterSelectorExpandCombos');
%   table(results)
%
% COVERAGE
%   - single untuned method per step -> exactly 1 combo
%   - mixed-radix expansion of a single method's tuned fields (odometer
%     correctness, same algorithm as the legacy parameter_selector tools'
%     fnc_parameter_sequence)
%   - UNION (not product) across candidate methods within a step -- the
%     deliberate deviation from the legacy tools, which shared one flat
%     table across every checked method and so cross-producted irrelevant
%     methods' rows together
%   - cross-join across the enhance/skeleton steps
%   - error on an empty tune range and on a step with no candidate methods

    methods (TestClassSetup)
        function addPaths(tc) %#ok<MANU>
            rootDir = fullfile(fileparts(mfilename('fullpath')), '..', 'src');
            addpath(rootDir);
        end
    end

    methods (Test)
        function testSingleUntunedMethodPerStepGivesOneCombo(tc)
            rows = [ ...
                tc.mkRow('enhance', 'vesselness', 'sigmaMin', 1, false, 1, 1, 1), ...
                tc.mkRow('skeleton', 'hysteresis', 'threshHigh', 0.5, false, 0.5, 0.5, 0.5)];
            combos = parameterSelectorExpandCombos(rows);
            tc.verifyEqual(numel(combos), 1);
            tc.verifyEqual(combos(1).enhanceMethod, 'vesselness');
            tc.verifyEqual(combos(1).enhanceValues.sigmaMin, 1);
            tc.verifyEqual(combos(1).skeletonMethod, 'hysteresis');
            tc.verifyEqual(combos(1).skeletonValues.threshHigh, 0.5);
        end

        function testMixedRadixExpansionWithinOneMethod(tc)
            % vesselness: sigmaMin tuned over [1 2] (2 values), sigmaMax
            % tuned over [3 4 5] (3 values) -> 6 combos, every pairing present.
            rows = [ ...
                tc.mkRow('enhance', 'vesselness', 'sigmaMin', 1, true, 1, 1, 2), ...
                tc.mkRow('enhance', 'vesselness', 'sigmaMax', 4, true, 3, 1, 5), ...
                tc.mkRow('skeleton', 'hysteresis', 'threshHigh', 0.5, false, 0.5, 0.5, 0.5)];
            combos = parameterSelectorExpandCombos(rows);
            tc.verifyEqual(numel(combos), 6);

            pairs = arrayfun(@(c) sprintf('%g,%g', c.enhanceValues.sigmaMin, c.enhanceValues.sigmaMax), ...
                combos, 'UniformOutput', false);
            expected = {'1,3','2,3','1,4','2,4','1,5','2,5'};
            tc.verifyEqual(sort(pairs), sort(expected));
        end

        function testCandidateMethodsWithinAStepAreUnionedNotMultiplied(tc)
            % enhance: vesselness (2 combos, sweeping sigmaMin) union ridge
            % (3 combos, sweeping alpha) -> 2+3 = 5 enhance-side combos, not 2*3=6.
            rows = [ ...
                tc.mkRow('enhance', 'vesselness', 'sigmaMin', 1, true, 1, 1, 2), ...
                tc.mkRow('enhance', 'ridge', 'alpha', 0.3, true, 0.3, 0.1, 0.5), ...
                tc.mkRow('skeleton', 'hysteresis', 'threshHigh', 0.5, false, 0.5, 0.5, 0.5)];
            combos = parameterSelectorExpandCombos(rows);
            tc.verifyEqual(numel(combos), 5);
            methods = {combos.enhanceMethod};
            tc.verifyEqual(sum(strcmp(methods, 'vesselness')), 2);
            tc.verifyEqual(sum(strcmp(methods, 'ridge')), 3);
        end

        function testCrossJoinAcrossSteps(tc)
            % enhance union = 2 combos, skeleton union = 3 combos -> 2*3 = 6 total.
            rows = [ ...
                tc.mkRow('enhance', 'vesselness', 'sigmaMin', 1, true, 1, 1, 2), ...
                tc.mkRow('skeleton', 'hysteresis', 'threshHigh', 0.3, true, 0.3, 0.1, 0.5)];
            combos = parameterSelectorExpandCombos(rows);
            tc.verifyEqual(numel(combos), 2 * 3);
        end

        function testEmptyTuneRangeThrows(tc)
            rows = [ ...
                tc.mkRow('enhance', 'vesselness', 'sigmaMin', 5, true, 5, 1, 2), ...  % min > max, empty range
                tc.mkRow('skeleton', 'hysteresis', 'threshHigh', 0.5, false, 0.5, 0.5, 0.5)];
            tc.verifyError(@() parameterSelectorExpandCombos(rows), ...
                'parameterSelectorExpandCombos:emptyRange');
        end

        function testMissingStepThrows(tc)
            rows = tc.mkRow('enhance', 'vesselness', 'sigmaMin', 1, false, 1, 1, 1);
            tc.verifyError(@() parameterSelectorExpandCombos(rows), ...
                'parameterSelectorExpandCombos:empty');
        end
    end

    methods (Static, Access = private)
        function r = mkRow(step, method, parameter, current, tune, mn, inc, mx)
            r = struct('step', step, 'method', method, 'parameter', parameter, ...
                'current', current, 'tune', tune, 'min', mn, 'inc', inc, 'max', mx);
        end
    end
end

classdef testParameterSelectorWindowData < matlab.unittest.TestCase
%TESTPARAMETERSELECTORWINDOWDATA  The helpers behind the generic sweep window.
%
% USAGE
%   results = runtests(fullfile(pwd,'tests','testParameterSelectorWindowData.m'));
%
% COVERAGE
%   Method list per chosen step, current method pre-selected          - 1 test
%   Rows and method table for chosen steps; default to current method - 2 tests
%   Sweep-table display; ranking with NaN last; settings shortened    - 2 tests
%
% Needs AnalyzERproject_sandbox/core/parameters on the path.

% SPDX-License-Identifier: GPL-2.0-or-later

    methods (TestClassSetup)
        function addPaths(tc) %#ok<MANU>
            here = fileparts(mfilename('fullpath'));
            addpath(fullfile(here, '..', 'src'));
            addpath(fullfile(here, '..', '..', 'AnalyzERproject_sandbox', 'core', 'parameters'));
        end
    end

    methods (Static, Access = private)
        function spec = makeSpec()
            d = struct('use', 1, 'method', 'li', 'methodPrevious', 'li', ...
                'li', struct('bias', 1.0), 'kapur', struct('bias', 1.0));
            f = struct('minVolume', 0.05, 'fill', '3D');
            spec.meta = [];
            spec.steps = struct('id', {'o.s.segment','o.s.refine'}, 'label', {'Segment','Refine'}, ...
                'current', {d, f}, 'defaults', {d, f}, 'methods', {{'li','kapur'}, {}});
        end
    end

    methods (Test)
        function testMethodItems(tc)
            spec = testParameterSelectorWindowData.makeSpec();
            [items, sel] = parameterSelectorMethodItems(spec, [1 2]);
            tc.verifyEqual(items, {'Segment: li','Segment: kapur'});
            tc.verifyEqual(sel, {'Segment: li'});
            tc.verifyEmpty(parameterSelectorMethodItems(spec, 2));
        end

        function testSelectionRows(tc)
            spec = testParameterSelectorWindowData.makeSpec();
            [r, m] = parameterSelectorSelectionRows(spec, [1 2], {'Segment: kapur','Segment: li'});
            tc.verifyEqual(sort({r.path}), sort({'o.s.segment.kapur.bias','o.s.segment.li.bias','o.s.refine.minVolume'}));
            tc.verifyEqual(size(m), [1 3]);
            tc.verifyEqual(m{1,2}, {'kapur','li'});
            tc.verifyEqual(m{1,3}, 'li');
        end

        function testNoMethodChosenUsesCurrent(tc)
            spec = testParameterSelectorWindowData.makeSpec();
            [r, m] = parameterSelectorSelectionRows(spec, 1, {});
            tc.verifyEqual({r.path}, {'o.s.segment.li.bias'});
            tc.verifyEqual(m{1,2}, {'li'});
        end

        function testTableData(tc)
            spec = testParameterSelectorWindowData.makeSpec();
            r = parameterSelectorSelectionRows(spec, 2, {});
            T = parameterSelectorTableData(r);
            tc.verifyEqual(T.Properties.VariableNames, {'Step','Method','Parameter','Current','Tune','Min','Inc','Max'});
            k = strcmp(T.Parameter, 'minVolume');
            tc.verifyEqual(T.Step{k}, 'refine');
            tc.verifyEqual(T.Current{k}, '0.05');
            tc.verifyFalse(T.Tune(k));
            tc.verifyGreaterThan(T.Max(k), T.Min(k));
        end

        function testResultsRanking(tc)
            R = table((1:3)', ["ok";"error: x";"ok"], ...
                ["o.s.segment.method=""li"";o.s.refine.minVolume=0.1;";"a";"b"], ...
                ["o.s.refine";"o.s.refine";"o.s.refine"], {'f';'f';'f'}, [0.2;NaN;0.9], ...
                'VariableNames', {'combo','status','settings','rerunFrom','filename','F1'});
            T = parameterSelectorResultsTable(R, 'F1');
            tc.verifyEqual(T.combo', [3 1 2]);
            tc.verifyEqual(T.settings(2), "segment.method=""li"";refine.minVolume=0.1;");
            tc.verifyFalse(ismember('filename', T.Properties.VariableNames));
        end
    end
end
